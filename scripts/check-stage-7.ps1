[CmdletBinding()]
param(
  [switch]$RequireTelegram,
  [string]$VendorInUrl = "http://localhost:5678/webhook/vendor-in",
  [string]$ManagerActionUrl = "http://localhost:5678/webhook/manager-action",
  [string]$BoardUrl = "http://localhost:5678/webhook/board",
  [string]$CompleteUrl = "http://localhost:5678/webhook/stage/complete",
  [string]$ErrorSmokeUrl = "http://localhost:5678/webhook/stage-7-error-smoke",
  [string]$WatchdogUrl = "http://localhost:5678/webhook/stall-watchdog",
  [string]$VendorToken,
  [string]$BoardToken,
  [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$reportDir = Join-Path $repoRoot "data\stage-7-reports"
$runId = "stage7-" + (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$fixturePath = Join-Path $repoRoot "fixtures\stage-7-fixtures.json"
$results = New-Object System.Collections.Generic.List[object]

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

function ConvertTo-SqlLiteral {
  param([string]$Value)
  return "'" + ($Value -replace "'", "''") + "'"
}

function Invoke-AppPsqlScalar {
  param([string]$Sql)
  $result = $Sql | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -tA
  if ($LASTEXITCODE -ne 0) {
    throw "psql scalar failed."
  }
  return ($result | Select-Object -First 1).Trim()
}

function Invoke-AppPsql {
  param([string]$Sql)
  $Sql | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "psql command failed."
  }
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
    [hashtable]$Headers = @{},
    [int]$MaxTime = 90
  )
  $json = $Body | ConvertTo-Json -Depth 30 -Compress
  $tmpBody = Join-Path $env:TEMP ("stage7-body-" + [guid]::NewGuid().ToString("N") + ".json")
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($tmpBody, $json, $utf8NoBom)
  $args = @("-sS", "-X", "POST", $Uri, "-H", "Content-Type: application/json")
  foreach ($headerName in $Headers.Keys) {
    $args += @("-H", "${headerName}: $($Headers[$headerName])")
  }
  $args += @("--data-binary", "@$tmpBody", "-w", "`n%{http_code}", "--max-time", "$MaxTime")
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
    try { $jsonBody = $bodyText | ConvertFrom-Json } catch { $jsonBody = $null }
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

function Add-Result {
  param(
    [string]$Id,
    [string]$Status,
    [string]$Notes,
    [decimal]$EstimatedCostUsd = 0
  )
  $results.Add([pscustomobject]@{
    id = $Id
    status = $Status
    notes = $Notes
    estimated_cost_usd = $EstimatedCostUsd
    recorded_at = (Get-Date).ToUniversalTime().ToString("o")
  }) | Out-Null
}

function Reset-Fixtures {
  & (Join-Path $scriptDir "reset-demo.ps1") | Out-Host
}

function Wait-ForSql {
  param(
    [string]$Sql,
    [scriptblock]$Predicate,
    [string]$Description,
    [int]$Seconds = $TimeoutSeconds
  )
  $deadline = (Get-Date).AddSeconds($Seconds)
  do {
    $value = Invoke-AppPsqlScalar $Sql
    if (& $Predicate $value) {
      return $value
    }
    Start-Sleep -Seconds 3
  } while ((Get-Date) -lt $deadline)
  throw "Timed out waiting for $Description. Last value: $value"
}

function Get-StageId {
  param([string]$Unit, [string]$Address, [string]$StageCode)
  return [int](Invoke-AppPsqlScalar "SELECT ts.id FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = $(ConvertTo-SqlLiteral $Unit) AND t.property_address = $(ConvertTo-SqlLiteral $Address) AND t.is_fixture = true AND ts.stage_code = $(ConvertTo-SqlLiteral $StageCode) LIMIT 1;")
}

function Send-GenericVendorMessage {
  param([string]$SenderRef, [string]$Text, [hashtable]$Extra = @{})
  $body = @{ sender_ref = $SenderRef; text = $Text }
  foreach ($key in $Extra.Keys) {
    $body[$key] = $Extra[$key]
  }
  return Invoke-CurlJson -Uri $VendorInUrl -Headers @{ "X-Vendor-In-Token" = $VendorToken } -Body $body
}

function Prompt-LiveStep {
  param([string]$FixtureId, [string]$Instruction)
  Write-Host ""
  Write-Host "[$FixtureId] $Instruction"
  Read-Host "Press Enter after completing the live Telegram step" | Out-Null
}

function Setup-DeepCleanGuard {
  Invoke-AppPsql @"
UPDATE turn_stage ts
SET status = CASE
    WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS','PAINT') THEN 'complete'
    WHEN ts.stage_code = 'FLOORING' THEN 'skipped'
    WHEN ts.stage_code = 'DEEP_CLEAN' THEN 'active'
    ELSE 'pending'
  END,
  activated_at = CASE WHEN ts.stage_code = 'DEEP_CLEAN' THEN now() ELSE activated_at END,
  completed_at = CASE WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS','PAINT','FLOORING') THEN now() - interval '1 hour' ELSE NULL END,
  completed_via = CASE
    WHEN ts.stage_code = 'FLOORING' THEN 'skip'
    WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS','PAINT') THEN 'manual'
    ELSE NULL
  END,
  completed_by = CASE WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS','PAINT','FLOORING') THEN 'stage-7-setup' ELSE NULL END
FROM "turn" t
WHERE t.id = ts.turn_id
  AND t.unit_label = '12B'
  AND t.property_address = '418 Maple St'
  AND t.is_fixture = true;

UPDATE turn_stage ts
SET status = CASE
    WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT') THEN 'complete'
    WHEN ts.stage_code = 'DEEP_CLEAN' THEN 'active'
    ELSE 'pending'
  END,
  activated_at = CASE WHEN ts.stage_code = 'DEEP_CLEAN' THEN now() ELSE NULL END,
  completed_at = CASE WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT') THEN now() - interval '1 hour' ELSE NULL END,
  completed_via = CASE WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT') THEN 'manual' ELSE NULL END,
  completed_by = CASE WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT') THEN 'stage-7-setup' ELSE NULL END
FROM "turn" t
WHERE t.id = ts.turn_id
  AND t.unit_label = '14A'
  AND t.property_address = '418 Maple St'
  AND t.is_fixture = true;
"@
}

function Setup-TwoPaintUnits {
  Invoke-AppPsql @"
UPDATE turn_stage ts
SET status = CASE
    WHEN ts.seq < 6 THEN 'complete'
    WHEN ts.stage_code = 'PAINT' THEN 'active'
    ELSE 'pending'
  END,
  activated_at = CASE WHEN ts.stage_code = 'PAINT' THEN now() - interval '2 hours' WHEN ts.seq < 6 THEN now() - interval '6 hours' ELSE NULL END,
  completed_at = CASE WHEN ts.seq < 6 THEN now() - interval '5 hours' ELSE NULL END,
  completed_via = CASE WHEN ts.seq < 6 THEN 'manual' ELSE NULL END,
  completed_by = CASE WHEN ts.seq < 6 THEN 'stage-7-setup' ELSE NULL END
FROM "turn" t
WHERE t.id = ts.turn_id
  AND t.unit_label = '12A'
  AND t.property_address = '418 Maple St'
  AND t.is_fixture = true;
"@
}

function Write-Report {
  New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
  $reportPath = Join-Path $reportDir "$runId.json"
  $payload = [pscustomobject]@{
    run_id = $runId
    require_telegram = [bool]$RequireTelegram
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    fixtures = $results
    estimated_total_cost_usd = [decimal](($results | Measure-Object -Property estimated_cost_usd -Sum).Sum)
  }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($reportPath, ($payload | ConvertTo-Json -Depth 20), $utf8NoBom)
  Write-Host "Stage 7 report written to $reportPath"
}

if (-not $VendorToken) {
  $VendorToken = Get-EnvFileValue "VENDOR_IN_DEMO_TOKEN" "local-stage-4-vendor-in-token"
}
if (-not $BoardToken) {
  $BoardToken = Get-EnvFileValue "BOARD_DEMO_TOKEN" "local-stage-3-demo-token"
}

$managerChatId = Get-EnvFileValue "MANAGER_TELEGRAM_CHAT_ID" ""
$builderChatId = Get-EnvFileValue "BUILDER_TELEGRAM_CHAT_ID" ""
$riveraChatId = Get-EnvFileValue "RIVERA_TELEGRAM_CHAT_ID" (Get-EnvFileValue "VENDOR_TELEGRAM_CHAT_ID" "")
$mariasChatId = Get-EnvFileValue "MARIAS_TELEGRAM_CHAT_ID" ""
$daleChatId = Get-EnvFileValue "DALE_TELEGRAM_CHAT_ID" ""
$statewideChatId = Get-EnvFileValue "STATEWIDE_TELEGRAM_CHAT_ID" ""

$fixtureSpec = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
Assert-Equal @($fixtureSpec.fixtures).Count 20 "Stage 7 fixture manifest should contain F01-F20."

docker compose config | Out-Null
if ($LASTEXITCODE -ne 0) { throw "docker compose config failed." }

Get-ChildItem -LiteralPath (Join-Path $repoRoot "n8n-workflows") -Filter "*.json" | ForEach-Object {
  Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json | Out-Null
}

Reset-Fixtures

$deadline = (Get-Date).AddSeconds(60)
do {
  $registeredBoard = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf3-board-api'' AND method = ''GET'' AND "webhookPath" = ''board'';'
  $registeredVendorIn = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf4-vendor-in-api'' AND method = ''POST'' AND "webhookPath" = ''vendor-in'';'
  $registeredManagerAction = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf5-manager-action-api'' AND method = ''POST'' AND "webhookPath" = ''manager-action'';'
  $registeredErrorSmoke = Invoke-N8nPsqlScalar 'SELECT count(*) FROM webhook_entity WHERE "workflowId" = ''wf7-error-smoke'' AND method = ''POST'' AND "webhookPath" = ''stage-7-error-smoke'';'
  if ([int]$registeredBoard -gt 0 -and [int]$registeredVendorIn -gt 0 -and [int]$registeredManagerAction -gt 0 -and [int]$registeredErrorSmoke -gt 0) { break }
  Start-Sleep -Seconds 2
} while ((Get-Date) -lt $deadline)
Assert-True ([int]$registeredBoard -gt 0) "Board webhook is not registered."
Assert-True ([int]$registeredVendorIn -gt 0) "Vendor-in webhook is not registered."
Assert-True ([int]$registeredManagerAction -gt 0) "Manager-action webhook is not registered."
Assert-True ([int]$registeredErrorSmoke -gt 0) "Stage 7 error-smoke webhook is not registered."

$linkedCount = [int](Invoke-N8nPsqlScalar "SELECT count(*) FROM workflow_entity WHERE id <> 'wf7-error-handler' AND id LIKE 'wf%' AND settings->>'errorWorkflow' = 'wf7-error-handler';")
Assert-True ($linkedCount -ge 19) "Expected all Stage 3-7 workflows to point at wf7-error-handler."

$beforeErrors = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM event_log WHERE event_type = 'workflow_error';")
$smoke = Invoke-CurlJson -Uri "${ErrorSmokeUrl}?token=$([uri]::EscapeDataString($BoardToken))" -Body @{ reason = "stage-7-check"; run_id = $runId } -MaxTime 30
Wait-ForSql -Sql "SELECT count(*) FROM event_log WHERE event_type = 'workflow_error';" -Predicate { param($value) [int]$value -eq ($beforeErrors + 1) } -Description "one workflow_error event from error smoke" -Seconds 60 | Out-Null
Add-Result "F1" "pass" "Error-smoke returned HTTP $($smoke.Status) and produced exactly one workflow_error event. Builder Telegram delivery is confirmed during -RequireTelegram live run."

if (-not $RequireTelegram) {
  foreach ($fixture in $fixtureSpec.fixtures) {
    if ($fixture.id -ne "F1") {
      Add-Result $fixture.id "not_run_requires_telegram" "Run scripts/check-stage-7.ps1 -RequireTelegram after configuring HTTPS WEBHOOK_URL and live chat IDs."
    }
  }
  Write-Report
  Write-Host "Stage 7 static/error-handler verification passed. Live F01-F20 verification requires -RequireTelegram."
  return
}

if ([string]::IsNullOrWhiteSpace($managerChatId) -or [string]::IsNullOrWhiteSpace($builderChatId) -or [string]::IsNullOrWhiteSpace($riveraChatId) -or [string]::IsNullOrWhiteSpace($mariasChatId) -or [string]::IsNullOrWhiteSpace($daleChatId) -or [string]::IsNullOrWhiteSpace($statewideChatId)) {
  throw "RequireTelegram needs MANAGER_TELEGRAM_CHAT_ID, BUILDER_TELEGRAM_CHAT_ID, RIVERA_TELEGRAM_CHAT_ID, MARIAS_TELEGRAM_CHAT_ID, DALE_TELEGRAM_CHAT_ID, and STATEWIDE_TELEGRAM_CHAT_ID in .env."
}

Prompt-LiveStep "F1" "Confirm the builder-only Telegram chat received one Stage 7 error alert, and that the demo manager/prospect chat did not receive it."
Add-Result "F1-live-alert" "pass" "User confirmed builder-only error alert delivery."

Reset-Fixtures
$f01Text = "done with 12b F01 $runId"
Prompt-LiveStep "F01" "From Rivera, send: $f01Text"
Wait-ForSql -Sql "SELECT ts.status || ':' || coalesce(ts.completed_via, '') FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'PAINT';" -Predicate { param($value) $value -eq "complete:vendor_reply" } -Description "F01 12B Paint vendor completion" | Out-Null
$f01QueueId = [int](Wait-ForSql -Sql "SELECT coalesce((SELECT id FROM outbound_queue WHERE turn_id = (SELECT id FROM ""turn"" WHERE unit_label = '12B' AND property_address = '418 Maple St' AND is_fixture = true) AND status = 'awaiting_approval' ORDER BY id DESC LIMIT 1), 0);" -Predicate { param($value) [int]$value -gt 0 } -Description "F01 approval queue")
Prompt-LiveStep "F01-manager" "In the manager Telegram approval card for queue $f01QueueId, press Send."
Wait-ForSql -Sql "SELECT oq.status || ':' || ts.status FROM outbound_queue oq JOIN turn_stage ts ON ts.id = oq.stage_id WHERE oq.id = $f01QueueId;" -Predicate { param($value) $value -eq "sent:active" } -Description "F01 manager Send callback" | Out-Null
Add-Result "F01" "pass" "Live Telegram happy path completed and manager Send callback activated Flooring."

Reset-Fixtures
$f02Text = "finished the one on maple F02 $runId"
Prompt-LiveStep "F02" "From Rivera, send: $f02Text"
Wait-ForSql -Sql "SELECT count(*) FROM event_log WHERE event_type = 'manager_match_needed' AND raw_text = $(ConvertTo-SqlLiteral $f02Text) AND parsed_json->'match'->>'needs_manager' = 'true';" -Predicate { param($value) [int]$value -eq 1 } -Description "F02 manager match needed" | Out-Null
Add-Result "F02" "pass" "Ambiguous Maple message asked manager to choose."

Reset-Fixtures
$f03 = Send-GenericVendorMessage "placeholder_statewide_flooring" "all set at oak, unit 7 F03 $runId"
Assert-Equal $f03.Json.match.selected.unit_label "7" "F03 should select 7 Oak."
Add-Result "F03" "pass" "Generic address plus unit matched 7 Oak."

Reset-Fixtures
$f04 = Send-GenericVendorMessage "placeholder_rivera_painting" "done F04 $runId"
Assert-Equal $f04.Json.outcome "manager_match_needed" "F04 should ask manager."
Assert-Equal ([int]$f04.Json.match.score) 60 "F04 should stay below action threshold."
Add-Result "F04" "pass" "Bare done stayed below action threshold."

Reset-Fixtures
Setup-DeepCleanGuard
$f05aText = "12b cleaned F05A $runId"
$f05bText = "14a cleaned F05B $runId"
Prompt-LiveStep "F05" "From Maria, send: $f05aText ; then send: $f05bText"
Wait-ForSql -Sql "SELECT ts.status || ':' || coalesce(ts.completed_via, '') FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'DEEP_CLEAN';" -Predicate { param($value) $value -eq "complete:vendor_reply" } -Description "F05 12B clean allowed" | Out-Null
Wait-ForSql -Sql "SELECT count(*) FROM event_log WHERE event_type = 'guard_blocked' AND raw_text LIKE '%Repairs still open%' AND stage_id = $(Get-StageId '14A' '418 Maple St' 'DEEP_CLEAN');" -Predicate { param($value) [int]$value -ge 1 } -Description "F05 14A guard blocked" | Out-Null
Add-Result "F05" "pass" "12B clean allowed; 14A clean blocked by Repairs guard."

Reset-Fixtures
$f06 = Send-GenericVendorMessage "placeholder_dale_hutchins" "cant get there till thursday, sorry F06 $runId"
Assert-Equal $f06.Json.outcome "delay_notice" "F06 should route as delay_notice."
Add-Result "F06" "pass" "Delay notice logged without mutation."

Reset-Fixtures
$f07 = Send-GenericVendorMessage "placeholder_rivera_painting" "" @{ media_type = "photo"; media_file_id = "F07-$runId" }
Assert-Equal $f07.Json.event_type "manager_photo_match_needed" "F07 should need manager photo match."
Add-Result "F07" "pass" "Photo-only stored for manager review."

Reset-Fixtures
$f08 = Send-GenericVendorMessage "placeholder_rivera_painting" "is the water back on at 12b? F08 $runId"
Assert-Equal $f08.Json.outcome "question" "F08 should route as question."
Add-Result "F08" "pass" "Question forwarded without stage change."

Reset-Fixtures
$f09 = Send-GenericVendorMessage "placeholder_rivera_painting" "finshed unit 12b F09 $runId"
Assert-Equal $f09.Json.outcome "completed_awaiting_approval" "F09 typo completion should complete."
Add-Result "F09" "pass" "Typo completion matched and completed 12B."

Reset-Fixtures
$f10Text = "done with 12b F10 $runId"
Prompt-LiveStep "F10" "From Rivera, send this exact message twice within 30 seconds: $f10Text"
Wait-ForSql -Sql "SELECT count(*) FROM event_log WHERE event_type = 'stage_complete' AND raw_text = $(ConvertTo-SqlLiteral $f10Text);" -Predicate { param($value) [int]$value -eq 1 } -Description "F10 first completion exactly once" | Out-Null
Wait-ForSql -Sql "SELECT count(*) FROM event_log WHERE event_type = 'duplicate_inbound' AND raw_text = $(ConvertTo-SqlLiteral $f10Text);" -Predicate { param($value) [int]$value -eq 1 } -Description "F10 duplicate logged" | Out-Null
Add-Result "F10" "pass" "Duplicate live reply did not double-advance or double-draft."

Reset-Fixtures
$f11 = Send-GenericVendorMessage "mystery_vendor" "done with 12b F11 $runId"
Assert-Equal $f11.Json.outcome "unknown_sender" "F11 should be unknown sender."
Assert-True ($null -eq $f11.Json.match) "F11 must not disclose match data."
Add-Result "F11" "pass" "Unknown sender logged without match disclosure."

Reset-Fixtures
Setup-DeepCleanGuard
$f12Text = "12b cleaned F12 $runId"
Prompt-LiveStep "F12" "From Maria, send: $f12Text"
Wait-ForSql -Sql "SELECT ts.status || ':' || coalesce(ts.completed_via, '') FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'DEEP_CLEAN';" -Predicate { param($value) $value -eq "complete:vendor_reply" } -Description "F12 skipped flooring allows clean" | Out-Null
Add-Result "F12" "pass" "Skipped Flooring counted as satisfied for Deep Clean."

Reset-Fixtures
$birchTurnId = [int](Invoke-AppPsqlScalar "SELECT id FROM ""turn"" WHERE unit_label = '55' AND property_address = '55 Birch Ct' AND is_fixture = true;")
$f13 = Invoke-CurlJson -Uri $ManagerActionUrl -Headers @{ "X-Demo-Token" = $BoardToken } -Body @{ action = "CANCEL"; turn_id = $birchTurnId; actor_id = "stage-7-check" }
Assert-Equal $f13.Json.outcome "cancelled" "F13 cancel should return cancelled."
Add-Result "F13" "pass" "55 Birch cancelled and removed from active flow."

Reset-Fixtures
Setup-TwoPaintUnits
$f14a = Send-GenericVendorMessage "placeholder_rivera_painting" "done with 12b F14A $runId"
$f14b = Send-GenericVendorMessage "placeholder_rivera_painting" "done with 12a F14B $runId"
Assert-Equal $f14a.Json.outcome "completed_awaiting_approval" "F14 12B should complete."
Assert-Equal $f14b.Json.outcome "completed_awaiting_approval" "F14 12A should complete."
$f14Queues = [int](Invoke-AppPsqlScalar "SELECT count(*) FROM outbound_queue WHERE status = 'awaiting_approval' AND created_at > now() - interval '10 minutes';")
Assert-True ($f14Queues -ge 2) "F14 should create two approval queues."
Add-Result "F14" "pass" "Same vendor completed two units with separate approval rows."

Reset-Fixtures
Prompt-LiveStep "F15" "From Rivera, send a voice note with no text."
Wait-ForSql -Sql "SELECT count(*) FROM event_log WHERE event_type = 'unsupported_media' AND channel = 'telegram' AND actor_id = $(ConvertTo-SqlLiteral $riveraChatId) AND created_at > now() - interval '5 minutes';" -Predicate { param($value) [int]$value -ge 1 } -Description "F15 unsupported voice note" | Out-Null
Add-Result "F15" "pass" "Voice note was logged as unsupported media."

Reset-Fixtures
$f16 = Send-GenericVendorMessage "placeholder_rivera_painting" "done with 12b F16 $runId" @{ received_at = "2026-08-03T09:00:00.000Z" }
Assert-Equal $f16.Json.outcome "completed_awaiting_approval" "F16 stage update should happen immediately."
$watchdogHeld = Invoke-CurlJson -Uri $WatchdogUrl -Body @{ force_hour = 2 }
Assert-True ([int]$watchdogHeld.Json.held_count -ge 1) "F16 watchdog should hold outside-hours stall alerts."
Add-Result "F16" "pass" "Completion was immediate; watchdog alert path held outside business hours."

Reset-Fixtures
$f17 = Send-GenericVendorMessage "placeholder_rivera_painting" "the tenant trashed this place, that carpet is coming out of their deposit F17 $runId"
Assert-Equal $f17.Json.outcome "question" "F17 should route as question."
Assert-True ($f17.BodyText -notmatch "charge|liability|deduct|wear") "F17 response should not generate deposit assessment language."
Add-Result "F17" "pass" "Deposit/damage message routed to manager without assessment language."

Reset-Fixtures
$f18 = Send-GenericVendorMessage "placeholder_rivera_painting" "done with 12b F18 $runId"
Assert-Equal $f18.Json.outcome "completed_awaiting_approval" "F18 generic happy path should complete."
Assert-Equal $f18.Json.stage_state_mutated $true "F18 should mutate through generic channel."
Add-Result "F18" "pass" "Generic webhook drove the same completion path as Telegram happy path."

Reset-Fixtures
$paint12B = Get-StageId "12B" "418 Maple St" "PAINT"
$boardBefore = Invoke-RestMethod -Uri "${BoardUrl}?token=$([uri]::EscapeDataString($BoardToken))" -Method Get -TimeoutSec 30
$beforeReplyRate = [int]$boardBefore.metrics.vendor_reply_rate
$f19Raw = & curl.exe -sS -X POST "${CompleteUrl}?token=$([uri]::EscapeDataString($BoardToken))" -d "stage_id=$paint12B" -d "actor_id=stage-7-check" -d "channel=board" -w "`n%{http_code}" --max-time 30
if ($LASTEXITCODE -ne 0) { throw "curl failed for F19 board completion." }
$f19Parts = @($f19Raw -split "`n")
Assert-Equal ([int]$f19Parts[-1]) 200 "F19 board completion should return 200."
$f19Status = Invoke-AppPsqlScalar "SELECT status || ':' || coalesce(completed_via, '') FROM turn_stage WHERE id = $paint12B;"
Assert-Equal $f19Status "complete:manual" "F19 should complete via manual."
$boardAfter = Invoke-RestMethod -Uri "${BoardUrl}?token=$([uri]::EscapeDataString($BoardToken))" -Method Get -TimeoutSec 30
Assert-True ([int]$boardAfter.metrics.vendor_reply_rate -lt $beforeReplyRate) "F19 should lower vendor reply rate."
Add-Result "F19" "pass" "Board manual completion worked and lowered vendor reply rate."

Reset-Fixtures
$deepClean14A = Get-StageId "14A" "418 Maple St" "DEEP_CLEAN"
$f20Raw = & curl.exe -sS -X POST "${CompleteUrl}?token=$([uri]::EscapeDataString($BoardToken))" -d "stage_id=$deepClean14A" -d "actor_id=stage-7-check" -d "channel=digest" -w "`n%{http_code}" --max-time 30
if ($LASTEXITCODE -ne 0) { throw "curl failed for F20 digest completion." }
$f20Parts = @($f20Raw -split "`n")
Assert-Equal ([int]$f20Parts[-1]) 409 "F20 digest completion should be blocked."
$f20Body = ($f20Parts[0..($f20Parts.Count - 2)] -join "`n") | ConvertFrom-Json
Assert-True ($f20Body.reason -like "*Repairs still open*") "F20 should explain Repairs-open guard."
Add-Result "F20" "pass" "Digest/manual guard blocked 14A Deep Clean while Repairs was open."

Write-Report
Write-Host "Stage 7 live fixture verification passed."
