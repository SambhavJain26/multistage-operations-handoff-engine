[CmdletBinding()]
param(
  [string]$InvalidModel = "invalid-model-for-make-ready-fallback-test"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$workflowPath = Join-Path $repoRoot "n8n-workflows\wf-9-ai-message-interpreter.json"
$testPath = Join-Path $repoRoot "data\ai-fallback-test.json"
$restorePath = Join-Path $repoRoot "data\ai-fallback-restore.json"
$containerTestPath = "/data/ai-fallback-test.json"
$containerRestorePath = "/data/ai-fallback-restore.json"
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Get-EnvValue([string]$Name, [string]$Default = "") {
  $path = Join-Path $repoRoot ".env"
  if (-not (Test-Path -LiteralPath $path)) { return $Default }
  $line = Get-Content -LiteralPath $path | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s*=" } | Select-Object -Last 1
  if (-not $line) { return $Default }
  $value = ($line -replace "^\s*$([regex]::Escape($Name))\s*=\s*", "").Trim().Trim('"').Trim("'")
  if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
  return $value
}

function Invoke-N8nSql([string]$Sql) {
  $result = $Sql | docker exec -i make-ready-postgres psql -q -U n8n -d n8n -tA
  if ($LASTEXITCODE -ne 0) { throw "n8n database query failed." }
  return ($result | Select-Object -First 1).Trim()
}

function Invoke-AppSql([string]$Sql) {
  $result = $Sql | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -tA
  if ($LASTEXITCODE -ne 0) { throw "application database query failed." }
  return ($result | Select-Object -First 1).Trim()
}

function Import-Interpreter([string]$HostPath, [string]$ContainerPath) {
  docker exec make-ready-n8n n8n import:workflow --input=$ContainerPath | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "AI interpreter import failed." }
  docker exec make-ready-n8n n8n publish:workflow --id=wf9-ai-interpreter | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "AI interpreter publish failed." }
  docker compose restart n8n | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "n8n restart failed." }
  for ($attempt = 0; $attempt -lt 45; $attempt++) {
    Start-Sleep -Seconds 1
    try {
      $response = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:5678/healthz" -TimeoutSec 3
      $probe = Invoke-WebRequest -UseBasicParsing -SkipHttpErrorCheck -Uri "http://localhost:5678/webhook/vendor-in" -Method Post -ContentType "application/json" -Body "{}" -TimeoutSec 3
      if ($response.StatusCode -eq 200 -and $probe.StatusCode -eq 401) { return }
    } catch {}
  }
  throw "n8n or the vendor-in webhook did not become ready after interpreter import."
}

node (Join-Path $scriptDir "generate-airtable-email-workflows.js") | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Workflow generation failed." }

$credentialId = Invoke-N8nSql "SELECT id FROM credentials_entity WHERE name='Make-Ready OpenAI' LIMIT 1;"
if ([string]::IsNullOrWhiteSpace($credentialId)) { throw "Create the Make-Ready OpenAI credential before running the fallback check." }
$normalModel = Get-EnvValue "OPENAI_MODEL_CLASSIFY" "gpt-5.6-luna"
$vendorToken = Get-EnvValue "VENDOR_IN_DEMO_TOKEN" "local-stage-4-vendor-in-token"

$canonical = Get-Content -Raw -LiteralPath $workflowPath
$restoreJson = $canonical.Replace("cred_make_ready_openai", $credentialId).Replace("gpt-5.6-luna", $normalModel)
$testJson = $canonical.Replace("cred_make_ready_openai", $credentialId).Replace("gpt-5.6-luna", $InvalidModel)
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $testPath) | Out-Null
[IO.File]::WriteAllText($restorePath, $restoreJson, $utf8)
[IO.File]::WriteAllText($testPath, $testJson, $utf8)

$restored = $false
try {
  Import-Interpreter $testPath $containerTestPath
  & (Join-Path $scriptDir "reset-demo.ps1") | Out-Null

  $runId = [guid]::NewGuid().ToString("N")
  $providerId = "ai-fallback-$runId"
  $message = "Which paint specification applies to 12B? fallback-$runId"
  $body = @{
    token = $vendorToken
    channel = "generic"
    sender_ref = "placeholder_rivera_painting_tg"
    provider_message_id = $providerId
    text = $message
  } | ConvertTo-Json
  Invoke-RestMethod -Uri "http://localhost:5678/webhook/vendor-in" -Method Post -ContentType "application/json" -Body $body -TimeoutSec 180 | Out-Null

  $status = Invoke-AppSql "SELECT ai_result->>'status' FROM communication_message WHERE channel='generic' AND provider_message_id='$providerId' LIMIT 1;"
  if ($status -ne "fallback_manager_review") { throw "Expected fallback_manager_review, got '$status'." }
  $fallbackEvents = [int](Invoke-AppSql "SELECT count(*) FROM event_log WHERE event_type='classification_fallback' AND raw_text='$($message.Replace("'", "''"))';")
  if ($fallbackEvents -ne 1) { throw "Expected exactly one classification_fallback event; found $fallbackEvents." }
  $paintActive = [int](Invoke-AppSql "SELECT count(*) FROM turn_stage ts JOIN `"turn`" t ON t.id=ts.turn_id WHERE t.unit_label='12B' AND ts.stage_code='PAINT' AND ts.status='active';")
  if ($paintActive -ne 1) { throw "AI fallback changed the 12B Paint stage." }

  Write-Host "AI fallback check passed: invalid model produced one fallback event and no stage mutation."
} finally {
  try {
    Import-Interpreter $restorePath $containerRestorePath
    $restored = $true
  } finally {
    Remove-Item -LiteralPath $testPath,$restorePath -Force -ErrorAction SilentlyContinue
  }
  if (-not $restored) { Write-Warning "Canonical AI interpreter restoration did not complete." }
}
