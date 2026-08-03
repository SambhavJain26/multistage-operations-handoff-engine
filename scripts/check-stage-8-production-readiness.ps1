[CmdletBinding()]
param(
  [string]$EnvFile = ".env.production",
  [string]$ComposeFile = "docker-compose.production.yml",
  [string]$Caddyfile = "Caddyfile.production",
  [switch]$SkipComposeConfig
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$envPath = Join-Path $repoRoot $EnvFile
$composePath = Join-Path $repoRoot $ComposeFile
$caddyPath = Join-Path $repoRoot $Caddyfile

function Fail {
  param([string]$Message)
  throw "Stage 8 production readiness check failed: $Message"
}

function Load-EnvFile {
  param([string]$Path)
  $map = @{}
  Get-Content -LiteralPath $Path | ForEach-Object {
    if ($_ -match "^\s*#" -or $_ -match "^\s*$") { return }
    if ($_ -notmatch "^\s*([^=]+?)\s*=\s*(.*)\s*$") { return }
    $name = $matches[1].Trim()
    $value = $matches[2].Trim().Trim('"').Trim("'")
    $map[$name] = $value
  }
  return $map
}

function Require-Key {
  param([hashtable]$Env, [string]$Name)
  if (-not $Env.ContainsKey($Name) -or [string]::IsNullOrWhiteSpace($Env[$Name])) {
    Fail "$Name is required in $EnvFile."
  }
}

function Assert-NotPlaceholder {
  param([string]$Name, [string]$Value)
  $badPatterns = @(
    "change-me",
    "replace-",
    "client.example.com",
    "example.com",
    "localhost",
    "trycloudflare.com",
    "local-stage-"
  )
  foreach ($pattern in $badPatterns) {
    if ($Value -like "*$pattern*") {
      Fail "$Name still contains a demo/default/placeholder value."
    }
  }
}

function Assert-MinLength {
  param([string]$Name, [string]$Value, [int]$Length)
  if ($Value.Length -lt $Length) {
    Fail "$Name must be at least $Length characters."
  }
}

if (-not (Test-Path -LiteralPath $envPath)) { Fail "Env file not found: $EnvFile." }
if (-not (Test-Path -LiteralPath $composePath)) { Fail "Compose file not found: $ComposeFile." }
if (-not (Test-Path -LiteralPath $caddyPath)) { Fail "Caddyfile not found: $Caddyfile." }

$envMap = Load-EnvFile $envPath

$requiredKeys = @(
  "CLIENT_DOMAIN",
  "N8N_HOST",
  "BOARD_HOST",
  "WEBHOOK_URL",
  "BOARD_ALLOWED_ORIGIN",
  "CADDY_ACME_EMAIL",
  "GENERIC_TIMEZONE",
  "RETENTION_MESSAGE_DAYS",
  "RETENTION_PHOTO_DAYS",
  "BACKUP_RETENTION_DAYS",
  "BACKUP_TARGET",
  "PRODUCTION_ALERT_EMAIL",
  "N8N_BASIC_AUTH_USER",
  "N8N_BASIC_AUTH_PASSWORD",
  "N8N_ENCRYPTION_KEY",
  "BOARD_AUTH_USER",
  "BOARD_AUTH_PASSWORD_HASH",
  "POSTGRES_PASSWORD",
  "N8N_DB_PASSWORD",
  "MAKE_READY_DB",
  "MAKE_READY_DB_USER",
  "MAKE_READY_DB_PASSWORD",
  "BOARD_DEMO_TOKEN",
  "VENDOR_IN_DEMO_TOKEN",
  "SMS_ENABLED"
)

foreach ($key in $requiredKeys) { Require-Key $envMap $key }

foreach ($name in @(
  "CLIENT_DOMAIN",
  "N8N_HOST",
  "BOARD_HOST",
  "WEBHOOK_URL",
  "BOARD_ALLOWED_ORIGIN",
  "CADDY_ACME_EMAIL",
  "BACKUP_TARGET",
  "PRODUCTION_ALERT_EMAIL",
  "N8N_BASIC_AUTH_USER",
  "N8N_BASIC_AUTH_PASSWORD",
  "N8N_ENCRYPTION_KEY",
  "BOARD_AUTH_USER",
  "BOARD_AUTH_PASSWORD_HASH",
  "POSTGRES_PASSWORD",
  "N8N_DB_PASSWORD",
  "MAKE_READY_DB_PASSWORD",
  "BOARD_DEMO_TOKEN",
  "VENDOR_IN_DEMO_TOKEN"
)) {
  Assert-NotPlaceholder $name $envMap[$name]
}

if ($envMap["WEBHOOK_URL"] -notmatch "^https://") { Fail "WEBHOOK_URL must be https." }
if ($envMap["WEBHOOK_URL"].TrimEnd("/") -ne "https://$($envMap["N8N_HOST"])") {
  Fail "WEBHOOK_URL must equal https://N8N_HOST."
}
if ($envMap["BOARD_ALLOWED_ORIGIN"].TrimEnd("/") -ne "https://$($envMap["BOARD_HOST"])") {
  Fail "BOARD_ALLOWED_ORIGIN must equal https://BOARD_HOST."
}
if ($envMap["N8N_HOST"] -ne "n8n.$($envMap["CLIENT_DOMAIN"])") {
  Fail "N8N_HOST must be n8n.CLIENT_DOMAIN."
}
if ($envMap["BOARD_HOST"] -ne "board.$($envMap["CLIENT_DOMAIN"])") {
  Fail "BOARD_HOST must be board.CLIENT_DOMAIN."
}
if ($envMap["SMS_ENABLED"].ToLowerInvariant() -ne "false") {
  Fail "SMS_ENABLED must remain false for the Stage 8 readiness pack."
}
if ($envMap["N8N_BASIC_AUTH_USER"].ToLowerInvariant() -eq "admin") {
  Fail "N8N_BASIC_AUTH_USER must not be the default admin user."
}

Assert-MinLength "N8N_BASIC_AUTH_PASSWORD" $envMap["N8N_BASIC_AUTH_PASSWORD"] 16
Assert-MinLength "N8N_ENCRYPTION_KEY" $envMap["N8N_ENCRYPTION_KEY"] 64
Assert-MinLength "POSTGRES_PASSWORD" $envMap["POSTGRES_PASSWORD"] 16
Assert-MinLength "N8N_DB_PASSWORD" $envMap["N8N_DB_PASSWORD"] 16
Assert-MinLength "MAKE_READY_DB_PASSWORD" $envMap["MAKE_READY_DB_PASSWORD"] 16
Assert-MinLength "BOARD_DEMO_TOKEN" $envMap["BOARD_DEMO_TOKEN"] 32
Assert-MinLength "VENDOR_IN_DEMO_TOKEN" $envMap["VENDOR_IN_DEMO_TOKEN"] 32

$messageRetention = [int]$envMap["RETENTION_MESSAGE_DAYS"]
$photoRetention = [int]$envMap["RETENTION_PHOTO_DAYS"]
$backupRetention = [int]$envMap["BACKUP_RETENTION_DAYS"]
if ($messageRetention -lt 30 -or $messageRetention -gt 365) { Fail "RETENTION_MESSAGE_DAYS must be between 30 and 365." }
if ($photoRetention -lt 30 -or $photoRetention -gt 365) { Fail "RETENTION_PHOTO_DAYS must be between 30 and 365." }
if ($backupRetention -lt 30) { Fail "BACKUP_RETENTION_DAYS must be at least 30." }

$composeRaw = Get-Content -Raw -LiteralPath $composePath
$images = [regex]::Matches($composeRaw, "(?m)^\s*image:\s*([^\s#]+)") | ForEach-Object { $_.Groups[1].Value }
if (@($images).Count -lt 3) { Fail "Production compose should define pinned caddy, postgres, and n8n images." }
foreach ($image in $images) {
  $lastSegment = ($image -split "/")[-1]
  if ($lastSegment -notmatch ":" -or $lastSegment -match ":latest$") {
    Fail "Image is not pinned to an explicit non-latest tag: $image"
  }
}
if ($composeRaw -match "127\.0\.0\.1:5678|localhost:5678|trycloudflare\.com") {
  Fail "Production compose contains local/tunnel URL values."
}

$caddyRaw = Get-Content -Raw -LiteralPath $caddyPath
foreach ($needle in @('{$N8N_HOST}', '{$BOARD_HOST}', 'reverse_proxy n8n:5678', 'basicauth', 'file_server')) {
  if ($caddyRaw -notlike "*$needle*") { Fail "Caddyfile missing expected production directive: $needle" }
}

$workflowCount = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot "n8n-workflows") -Filter "*.json").Count
if ($workflowCount -lt 20) { Fail "Expected at least the Stage 3-7 workflow exports before production readiness." }

if (-not $SkipComposeConfig) {
  docker compose --env-file $envPath -f $composePath config | Out-Null
  if ($LASTEXITCODE -ne 0) { Fail "docker compose config failed for production template." }
}

Write-Host "Stage 8 production readiness checks passed for $EnvFile."
