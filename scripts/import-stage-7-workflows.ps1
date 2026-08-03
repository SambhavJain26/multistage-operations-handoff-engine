[CmdletBinding()]
param(
  [switch]$ActivateTelegram,
  [switch]$NoRestart,
  [string]$ClassifyModelOverride
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$workflowDir = Join-Path $repoRoot "n8n-workflows"
$tmpImportDir = Join-Path $repoRoot "data\tmp-stage-7-workflow-import"
$containerImportDir = "/data/tmp-stage-7-workflow-import"

function Get-EnvFileValue {
  param([string]$Name)
  $envPath = Join-Path $repoRoot ".env"
  if (-not (Test-Path -LiteralPath $envPath)) {
    return $null
  }

  $line = Get-Content -LiteralPath $envPath |
    Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s*=" } |
    Select-Object -Last 1

  if (-not $line) {
    return $null
  }

  return ($line -replace "^\s*$([regex]::Escape($Name))\s*=\s*", "").Trim().Trim('"').Trim("'")
}

function ConvertTo-SqlLiteral {
  param([string]$Value)
  return "'" + ($Value -replace "'", "''") + "'"
}

function Invoke-N8nPsqlScalar {
  param([string]$Sql)
  $result = $Sql | docker exec -i make-ready-postgres psql -q -U n8n -d n8n -tA
  if ($LASTEXITCODE -ne 0) {
    throw "n8n psql scalar failed."
  }
  return ($result | Select-Object -First 1).Trim()
}

$boardToken = Get-EnvFileValue "BOARD_DEMO_TOKEN"
$vendorInToken = Get-EnvFileValue "VENDOR_IN_DEMO_TOKEN"
$boardOrigin = Get-EnvFileValue "BOARD_ALLOWED_ORIGIN"
$managerChatId = Get-EnvFileValue "MANAGER_TELEGRAM_CHAT_ID"
$builderChatId = Get-EnvFileValue "BUILDER_TELEGRAM_CHAT_ID"
$vendorChatId = Get-EnvFileValue "VENDOR_TELEGRAM_CHAT_ID"
$riveraChatId = Get-EnvFileValue "RIVERA_TELEGRAM_CHAT_ID"
$mariasChatId = Get-EnvFileValue "MARIAS_TELEGRAM_CHAT_ID"
$daleChatId = Get-EnvFileValue "DALE_TELEGRAM_CHAT_ID"
$statewideChatId = Get-EnvFileValue "STATEWIDE_TELEGRAM_CHAT_ID"
$classifyModel = Get-EnvFileValue "OPENAI_MODEL_CLASSIFY"

if ([string]::IsNullOrWhiteSpace($boardToken)) {
  $boardToken = "local-stage-3-demo-token"
}
if ([string]::IsNullOrWhiteSpace($vendorInToken)) {
  $vendorInToken = "local-stage-4-vendor-in-token"
}
if ([string]::IsNullOrWhiteSpace($boardOrigin)) {
  $boardOrigin = "http://localhost:8080"
}
if ([string]::IsNullOrWhiteSpace($classifyModel)) {
  $classifyModel = "gpt-5.6-luna"
}
if (-not [string]::IsNullOrWhiteSpace($ClassifyModelOverride)) {
  $classifyModel = $ClassifyModelOverride
}
if ([string]::IsNullOrWhiteSpace($riveraChatId)) {
  $riveraChatId = $vendorChatId
}

if ($ActivateTelegram) {
  $webhookUrl = Get-EnvFileValue "WEBHOOK_URL"
  $containerWebhookUrl = docker exec make-ready-n8n printenv WEBHOOK_URL
  if ($LASTEXITCODE -ne 0) {
    throw "Could not read WEBHOOK_URL from the n8n container."
  }
  $containerWebhookUrl = ($containerWebhookUrl | Select-Object -First 1).Trim()

  if ([string]::IsNullOrWhiteSpace($managerChatId)) {
    throw "MANAGER_TELEGRAM_CHAT_ID is required before activating Stage 7 Telegram workflows."
  }
  if ([string]::IsNullOrWhiteSpace($builderChatId)) {
    throw "BUILDER_TELEGRAM_CHAT_ID is required before activating Stage 7 builder alerts."
  }
  if ($builderChatId -eq $managerChatId) {
    throw "BUILDER_TELEGRAM_CHAT_ID must be separate from MANAGER_TELEGRAM_CHAT_ID so infrastructure errors do not appear in the demo manager/prospect chat."
  }

  $fixtureChatIds = @($riveraChatId, $mariasChatId, $daleChatId, $statewideChatId)
  if ($fixtureChatIds | Where-Object { [string]::IsNullOrWhiteSpace($_) }) {
    throw "RIVERA_TELEGRAM_CHAT_ID, MARIAS_TELEGRAM_CHAT_ID, DALE_TELEGRAM_CHAT_ID, and STATEWIDE_TELEGRAM_CHAT_ID are required for Stage 7 live fixture coverage. VENDOR_TELEGRAM_CHAT_ID can be used as Rivera's fallback."
  }
  $distinctFixtureChatIds = @($fixtureChatIds | Select-Object -Unique)
  if ($distinctFixtureChatIds.Count -ne $fixtureChatIds.Count) {
    throw "Stage 7 vendor Telegram chat IDs must be distinct because vendor.telegram_chat_id is unique and live fixtures need separate vendor identities."
  }
  if ($webhookUrl -notmatch "^https://") {
    throw "WEBHOOK_URL in .env must be the active HTTPS tunnel URL before activating Telegram Trigger workflows."
  }
  if ($containerWebhookUrl -notmatch "^https://") {
    throw "The n8n container WEBHOOK_URL is not HTTPS. Recreate n8n after editing .env: docker compose up -d --force-recreate n8n"
  }
}

docker compose config | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "docker compose config failed."
}

Get-ChildItem -LiteralPath (Join-Path $repoRoot "db\postgres\migrations") -Filter "*.sql" | Sort-Object Name | ForEach-Object {
  docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -f "/docker-entrypoint-initdb.d/migrations/$($_.Name)" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Migration failed: $($_.Name)"
  }
}

node (Join-Path $scriptDir "generate-stage-7-workflows.js")
if ($LASTEXITCODE -ne 0) {
  throw "Stage 7 workflow generation failed."
}

$importNames = @(
  "wf-3-sequence-guard.json",
  "wf-3-stage-complete-core.json",
  "wf-3-board-api.json",
  "wf-3-stage-complete-api.json",
  "wf-3-daily-digest.json",
  "wf-3-manager-router.json",
  "wf-4-turn-intake.json",
  "wf-4-unit-matcher.json",
  "wf-4-vendor-router.json",
  "wf-4-vendor-in-api.json",
  "wf-4-vendor-telegram-ingest.json",
  "wf-5-vendor-completion-handler.json",
  "wf-5-manager-action-core.json",
  "wf-5-manager-action-api.json",
  "wf-6-health-core.json",
  "wf-6-health-api.json",
  "wf-6-stall-watchdog.json",
  "wf-6-weekly-digest.json",
  "wf-7-error-handler.json",
  "wf-7-error-smoke.json"
)

foreach ($name in $importNames) {
  Get-Content -Raw -LiteralPath (Join-Path $workflowDir $name) | ConvertFrom-Json | Out-Null
}

New-Item -ItemType Directory -Force -Path $tmpImportDir | Out-Null
Get-ChildItem -LiteralPath $tmpImportDir -Force | Remove-Item -Recurse -Force

foreach ($name in $importNames) {
  $workflow = Get-Content -Raw -LiteralPath (Join-Path $workflowDir $name) | ConvertFrom-Json
  $workflow.active = $false
  if ($workflow.id -in @("wf3-board-api", "wf3-stage-complete-api", "wf4-vendor-in-api", "wf5-manager-action-api", "wf6-health-api", "wf6-stall-watchdog", "wf7-error-handler", "wf7-error-smoke")) {
    $workflow.active = $true
  }
  if ($workflow.id -in @("wf3-manager-router", "wf4-vendor-telegram-ingest", "wf3-daily-digest", "wf6-weekly-digest")) {
    $workflow.active = [bool]$ActivateTelegram
  }

  $json = $workflow | ConvertTo-Json -Depth 100
  $json = $json.Replace("local-stage-3-demo-token", $boardToken)
  $json = $json.Replace("local-stage-4-vendor-in-token", $vendorInToken)
  $json = $json.Replace("http://localhost:8080", $boardOrigin)
  $json = $json.Replace("gpt-5.6-luna", $classifyModel)
  if ($ActivateTelegram) {
    $json = $json.Replace("stage3-manager-chat-id-missing", $managerChatId)
    $json = $json.Replace("stage5-manager-chat-id-missing", $managerChatId)
    $json = $json.Replace("stage7-builder-chat-id-missing", $builderChatId)
  }

  $target = Join-Path $tmpImportDir $name
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($target, $json, $utf8NoBom)
}

docker exec make-ready-n8n n8n import:workflow --separate --input=$containerImportDir
if ($LASTEXITCODE -ne 0) {
  throw "Stage 7 workflow import failed."
}

docker exec make-ready-n8n n8n publish:workflow --id=wf7-error-handler | Out-Host
if ($LASTEXITCODE -ne 0) {
  throw "Could not publish wf7-error-handler."
}

$publishedWorkflowIds = @(
  "wf3-sequence-guard",
  "wf3-stage-complete-core",
  "wf3-board-api",
  "wf3-stage-complete-api",
  "wf4-turn-intake",
  "wf4-unit-matcher",
  "wf4-vendor-router",
  "wf4-vendor-in-api",
  "wf5-vendor-completion-handler",
  "wf5-manager-action-core",
  "wf5-manager-action-api",
  "wf6-health-core",
  "wf6-health-api",
  "wf6-stall-watchdog",
  "wf7-error-smoke"
)

if ($ActivateTelegram) {
  $publishedWorkflowIds += "wf3-manager-router"
  $publishedWorkflowIds += "wf4-vendor-telegram-ingest"
  $publishedWorkflowIds += "wf3-daily-digest"
  $publishedWorkflowIds += "wf6-weekly-digest"
} else {
  docker exec make-ready-n8n n8n unpublish:workflow --id=wf3-manager-router | Out-Host
  docker exec make-ready-n8n n8n unpublish:workflow --id=wf4-vendor-telegram-ingest | Out-Host
  docker exec make-ready-n8n n8n unpublish:workflow --id=wf3-daily-digest | Out-Host
  docker exec make-ready-n8n n8n unpublish:workflow --id=wf6-weekly-digest | Out-Host
}

foreach ($workflowId in $publishedWorkflowIds) {
  docker exec make-ready-n8n n8n publish:workflow --id=$workflowId | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw "Could not publish workflow $workflowId."
  }
}

if ($ActivateTelegram) {
  $updates = @(
    @{ Name = "Rivera Painting"; Trade = "paint"; ChatId = $riveraChatId },
    @{ Name = "Maria's Cleaning Co"; Trade = "clean"; ChatId = $mariasChatId },
    @{ Name = "Dale Hutchins"; Trade = "repairs"; ChatId = $daleChatId },
    @{ Name = "Statewide Flooring"; Trade = "flooring"; ChatId = $statewideChatId }
  )
  foreach ($update in $updates) {
    $sql = "UPDATE vendor SET telegram_chat_id = $(ConvertTo-SqlLiteral $update.ChatId) WHERE name = $(ConvertTo-SqlLiteral $update.Name) AND trade = $(ConvertTo-SqlLiteral $update.Trade) AND is_fixture = true;"
    docker exec make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -c $sql | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Could not update fixture Telegram sender mapping for $($update.Name)."
    }
  }
}

if (-not $NoRestart) {
  docker compose restart n8n | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw "n8n restart failed after workflow import."
  }
}

$linkedCount = [int](Invoke-N8nPsqlScalar "SELECT count(*) FROM workflow_entity WHERE id <> 'wf7-error-handler' AND id LIKE 'wf%' AND settings->>'errorWorkflow' = 'wf7-error-handler';")
if ($linkedCount -lt 19) {
  throw "Expected Stage 3-7 workflows to link wf7-error-handler; found only $linkedCount linked workflow(s)."
}

docker exec make-ready-n8n n8n list:workflow
Write-Host "Stage 7 workflows imported. Telegram workflows active: $([bool]$ActivateTelegram). Classification model: $classifyModel."
