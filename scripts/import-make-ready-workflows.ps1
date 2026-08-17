[CmdletBinding()]
param(
  [switch]$ActivateLive,
  [switch]$NoRestart
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$workflowDir = Join-Path $repoRoot "n8n-workflows"
$tmpDir = Join-Path $repoRoot "data\tmp-demo-import"
$containerDir = "/data/tmp-demo-import"

function Get-EnvValue([string]$Name) {
  $path = Join-Path $repoRoot ".env"
  if (-not (Test-Path -LiteralPath $path)) { return $null }
  $line = Get-Content -LiteralPath $path | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s*=" } | Select-Object -Last 1
  if (-not $line) { return $null }
  return ($line -replace "^\s*$([regex]::Escape($Name))\s*=\s*", "").Trim().Trim('"').Trim("'")
}

function Require-Env([string]$Name) {
  $value = Get-EnvValue $Name
  if ([string]::IsNullOrWhiteSpace($value)) { throw "$Name is required in .env when -ActivateLive is used." }
  return $value
}

function Invoke-N8nScalar([string]$Sql) {
  $value = $Sql | docker exec -i make-ready-postgres psql -q -U n8n -d n8n -tA
  if ($LASTEXITCODE -ne 0) { throw "n8n database query failed." }
  $first = $value | Select-Object -First 1
  if ($null -eq $first) { return "" }
  return $first.Trim()
}

function Invoke-DemoSql([string]$Sql) {
  $Sql | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "make_ready_demo database update failed." }
}

function Get-CredentialId([string[]]$Names) {
  foreach ($name in $Names) {
    $escaped = $name.Replace("'", "''")
    $id = Invoke-N8nScalar "SELECT id FROM credentials_entity WHERE name='$escaped' LIMIT 1;"
    if (-not [string]::IsNullOrWhiteSpace($id)) { return $id }
  }
  throw "Missing n8n credential. Create one of: $($Names -join ', ')."
}

docker compose config | Out-Null
if ($LASTEXITCODE -ne 0) { throw "docker compose config failed." }

node (Join-Path $scriptDir "generate-demo-workflows.js")
if ($LASTEXITCODE -ne 0) { throw "Consolidated workflow generation failed." }

Get-ChildItem (Join-Path $repoRoot "db\postgres\migrations") -Filter "*.sql" | Sort-Object Name | ForEach-Object {
  docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -f "/docker-entrypoint-initdb.d/migrations/$($_.Name)" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Migration failed: $($_.Name)" }
}

$files = @(Get-ChildItem -LiteralPath $workflowDir -Filter "*.json" | Sort-Object Name)
if ($files.Count -ne 7) { throw "Expected exactly seven consolidated workflow exports; found $($files.Count)." }

$baseId = Get-EnvValue "AIRTABLE_BASE_ID"
$fromEmail = Get-EnvValue "VENDOR_EMAIL_FROM"
$replyTo = Get-EnvValue "VENDOR_EMAIL_REPLY_TO"
$vendorToken = Get-EnvValue "VENDOR_IN_DEMO_TOKEN"
if ([string]::IsNullOrWhiteSpace($vendorToken)) { $vendorToken = "local-stage-4-vendor-in-token" }
$model = Get-EnvValue "OPENAI_MODEL_CLASSIFY"
if ([string]::IsNullOrWhiteSpace($model)) { $model = "gpt-5.6-luna" }

$credentialIds = @{
  "cred_make_ready_pg" = Get-CredentialId @("Make-Ready Postgres")
  "cred_make_ready_openai" = Get-CredentialId @("Make-Ready OpenAI")
  "jASZWMlrfp3v2tWH" = Get-CredentialId @("Make-Ready Manager Telegram Bot")
  "5mBfLarFM6t8Cgcz" = Get-CredentialId @("Make-Ready Vendor Telegram Bot")
  "cred_make_ready_airtable" = Get-CredentialId @("Make-Ready Airtable", "Airtable Make Ready Demo")
  "cred_make_ready_email_imap" = Get-CredentialId @("Make-Ready Vendor Email IMAP")
  "cred_make_ready_email_smtp" = Get-CredentialId @("Make-Ready Vendor Email SMTP")
}

$managerChat = $null
$builderChat = $null
if ($ActivateLive) {
  $baseId = Require-Env "AIRTABLE_BASE_ID"
  if ($baseId -notmatch '^app') { throw "AIRTABLE_BASE_ID must be a valid Airtable base ID." }
  $fromEmail = Require-Env "VENDOR_EMAIL_FROM"
  $replyTo = Require-Env "VENDOR_EMAIL_REPLY_TO"
  $managerChat = Require-Env "MANAGER_TELEGRAM_CHAT_ID"
  $builderChat = Require-Env "BUILDER_TELEGRAM_CHAT_ID"
  $webhook = Require-Env "WEBHOOK_URL"
  $containerWebhook = (docker exec make-ready-n8n printenv WEBHOOK_URL | Select-Object -First 1).Trim()
  if ($webhook -notmatch '^https://' -or $containerWebhook -ne $webhook) {
    throw "-ActivateLive requires the same fresh HTTPS WEBHOOK_URL in .env and the recreated n8n container."
  }
  foreach ($name in @("RIVERA_TELEGRAM_CHAT_ID", "MARIAS_TELEGRAM_CHAT_ID", "DALE_TELEGRAM_CHAT_ID", "STATEWIDE_TELEGRAM_CHAT_ID", "RIVERA_VENDOR_EMAIL", "MARIAS_VENDOR_EMAIL", "DALE_VENDOR_EMAIL", "STATEWIDE_VENDOR_EMAIL", "QUICKHAUL_VENDOR_EMAIL")) {
    Require-Env $name | Out-Null
  }
}

New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
Get-ChildItem -LiteralPath $tmpDir -Force | Remove-Item -Recurse -Force
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($file in $files) {
  $workflow = Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json
  $workflow.active = $false
  $json = $workflow | ConvertTo-Json -Depth 100
  $json = $json.Replace("local-stage-4-vendor-in-token", $vendorToken).Replace("gpt-5.6-luna", $model)
  foreach ($placeholder in $credentialIds.Keys) { $json = $json.Replace($placeholder, $credentialIds[$placeholder]) }
  if ($ActivateLive) {
    $json = $json.Replace("AIRTABLE_BASE_ID_PLACEHOLDER", $baseId).Replace("VENDOR_EMAIL_FROM_PLACEHOLDER", $fromEmail).Replace("VENDOR_EMAIL_REPLY_TO_PLACEHOLDER", $replyTo)
    $json = $json.Replace("stage3-manager-chat-id-missing", $managerChat).Replace("stage5-manager-chat-id-missing", $managerChat).Replace("stage7-builder-chat-id-missing", $builderChat)
  }
  [IO.File]::WriteAllText((Join-Path $tmpDir $file.Name), $json, $utf8)
}

docker exec make-ready-n8n n8n import:workflow --separate --input=$containerDir
if ($LASTEXITCODE -ne 0) { throw "Consolidated workflow import failed." }

$retired = @(
  "wf3-daily-digest", "wf3-manager-router", "wf3-sequence-guard", "wf3-stage-complete-core", "wf4-turn-intake", "wf4-unit-matcher", "wf4-vendor-in-api", "wf4-vendor-router", "wf4-vendor-telegram-ingest", "wf5-manager-action-core", "wf5-vendor-completion-handler", "wf6-health-core", "wf6-stall-watchdog", "wf6-weekly-digest", "wf7-error-handler", "wf9-ai-interpreter", "wf9-airtable-sync", "wf9-vendor-delivery", "wf9-vendor-email-ingest",
  "wf3-board-api", "wf3-stage-complete-api", "wf5-manager-action-api", "wf6-health-api", "wf7-error-smoke"
)
$retiredSql = ($retired | ForEach-Object { "'" + $_.Replace("'", "''") + "'" }) -join ','
@"
UPDATE workflow_entity SET active = false WHERE id IN ($retiredSql);
DELETE FROM workflow_published_version WHERE "workflowId" IN ($retiredSql);
DELETE FROM workflow_publication_outbox WHERE "workflowId" IN ($retiredSql);
DELETE FROM workflow_entity WHERE id IN ($retiredSql);
"@ | docker exec -i make-ready-postgres psql -q -U n8n -d n8n -v ON_ERROR_STOP=1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Could not retire the prior workflow records." }

if ($ActivateLive) {
  $telegramMap = @(
    @("Rivera Painting", "paint", "RIVERA_TELEGRAM_CHAT_ID"), @("Maria's Cleaning Co", "clean", "MARIAS_TELEGRAM_CHAT_ID"),
    @("Dale Hutchins", "repairs", "DALE_TELEGRAM_CHAT_ID"), @("Statewide Flooring", "flooring", "STATEWIDE_TELEGRAM_CHAT_ID"),
    @("QuickHaul Junk Removal", "trashout", "QUICKHAUL_TELEGRAM_CHAT_ID")
  )
  foreach ($row in $telegramMap) {
    $value = Require-Env $row[2]
    Invoke-DemoSql "UPDATE vendor SET telegram_chat_id='$($value.Replace("'", "''"))' WHERE name='$($row[0].Replace("'", "''"))' AND trade='$($row[1])';"
  }
  $emailMap = @(
    @("Rivera Painting", "paint", "RIVERA_VENDOR_EMAIL"), @("Maria's Cleaning Co", "clean", "MARIAS_VENDOR_EMAIL"),
    @("Dale Hutchins", "repairs", "DALE_VENDOR_EMAIL"), @("Statewide Flooring", "flooring", "STATEWIDE_VENDOR_EMAIL"),
    @("QuickHaul Junk Removal", "trashout", "QUICKHAUL_VENDOR_EMAIL")
  )
  foreach ($row in $emailMap) {
    $value = Require-Env $row[2]
    Invoke-DemoSql "UPDATE vendor SET email_address='$($value.Replace("'", "''"))' WHERE name='$($row[0].Replace("'", "''"))' AND trade='$($row[1])';"
  }
  foreach ($file in $files) {
    $id = (Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json).id
    docker exec make-ready-n8n n8n publish:workflow --id=$id | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Could not publish $id." }
  }
}

if (-not $NoRestart) {
  docker compose restart n8n | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "n8n restart failed." }
}

$workflowIdSql = ($files | ForEach-Object { $w = Get-Content -Raw $_.FullName | ConvertFrom-Json; "'" + $w.id.Replace("'", "''") + "'" }) -join ','
$count = [int](Invoke-N8nScalar "SELECT count(*) FROM workflow_entity WHERE id IN ($workflowIdSql);")
if ($count -ne 7) { throw "n8n contains only $count of the seven consolidated workflows after import." }
$linked = [int](Invoke-N8nScalar "SELECT count(*) FROM workflow_entity WHERE id <> 'demo-builder-error-handler' AND settings->>'errorWorkflow'='demo-builder-error-handler' AND id IN ($workflowIdSql);")
if ($linked -ne 6) { throw "Expected all six non-error workflows to use Builder Error Handler; found $linked." }
$visible = [int](Invoke-N8nScalar "SELECT count(*) FROM workflow_entity;")
if ($visible -ne 7) { throw "Expected n8n to show only seven workflows; found $visible." }

Write-Host "Imported seven consolidated demo workflows. Live activation: $([bool]$ActivateLive)."
