[CmdletBinding()]
param(
  [switch]$ActivateTelegram,
  [switch]$NoRestart
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$workflowDir = Join-Path $repoRoot "n8n-workflows"
$tmpImportDir = Join-Path $repoRoot "data\tmp-stage-5-workflow-import"
$containerImportDir = "/data/tmp-stage-5-workflow-import"

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

$boardToken = Get-EnvFileValue "BOARD_DEMO_TOKEN"
$vendorInToken = Get-EnvFileValue "VENDOR_IN_DEMO_TOKEN"
$boardOrigin = Get-EnvFileValue "BOARD_ALLOWED_ORIGIN"
$managerChatId = Get-EnvFileValue "MANAGER_TELEGRAM_CHAT_ID"
$vendorChatId = Get-EnvFileValue "VENDOR_TELEGRAM_CHAT_ID"
$classifyModel = Get-EnvFileValue "OPENAI_MODEL_CLASSIFY"
$draftModel = Get-EnvFileValue "OPENAI_MODEL_DRAFT"

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
if ([string]::IsNullOrWhiteSpace($draftModel)) {
  $draftModel = "gpt-5.6-luna"
}

if ($ActivateTelegram) {
  $webhookUrl = Get-EnvFileValue "WEBHOOK_URL"
  $containerWebhookUrl = docker exec make-ready-n8n printenv WEBHOOK_URL
  if ($LASTEXITCODE -ne 0) {
    throw "Could not read WEBHOOK_URL from the n8n container."
  }
  $containerWebhookUrl = ($containerWebhookUrl | Select-Object -First 1).Trim()

  if ([string]::IsNullOrWhiteSpace($managerChatId)) {
    throw "MANAGER_TELEGRAM_CHAT_ID is required before activating manager Telegram workflows."
  }
  if ([string]::IsNullOrWhiteSpace($vendorChatId)) {
    throw "VENDOR_TELEGRAM_CHAT_ID is required before activating vendor Telegram workflows."
  }
  if ($webhookUrl -notmatch "^https://") {
    throw "WEBHOOK_URL in .env must be the active HTTPS tunnel URL before activating Telegram Trigger workflows."
  }
  if ($containerWebhookUrl -notmatch "^https://") {
    throw "The n8n container WEBHOOK_URL is not HTTPS. Recreate n8n after editing .env: docker compose up -d --force-recreate n8n"
  }
}

node (Join-Path $scriptDir "generate-stage-3-workflows.js")
if ($LASTEXITCODE -ne 0) {
  throw "Stage 3 workflow generation failed."
}
node (Join-Path $scriptDir "generate-stage-4-workflows.js")
if ($LASTEXITCODE -ne 0) {
  throw "Stage 4 workflow generation failed."
}
node (Join-Path $scriptDir "generate-stage-5-workflows.js")
if ($LASTEXITCODE -ne 0) {
  throw "Stage 5 workflow generation failed."
}

$importNames = @(
  "wf-3-sequence-guard.json",
  "wf-3-stage-complete-core.json",
  "wf-3-board-api.json",
  "wf-3-stage-complete-api.json",
  "wf-3-manager-router.json",
  "wf-4-turn-intake.json",
  "wf-4-unit-matcher.json",
  "wf-4-vendor-router.json",
  "wf-4-vendor-in-api.json",
  "wf-4-vendor-telegram-ingest.json",
  "wf-5-vendor-completion-handler.json",
  "wf-5-manager-action-core.json",
  "wf-5-manager-action-api.json"
)

foreach ($name in $importNames) {
  Get-Content -Raw -LiteralPath (Join-Path $workflowDir $name) | ConvertFrom-Json | Out-Null
}

New-Item -ItemType Directory -Force -Path $tmpImportDir | Out-Null
Get-ChildItem -LiteralPath $tmpImportDir -Force | Remove-Item -Recurse -Force

foreach ($name in $importNames) {
  $workflow = Get-Content -Raw -LiteralPath (Join-Path $workflowDir $name) | ConvertFrom-Json
  $workflow.active = $false
  if ($workflow.id -in @("wf3-board-api", "wf3-stage-complete-api", "wf4-vendor-in-api", "wf5-manager-action-api")) {
    $workflow.active = $true
  }
  if ($workflow.id -in @("wf3-manager-router", "wf4-vendor-telegram-ingest")) {
    $workflow.active = [bool]$ActivateTelegram
  }

  $json = $workflow | ConvertTo-Json -Depth 100
  $json = $json.Replace("local-stage-3-demo-token", $boardToken)
  $json = $json.Replace("local-stage-4-vendor-in-token", $vendorInToken)
  $json = $json.Replace("http://localhost:8080", $boardOrigin)
  $json = $json.Replace("gpt-5.6-luna", $classifyModel)
  if (-not [string]::IsNullOrWhiteSpace($managerChatId)) {
    $json = $json.Replace("stage3-manager-chat-id-missing", $managerChatId)
    $json = $json.Replace("stage5-manager-chat-id-missing", $managerChatId)
  }

  $target = Join-Path $tmpImportDir $name
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($target, $json, $utf8NoBom)
}

docker exec make-ready-n8n n8n import:workflow --separate --input=$containerImportDir
if ($LASTEXITCODE -ne 0) {
  throw "Stage 5 workflow import failed."
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
  "wf5-manager-action-api"
)

if ($ActivateTelegram) {
  $publishedWorkflowIds += "wf3-manager-router"
  $publishedWorkflowIds += "wf4-vendor-telegram-ingest"
} else {
  docker exec make-ready-n8n n8n unpublish:workflow --id=wf3-manager-router | Out-Host
  docker exec make-ready-n8n n8n unpublish:workflow --id=wf4-vendor-telegram-ingest | Out-Host
}

foreach ($workflowId in $publishedWorkflowIds) {
  docker exec make-ready-n8n n8n publish:workflow --id=$workflowId | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw "Could not publish workflow $workflowId."
  }
}

if ($ActivateTelegram) {
  $sql = "UPDATE vendor SET telegram_chat_id = $(ConvertTo-SqlLiteral $vendorChatId) WHERE name = 'Rivera Painting' AND trade = 'paint' AND is_fixture = true;"
  docker exec make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -c $sql | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Could not update the local fixture vendor Telegram sender mapping."
  }
}

if (-not $NoRestart) {
  docker compose restart n8n | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw "n8n restart failed after workflow import."
  }
}

docker exec make-ready-n8n n8n list:workflow
Write-Host "Stage 5 workflows imported. Telegram workflows active: $([bool]$ActivateTelegram)."
