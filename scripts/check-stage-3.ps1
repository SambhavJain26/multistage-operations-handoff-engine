[CmdletBinding()]
param(
  [switch]$SkipReset,
  [string]$BoardUrl = "http://localhost:5678/webhook/board",
  [string]$CompleteUrl = "http://localhost:5678/webhook/stage/complete",
  [string]$Token
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

if (-not $Token) {
  $Token = Get-EnvFileValue "BOARD_DEMO_TOKEN" "local-stage-3-demo-token"
}

if (-not $SkipReset) {
  & (Join-Path $scriptDir "reset-demo.ps1")
}

Get-ChildItem -LiteralPath (Join-Path $repoRoot "n8n-workflows") -Filter "wf-3-*.json" | ForEach-Object {
  Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json | Out-Null
}

try {
  Invoke-WebRequest -Uri $BoardUrl -Method Get -TimeoutSec 30 | Out-Null
  throw "Unauthorized board request unexpectedly succeeded."
} catch {
  if (-not $_.Exception.Response -or [int]$_.Exception.Response.StatusCode -ne 401) {
    throw
  }
}

$board = Invoke-RestMethod -Uri "${BoardUrl}?token=$([uri]::EscapeDataString($Token))" -Method Get -TimeoutSec 30
if ($board.metrics.active_turns -ne 6) {
  throw "Expected 6 active turns from board API, found $($board.metrics.active_turns)."
}

if ($board.turns[0].unit_label -ne "12B" -or $board.turns[0].health -ne "red") {
  throw "Expected 12B red stalled card first, found $($board.turns[0].unit_label) / $($board.turns[0].health)."
}

$deepClean14A = Invoke-AppPsqlScalar "SELECT ts.id FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '14A' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'DEEP_CLEAN';"
$paint12B = Invoke-AppPsqlScalar "SELECT ts.id FROM turn_stage ts JOIN ""turn"" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND t.is_fixture = true AND ts.stage_code = 'PAINT';"

$blockedRaw = & curl.exe -s -X POST "${CompleteUrl}?token=$([uri]::EscapeDataString($Token))" `
  -d "stage_id=$deepClean14A" `
  -d "actor_id=stage-3-check" `
  -d "channel=board" `
  -w "`n%{http_code}" `
  --max-time 30
if ($LASTEXITCODE -ne 0) {
  throw "curl failed while checking 14A Deep Clean guard."
}
$blockedParts = @($blockedRaw -split "`n")
$blockedStatus = [int]$blockedParts[-1]
$blockedBody = ($blockedParts[0..($blockedParts.Count - 2)] -join "`n")
if ($blockedStatus -ne 409) {
  throw "Expected 14A Deep Clean to return 409, found $blockedStatus with body: $blockedBody"
}
$blocked = $blockedBody | ConvertFrom-Json
if (-not ($blocked.reason -like "*Repairs still open*")) {
  throw "Expected repairs guard reason, found: $($blocked.reason)"
}

$completion = Invoke-RestMethod -Uri "${CompleteUrl}?token=$([uri]::EscapeDataString($Token))" -Method Post -Body @{
  stage_id = $paint12B
  actor_id = "stage-3-check"
  channel = "board"
} -TimeoutSec 30

if (-not $completion.allowed -or $completion.completed_via -ne "manual") {
  throw "12B Paint completion did not return an allowed manual result."
}

docker exec make-ready-postgres psql -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/verify-stage-3.sql
if ($LASTEXITCODE -ne 0) {
  throw "Stage 3 database verification failed."
}

$boardAfter = Invoke-RestMethod -Uri "${BoardUrl}?token=$([uri]::EscapeDataString($Token))" -Method Get -TimeoutSec 30
$unit12B = $boardAfter.turns | Where-Object { $_.unit_label -eq "12B" } | Select-Object -First 1
if ($unit12B.current_stage.stage_code -ne "FLOORING") {
  throw "Expected 12B current stage FLOORING after Paint, found $($unit12B.current_stage.stage_code)."
}

Write-Host "Stage 3 verification passed."
Write-Host "Note: Telegram digest callback verification requires MANAGER_TELEGRAM_CHAT_ID plus an active HTTPS WEBHOOK_URL, then .\scripts\import-stage-3-workflows.ps1 -ActivateTelegram."
