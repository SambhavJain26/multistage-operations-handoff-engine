[CmdletBinding()]
param(
  [int]$TimeoutSeconds = 45
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$cloudflared = Get-Command cloudflared -ErrorAction Stop
$stateDir = Join-Path $repoRoot "data\demo-tunnel"
$pidPath = Join-Path $stateDir "cloudflared.pid"
$stdout = Join-Path $stateDir "cloudflared.out.log"
$stderr = Join-Path $stateDir "cloudflared.err.log"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

if (Test-Path -LiteralPath $pidPath) {
  $oldPid = [int](Get-Content -Raw -LiteralPath $pidPath)
  $oldProcess = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
  if ($oldProcess) { Stop-Process -Id $oldPid -Force }
}
Remove-Item -LiteralPath $stdout, $stderr -Force -ErrorAction SilentlyContinue

$process = Start-Process -FilePath $cloudflared.Source -ArgumentList @("tunnel", "--url", "http://localhost:5678", "--no-autoupdate") -WorkingDirectory $repoRoot -RedirectStandardOutput $stdout -RedirectStandardError $stderr -WindowStyle Hidden -PassThru
[IO.File]::WriteAllText($pidPath, [string]$process.Id, (New-Object System.Text.UTF8Encoding($false)))

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$tunnelUrl = $null
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 1
  $text = (Get-Content -Raw -LiteralPath $stdout -ErrorAction SilentlyContinue) + (Get-Content -Raw -LiteralPath $stderr -ErrorAction SilentlyContinue)
  if ($text -match "https://[A-Za-z0-9.-]+\.trycloudflare\.com") { $tunnelUrl = $Matches[0]; break }
  if ($process.HasExited) { throw "cloudflared exited before creating a tunnel." }
}
if (-not $tunnelUrl) { throw "No trycloudflare.com URL appeared within $TimeoutSeconds seconds." }

$health = $null
$lastHealthError = $null
for ($attempt = 1; $attempt -le 12; $attempt++) {
  try {
    $health = Invoke-WebRequest -Uri "$tunnelUrl/healthz" -UseBasicParsing -TimeoutSec 20
    if ($health.StatusCode -eq 200) { break }
    $lastHealthError = "status $($health.StatusCode)"
  } catch {
    $lastHealthError = $_.Exception.Message
  }
  if ($attempt -lt 12) { Start-Sleep -Seconds 3 }
}
if (-not $health -or $health.StatusCode -ne 200) {
  Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
  throw "Tunnel health check failed: $lastHealthError"
}

$envPath = Join-Path $repoRoot ".env"
if (-not (Test-Path -LiteralPath $envPath)) { throw "Missing local .env file." }
$content = [IO.File]::ReadAllText($envPath)
$pattern = "(?m)^\s*WEBHOOK_URL\s*=.*$"
if ([regex]::IsMatch($content, $pattern)) { $content = [regex]::Replace($content, $pattern, "WEBHOOK_URL=$tunnelUrl") }
else { $content = "$content`r`nWEBHOOK_URL=$tunnelUrl`r`n" }
[IO.File]::WriteAllText($envPath, $content, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Temporary Telegram tunnel is healthy and WEBHOOK_URL was updated in ignored local configuration."
