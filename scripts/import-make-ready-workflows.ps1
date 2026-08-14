[CmdletBinding()]
param(
  [switch]$ActivateTelegram,
  [switch]$ActivateEmail,
  [switch]$ActivateAirtable,
  [switch]$NoRestart
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$workflowDir = Join-Path $repoRoot "n8n-workflows"
$tmpDir = Join-Path $repoRoot "data\tmp-airtable-email-import"
$containerDir = "/data/tmp-airtable-email-import"

function Get-EnvValue([string]$Name) {
  $path = Join-Path $repoRoot ".env"
  if (-not (Test-Path -LiteralPath $path)) { return $null }
  $line = Get-Content -LiteralPath $path | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s*=" } | Select-Object -Last 1
  if (-not $line) { return $null }
  return ($line -replace "^\s*$([regex]::Escape($Name))\s*=\s*", "").Trim().Trim('"').Trim("'")
}

function Invoke-N8nScalar([string]$Sql) {
  $value = $Sql | docker exec -i make-ready-postgres psql -q -U n8n -d n8n -tA
  if ($LASTEXITCODE -ne 0) { throw "n8n database query failed." }
  $first = $value | Select-Object -First 1
  if ($null -eq $first) { return "" }
  return $first.Trim()
}

function Get-CredentialId([string]$Name, [switch]$Required) {
  $escaped = $Name.Replace("'", "''")
  $id = Invoke-N8nScalar "SELECT id FROM credentials_entity WHERE name='$escaped' LIMIT 1;"
  if ($Required -and [string]::IsNullOrWhiteSpace($id)) { throw "Create the n8n credential named '$Name' before activating this connector." }
  return $id
}

function Require-Env([string]$Name) {
  $value = Get-EnvValue $Name
  if ([string]::IsNullOrWhiteSpace($value)) { throw "$Name is required in .env for the selected activation mode." }
  return $value
}

docker compose config | Out-Null
if ($LASTEXITCODE -ne 0) { throw "docker compose config failed." }

node (Join-Path $scriptDir "generate-airtable-email-workflows.js")
if ($LASTEXITCODE -ne 0) { throw "Workflow generation failed." }

Get-ChildItem (Join-Path $repoRoot "db\postgres\migrations") -Filter "*.sql" | Sort-Object Name | ForEach-Object {
  docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -f "/docker-entrypoint-initdb.d/migrations/$($_.Name)" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Migration failed: $($_.Name)" }
}

$baseId = Get-EnvValue "AIRTABLE_BASE_ID"
$manifestPath = Join-Path $repoRoot "data\airtable\airtable-manifest.json"
if ([string]::IsNullOrWhiteSpace($baseId) -and (Test-Path -LiteralPath $manifestPath)) {
  $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
  $baseId = if ($manifest.baseId) { $manifest.baseId } else { $manifest.base_id }
}
$fromEmail = Get-EnvValue "VENDOR_EMAIL_FROM"
$replyTo = Get-EnvValue "VENDOR_EMAIL_REPLY_TO"
$vendorToken = Get-EnvValue "VENDOR_IN_DEMO_TOKEN"
if ([string]::IsNullOrWhiteSpace($vendorToken)) { $vendorToken = "local-stage-4-vendor-in-token" }
$model = Get-EnvValue "OPENAI_MODEL_CLASSIFY"
if ([string]::IsNullOrWhiteSpace($model)) { $model = "gpt-5.6-luna" }

$managerChat = Get-EnvValue "MANAGER_TELEGRAM_CHAT_ID"
$builderChat = Get-EnvValue "BUILDER_TELEGRAM_CHAT_ID"
if ($ActivateTelegram) {
  $managerChat = Require-Env "MANAGER_TELEGRAM_CHAT_ID"
  $builderChat = Require-Env "BUILDER_TELEGRAM_CHAT_ID"
  $webhook = Require-Env "WEBHOOK_URL"
  $containerWebhook = (docker exec make-ready-n8n printenv WEBHOOK_URL | Select-Object -First 1).Trim()
  if ($webhook -notmatch '^https://' -or $containerWebhook -notmatch '^https://') { throw "Telegram activation requires the same HTTPS WEBHOOK_URL in .env and the recreated n8n container." }
}
if ($ActivateAirtable -and ([string]::IsNullOrWhiteSpace($baseId) -or $baseId -notmatch '^app')) { throw "A valid AIRTABLE_BASE_ID or ignored Airtable manifest is required." }
if ($ActivateEmail) {
  $fromEmail = Require-Env "VENDOR_EMAIL_FROM"
  $replyTo = Require-Env "VENDOR_EMAIL_REPLY_TO"
}

$credentialIds = @{
  "cred_make_ready_pg" = Get-CredentialId "Make-Ready Postgres" -Required
  "cred_make_ready_openai" = Get-CredentialId "Make-Ready OpenAI" -Required
  "jASZWMlrfp3v2tWH" = Get-CredentialId "Make-Ready Manager Telegram Bot" -Required:$ActivateTelegram
  "5mBfLarFM6t8Cgcz" = Get-CredentialId "Make-Ready Vendor Telegram Bot" -Required:$ActivateTelegram
  "cred_make_ready_airtable" = Get-CredentialId "Make-Ready Airtable" -Required:$ActivateAirtable
  "cred_make_ready_email_imap" = Get-CredentialId "Make-Ready Vendor Email IMAP" -Required:$ActivateEmail
  "cred_make_ready_email_smtp" = Get-CredentialId "Make-Ready Vendor Email SMTP" -Required:$ActivateEmail
}

$all = @(Get-ChildItem -LiteralPath $workflowDir -Filter "*.json" | Sort-Object Name)
if ($all.Count -ne 19) { throw "Expected exactly 19 operational workflow exports; found $($all.Count)." }
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
Get-ChildItem -LiteralPath $tmpDir -Force | Remove-Item -Recurse -Force
$utf8 = New-Object System.Text.UTF8Encoding($false)

$alwaysActive = @('wf3-sequence-guard','wf3-stage-complete-core','wf4-unit-matcher','wf4-vendor-router','wf4-vendor-in-api','wf5-vendor-completion-handler','wf5-manager-action-core','wf6-health-core','wf6-stall-watchdog','wf9-ai-interpreter','wf9-airtable-sync','wf9-vendor-delivery')
$telegramActive = @('wf3-manager-router','wf3-daily-digest','wf4-vendor-telegram-ingest','wf6-weekly-digest')
$emailActive = @('wf9-vendor-email-ingest')
$airtableActive = @('wf4-turn-intake','wf9-airtable-sync')

foreach ($file in $all) {
  $workflow = Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json
  $workflow.active = $false
  $json = $workflow | ConvertTo-Json -Depth 100
  $json = $json.Replace("local-stage-4-vendor-in-token", $vendorToken).Replace("gpt-5.6-luna", $model)
  if ($ActivateTelegram) { $json = $json.Replace("stage3-manager-chat-id-missing", $managerChat).Replace("stage5-manager-chat-id-missing", $managerChat).Replace("stage7-builder-chat-id-missing", $builderChat) }
  if ($ActivateAirtable) { $json = $json.Replace("AIRTABLE_BASE_ID_PLACEHOLDER", $baseId) }
  if ($ActivateEmail) { $json = $json.Replace("VENDOR_EMAIL_FROM_PLACEHOLDER", $fromEmail).Replace("VENDOR_EMAIL_REPLY_TO_PLACEHOLDER", $replyTo) }
  foreach ($placeholder in $credentialIds.Keys) { if (-not [string]::IsNullOrWhiteSpace($credentialIds[$placeholder])) { $json = $json.Replace($placeholder, $credentialIds[$placeholder]) } }
  [System.IO.File]::WriteAllText((Join-Path $tmpDir $file.Name), $json, $utf8)
}

docker exec make-ready-n8n n8n import:workflow --separate --input=$containerDir
if ($LASTEXITCODE -ne 0) { throw "Workflow import failed." }

$retired = @('wf3-board-api','wf3-stage-complete-api','wf5-manager-action-api','wf6-health-api','wf7-error-smoke')
foreach ($id in $retired) { docker exec make-ready-n8n n8n unpublish:workflow --id=$id 2>$null | Out-Null }
$retiredSql = ($retired | ForEach-Object { "'" + $_.Replace("'", "''") + "'" }) -join ','
@"
DELETE FROM workflow_published_version WHERE "workflowId" IN ($retiredSql);
DELETE FROM workflow_publication_outbox WHERE "workflowId" IN ($retiredSql);
DELETE FROM workflow_entity WHERE id IN ($retiredSql);
"@ | docker exec -i make-ready-postgres psql -q -U n8n -d n8n -v ON_ERROR_STOP=1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Could not remove retired UI-only workflows." }

docker exec make-ready-n8n n8n publish:workflow --id=wf7-error-handler | Out-Host
$publish = @($alwaysActive)
if ($ActivateTelegram) { $publish += $telegramActive }
if ($ActivateEmail) { $publish += $emailActive }
if ($ActivateAirtable) { $publish += $airtableActive }
foreach ($id in ($publish | Select-Object -Unique)) { docker exec make-ready-n8n n8n publish:workflow --id=$id | Out-Host; if ($LASTEXITCODE -ne 0) { throw "Could not publish $id." } }
foreach ($id in @($telegramActive + $emailActive + $airtableActive | Select-Object -Unique)) { if ($publish -notcontains $id) { docker exec make-ready-n8n n8n unpublish:workflow --id=$id 2>$null | Out-Null } }

if ($ActivateTelegram) {
  $telegramMap = @(@("Rivera Painting","paint","RIVERA_TELEGRAM_CHAT_ID"),@("Maria's Cleaning Co","clean","MARIAS_TELEGRAM_CHAT_ID"),@("Dale Hutchins","repairs","DALE_TELEGRAM_CHAT_ID"),@("Statewide Flooring","flooring","STATEWIDE_TELEGRAM_CHAT_ID"),@("QuickHaul Junk Removal","trashout","QUICKHAUL_TELEGRAM_CHAT_ID"))
  foreach ($row in $telegramMap) { $value=Require-Env $row[2]; $sql="UPDATE vendor SET telegram_chat_id='"+$value.Replace("'","''")+"' WHERE name='"+$row[0].Replace("'","''")+"' AND trade='"+$row[1]+"';"; $sql | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 | Out-Null }
}
if ($ActivateEmail) {
  $emailMap = @(@("Rivera Painting","paint","RIVERA_VENDOR_EMAIL"),@("Maria's Cleaning Co","clean","MARIAS_VENDOR_EMAIL"),@("Dale Hutchins","repairs","DALE_VENDOR_EMAIL"),@("Statewide Flooring","flooring","STATEWIDE_VENDOR_EMAIL"),@("QuickHaul Junk Removal","trashout","QUICKHAUL_VENDOR_EMAIL"))
  foreach ($row in $emailMap) { $value=Require-Env $row[2]; $sql="UPDATE vendor SET email_address='"+$value.Replace("'","''")+"' WHERE name='"+$row[0].Replace("'","''")+"' AND trade='"+$row[1]+"';"; $sql | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 | Out-Null }
}

if (-not $NoRestart) { docker compose restart n8n | Out-Host; if ($LASTEXITCODE -ne 0) { throw "n8n restart failed." } }
$workflowIdSql = ($all | ForEach-Object { $w = Get-Content -Raw $_.FullName | ConvertFrom-Json; "'" + $w.id.Replace("'", "''") + "'" }) -join ','
$count = [int](Invoke-N8nScalar "SELECT count(*) FROM workflow_entity WHERE id IN ($workflowIdSql);")
if ($count -ne 19) { throw "n8n contains only $count of the 19 operational workflows after import." }
$linked = [int](Invoke-N8nScalar "SELECT count(*) FROM workflow_entity WHERE id<>'wf7-error-handler' AND settings->>'errorWorkflow'='wf7-error-handler' AND id IN ($workflowIdSql);")
if ($linked -ne 18) { throw "Expected all 18 non-error workflows to use Builder Error Handler; found $linked." }
Write-Host "Imported 19 operational workflows. Telegram=$([bool]$ActivateTelegram) Email=$([bool]$ActivateEmail) Airtable=$([bool]$ActivateAirtable)."
