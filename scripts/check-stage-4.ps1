[CmdletBinding()]
param(
  [switch]$SkipReset,
  [string]$VendorInUrl = "http://localhost:5678/webhook/vendor-in",
  [string]$BoardUrl = "http://localhost:5678/webhook/board",
  [string]$Token,
  [string]$BoardToken
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")

function Get-EnvFileValue {
  param(
    [string]$Name,
    [string]$Default
  )
  $envPath = Join-Path $repoRoot ".env"
  if (Test-Path -LiteralPath $envPath) {
    $line = Get-Content -LiteralPath $envPath |
      Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s*=" } |
      Select-Object -Last 1
    if ($line) {
      $value = ($line -replace "^\s*$([regex]::Escape($Name))\s*=\s*", "").Trim().Trim('"').Trim("'")
      if (-not [string]::IsNullOrWhiteSpace($value)) {
        return $value
      }
    }
  }
  return $Default
}

function Invoke-AppPsqlScalar {
  param([string]$Sql)
  $result = docker exec make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -tAc $Sql
  if ($LASTEXITCODE -ne 0) {
    throw "psql scalar failed."
  }
  return ($result | Select-Object -First 1).Trim()
}

function Invoke-N8nPsqlScalar {
  param([string]$Sql)
  $result = $Sql | docker exec -i make-ready-postgres psql -q -U n8n -d n8n -tA
  if ($LASTEXITCODE -ne 0) {
    throw "n8n psql scalar failed."
  }
  return ($result | Select-Object -First 1).Trim()
}

function Invoke-AppPsql {
  param([string]$Sql)
  docker exec make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -c $Sql | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "psql command failed."
  }
}

function Invoke-CurlJson {
  param(
    [string]$Uri,
    [hashtable]$Body,
    [hashtable]$Headers = @{}
  )
  $json = $Body | ConvertTo-Json -Depth 20 -Compress
  $tmpBody = Join-Path $env:TEMP ("stage4-vendor-in-" + [guid]::NewGuid().ToString("N") + ".json")
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($tmpBody, $json, $utf8NoBom)
  $args = @("-sS", "-X", "POST", $Uri, "-H", "Content-Type: application/json")
  foreach ($headerName in $Headers.Keys) {
    $args += @("-H", "${headerName}: $($Headers[$headerName])")
  }
  $args += @("--data-binary", "@$tmpBody", "-w", "`n%{http_code}", "--max-time", "30")
  try {
    $raw = & curl.exe @args
    if ($LASTEXITCODE -ne 0) {
      throw "curl failed for $Uri."
    }
  } finally {
    Remove-Item -LiteralPath $tmpBody -Force -ErrorAction SilentlyContinue
  }
  $parts = @($raw -split "`n")
  $status = [int]$parts[-1]
  $bodyText = ""
  if ($parts.Count -gt 1) {
    $bodyText = ($parts[0..($parts.Count - 2)] -join "`n")
  }
  $jsonBody = $null
  if (-not [string]::IsNullOrWhiteSpace($bodyText)) {
    $jsonBody = $bodyText | ConvertFrom-Json
  }
  return [pscustomobject]@{
    Status = $status
    BodyText = $bodyText
    Json = $jsonBody
  }
}

function Assert-True {
  param(
    [bool]$Condition,
    [string]$Message
  )
  if (-not $Condition) {
    throw $Message
  }
}

function Assert-Equal {
  param(
    $Actual,
    $Expected,
    [string]$Message
  )
  if ($Actual -ne $Expected) {
    throw "$Message Expected '$Expected', found '$Actual'."
  }
}

if (-not $Token) {
  $Token = Get-EnvFileValue "VENDOR_IN_DEMO_TOKEN" "local-stage-4-vendor-in-token"
}
if (-not $BoardToken) {
  $BoardToken = Get-EnvFileValue "BOARD_DEMO_TOKEN" "local-stage-3-demo-token"
}

if (-not $SkipReset) {
  & (Join-Path $scriptDir "reset-demo.ps1")
}

Invoke-AppPsql "DELETE FROM event_log WHERE actor_type = 'vendor' AND channel = 'generic' AND actor_id IN ('placeholder_rivera_painting', 'placeholder_statewide_flooring', 'mystery_vendor') AND event_type IN ('vendor_inbound', 'manager_match_needed', 'duplicate_inbound', 'unknown_sender');"

Get-ChildItem -LiteralPath (Join-Path $repoRoot "n8n-workflows") -Filter "wf-4-*.json" | ForEach-Object {
  Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json | Out-Null
}

$readyDeadline = (Get-Date).AddSeconds(40)
do {
  $registeredVendorIn = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf4-vendor-in-api'' AND method = ''POST'' AND "webhookPath" = ''vendor-in'';'
  if ([int]$registeredVendorIn -gt 0) {
    break
  }
  Start-Sleep -Seconds 2
} while ((Get-Date) -lt $readyDeadline)
Assert-True ([int]$registeredVendorIn -gt 0) "Stage 4 /vendor-in webhook was not registered."

$initialStageSnapshot = Invoke-AppPsqlScalar "SELECT coalesce(jsonb_object_agg(t.unit_label || ':' || ts.stage_code, ts.status ORDER BY t.unit_label, ts.seq), '{}'::jsonb)::text FROM ""turn"" t JOIN turn_stage ts ON ts.turn_id = t.id WHERE t.is_fixture = true;"
$initialOutboundCount = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM outbound_queue;")

$unauthorized = Invoke-CurlJson -Uri $VendorInUrl -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "done with 12b"
}
Assert-Equal $unauthorized.Status 401 "Unauthorized /vendor-in did not return 401."

$malformed = Invoke-CurlJson -Uri $VendorInUrl -Headers @{ "X-Vendor-In-Token" = $Token } -Body @{
  sender_ref = "placeholder_rivera_painting"
}
Assert-Equal $malformed.Status 400 "Malformed /vendor-in did not return 400."

$authHeader = @{ "X-Vendor-In-Token" = $Token }

$f01 = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "done with 12b"
}
Assert-Equal $f01.Status 200 "F01 did not return 200."
Assert-Equal $f01.Json.outcome "matched_logged" "F01 outcome mismatch."
Assert-Equal $f01.Json.event_type "vendor_inbound" "F01 event type mismatch."
Assert-Equal $f01.Json.match.selected.unit_label "12B" "F01 unit mismatch."
Assert-Equal ([int]$f01.Json.match.selected.score) 100 "F01 score mismatch."
Assert-True (-not [bool]$f01.Json.stage_state_mutated) "F01 mutated stage state."

$duplicate = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "done with 12b"
}
Assert-Equal $duplicate.Status 200 "Duplicate did not return 200."
Assert-Equal $duplicate.Json.event_type "duplicate_inbound" "Duplicate event type mismatch."
Assert-True ([bool]$duplicate.Json.duplicate_like) "Duplicate flag was not set."

$f02 = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "finished the one on maple"
}
Assert-Equal $f02.Status 200 "F02 did not return 200."
Assert-Equal $f02.Json.outcome "manager_match_needed" "F02 outcome mismatch."
Assert-True ([bool]$f02.Json.match.needs_manager) "F02 did not request manager match."
$mapleCandidates = @($f02.Json.match.candidates | Where-Object { $_.score -eq 70 })
Assert-True ($mapleCandidates.Count -ge 2) "F02 did not return multiple Maple candidates."

$f03 = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_statewide_flooring"
  text = "all set at oak, unit 7"
}
Assert-Equal $f03.Status 200 "F03 did not return 200."
Assert-Equal $f03.Json.match.selected.unit_label "7" "F03 should resolve unit 7 Oak."
Assert-Equal ([int]$f03.Json.match.selected.score) 100 "F03 score mismatch."

$f04 = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "done"
}
Assert-Equal $f04.Status 200 "F04 did not return 200."
Assert-Equal $f04.Json.outcome "manager_match_needed" "F04 outcome mismatch."
Assert-True ([bool]$f04.Json.match.needs_manager) "F04 did not request manager match."
Assert-Equal ([int]$f04.Json.match.score) 60 "F04 score mismatch."

$unknown = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "mystery_vendor"
  text = "done with 12b"
}
Assert-Equal $unknown.Status 200 "Unknown sender did not return 200."
Assert-Equal $unknown.Json.outcome "unknown_sender" "Unknown sender outcome mismatch."
Assert-True ($null -eq $unknown.Json.match) "Unknown sender disclosed match data."

$paint12BStatus = Invoke-AppPsqlScalar "SELECT ts.status FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'PAINT';"
Assert-Equal $paint12BStatus "active" "12B Paint was mutated by vendor ingest."

$finalStageSnapshot = Invoke-AppPsqlScalar "SELECT coalesce(jsonb_object_agg(t.unit_label || ':' || ts.stage_code, ts.status ORDER BY t.unit_label, ts.seq), '{}'::jsonb)::text FROM ""turn"" t JOIN turn_stage ts ON ts.turn_id = t.id WHERE t.is_fixture = true;"
$finalOutboundCount = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM outbound_queue;")
Assert-Equal $finalStageSnapshot $initialStageSnapshot "Fixture turn_stage statuses changed during Stage 4 ingest checks."
Assert-Equal $finalOutboundCount $initialOutboundCount "Outbound queue changed during Stage 4 ingest checks."

$eventTypeCount = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM event_log WHERE event_type IN ('vendor_inbound', 'manager_match_needed', 'duplicate_inbound', 'unknown_sender') AND actor_type = 'vendor';")
Assert-True ($eventTypeCount -ge 6) "Expected at least 6 Stage 4 vendor event rows."

docker exec make-ready-postgres psql -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/verify-stage-4.sql
if ($LASTEXITCODE -ne 0) {
  throw "Stage 4 database verification failed."
}

$formPath = Invoke-N8nPsqlScalar 'SELECT "webhookPath" FROM webhook_entity WHERE "workflowId" = ''wf4-turn-intake'' AND method = ''POST'' LIMIT 1;'
if ([string]::IsNullOrWhiteSpace($formPath)) {
  throw "Could not find the active Stage 4 intake form webhook path."
}
$formUrl = "http://localhost:5678/form/$formPath"
$today = (Get-Date).ToUniversalTime().Date
$moveout = $today.AddDays(3).ToString("yyyy-MM-dd")
$notice = $today.ToString("yyyy-MM-dd")
$intakeBody = [ordered]@{
  "field-0" = "99Z-STAGE4"
  "field-1" = "99 Test Ln"
  "field-2" = "999"
  "field-3" = $notice
  "field-4" = $moveout
  "field-6" = "QuickHaul Junk Removal"
  "field-7" = "Dale Hutchins"
  "field-8" = "Rivera Painting"
  "field-9" = "Statewide Flooring"
  "field-10" = "Maria's Cleaning Co"
}
$formArgs = @("-sS", "-X", "POST", $formUrl, "--max-time", "30")
foreach ($fieldName in $intakeBody.Keys) {
  $formArgs += @("-F", "$fieldName=$($intakeBody[$fieldName])")
}
$formRaw = & curl.exe @formArgs
if ($LASTEXITCODE -ne 0) {
  throw "curl failed while submitting the Stage 4 intake form."
}
if ($formRaw -match "Workflow Form Error") {
  throw "Stage 4 intake form submission failed: $formRaw"
}

$deadline = (Get-Date).AddSeconds(20)
$boardHasIntake = $false
while ((Get-Date) -lt $deadline) {
  $board = Invoke-RestMethod -Uri "${BoardUrl}?token=$([uri]::EscapeDataString($BoardToken))" -Method Get -TimeoutSec 30
  $intakeTurn = $board.turns | Where-Object { $_.unit_label -eq "99Z-STAGE4" } | Select-Object -First 1
  if ($intakeTurn) {
    Assert-Equal $intakeTurn.current_stage.stage_code "NOTICE" "Intake turn current stage mismatch."
    Assert-Equal @($intakeTurn.stages).Count 11 "Intake turn stage count mismatch."
    $boardHasIntake = $true
    break
  }
  Start-Sleep -Seconds 2
}
Assert-True $boardHasIntake "Board did not show the Stage 4 intake turn within one poll cycle."

Invoke-AppPsql @"
WITH doomed AS (
  SELECT id FROM "turn" WHERE unit_label = '99Z-STAGE4' AND property_address = '99 Test Ln' AND is_fixture = false
)
DELETE FROM event_log WHERE turn_id IN (SELECT id FROM doomed);
DELETE FROM "turn" WHERE unit_label = '99Z-STAGE4' AND property_address = '99 Test Ln' AND is_fixture = false;
"@

& (Join-Path $scriptDir "reset-demo.ps1")

Write-Host "Stage 4 verification passed."
Write-Host "Note: Vendor Telegram verification requires HTTPS WEBHOOK_URL, VENDOR_TELEGRAM_CHAT_ID, then .\scripts\import-stage-4-workflows.ps1 -ActivateTelegram."
