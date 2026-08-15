[CmdletBinding()]
param(
  [string[]]$CredentialNames = @(
    "Make-Ready Vendor Telegram Bot",
    "Make-Ready Manager Telegram Bot"
  )
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

function Get-LocalEnvValue([string]$Name) {
  $envPath = Join-Path $repoRoot ".env"
  if (-not (Test-Path -LiteralPath $envPath)) { return "" }
  $line = Get-Content -LiteralPath $envPath | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s*=" } | Select-Object -Last 1
  if (-not $line) { return "" }
  return ($line -replace "^\s*$([regex]::Escape($Name))\s*=\s*", "").Trim().Trim('"').Trim("'")
}

$configuredChats = @{
  "Make-Ready Vendor Telegram Bot" = @(
    @{ Label = "Rivera Painting"; Env = "RIVERA_TELEGRAM_CHAT_ID" },
    @{ Label = "Maria's Cleaning Co"; Env = "MARIAS_TELEGRAM_CHAT_ID" },
    @{ Label = "Dale Hutchins"; Env = "DALE_TELEGRAM_CHAT_ID" },
    @{ Label = "Statewide Flooring"; Env = "STATEWIDE_TELEGRAM_CHAT_ID" },
    @{ Label = "QuickHaul Junk Removal"; Env = "QUICKHAUL_TELEGRAM_CHAT_ID" }
  )
  "Make-Ready Manager Telegram Bot" = @(
    @{ Label = "Manager control chat"; Env = "MANAGER_TELEGRAM_CHAT_ID" },
    @{ Label = "Builder alert chat"; Env = "BUILDER_TELEGRAM_CHAT_ID" }
  )
}

$raw = docker exec make-ready-n8n n8n export:credentials --all --decrypted
if ($LASTEXITCODE -ne 0) {
  throw "Could not read n8n credentials."
}

$parsedCredentials = $raw | ConvertFrom-Json
if ($parsedCredentials -is [array]) {
  $credentials = $parsedCredentials
} else {
  $credentials = @($parsedCredentials)
}

foreach ($credentialName in $CredentialNames) {
  $credential = $credentials | Where-Object { $_.name -eq $credentialName } | Select-Object -First 1
  if (-not $credential) {
    Write-Warning "Credential not found: $credentialName"
    continue
  }

  if ($credential.type -ne "telegramApi") {
    Write-Warning "Credential is not telegramApi: $credentialName"
    continue
  }

  $baseUrl = $credential.data.baseUrl
  if ([string]::IsNullOrWhiteSpace($baseUrl)) {
    $baseUrl = "https://api.telegram.org"
  }

  $bot = Invoke-RestMethod -Uri "$($baseUrl.TrimEnd('/'))/bot$($credential.data.accessToken)/getMe" -Method Get -TimeoutSec 30
  Write-Host ""
  $botLabel = if ($bot.ok -and $bot.result.username) { "@$($bot.result.username)" } else { "unknown bot" }
  Write-Host "$credentialName ($botLabel)"
  $known = $configuredChats[$credentialName]
  if (-not $known) {
    Write-Host "  No project chat mapping is configured for this bot."
    continue
  }

  foreach ($entry in $known) {
    $chatId = Get-LocalEnvValue $entry.Env
    if ([string]::IsNullOrWhiteSpace($chatId)) {
      Write-Host "  $($entry.Label): not configured"
      continue
    }
    try {
      $chatResult = Invoke-RestMethod -Uri "$($baseUrl.TrimEnd('/'))/bot$($credential.data.accessToken)/getChat?chat_id=$chatId" -Method Get -TimeoutSec 8
    } catch {
      Write-Host "  $($entry.Label): configured but Telegram did not respond"
      continue
    }
    if (-not $chatResult.ok) {
      Write-Host "  $($entry.Label): configured but unavailable to this bot"
      continue
    }
    $chat = $chatResult.result
    $chatTitle = if ($chat.title) { $chat.title } elseif ($chat.username) { "@$($chat.username)" } else { ("{0} {1}" -f $chat.first_name, $chat.last_name).Trim() }
    Write-Host ("  {0}: '{1}' chat_id={2} type={3}" -f $entry.Label, $chatTitle, $chat.id, $chat.type)
  }
}
