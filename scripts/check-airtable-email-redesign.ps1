[CmdletBinding()]
param(
  [switch]$SkipGenerate,
  [switch]$RequireDocker,
  [switch]$RequireAirtable
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
function Fail([string]$Message) { throw "Airtable/email redesign check failed: $Message" }

if (-not $SkipGenerate) {
  node (Join-Path $scriptDir "generate-airtable-email-workflows.js")
  if ($LASTEXITCODE -ne 0) { Fail "workflow generation failed" }
}

$expected = @(
  "Airtable Turn Intake", "Airtable Sync", "Vendor Email Ingest", "Vendor Telegram Ingest", "Vendor Inbound API",
  "Vendor Message Router", "AI Message Interpreter", "Unit Matcher", "Sequence Guard", "Stage Complete Core",
  "Vendor Completion Handler", "Vendor Delivery Dispatcher", "Manager Telegram Router", "Manager Action Core",
  "Manager Daily Digest", "Stall Watchdog", "Health Core", "Weekly Metrics Digest", "Builder Error Handler"
)
$files = @(Get-ChildItem (Join-Path $repoRoot "n8n-workflows") -Filter "*.json")
if ($files.Count -ne 19) { Fail "expected 19 workflows, found $($files.Count)" }
$workflows = @($files | ForEach-Object { Get-Content -Raw $_.FullName | ConvertFrom-Json })
$actual = @($workflows.name | Sort-Object)
if ((Compare-Object ($expected | Sort-Object) $actual).Count -gt 0) { Fail "visible workflow names do not match the approved operational list" }
foreach ($workflow in $workflows) {
  if ($workflow.id -ne "wf7-error-handler" -and $workflow.settings.errorWorkflow -ne "wf7-error-handler") { Fail "$($workflow.name) is not linked to Builder Error Handler" }
  if ($workflow.name -match '^WF-|Stage\s+[0-9]') { Fail "$($workflow.name) exposes an internal stage/workflow number" }
  foreach ($node in @($workflow.nodes | Where-Object type -eq "n8n-nodes-base.code")) {
    if ($node.parameters.jsCode -match '(?m)(?:\bitems\s*\.(?:map|filter|forEach)|return\s+items\b|of\s+items\b)') { Fail "$($workflow.name) / $($node.name) uses the legacy items variable" }
  }
}

foreach ($removed in @("board\index.html", "board\sim.html", "n8n-workflows\wf-3-board-api.json", "n8n-workflows\wf-3-stage-complete-api.json", "n8n-workflows\wf-5-manager-action-api.json", "n8n-workflows\wf-6-health-api.json")) {
  if (Test-Path (Join-Path $repoRoot $removed)) { Fail "removed custom-UI asset still exists: $removed" }
}
$compose = Get-Content -Raw (Join-Path $repoRoot "docker-compose.yml")
if ($compose -match 'BOARD_|/board|board:') { Fail "local Compose still contains custom-board configuration" }

$interpreter = $workflows | Where-Object id -eq "wf9-ai-interpreter"
$interpreterRaw = $interpreter | ConvertTo-Json -Depth 100
foreach ($intent in @("stage_complete","stage_started","delay_notice","schedule_change","access_issue","question","materials_issue","invoice_payment","deposit_tenant_liability","not_my_unit","unrelated","unclear")) {
  if ($interpreterRaw -notlike "*$intent*") { Fail "AI schema is missing intent $intent" }
}
if ($interpreterRaw -notlike "*json_schema*" -or $interpreterRaw -notlike "*strict*") { Fail "AI interpreter is not using strict structured output" }

$delivery = $workflows | Where-Object id -eq "wf9-vendor-delivery"
$deliveryRaw = $delivery | ConvertTo-Json -Depth 100
foreach ($needle in @("Send Vendor Email","Send Vendor Telegram","partially_sent","retry_pending","outbound_delivery")) { if ($deliveryRaw -notlike "*$needle*") { Fail "delivery workflow missing $needle" } }
$actionRaw = ($workflows | Where-Object id -eq "wf5-manager-action-core") | ConvertTo-Json -Depth 100
foreach ($needle in @("configuration_blocked","RETRY_EMAIL","RETRY_TELEGRAM","email_address","telegram_chat_id")) { if ($actionRaw -notlike "*$needle*") { Fail "manager action safety gate missing $needle" } }

$email = $workflows | Where-Object id -eq "wf9-vendor-email-ingest"
if (-not ($email.nodes.type -contains "n8n-nodes-base.emailReadImap")) { Fail "email intake does not use an IMAP trigger" }
if (($email | ConvertTo-Json -Depth 100) -notlike "*content.airtable.com*v0*uploadAttachment*") { Fail "supported email evidence is not uploaded to Airtable attachments" }
$telegramIngestRaw = ($workflows | Where-Object id -eq "wf4-vendor-telegram-ingest") | ConvertTo-Json -Depth 100
foreach ($needle in @("Download Vendor Telegram Photo", "Upload Telegram Evidence To Airtable", "content.airtable.com")) { if ($telegramIngestRaw -notlike "*$needle*") { Fail "Telegram evidence path missing $needle" } }
if (-not ($delivery.nodes.type -contains "n8n-nodes-base.emailSend")) { Fail "vendor delivery does not use SMTP email" }
$manager = $workflows | Where-Object id -eq "wf3-manager-router"
if (-not ($manager.nodes.type -contains "n8n-nodes-base.telegramTrigger")) { Fail "manager controls are not Telegram-only" }

$migration = Get-Content -Raw (Join-Path $repoRoot "db\postgres\migrations\006-airtable-email-ai-redesign.sql")
foreach ($needle in @("communication_message","outbound_delivery","airtable_record_map","partially_sent","email_address")) { if ($migration -notlike "*$needle*") { Fail "migration missing $needle" } }
$syncRaw = ($workflows | Where-Object id -eq "wf9-airtable-sync") | ConvertTo-Json -Depth 100
foreach ($needle in @('performUpsert', 'fieldsToMergeOn', 'payload_hash', '$input.all()')) { if ($syncRaw -notlike "*$needle*") { Fail "Airtable reconciliation missing $needle" } }
$fixtures = Get-Content -Raw (Join-Path $repoRoot "fixtures\email-ai-fixtures.json") | ConvertFrom-Json
if ($fixtures.fixtures.Count -lt 15) { Fail "email/AI fixture coverage is incomplete" }

$schemaArgs = @("-NoProfile", "-File", (Join-Path $scriptDir "check-airtable-schema.ps1"))
if ($RequireAirtable) { $schemaArgs += "-Live" }
& pwsh @schemaArgs
if ($LASTEXITCODE -ne 0) { Fail "Airtable schema check failed" }

$parseErrors = @()
Get-ChildItem (Join-Path $repoRoot "scripts") -Filter "*.ps1" | ForEach-Object {
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$errors) | Out-Null
  if ($errors) { $parseErrors += "$($_.Name): $($errors.Message -join '; ')" }
}
if ($parseErrors.Count) { Fail ($parseErrors -join " | ") }

docker compose config | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "docker compose config failed" }
if ($RequireDocker) {
  $running = docker compose ps --status running --services
  if ($LASTEXITCODE -ne 0 -or $running -notcontains "postgres" -or $running -notcontains "n8n") { Fail "n8n and Postgres must be running" }
  $tables = "SELECT to_regclass('public.communication_message') IS NOT NULL AND to_regclass('public.outbound_delivery') IS NOT NULL AND to_regclass('public.airtable_record_map') IS NOT NULL;" | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -tA
  if (($tables | Select-Object -First 1).Trim() -ne 't') { Fail "redesign tables are not migrated in Postgres" }
}

Write-Host "Airtable/email redesign checks passed. Workflows: 19. Email/AI fixtures: $($fixtures.fixtures.Count)."
