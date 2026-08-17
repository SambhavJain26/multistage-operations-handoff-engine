[CmdletBinding()]
param(
  [switch]$SkipGenerate,
  [switch]$RequireDocker,
  [switch]$RequireAirtable
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
function Fail([string]$Message) { throw "Consolidated demo check failed: $Message" }

if (-not $SkipGenerate) {
  node (Join-Path $scriptDir "generate-demo-workflows.js")
  if ($LASTEXITCODE -ne 0) { Fail "workflow generation failed" }
}

$expected = @("Airtable Workspace", "Vendor Communications", "Stage Update", "Manager Operations", "Vendor Delivery", "Monitoring", "Builder Error Handler")
$files = @(Get-ChildItem (Join-Path $repoRoot "n8n-workflows") -Filter "*.json")
if ($files.Count -ne 7) { Fail "expected seven workflows, found $($files.Count)" }
$workflows = @($files | ForEach-Object { Get-Content -Raw $_.FullName | ConvertFrom-Json })
if ((Compare-Object ($expected | Sort-Object) ($workflows.name | Sort-Object)).Count -gt 0) { Fail "visible workflow names do not match the consolidated demo list" }
foreach ($workflow in $workflows) {
  if ($workflow.id -ne "demo-builder-error-handler" -and $workflow.settings.errorWorkflow -ne "demo-builder-error-handler") { Fail "$($workflow.name) is not linked to Builder Error Handler" }
  if ($workflow.name -match '^(WF-|Stage\s+[0-9])') { Fail "$($workflow.name) exposes an internal stage/workflow number" }
  foreach ($node in @($workflow.nodes | Where-Object type -eq "n8n-nodes-base.code")) {
    if ($node.parameters.jsCode -match '(?m)(?:\bitems\s*\.(?:map|filter|forEach)|return\s+items\b|of\s+items\b)') { Fail "$($workflow.name) / $($node.name) uses the legacy items variable" }
  }
}

$vendor = $workflows | Where-Object id -eq "demo-vendor-communications"
$vendorRaw = $vendor | ConvertTo-Json -Depth 100
foreach ($needle in @("n8n-nodes-base.emailReadImap", "n8n-nodes-base.telegramTrigger", "n8n-nodes-base.webhook", "json_schema", "selfOriginated", "content.airtable.com")) {
  if ($vendorRaw -notlike "*$needle*") { Fail "Vendor Communications is missing $needle" }
}
foreach ($intent in @("stage_complete", "delay_notice", "question", "deposit_tenant_liability", "unclear")) {
  if ($vendorRaw -notlike "*$intent*") { Fail "AI interpretation schema is missing $intent" }
}

$stageRaw = ($workflows | Where-Object id -eq "demo-stage-update") | ConvertTo-Json -Depth 100
foreach ($needle in @("Sequence Guard", "completion", "awaiting_approval", "Log Completion Guard Block")) { if ($stageRaw -notlike "*$needle*") { Fail "Stage Update is missing $needle" } }
$deliveryRaw = ($workflows | Where-Object id -eq "demo-vendor-delivery") | ConvertTo-Json -Depth 100
foreach ($needle in @("Send Vendor Email", "Send Vendor Telegram", "partially_sent", "retry_pending", "outbound_delivery")) { if ($deliveryRaw -notlike "*$needle*") { Fail "Vendor Delivery is missing $needle" } }
$managerRaw = ($workflows | Where-Object id -eq "demo-manager-operations") | ConvertTo-Json -Depth 100
foreach ($needle in @("n8n-nodes-base.telegramTrigger", "RETRY_EMAIL", "RETRY_TELEGRAM", "SNOOZE", "CANCEL", "/health")) { if ($managerRaw -notlike "*$needle*") { Fail "Manager Operations is missing $needle" } }
$airtableRaw = ($workflows | Where-Object id -eq "demo-airtable-workspace") | ConvertTo-Json -Depth 100
foreach ($needle in @("performUpsert", "fieldsToMergeOn", "payload_hash", '$input.all()')) { if ($airtableRaw -notlike "*$needle*") { Fail "Airtable Workspace is missing $needle" } }
$monitorRaw = ($workflows | Where-Object id -eq "demo-monitoring") | ConvertTo-Json -Depth 100
foreach ($needle in @("Stall", "weekly", "scheduleTrigger")) { if ($monitorRaw -notlike "*$needle*") { Fail "Monitoring is missing $needle" } }

foreach ($removed in @("board\index.html", "board\sim.html", "n8n-workflows\wf-3-board-api.json", "n8n-workflows\wf-3-stage-complete-api.json", "n8n-workflows\wf-5-manager-action-api.json", "n8n-workflows\wf-6-health-api.json")) {
  if (Test-Path (Join-Path $repoRoot $removed)) { Fail "removed custom-UI asset still exists: $removed" }
}
$compose = Get-Content -Raw (Join-Path $repoRoot "docker-compose.yml")
if ($compose -match 'BOARD_|/board|board:') { Fail "local Compose still contains custom-board configuration" }

$fixtures = Get-Content -Raw (Join-Path $repoRoot "fixtures\email-ai-fixtures.json") | ConvertFrom-Json
if (-not ($fixtures.fixtures | Where-Object { $_.id -eq "E16" -and $_.expected.self_originated_without_reply_header })) { Fail "single-inbox self-message fixture is missing" }

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
  $ids = "'demo-airtable-workspace','demo-vendor-communications','demo-stage-update','demo-manager-operations','demo-vendor-delivery','demo-monitoring','demo-builder-error-handler'"
  $count = "SELECT count(*) FROM workflow_entity WHERE id IN ($ids);" | docker exec -i make-ready-postgres psql -q -U n8n -d n8n -tA
  if ([int](($count | Select-Object -First 1).Trim()) -ne 7) { Fail "n8n does not contain all seven consolidated workflows" }
}

Write-Host "Consolidated Airtable/email demo checks passed. Workflows: 7."
