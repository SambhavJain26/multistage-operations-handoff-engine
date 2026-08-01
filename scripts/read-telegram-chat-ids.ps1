[CmdletBinding()]
param(
  [string[]]$CredentialNames = @(
    "Make-Ready Vendor Telegram Bot",
    "Make-Ready Manager Telegram Bot"
  )
)

$ErrorActionPreference = "Stop"

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

  $updates = Invoke-RestMethod -Uri "$($baseUrl.TrimEnd('/'))/bot$($credential.data.accessToken)/getUpdates" -Method Get -TimeoutSec 30
  Write-Host ""
  Write-Host $credentialName
  if (-not $updates.ok -or -not $updates.result -or $updates.result.Count -eq 0) {
    Write-Host "  No updates found. Send a message to this bot, then run the script again."
    continue
  }

  $updates.result | ForEach-Object {
    $message = $_.message
    if (-not $message) {
      $message = $_.edited_message
    }
    if (-not $message) {
      return
    }

    $chat = $message.chat
    $from = $message.from
    $date = ([DateTimeOffset]::FromUnixTimeSeconds([int64]$message.date)).ToLocalTime().ToString("s")
    Write-Host ("  chat_id={0} chat_type={1} from=@{2} name={3} {4} date={5}" -f $chat.id, $chat.type, $from.username, $from.first_name, $from.last_name, $date)
  }
}
