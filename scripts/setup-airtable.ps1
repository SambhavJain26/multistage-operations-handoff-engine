[CmdletBinding()]
param(
  [string]$BaseId = $env:AIRTABLE_BASE_ID,
  [string]$WorkspaceId = $env:AIRTABLE_WORKSPACE_ID,
  [switch]$AllowExistingDefaultRecord,
  [switch]$KeepExistingDefaultTable,
  [string]$CredentialName = "Airtable Make Ready Demo",
  [string]$SchemaPath = (Join-Path $PSScriptRoot "..\fixtures\airtable-schema.json"),
  [string]$OutputPath = (Join-Path $PSScriptRoot "..\data\airtable\airtable-manifest.json")
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $SchemaPath)) { throw "Airtable schema not found: $SchemaPath" }
if ([string]::IsNullOrWhiteSpace($BaseId) -and [string]::IsNullOrWhiteSpace($WorkspaceId)) {
  throw "Pass -BaseId for an existing empty base, or -WorkspaceId to create a new base."
}

function Get-AirtableToken {
  if (-not [string]::IsNullOrWhiteSpace($env:AIRTABLE_PAT)) { return $env:AIRTABLE_PAT }

  $credentialJson = docker exec make-ready-n8n n8n export:credentials --all --decrypted
  if ($LASTEXITCODE -eq 0 -and $credentialJson) {
    try {
      $credentials = $credentialJson | ConvertFrom-Json
      $credential = @($credentials | Where-Object { $_.name -eq $CredentialName } | Select-Object -First 1)
      if ($credential.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace($credential[0].data.accessToken)) {
        return [string]$credential[0].data.accessToken
      }
    } finally {
      $credentialJson = $null
      Remove-Variable credentialJson -ErrorAction SilentlyContinue
    }
  }

  $secureToken = Read-Host "Airtable personal access token" -AsSecureString
  $tokenPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenPtr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPtr)
  }
}

$plainToken = Get-AirtableToken
if ([string]::IsNullOrWhiteSpace($plainToken)) { throw "An Airtable personal access token is required." }
$schema = Get-Content -Raw -LiteralPath $SchemaPath | ConvertFrom-Json
$headers = @{ Authorization = "Bearer $plainToken"; "Content-Type" = "application/json" }

function Invoke-AirtableJson {
  param(
    [Parameter(Mandatory)][ValidateSet("GET", "POST", "PATCH", "DELETE")][string]$Method,
    [Parameter(Mandatory)][string]$Uri,
    $Body
  )
  $params = @{ Method = $Method; Uri = $Uri; Headers = $headers }
  if ($null -ne $Body) { $params.Body = ($Body | ConvertTo-Json -Depth 100 -Compress) }
  return Invoke-RestMethod @params
}

function New-FieldDefinition($Field) {
  $field = [ordered]@{ name = $Field.name; type = $Field.type }
  $options = $Field.options
  # Airtable does not accept the legacy "alert" checkbox icon through the schema API.
  if ($Field.type -eq "checkbox" -and $Field.options.icon -eq "alert") { $options = [ordered]@{ icon = "check"; color = $Field.options.color } }
  if ($null -ne $options) { $field.options = $options }
  return [pscustomobject]$field
}

function New-TableFields($Table) {
  # Airtable accepts created-time fields when added after table creation, not in a bulk table payload.
  return @($Table.fields | Where-Object { $_.type -notin @("multipleRecordLinks", "createdTime") } | ForEach-Object {
    $field = [ordered]@{ name = $_.name; type = $_.type }
    $options = $_.options
    if ($_.type -eq "checkbox" -and $_.options.icon -eq "alert") { $options = [ordered]@{ icon = "check"; color = $_.options.color } }
    if ($null -ne $options) { $field.options = $options }
    [pscustomobject]$field
  })
}

try {
  if ([string]::IsNullOrWhiteSpace($BaseId)) {
    $baseTables = @($schema.tables | ForEach-Object { [pscustomobject]@{ name = $_.name; fields = (New-TableFields $_) } })
    $createdBase = Invoke-AirtableJson -Method POST -Uri "https://api.airtable.com/v0/meta/bases" -Body @{ name = $schema.baseName; workspaceId = $WorkspaceId; tables = $baseTables }
    $BaseId = $createdBase.id
    if ([string]::IsNullOrWhiteSpace($BaseId)) { throw "Airtable did not return a base ID." }
  } elseif (-not $KeepExistingDefaultTable) {
    throw "Existing-base setup preserves its current tables. Pass -KeepExistingDefaultTable to add the operational tables beside Table 1."
  }

  $liveSchema = Invoke-AirtableJson -Method GET -Uri "https://api.airtable.com/v0/meta/bases/$BaseId/tables"
  $existingByName = @{}
  foreach ($table in @($liveSchema.tables)) { $existingByName[$table.name] = $table }
  foreach ($table in $schema.tables) {
    if ($existingByName.ContainsKey($table.name)) { continue }
    $createdTable = Invoke-AirtableJson -Method POST -Uri "https://api.airtable.com/v0/meta/bases/$BaseId/tables" -Body @{ name = $table.name; fields = (New-TableFields $table) }
    $existingByName[$table.name] = $createdTable
  }

  $liveSchema = Invoke-AirtableJson -Method GET -Uri "https://api.airtable.com/v0/meta/bases/$BaseId/tables"
  $tableIds = @{}
  foreach ($table in @($liveSchema.tables)) { $tableIds[$table.name] = $table.id }
  foreach ($tableSource in $schema.tables) {
    $liveTable = @($liveSchema.tables | Where-Object name -eq $tableSource.name)[0]
    $liveFieldNames = @($liveTable.fields.name)
    foreach ($fieldSource in @($tableSource.fields | Where-Object { $_.type -ne "multipleRecordLinks" })) {
      if ($liveFieldNames -contains $fieldSource.name) { continue }
      $fieldDefinition = [ordered]@{ name = $fieldSource.name; type = $fieldSource.type }
      $fieldOptions = $fieldSource.options
      if ($fieldSource.type -eq "checkbox" -and $fieldSource.options.icon -eq "alert") { $fieldOptions = [ordered]@{ icon = "check"; color = $fieldSource.options.color } }
      if ($null -ne $fieldOptions) { $fieldDefinition.options = $fieldOptions }
      Invoke-AirtableJson -Method POST -Uri "https://api.airtable.com/v0/meta/bases/$BaseId/tables/$($liveTable.id)/fields" -Body $fieldDefinition | Out-Null
    }
  }

  $liveSchema = Invoke-AirtableJson -Method GET -Uri "https://api.airtable.com/v0/meta/bases/$BaseId/tables"
  $tableIds = @{}
  foreach ($table in @($liveSchema.tables)) { $tableIds[$table.name] = $table.id }
  foreach ($tableSource in $schema.tables) {
    $liveTable = @($liveSchema.tables | Where-Object name -eq $tableSource.name)[0]
    $liveFieldNames = @($liveTable.fields.name)
    foreach ($fieldSource in @($tableSource.fields | Where-Object { $_.type -eq "multipleRecordLinks" })) {
      if ($liveFieldNames -contains $fieldSource.name) { continue }
      $linkedTableId = $tableIds[$fieldSource.linkedTable]
      if ([string]::IsNullOrWhiteSpace($linkedTableId)) { throw "Linked Airtable table not found: $($fieldSource.linkedTable)" }
      # The API accepts only the linked table ID at creation time; the UI preference is not writable.
      $options = [ordered]@{ linkedTableId = $linkedTableId }
      Invoke-AirtableJson -Method POST -Uri "https://api.airtable.com/v0/meta/bases/$BaseId/tables/$($liveTable.id)/fields" -Body @{ name = $fieldSource.name; type = "multipleRecordLinks"; options = $options } | Out-Null
    }
  }

  $liveSchema = Invoke-AirtableJson -Method GET -Uri "https://api.airtable.com/v0/meta/bases/$BaseId/tables"
  $manifestTables = [ordered]@{}
  foreach ($table in $liveSchema.tables) {
    $fieldMap = [ordered]@{}
    foreach ($field in $table.fields) { $fieldMap[$field.name] = $field.id }
    $manifestTables[$table.name] = [ordered]@{ id = $table.id; fields = $fieldMap }
  }
  $manifest = [ordered]@{
    baseId = $BaseId
    baseName = $schema.baseName
    createdAt = (Get-Date).ToUniversalTime().ToString("o")
    tables = $manifestTables
  }
  $outputDirectory = Split-Path -Parent $OutputPath
  New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($OutputPath, ($manifest | ConvertTo-Json -Depth 100), $utf8NoBom)

  Write-Host "Configured Airtable base '$BaseId' with $($schema.tables.Count) typed operational tables."
  Write-Host "Non-secret manifest: $OutputPath"
} finally {
  $plainToken = $null
  Remove-Variable plainToken -ErrorAction SilentlyContinue
}
