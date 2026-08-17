[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidatePattern('^app')][string]$AirtableBaseId,
  [Parameter(Mandatory)][ValidatePattern('^[^@\s]+@[^@\s]+$')][string]$DemoEmail
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envPath = Join-Path $repoRoot ".env"
if (-not (Test-Path -LiteralPath $envPath)) { throw "Missing local .env file." }

function Set-DotEnvValue([string]$Content, [string]$Name, [string]$Value) {
  $escapedName = [regex]::Escape($Name)
  $pattern = "(?m)^\s*$escapedName\s*=.*$"
  $replacement = "$Name=$Value"
  if ([regex]::IsMatch($Content, $pattern)) { return [regex]::Replace($Content, $pattern, $replacement) }
  $suffix = if ($Content.EndsWith("`n")) { "" } else { "`r`n" }
  return "$Content$suffix$replacement`r`n"
}

$content = [IO.File]::ReadAllText($envPath)
$values = [ordered]@{
  AIRTABLE_BASE_ID = $AirtableBaseId
  VENDOR_EMAIL_FROM = $DemoEmail
  VENDOR_EMAIL_REPLY_TO = $DemoEmail
  RIVERA_VENDOR_EMAIL = $DemoEmail
  MARIAS_VENDOR_EMAIL = $DemoEmail
  DALE_VENDOR_EMAIL = $DemoEmail
  STATEWIDE_VENDOR_EMAIL = $DemoEmail
  QUICKHAUL_VENDOR_EMAIL = $DemoEmail
}
foreach ($entry in $values.GetEnumerator()) { $content = Set-DotEnvValue $content $entry.Key $entry.Value }
[IO.File]::WriteAllText($envPath, $content, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Updated ignored demo connector settings. No credentials were printed."
