[CmdletBinding()]
param(
  [string]$VendorBotToken = $env:TELEGRAM_VENDOR_BOT_TOKEN,
  [string]$ManagerBotToken = $env:TELEGRAM_MANAGER_BOT_TOKEN
)

$ErrorActionPreference = "Stop"

function Read-TokenIfMissing {
  param(
    [string]$CurrentValue,
    [string]$Prompt
  )

  if (-not [string]::IsNullOrWhiteSpace($CurrentValue)) {
    return $CurrentValue
  }

  $secure = Read-Host $Prompt -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  }
}

function Test-Bot {
  param(
    [string]$Label,
    [string]$Token
  )

  if ([string]::IsNullOrWhiteSpace($Token)) {
    throw "$Label bot token is required."
  }

  $uri = "https://api.telegram.org/bot$Token/getMe"
  $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 30
  if (-not $response.ok) {
    throw "$Label getMe returned ok=false."
  }

  $user = $response.result
  Write-Host "$Label bot OK: @$($user.username) (id $($user.id))"
}

$VendorBotToken = Read-TokenIfMissing -CurrentValue $VendorBotToken -Prompt "Vendor Telegram bot token"
$ManagerBotToken = Read-TokenIfMissing -CurrentValue $ManagerBotToken -Prompt "Manager Telegram bot token"

Test-Bot -Label "Vendor" -Token $VendorBotToken
Test-Bot -Label "Manager" -Token $ManagerBotToken
