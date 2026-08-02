[CmdletBinding()]
param(
  [switch]$SkipReset,
  [string]$VendorInUrl = "http://localhost:5678/webhook/vendor-in",
  [string]$ManagerActionUrl = "http://localhost:5678/webhook/manager-action",
  [string]$BoardUrl = "http://localhost:5678/webhook/board",
  [string]$CompleteUrl = "http://localhost:5678/webhook/stage/complete",
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

function Invoke-CurlJson {
  param(
    [string]$Uri,
    [hashtable]$Body,
    [hashtable]$Headers = @{}
  )
  $json = $Body | ConvertTo-Json -Depth 30 -Compress
  $tmpBody = Join-Path $env:TEMP ("stage5-body-" + [guid]::NewGuid().ToString("N") + ".json")
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($tmpBody, $json, $utf8NoBom)
  $args = @("-sS", "-X", "POST", $Uri, "-H", "Content-Type: application/json")
  foreach ($headerName in $Headers.Keys) {
    $args += @("-H", "${headerName}: $($Headers[$headerName])")
  }
  $args += @("--data-binary", "@$tmpBody", "-w", "`n%{http_code}", "--max-time", "75")
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
if ($LASTEXITCODE -ne 0) {
  throw "docker compose config failed."
}

Get-ChildItem -LiteralPath (Join-Path $repoRoot "n8n-workflows") -Filter "*.json" | ForEach-Object {
  Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json | Out-Null
}

$deadline = (Get-Date).AddSeconds(50)
do {
  $registeredVendorIn = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf4-vendor-in-api'' AND method = ''POST'' AND "webhookPath" = ''vendor-in'';'
  $registeredManagerAction = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf5-manager-action-api'' AND method = ''POST'' AND "webhookPath" = ''manager-action'';'
  $registeredBoard = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf3-board-api'' AND method = ''GET'' AND "webhookPath" = ''board'';'
  if ([int]$registeredVendorIn -gt 0 -and [int]$registeredManagerAction -gt 0 -and [int]$registeredBoard -gt 0) {
    break
  }
  Start-Sleep -Seconds 2
} while ((Get-Date) -lt $deadline)
Assert-True ([int]$registeredVendorIn -gt 0) "Stage 5 /vendor-in webhook was not registered."
Assert-True ([int]$registeredManagerAction -gt 0) "Stage 5 /manager-action webhook was not registered."
Assert-True ([int]$registeredBoard -gt 0) "Stage 5 /board webhook was not registered."

$authHeader = @{ "X-Vendor-In-Token" = $VendorToken }
$managerHeader = @{ "X-Demo-Token" = $BoardToken }

$f01 = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "done with 12b"
}
Assert-Equal $f01.Status 200 "F01 did not return 200."
Assert-Equal $f01.Json.outcome "completed_awaiting_approval" "F01 outcome mismatch."
Assert-True ([bool]$f01.Json.stage_state_mutated) "F01 did not report state mutation."

$paint12BStatus = Invoke-AppPsqlScalar "SELECT ts.status || ':' || coalesce(ts.completed_via, '') FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'PAINT';"
Assert-Equal $paint12BStatus "complete:vendor_reply" "12B Paint was not completed by vendor reply."

$flooring12BStatus = Invoke-AppPsqlScalar "SELECT ts.status FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'FLOORING';"
Assert-Equal $flooring12BStatus "awaiting_approval" "12B Flooring should wait for manager approval before activation."

$queueId = [int](Invoke-AppPsqlScalar "SELECT id FROM outbound_queue WHERE status = 'awaiting_approval' AND turn_id = (SELECT id FROM ""turn"" WHERE unit_label = '12B' AND property_address = '418 Maple St' AND is_fixture = true) ORDER BY id DESC LIMIT 1;")
Assert-True ($queueId -gt 0) "F01 did not create an awaiting approval queue row."

$sentBeforeSend = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM event_log WHERE event_type = 'msg_sent' AND created_at > now() - interval '10 minutes';")
Assert-Equal $sentBeforeSend 0 "A vendor send was logged before manager Send."

$board = Invoke-RestMethod -Uri "${BoardUrl}?token=$([uri]::EscapeDataString($BoardToken))" -Method Get -TimeoutSec 30
$unit12B = $board.turns | Where-Object { $_.unit_label -eq "12B" } | Select-Object -First 1
Assert-True ($null -ne $unit12B) "Board did not show 12B while awaiting approval."
Assert-Equal $unit12B.current_stage.stage_code "FLOORING" "Board current stage mismatch after F01."
Assert-Equal $unit12B.current_stage.status "awaiting_approval" "Board did not expose awaiting_approval state."

$duplicate = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "done with 12b"
}
Assert-Equal $duplicate.Status 200 "Duplicate did not return 200."
Assert-Equal $duplicate.Json.event_type "duplicate_inbound" "Duplicate event type mismatch."
$queueCount = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM outbound_queue WHERE turn_id = (SELECT id FROM ""turn"" WHERE unit_label = '12B' AND property_address = '418 Maple St' AND is_fixture = true);")
Assert-Equal $queueCount 1 "Duplicate completion created a second draft."

$editedText = "Statewide, 12B at 418 Maple St is ready for flooring. Please reply when complete. - Cedar Ridge"
$edit = Invoke-CurlJson -Uri $ManagerActionUrl -Headers $managerHeader -Body @{
  action = "EDIT"
  queue_id = $queueId
  edited_text = $editedText
  actor_id = "stage-5-check"
}
Assert-Equal $edit.Status 200 "Edit did not return 200."
Assert-Equal $edit.Json.outcome "awaiting_approval" "Edit did not return queue to awaiting approval."
$storedEdit = Invoke-AppPsqlScalar "SELECT approved_text FROM outbound_queue WHERE id = $queueId;"
Assert-Equal $storedEdit $editedText "Edited draft text was not stored."

$send = Invoke-CurlJson -Uri $ManagerActionUrl -Headers $managerHeader -Body @{
  action = "SEND"
  queue_id = $queueId
  actor_id = "stage-5-check"
}
Assert-Equal $send.Status 200 "Send did not return 200."
Assert-Equal $send.Json.outcome "sent" "Send outcome mismatch."
$sentStatus = Invoke-AppPsqlScalar "SELECT oq.status || ':' || ts.status FROM outbound_queue oq JOIN turn_stage ts ON ts.id = oq.stage_id WHERE oq.id = $queueId;"
Assert-Equal $sentStatus "sent:active" "Send did not mark queue sent and activate next stage."

& (Join-Path $scriptDir "reset-demo.ps1")

$holdSeed = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "done with 12b hold path"
}
Assert-Equal $holdSeed.Json.outcome "completed_awaiting_approval" "Hold setup did not create a draft."
$holdQueueId = [int](Invoke-AppPsqlScalar "SELECT id FROM outbound_queue WHERE status = 'awaiting_approval' ORDER BY id DESC LIMIT 1;")
$hold = Invoke-CurlJson -Uri $ManagerActionUrl -Headers $managerHeader -Body @{
  action = "HOLD"
  queue_id = $holdQueueId
  actor_id = "stage-5-check"
}
Assert-Equal $hold.Status 200 "Hold did not return 200."
Assert-Equal $hold.Json.outcome "held" "Hold outcome mismatch."
$heldStatus = Invoke-AppPsqlScalar "SELECT status FROM outbound_queue WHERE id = $holdQueueId;"
Assert-Equal $heldStatus "held" "Hold did not persist held status."

& (Join-Path $scriptDir "reset-demo.ps1")

$mismatch = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_marias_cleaning"
  text = "14a cleaned"
}
Assert-Equal $mismatch.Status 200 "Vendor mismatch did not return 200."
Assert-Equal $mismatch.Json.outcome "stage_vendor_mismatch" "Cleaner should not complete 14A Repairs."
$repairs14A = Invoke-AppPsqlScalar "SELECT ts.status FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '14A' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'REPAIRS';"
Assert-Equal $repairs14A "active" "Vendor mismatch mutated 14A Repairs."

$unclear = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "hello"
}
Assert-Equal $unclear.Status 200 "Unclear fallback did not return 200."
Assert-Equal $unclear.Json.outcome "low_confidence" "Unclear fallback should route to manager."

$deepClean14A = Invoke-AppPsqlScalar "SELECT ts.id FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '14A' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'DEEP_CLEAN';"
$blockedRaw = & curl.exe -s -X POST "${CompleteUrl}?token=$([uri]::EscapeDataString($BoardToken))" `
  -d "stage_id=$deepClean14A" `
  -d "actor_id=stage-5-check" `
  -d "channel=board" `
  -w "`n%{http_code}" `
  --max-time 30
if ($LASTEXITCODE -ne 0) {
  throw "curl failed while checking guard block."
}
$blockedParts = @($blockedRaw -split "`n")
$blockedStatus = [int]$blockedParts[-1]
$blockedBody = ($blockedParts[0..($blockedParts.Count - 2)] -join "`n")
Assert-Equal $blockedStatus 409 "Guard violation did not return 409."
$blocked = $blockedBody | ConvertFrom-Json
Assert-True ($blocked.reason -like "*Repairs still open*") "Guard block reason mismatch."

$birchTurnId = [int](Invoke-AppPsqlScalar "SELECT id FROM ""turn"" WHERE unit_label = '55' AND property_address = '55 Birch Ct' AND is_fixture = true;")
$cancel = Invoke-CurlJson -Uri $ManagerActionUrl -Headers $managerHeader -Body @{
  action = "CANCEL"
  turn_id = $birchTurnId
  actor_id = "stage-5-check"
}
Assert-Equal $cancel.Status 200 "Cancel did not return 200."
Assert-Equal $cancel.Json.outcome "cancelled" "Cancel outcome mismatch."
$birchStatus = Invoke-AppPsqlScalar "SELECT status FROM ""turn"" WHERE id = $birchTurnId;"
Assert-Equal $birchStatus "cancelled" "55 Birch turn was not cancelled."
$boardAfterCancel = Invoke-RestMethod -Uri "${BoardUrl}?token=$([uri]::EscapeDataString($BoardToken))" -Method Get -TimeoutSec 30
$birchOnBoard = $boardAfterCancel.turns | Where-Object { $_.unit_label -eq "55" } | Select-Object -First 1
Assert-True ($null -eq $birchOnBoard) "Cancelled 55 Birch still appears on the active board."

$finalF01 = Invoke-CurlJson -Uri $VendorInUrl -Headers $authHeader -Body @{
  sender_ref = "placeholder_rivera_painting"
  text = "done with 12b final verify"
}
Assert-Equal $finalF01.Json.outcome "completed_awaiting_approval" "Final verifier F01 did not create a draft."
$finalQueueId = [int](Invoke-AppPsqlScalar "SELECT id FROM outbound_queue WHERE status = 'awaiting_approval' ORDER BY id DESC LIMIT 1;")
$finalSend = Invoke-CurlJson -Uri $ManagerActionUrl -Headers $managerHeader -Body @{
  action = "SEND"
  queue_id = $finalQueueId
  actor_id = "stage-5-check"
}
Assert-Equal $finalSend.Json.outcome "sent" "Final verifier Send did not mark the queue sent."

docker exec make-ready-postgres psql -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/verify-stage-5.sql
if ($LASTEXITCODE -ne 0) {
  throw "Stage 5 database verification failed."
}

Write-Host "Stage 5 verification passed."
Write-Host "Note: Live Telegram Send verification still requires HTTPS WEBHOOK_URL, MANAGER_TELEGRAM_CHAT_ID, VENDOR_TELEGRAM_CHAT_ID, then .\scripts\import-stage-5-workflows.ps1 -ActivateTelegram."
