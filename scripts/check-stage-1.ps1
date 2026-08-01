[CmdletBinding()]
param(
  [string]$N8nUrl = "http://localhost:5678",
  [string]$PostgresHost = "127.0.0.1",
  [int]$PostgresPort = 5432,
  [string]$BoardUrl = "http://localhost:8080"
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]

function Write-Check {
  param(
    [string]$Name,
    [bool]$Passed,
    [string]$Detail = ""
  )

  $status = if ($Passed) { "OK" } else { "FAIL" }
  $line = "[$status] $Name"
  if ($Detail) {
    $line = "$line - $Detail"
  }
  Write-Host $line
  if (-not $Passed) {
    $script:failures.Add($Name) | Out-Null
  }
}

function Write-Info {
  param(
    [string]$Name,
    [string]$Detail
  )

  Write-Host "[INFO] $Name - $Detail"
}

function Test-HttpWithRetry {
  param(
    [string]$Uri,
    [int[]]$AcceptedStatusCodes = @(200),
    [int]$Attempts = 6,
    [int]$DelaySeconds = 2
  )

  $lastError = $null
  for ($i = 1; $i -le $Attempts; $i++) {
    try {
      $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 5
      if ($AcceptedStatusCodes -contains [int]$response.StatusCode) {
        return @{
          Passed = $true
          Detail = "status $($response.StatusCode)"
        }
      }
      $lastError = "status $($response.StatusCode)"
    } catch {
      $lastError = $_.Exception.Message
    }

    if ($i -lt $Attempts) {
      Start-Sleep -Seconds $DelaySeconds
    }
  }

  return @{
    Passed = $false
    Detail = $lastError
  }
}

try {
  $composeVersion = docker compose version 2>$null
  Write-Check "Docker Compose" ($LASTEXITCODE -eq 0) $composeVersion
} catch {
  Write-Check "Docker Compose" $false $_.Exception.Message
}

try {
  $containers = docker compose ps --format json 2>$null
  Write-Check "Docker Compose services" ($LASTEXITCODE -eq 0) "compose ps returned"
  if ($containers) {
    $containers -split "`n" | Where-Object { $_.Trim() } | ForEach-Object {
      $row = $_ | ConvertFrom-Json
      Write-Host ("  {0}: {1}" -f $row.Service, $row.State)
    }
  }
} catch {
  Write-Check "Docker Compose services" $false $_.Exception.Message
}

$n8nHealth = Test-HttpWithRetry -Uri "$N8nUrl/healthz"
Write-Check "n8n health HTTP" $n8nHealth.Passed $n8nHealth.Detail

$n8nEditor = Test-HttpWithRetry -Uri $N8nUrl
Write-Check "n8n editor HTTP" $n8nEditor.Passed $n8nEditor.Detail

try {
  $tcpClient = [System.Net.Sockets.TcpClient]::new()
  $connect = $tcpClient.BeginConnect($PostgresHost, $PostgresPort, $null, $null)
  $connected = $connect.AsyncWaitHandle.WaitOne(3000, $false)
  if ($connected) {
    $tcpClient.EndConnect($connect)
  }
  $tcpClient.Close()
  Write-Check "Postgres TCP" $connected "$PostgresHost`:$PostgresPort"
} catch {
  Write-Check "Postgres TCP" $false $_.Exception.Message
}

$board = Test-HttpWithRetry -Uri $BoardUrl -Attempts 2 -DelaySeconds 1
if ($board.Passed) {
  Write-Check "Board placeholder HTTP" $true $board.Detail
} else {
  Write-Check "Board placeholder HTTP" $false "Start with: python -m http.server 8080 --directory board"
}

$manualCredentialVars = @(
  "OPENAI_API_KEY",
  "TELEGRAM_VENDOR_BOT_TOKEN",
  "TELEGRAM_MANAGER_BOT_TOKEN"
)

foreach ($name in $manualCredentialVars) {
  $value = [Environment]::GetEnvironmentVariable($name)
  $present = -not [string]::IsNullOrWhiteSpace($value)
  $detail = if ($present) { "present in process environment" } else { "not set; manual verification may still be pending" }
  Write-Info "Credential env $name" $detail
}

if ($failures.Count -gt 0) {
  Write-Host ""
  Write-Host "Stage 1 smoke check finished with $($failures.Count) unresolved check(s)."
  exit 1
}

Write-Host ""
Write-Host "Stage 1 smoke check passed."
