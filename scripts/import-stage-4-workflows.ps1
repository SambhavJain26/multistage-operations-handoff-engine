[CmdletBinding()]
param(
  [switch]$ActivateTelegram,
  [switch]$NoRestart
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$workflowDir = Join-Path $repoRoot "n8n-workflows"
$tmpImportDir = Join-Path $repoRoot "data\tmp-stage-4-workflow-import"
$containerImportDir = "/data/tmp-stage-4-workflow-import"

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

$vendorInToken = Get-EnvFileValue "VENDOR_IN_DEMO_TOKEN"
$boardOrigin = Get-EnvFileValue "BOARD_ALLOWED_ORIGIN"
$managerChatId = Get-EnvFileValue "MANAGER_TELEGRAM_CHAT_ID"
$vendorChatId = Get-EnvFileValue "VENDOR_TELEGRAM_CHAT_ID"

node (Join-Path $scriptDir "generate-stage-4-workflows.js")
if ($LASTEXITCODE -ne 0) {
  throw "Workflow generation failed."
}

Get-ChildItem -LiteralPath $workflowDir -Filter "wf-4-*.json" | ForEach-Object {
  Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json | Out-Null
}

if ([string]::IsNullOrWhiteSpace($vendorInToken)) {
  $vendorInToken = "local-stage-4-vendor-in-token"
}
if ([string]::IsNullOrWhiteSpace($boardOrigin)) {
  $boardOrigin = "http://localhost:8080"
}

if ($ActivateTelegram) {
  $webhookUrl = Get-EnvFileValue "WEBHOOK_URL"
  $containerWebhookUrl = docker exec make-ready-n8n printenv WEBHOOK_URL
  if ($LASTEXITCODE -ne 0) {
    throw "Could not read WEBHOOK_URL from the n8n container."
  }
  $containerWebhookUrl = ($containerWebhookUrl | Select-Object -First 1).Trim()

  if ([string]::IsNullOrWhiteSpace($vendorChatId)) {
    throw "VENDOR_TELEGRAM_CHAT_ID is required before activating the Stage 4 Vendor Telegram Trigger."
  }
  if ($webhookUrl -notmatch "^https://") {
    throw "WEBHOOK_URL in .env must be the active HTTPS tunnel URL before activating the Telegram Trigger workflow."
  }
  if ($containerWebhookUrl -notmatch "^https://") {
    throw "The n8n container WEBHOOK_URL is not HTTPS. Recreate n8n after editing .env: docker compose up -d --force-recreate n8n"
  }
}

New-Item -ItemType Directory -Force -Path $tmpImportDir | Out-Null
Get-ChildItem -LiteralPath $tmpImportDir -Force | Remove-Item -Recurse -Force

Get-ChildItem -LiteralPath $workflowDir -Filter "wf-4-*.json" | ForEach-Object {
  $workflow = Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json
  $workflow.active = $workflow.id -ne "wf4-vendor-telegram-ingest"
  if ($workflow.id -eq "wf4-vendor-telegram-ingest") {
    $workflow.active = [bool]$ActivateTelegram
  }

  $target = Join-Path $tmpImportDir $_.Name
  $json = $workflow | ConvertTo-Json -Depth 100
  $json = $json.Replace("local-stage-4-vendor-in-token", $vendorInToken)
  $json = $json.Replace("http://localhost:8080", $boardOrigin)
  if (-not [string]::IsNullOrWhiteSpace($managerChatId)) {
    $json = $json.Replace("stage4-manager-chat-id-missing", $managerChatId)
  }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($target, $json, $utf8NoBom)
}

docker exec make-ready-n8n n8n import:workflow --separate --input=$containerImportDir
if ($LASTEXITCODE -ne 0) {
  throw "Stage 4 workflow import failed."
}

$publishedWorkflowIds = @(
  "wf4-turn-intake",
  "wf4-unit-matcher",
  "wf4-vendor-router",
  "wf4-vendor-in-api"
)

if ($ActivateTelegram) {
  $publishedWorkflowIds += "wf4-vendor-telegram-ingest"
} else {
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
Write-Host "Stage 4 workflows imported. Vendor Telegram workflow active: $([bool]$ActivateTelegram)."
