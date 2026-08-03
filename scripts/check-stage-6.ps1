[CmdletBinding()]
param(
  [switch]$SkipReset,
  [string]$VendorInUrl = "http://localhost:5678/webhook/vendor-in",
  [string]$ManagerActionUrl = "http://localhost:5678/webhook/manager-action",
  [string]$BoardUrl = "http://localhost:5678/webhook/board",
  [string]$HealthUrl = "http://localhost:5678/webhook/health",
  [string]$WatchdogUrl = "http://localhost:5678/webhook/stall-watchdog",
  [string]$VendorToken,
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
  $result = $Sql | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -tA
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

function Invoke-CurlJson {
  param(
    [string]$Uri,
    [hashtable]$Body,
    [hashtable]$Headers = @{}
  )
  $json = $Body | ConvertTo-Json -Depth 30 -Compress
  $tmpBody = Join-Path $env:TEMP ("stage6-body-" + [guid]::NewGuid().ToString("N") + ".json")
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($tmpBody, $json, $utf8NoBom)
  $args = @("-sS", "-X", "POST", $Uri, "-H", "Content-Type: application/json")
  foreach ($headerName in $Headers.Keys) {
    $args += @("-H", "${headerName}: $($Headers[$headerName])")
  }
  $args += @("--data-binary", "@$tmpBody", "-w", "`n%{http_code}", "--max-time", "90")
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
  return [pscustomobject]@{ Status = $status; BodyText = $bodyText; Json = $jsonBody }
}

function Assert-True {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Assert-Equal {
  param($Actual, $Expected, [string]$Message)
  if ($Actual -ne $Expected) { throw "$Message Expected '$Expected', found '$Actual'." }
}

if (-not $VendorToken) {
  $VendorToken = Get-EnvFileValue "VENDOR_IN_DEMO_TOKEN" "local-stage-4-vendor-in-token"
}
if (-not $BoardToken) {
  $BoardToken = Get-EnvFileValue "BOARD_DEMO_TOKEN" "local-stage-3-demo-token"
}

if (-not $SkipReset) {
  & (Join-Path $scriptDir "reset-demo.ps1")
}

docker compose config | Out-Null
if ($LASTEXITCODE -ne 0) { throw "docker compose config failed." }

Get-ChildItem -LiteralPath (Join-Path $repoRoot "n8n-workflows") -Filter "*.json" | ForEach-Object {
  Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json | Out-Null
}

$deadline = (Get-Date).AddSeconds(60)
do {
  $registeredVendorIn = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf4-vendor-in-api'' AND method = ''POST'' AND "webhookPath" = ''vendor-in'';'
  $registeredManagerAction = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf5-manager-action-api'' AND method = ''POST'' AND "webhookPath" = ''manager-action'';'
  $registeredBoard = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf3-board-api'' AND method = ''GET'' AND "webhookPath" = ''board'';'
  $registeredHealth = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf6-health-api'' AND method = ''GET'' AND "webhookPath" = ''health'';'
  $registeredWatchdog = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf6-stall-watchdog'' AND method = ''POST'' AND "webhookPath" = ''stall-watchdog'';'
  if ([int]$registeredVendorIn -gt 0 -and [int]$registeredManagerAction -gt 0 -and [int]$registeredBoard -gt 0 -and [int]$registeredHealth -gt 0 -and [int]$registeredWatchdog -gt 0) { break }
  Start-Sleep -Seconds 2
} while ((Get-Date) -lt $deadline)
Assert-True ([int]$registeredVendorIn -gt 0) "Stage 6 /vendor-in webhook was not registered."
Assert-True ([int]$registeredManagerAction -gt 0) "Stage 6 /manager-action webhook was not registered."
Assert-True ([int]$registeredBoard -gt 0) "Stage 6 /board webhook was not registered."
Assert-True ([int]$registeredHealth -gt 0) "Stage 6 /health webhook was not registered."
Assert-True ([int]$registeredWatchdog -gt 0) "Stage 6 /stall-watchdog webhook was not registered."

$authHeader = @{ "X-Vendor-In-Token" = $VendorToken }
$managerHeader = @{ "X-Demo-Token" = $BoardToken }

$watchdog = Invoke-CurlJson -Uri $WatchdogUrl -Body @{ force_hour = 9 }
Assert-Equal $watchdog.Status 200 "Watchdog did not return 200."
Assert-True ([int]$watchdog.Json.alert_count -ge 1) "Watchdog did not alert during business hours."
$oakAlerts = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM event_log e JOIN turn_stage ts ON ts.id = e.stage_id JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '3' AND t.property_address = '2201 Oak Ave' AND ts.stage_code = 'TRASHOUT' AND e.event_type = 'stall_alert';")
Assert-Equal $oakAlerts 1 "3 Oak Trash-out did not fire exactly one stall alert."

$watchdogAgain = Invoke-CurlJson -Uri $WatchdogUrl -Body @{ force_hour = 9 }
Assert-Equal $watchdogAgain.Status 200 "Second watchdog did not return 200."
$oakAlertsAgain = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM event_log e JOIN turn_stage ts ON ts.id = e.stage_id JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '3' AND t.property_address = '2201 Oak Ave' AND ts.stage_code = 'TRASHOUT' AND e.event_type = 'stall_alert';")
Assert-Equal $oakAlertsAgain 1 "Watchdog duplicated the 3 Oak stall alert."

& (Join-Path $scriptDir "reset-demo.ps1")
$oakStageId = [int](Invoke-AppPsqlScalar "SELECT ts.id FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '3' AND t.property_address = '2201 Oak Ave' AND t.is_fixture = true AND ts.stage_code = 'TRASHOUT';")
Invoke-AppPsqlScalar "UPDATE turn_stage SET snooze_until = now() + interval '24 hours' WHERE id = $oakStageId RETURNING id;" | Out-Null
$snoozedWatchdog = Invoke-CurlJson -Uri $WatchdogUrl -Body @{ force_hour = 9 }
Assert-Equal $snoozedWatchdog.Status 200 "Snoozed watchdog did not return 200."
$oakSnoozeAlerts = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM event_log WHERE stage_id = $oakStageId AND event_type = 'stall_alert';")
Assert-Equal $oakSnoozeAlerts 0 "Snoozed 3 Oak stage still alerted."

& (Join-Path $scriptDir "reset-demo.ps1")
$heldWatchdog = Invoke-CurlJson -Uri $WatchdogUrl -Body @{ force_hour = 2 }
Assert-Equal $heldWatchdog.Status 200 "Held watchdog did not return 200."
Assert-True ([int]$heldWatchdog.Json.held_count -ge 1) "Outside-hours watchdog did not hold alerts."
$oakStageId = [int](Invoke-AppPsqlScalar "SELECT ts.id FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '3' AND t.property_address = '2201 Oak Ave' AND t.is_fixture = true AND ts.stage_code = 'TRASHOUT';")
$oakHeld = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM event_log WHERE stage_id = $oakStageId AND event_type = 'stall_alert_held';")
Assert-Equal $oakHeld 1 "3 Oak outside-hours alert was not held exactly once."
$oakAlertedAt = Invoke-AppPsqlScalar "SELECT coalesce(alerted_at::text, '') FROM turn_stage WHERE id = $oakStageId;"
Assert-Equal $oakAlertedAt "" "Held outside-hours alert should not stamp alerted_at."
$businessAfterHeld = Invoke-CurlJson -Uri $WatchdogUrl -Body @{ force_hour = 9 }
Assert-True ([int]$businessAfterHeld.Json.alert_count -ge 1) "Held alert did not become eligible during business hours."

& (Join-Path $scriptDir "reset-demo.ps1")
$oakStageId = [int](Invoke-AppPsqlScalar "SELECT ts.id FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '3' AND t.property_address = '2201 Oak Ave' AND t.is_fixture = true AND ts.stage_code = 'TRASHOUT';")
$chase = Invoke-CurlJson -Uri $ManagerActionUrl -Headers $managerHeader -Body @{ action = "CHASE"; stage_id = $oakStageId; actor_id = "stage-6-check" }
Assert-Equal $chase.Status 200 "Chase did not return 200."
Assert-True ($chase.Json.outcome -in @("chase_awaiting_approval", "chase_already_pending")) "Chase did not create or preserve an approval draft."
$chaseQueueCount = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM outbound_queue WHERE stage_id = $oakStageId AND status = 'awaiting_approval';")
Assert-Equal $chaseQueueCount 1 "Chase did not create exactly one awaiting approval queue."
$sendEvents = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM event_log WHERE event_type = 'msg_sent' AND created_at > now() - interval '10 minutes';")
Assert-Equal $sendEvents 0 "Chase logged a vendor send before manager approval."

$board = Invoke-RestMethod -Uri "${BoardUrl}?token=$([uri]::EscapeDataString($BoardToken))" -Method Get -TimeoutSec 30
$health = Invoke-RestMethod -Uri "${HealthUrl}?token=$([uri]::EscapeDataString($BoardToken))" -Method Get -TimeoutSec 30
Assert-Equal ([int]$health.vendor_reply_rate) ([int]$board.metrics.vendor_reply_rate) "Health vendor reply rate does not match Board API."
Assert-Equal ([int]$health.auto_handled_rate) ([int]$board.metrics.auto_handled_rate) "Health auto-handled rate does not match Board API."

& (Join-Path $scriptDir "reset-demo.ps1")
$photoCompletion = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "done with 12b photo"
  media_type = "photo"
  media_file_id = "stage6-captioned-photo"
  media_url = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 640 360'%3E%3Crect width='640' height='360' fill='%23131b23'/%3E%3C/svg%3E"
}
Assert-Equal $photoCompletion.Status 200 "Captioned photo completion did not return 200."
Assert-Equal $photoCompletion.Json.outcome "completed_awaiting_approval" "Captioned photo completion did not complete the stage."
$photoPath = Invoke-AppPsqlScalar "SELECT ts.evidence_photo FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'PAINT';"
Assert-True ($photoPath -like "data:image*") "Captioned photo did not store evidence_photo."
$photoStoredEvents = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM event_log WHERE event_type = 'photo_stored' AND created_at > now() - interval '10 minutes';")
Assert-True ($photoStoredEvents -ge 1) "Captioned photo did not log photo_stored."
$boardAfterPhoto = Invoke-RestMethod -Uri "${BoardUrl}?token=$([uri]::EscapeDataString($BoardToken))" -Method Get -TimeoutSec 30
$photoTurn = $boardAfterPhoto.turns | Where-Object { $_.unit_label -eq "12B" } | Select-Object -First 1
Assert-True ($photoTurn.evidence_photo -like "data:image*") "Board API did not expose the completion photo."

& (Join-Path $scriptDir "reset-demo.ps1")
$photoOnly = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  media_type = "photo"
  media_file_id = "stage6-photo-only"
}
Assert-Equal $photoOnly.Status 200 "Photo-only message did not return 200."
Assert-Equal $photoOnly.Json.event_type "manager_photo_match_needed" "Photo-only message did not ask manager to match it."
$photoOnlyMedia = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM media_asset WHERE file_id = 'stage6-photo-only' AND status = 'needs_manager';")
Assert-Equal $photoOnlyMedia 1 "Photo-only media was not stored for manager review."
$paintStatus = Invoke-AppPsqlScalar "SELECT ts.status FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'PAINT';"
Assert-Equal $paintStatus "active" "Photo-only message mutated 12B Paint."

$voice = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  media_type = "voice"
  media_file_id = "stage6-voice-note"
}
Assert-Equal $voice.Status 200 "Voice note did not return 200."
Assert-Equal $voice.Json.event_type "unsupported_media" "Voice note was not logged as unsupported media."
$voiceMedia = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM media_asset WHERE file_id = 'stage6-voice-note' AND status = 'unsupported';")
Assert-Equal $voiceMedia 1 "Voice note media was not stored as unsupported."

Assert-True (Test-Path -LiteralPath (Join-Path $repoRoot "board\sim.html")) "Simulator page is missing."
$simContent = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "board\sim.html")
Assert-True ($simContent -like "*/vendor-in*") "Simulator does not post to /vendor-in."

docker exec make-ready-postgres psql -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/verify-stage-6.sql
if ($LASTEXITCODE -ne 0) { throw "Stage 6 database verification failed." }

Write-Host "Stage 6 verification passed."
Write-Host "Note: Live Telegram photo/Send verification remains optional and requires a fresh HTTPS WEBHOOK_URL plus real chat IDs."
