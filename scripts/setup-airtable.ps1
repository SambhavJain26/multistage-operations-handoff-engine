param(
  [string]$WorkspaceId = $env:AIRTABLE_WORKSPACE_ID,
  [string]$SchemaPath = (Join-Path $PSScriptRoot "..\fixtures\airtable-schema.json"),
  [string]$OutputPath = (Join-Path $PSScriptRoot "..\data\airtable\airtable-manifest.json")
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($WorkspaceId)) {
  throw "Airtable workspace ID is required. Pass -WorkspaceId or set AIRTABLE_WORKSPACE_ID."
}
if (-not (Test-Path -LiteralPath $SchemaPath)) {
  throw "Airtable schema not found: $SchemaPath"
}

$plainToken = $env:AIRTABLE_PAT
if ([string]::IsNullOrWhiteSpace($plainToken)) {
  $secureToken = Read-Host "Airtable personal access token" -AsSecureString
  $tokenPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
  try {
    $plainToken = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenPtr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPtr)
  }
}
if ([string]::IsNullOrWhiteSpace($plainToken)) {
  throw "Airtable personal access token is required."
}

$schema = Get-Content -Raw -LiteralPath $SchemaPath | ConvertFrom-Json -Depth 100
$headers = @{
  Authorization = "Bearer $plainToken"
  "Content-Type" = "application/json"
}

function Invoke-AirtableJson {
  param(
    [Parameter(Mandatory)][ValidateSet("GET", "POST", "PATCH")][string]$Method,
    [Parameter(Mandatory)][string]$Uri,
    $Body
  )
  $params = @{ Method = $Method; Uri = $Uri; Headers = $headers }
  if ($null -ne $Body) {
    $params.Body = ($Body | ConvertTo-Json -Depth 100 -Compress)
  }
  Invoke-RestMethod @params
}

try {
  $baseTables = @()
  foreach ($table in $schema.tables) {
    $fields = @($table.fields | Where-Object { $_.type -ne "multipleRecordLinks" } | ForEach-Object {
      $field = [ordered]@{ name = $_.name; type = $_.type }
      if ($null -ne $_.options) { $field.options = $_.options }
      [pscustomobject]$field
    })
    $baseTables += [pscustomobject]@{ name = $table.name; fields = $fields }
  }

  $createdBase = Invoke-AirtableJson -Method POST -Uri "https://api.airtable.com/v0/meta/bases" -Body @{
    name = $schema.baseName
    workspaceId = $WorkspaceId
    tables = $baseTables
  }
  if ([string]::IsNullOrWhiteSpace($createdBase.id)) {
    throw "Airtable did not return a base ID."
  }

  $tableIds = @{}
  foreach ($table in $createdBase.tables) {
    $tableIds[$table.name] = $table.id
  }

  foreach ($table in $schema.tables) {
    foreach ($fieldSource in @($table.fields | Where-Object { $_.type -eq "multipleRecordLinks" })) {
      $linkedTableId = $tableIds[$fieldSource.linkedTable]
      if ([string]::IsNullOrWhiteSpace($linkedTableId)) {
        throw "Linked Airtable table not found: $($fieldSource.linkedTable)"
      }
      $options = [ordered]@{ linkedTableId = $linkedTableId }
      if ($null -ne $fieldSource.options.prefersSingleRecordLink) {
        $options.prefersSingleRecordLink = [bool]$fieldSource.options.prefersSingleRecordLink
      }
      Invoke-AirtableJson -Method POST -Uri "https://api.airtable.com/v0/meta/bases/$($createdBase.id)/tables/$($tableIds[$table.name])/fields" -Body @{
        name = $fieldSource.name
        type = "multipleRecordLinks"
        options = $options
      } | Out-Null
    }
  }

  $liveSchema = Invoke-AirtableJson -Method GET -Uri "https://api.airtable.com/v0/meta/bases/$($createdBase.id)/tables"
  $manifestTables = [ordered]@{}
  foreach ($table in $liveSchema.tables) {
    $fieldMap = [ordered]@{}
    foreach ($field in $table.fields) { $fieldMap[$field.name] = $field.id }
    $manifestTables[$table.name] = [ordered]@{ id = $table.id; fields = $fieldMap }
  }

  $manifest = [ordered]@{
    baseId = $createdBase.id
    baseName = $schema.baseName
    workspaceId = $WorkspaceId
    createdAt = (Get-Date).ToUniversalTime().ToString("o")
    tables = $manifestTables
  }
  $outputDirectory = Split-Path -Parent $OutputPath
  New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($OutputPath, ($manifest | ConvertTo-Json -Depth 100), $utf8NoBom)

  Write-Host "Created Airtable base '$($schema.baseName)'."
  Write-Host "Base ID: $($createdBase.id)"
  Write-Host "Non-secret manifest: $OutputPath"
  Write-Host "Next: create the Airtable Interface and Turn Intake form using docs/airtable-workspace-setup.md."
} finally {
  $plainToken = $null
  Remove-Variable plainToken -ErrorAction SilentlyContinue
}
