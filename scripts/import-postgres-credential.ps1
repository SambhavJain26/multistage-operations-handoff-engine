[CmdletBinding()]
param(
  [string]$CredentialName = "Make-Ready Postgres",
  [string]$CredentialId = "cred_make_ready_pg",
  [string]$EnvPath = ".env"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $EnvPath)) {
  throw "Missing $EnvPath. Copy .env.example to .env and set local Postgres values first."
}

$envMap = @{}
Get-Content -LiteralPath $EnvPath | Where-Object { $_ -match '^[A-Za-z_][A-Za-z0-9_]*=' } | ForEach-Object {
  $idx = $_.IndexOf("=")
  $envMap[$_.Substring(0, $idx)] = $_.Substring($idx + 1)
}

foreach ($required in @("MAKE_READY_DB", "MAKE_READY_DB_USER", "MAKE_READY_DB_PASSWORD")) {
  if ([string]::IsNullOrWhiteSpace($envMap[$required])) {
    throw "Missing $required in $EnvPath."
  }
}

$existingRaw = docker exec make-ready-n8n n8n export:credentials --all
if ($LASTEXITCODE -ne 0) {
  throw "Could not export n8n credentials to check existing credential list."
}

$existing = @($existingRaw | ConvertFrom-Json)
if ($existing | Where-Object { $_.id -eq $CredentialId -or $_.name -eq $CredentialName }) {
  Write-Host "Postgres credential already exists: $CredentialName"
  exit 0
}

$credential = @(
  [ordered]@{
    id = $CredentialId
    name = $CredentialName
    type = "postgres"
    data = [ordered]@{
      host = "postgres"
      database = $envMap["MAKE_READY_DB"]
      user = $envMap["MAKE_READY_DB_USER"]
      password = $envMap["MAKE_READY_DB_PASSWORD"]
      port = 5432
      ssl = "disable"
      maxConnections = 100
      allowUnauthorizedCerts = $false
    }
  }
)

$credential | ConvertTo-Json -Depth 8 | docker exec -i make-ready-n8n n8n import:credentials --input=/dev/stdin
if ($LASTEXITCODE -ne 0) {
  throw "n8n credential import failed."
}

Write-Host "Imported Postgres credential: $CredentialName"
