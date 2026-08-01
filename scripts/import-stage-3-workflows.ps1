[CmdletBinding()]
param(
  [switch]$ActivateTelegram,
  [switch]$NoRestart
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$workflowDir = Join-Path $repoRoot "n8n-workflows"
$tmpImportDir = Join-Path $repoRoot "data\tmp-stage-3-workflow-import"
$containerImportDir = "/data/tmp-stage-3-workflow-import"

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

$boardToken = Get-EnvFileValue "BOARD_DEMO_TOKEN"
$boardOrigin = Get-EnvFileValue "BOARD_ALLOWED_ORIGIN"
$managerChatId = Get-EnvFileValue "MANAGER_TELEGRAM_CHAT_ID"
$timezone = Get-EnvFileValue "GENERIC_TIMEZONE"

node (Join-Path $scriptDir "generate-stage-3-workflows.js")
if ($LASTEXITCODE -ne 0) {
  throw "Workflow generation failed."
}

Get-ChildItem -LiteralPath $workflowDir -Filter "wf-3-*.json" | ForEach-Object {
  Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json | Out-Null
}

if ($ActivateTelegram) {
  $webhookUrl = Get-EnvFileValue "WEBHOOK_URL"

  if ([string]::IsNullOrWhiteSpace($managerChatId)) {
    throw "MANAGER_TELEGRAM_CHAT_ID is required before activating Stage 3 Telegram workflows."
  }

  if ($webhookUrl -notmatch "^https://") {
    throw "WEBHOOK_URL must be the active HTTPS tunnel URL before activating the Telegram Trigger workflow."
  }
}

if ([string]::IsNullOrWhiteSpace($boardToken)) {
  $boardToken = "local-stage-3-demo-token"
}
if ([string]::IsNullOrWhiteSpace($boardOrigin)) {
  $boardOrigin = "http://localhost:8080"
}
if ([string]::IsNullOrWhiteSpace($timezone)) {
  $timezone = "America/Phoenix"
}

New-Item -ItemType Directory -Force -Path $tmpImportDir | Out-Null
Get-ChildItem -LiteralPath $tmpImportDir -Force | Remove-Item -Recurse -Force

Get-ChildItem -LiteralPath $workflowDir -Filter "wf-3-*.json" | ForEach-Object {
  $workflow = Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json
  if ($workflow.id -in @("wf3-daily-digest", "wf3-manager-router")) {
    $workflow.active = [bool]$ActivateTelegram
  }
  $target = Join-Path $tmpImportDir $_.Name
  $json = $workflow | ConvertTo-Json -Depth 100
  $json = $json.Replace("local-stage-3-demo-token", $boardToken)
  $json = $json.Replace("http://localhost:8080", $boardOrigin)
  $json = $json.Replace("America/Phoenix", $timezone)
  if (-not [string]::IsNullOrWhiteSpace($managerChatId)) {
    $json = $json.Replace("stage3-manager-chat-id-missing", $managerChatId)
  }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($target, $json, $utf8NoBom)
}

docker exec make-ready-n8n n8n import:workflow --separate --input=$containerImportDir
if ($LASTEXITCODE -ne 0) {
  throw "Stage 3 workflow import failed."
}

$publishedWorkflowIds = @(
  "wf3-board-api",
  "wf3-stage-complete-api",
  "wf3-sequence-guard",
  "wf3-stage-complete-core"
)

if ($ActivateTelegram) {
  $publishedWorkflowIds += @("wf3-daily-digest", "wf3-manager-router")
} else {
  foreach ($workflowId in @("wf3-daily-digest", "wf3-manager-router")) {
    docker exec make-ready-n8n n8n unpublish:workflow --id=$workflowId | Out-Host
  }
}

foreach ($workflowId in $publishedWorkflowIds) {
  docker exec make-ready-n8n n8n publish:workflow --id=$workflowId | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw "Could not publish workflow $workflowId."
  }
}

if (-not $NoRestart) {
  docker compose restart n8n | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw "n8n restart failed after workflow import."
  }
}

docker exec make-ready-n8n n8n list:workflow
Write-Host "Stage 3 workflows imported. Telegram workflows active: $([bool]$ActivateTelegram)."
