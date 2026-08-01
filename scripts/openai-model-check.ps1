[CmdletBinding()]
param(
  [string]$ApiKey = $env:OPENAI_API_KEY,
  [string]$PreferredModel = "gpt-5.6-luna"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
  $secure = Read-Host "OpenAI API key" -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  }
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
  throw "OpenAI API key is required. Set OPENAI_API_KEY or enter it when prompted."
}

$headers = @{
  Authorization = "Bearer $ApiKey"
}

$response = Invoke-RestMethod -Uri "https://api.openai.com/v1/models" -Headers $headers -Method Get -TimeoutSec 30
$models = @($response.data | ForEach-Object { $_.id })

Write-Host "OpenAI /v1/models returned $($models.Count) model(s)."

if ($models -contains $PreferredModel) {
  Write-Host "Preferred model available: $PreferredModel"
  Write-Host "OPENAI_MODEL_CLASSIFY=$PreferredModel"
  Write-Host "OPENAI_MODEL_DRAFT=$PreferredModel"
  exit 0
}

$fallbackClassify = @("gpt-5.4-nano", "gpt-5.4-mini", "gpt-5.6-terra") | Where-Object { $models -contains $_ } | Select-Object -First 1
$fallbackDraft = @("gpt-5.4-mini", "gpt-5.6-terra", "gpt-5.4-nano") | Where-Object { $models -contains $_ } | Select-Object -First 1

Write-Host "Preferred model unavailable: $PreferredModel"

if ($fallbackClassify) {
  Write-Host "Suggested OPENAI_MODEL_CLASSIFY=$fallbackClassify"
} else {
  Write-Host "No documented classification fallback found in available model list."
}

if ($fallbackDraft) {
  Write-Host "Suggested OPENAI_MODEL_DRAFT=$fallbackDraft"
} else {
  Write-Host "No documented drafting fallback found in available model list."
}

exit 2
