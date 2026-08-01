[CmdletBinding()]
param(
  [string]$LocalUrl = "http://localhost:5678",
  [int]$TimeoutSeconds = 45
)

$ErrorActionPreference = "Stop"

$cloudflared = Get-Command cloudflared -ErrorAction SilentlyContinue
if (-not $cloudflared) {
  throw "cloudflared is not installed or not on PATH."
}

$tmpDir = Join-Path (Get-Location) "tmp"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

$stdout = Join-Path $tmpDir "cloudflared-stage1.out.log"
$stderr = Join-Path $tmpDir "cloudflared-stage1.err.log"
Remove-Item -LiteralPath $stdout, $stderr -Force -ErrorAction SilentlyContinue

$process = Start-Process `
  -FilePath $cloudflared.Source `
  -ArgumentList @("tunnel", "--url", $LocalUrl, "--no-autoupdate") `
  -WorkingDirectory (Get-Location) `
  -RedirectStandardOutput $stdout `
  -RedirectStandardError $stderr `
  -WindowStyle Hidden `
  -PassThru

try {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  $tunnelUrl = $null

  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 1

    $text = ""
    if (Test-Path -LiteralPath $stdout) {
      $text += Get-Content -Raw -LiteralPath $stdout -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $stderr) {
      $text += Get-Content -Raw -LiteralPath $stderr -ErrorAction SilentlyContinue
    }

    if ($text -match "https://[A-Za-z0-9.-]+\.trycloudflare\.com") {
      $tunnelUrl = $Matches[0]
      break
    }

    if ($process.HasExited) {
      throw "cloudflared exited before producing a tunnel URL."
    }
  }

  if (-not $tunnelUrl) {
    throw "No trycloudflare.com URL appeared within $TimeoutSeconds seconds."
  }

  $health = $null
  $lastHealthError = $null
  for ($attempt = 1; $attempt -le 12; $attempt++) {
    try {
      $health = Invoke-WebRequest -Uri "$tunnelUrl/healthz" -UseBasicParsing -TimeoutSec 20
      if ($health.StatusCode -eq 200) {
        break
      }
      $lastHealthError = "status $($health.StatusCode)"
    } catch {
      $lastHealthError = $_.Exception.Message
    }

    if ($attempt -lt 12) {
      Start-Sleep -Seconds 3
    }
  }

  if (-not $health -or $health.StatusCode -ne 200) {
    throw "Tunnel health check failed: $lastHealthError"
  }

  Write-Host "Cloudflare tunnel OK: $tunnelUrl"
  Write-Host "Tunnel health: $($health.Content)"
} finally {
  if ($process -and -not $process.HasExited) {
    Stop-Process -Id $process.Id
    $process.WaitForExit(5000) | Out-Null
  }
}
