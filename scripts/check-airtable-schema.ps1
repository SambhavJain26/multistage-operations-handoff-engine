param(
  [switch]$Live,
  [string]$SchemaPath = (Join-Path $PSScriptRoot "..\fixtures\airtable-schema.json"),
  [string]$ManifestPath = (Join-Path $PSScriptRoot "..\data\airtable\airtable-manifest.json")
)

$ErrorActionPreference = "Stop"

function Assert-True {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

$schema = Get-Content -Raw -LiteralPath $SchemaPath | ConvertFrom-Json
$expectedTables = @("Turn Intake", "Turns", "Stages", "Vendors", "Communications", "Approvals & Deliveries")
foreach ($tableName in $expectedTables) {
  Assert-True ($null -ne ($schema.tables | Where-Object name -eq $tableName)) "Missing Airtable table: $tableName"
}

$typedRequirements = @{
  "Turn Intake" = @{ "Monthly Rent" = "currency"; "Notice Date" = "date"; "Paint Vendor" = "multipleRecordLinks"; "Intake Status" = "singleSelect"; "Submitted At" = "dateTime" }
  "Turns" = @{ "Monthly Rent" = "currency"; "Health" = "singleSelect"; "Active Vendor" = "multipleRecordLinks"; "Elapsed" = "duration"; "SLA Progress" = "percent"; "Vacancy Loss" = "currency" }
  "Stages" = @{ "Turn" = "multipleRecordLinks"; "Status" = "singleSelect"; "Overdue" = "checkbox"; "Evidence" = "multipleAttachments" }
  "Vendors" = @{ "Trade" = "singleSelect"; "Email" = "email"; "Active" = "checkbox" }
  "Communications" = @{ "Intent" = "singleSelect"; "AI Confidence" = "percent"; "Needs Review" = "checkbox"; "Attachments" = "multipleAttachments" }
  "Approvals & Deliveries" = @{ "Channels" = "multipleSelects"; "Approval Status" = "singleSelect"; "Decision At" = "dateTime" }
}

foreach ($tableName in $typedRequirements.Keys) {
  $table = $schema.tables | Where-Object name -eq $tableName
  foreach ($fieldName in $typedRequirements[$tableName].Keys) {
    $field = $table.fields | Where-Object name -eq $fieldName
    Assert-True ($null -ne $field) "Missing Airtable field: $tableName.$fieldName"
    Assert-True ($field.type -eq $typedRequirements[$tableName][$fieldName]) "Wrong Airtable field type for ${tableName}.${fieldName}: expected $($typedRequirements[$tableName][$fieldName]), got $($field.type)"
  }
}

foreach ($tableSource in $schema.tables) {
  $duplicateFields = @($tableSource.fields | Group-Object name | Where-Object Count -gt 1)
  Assert-True ($duplicateFields.Count -eq 0) "Duplicate Airtable fields in $($tableSource.name): $($duplicateFields.Name -join ', ')"
  foreach ($fieldSource in $tableSource.fields) {
    if ($fieldSource.type -eq "multipleRecordLinks") {
      Assert-True (-not [string]::IsNullOrWhiteSpace($fieldSource.linkedTable)) "Linked field is missing linkedTable: $($tableSource.name).$($fieldSource.name)"
      Assert-True ($null -ne ($schema.tables | Where-Object name -eq $fieldSource.linkedTable)) "Linked table does not exist: $($fieldSource.linkedTable)"
    }
    if ($fieldSource.type -in @("singleSelect", "multipleSelects")) {
      $choiceNames = @($fieldSource.options.choices.name)
      Assert-True ($choiceNames.Count -gt 0) "Select field has no choices: $($tableSource.name).$($fieldSource.name)"
      Assert-True (($choiceNames | Sort-Object -Unique).Count -eq $choiceNames.Count) "Select field has duplicate choices: $($tableSource.name).$($fieldSource.name)"
    }
  }
}

if (-not $Live) {
  Write-Host "Airtable schema contract passed."
  exit 0
}

Assert-True (Test-Path -LiteralPath $ManifestPath) "Airtable manifest is required for -Live. Run scripts/setup-airtable.ps1 first."
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$plainToken = $env:AIRTABLE_PAT
if ([string]::IsNullOrWhiteSpace($plainToken)) {
  $credentialJson = docker exec make-ready-n8n n8n export:credentials --all --decrypted
  if ($LASTEXITCODE -eq 0 -and $credentialJson) {
    try {
      $credentials = $credentialJson | ConvertFrom-Json
      $credential = @($credentials | Where-Object { $_.name -in @("Airtable Make Ready Demo", "Make-Ready Airtable") } | Select-Object -First 1)
      if ($credential.Count -eq 1) { $plainToken = [string]$credential[0].data.accessToken }
    } finally {
      $credentialJson = $null
      Remove-Variable credentialJson -ErrorAction SilentlyContinue
    }
  }
}
if ([string]::IsNullOrWhiteSpace($plainToken)) { throw "Airtable credential is required for -Live." }
try {
  $liveSchema = Invoke-RestMethod -Method GET -Uri "https://api.airtable.com/v0/meta/bases/$($manifest.baseId)/tables" -Headers @{ Authorization = "Bearer $plainToken" }
  foreach ($tableSource in $schema.tables) {
    $liveTable = $liveSchema.tables | Where-Object name -eq $tableSource.name
    Assert-True ($null -ne $liveTable) "Live Airtable table missing: $($tableSource.name)"
    foreach ($fieldSource in $tableSource.fields) {
      $liveField = $liveTable.fields | Where-Object name -eq $fieldSource.name
      Assert-True ($null -ne $liveField) "Live Airtable field missing: $($tableSource.name).$($fieldSource.name)"
      Assert-True ($liveField.type -eq $fieldSource.type) "Live Airtable type mismatch for $($tableSource.name).$($fieldSource.name): expected $($fieldSource.type), got $($liveField.type)"
      if ($fieldSource.type -in @("singleSelect", "multipleSelects")) {
        $expectedChoices = @($fieldSource.options.choices.name | Sort-Object)
        $actualChoices = @($liveField.options.choices.name | Sort-Object)
        Assert-True ((Compare-Object $expectedChoices $actualChoices).Count -eq 0) "Live Airtable choices differ for $($tableSource.name).$($fieldSource.name)"
      }
      if ($fieldSource.type -eq "multipleRecordLinks") {
        $expectedLinkedTable = $liveSchema.tables | Where-Object name -eq $fieldSource.linkedTable
        Assert-True ($liveField.options.linkedTableId -eq $expectedLinkedTable.id) "Live Airtable link target differs for $($tableSource.name).$($fieldSource.name)"
      }
    }
  }
  Write-Host "Live Airtable schema passed."
} finally {
  $plainToken = $null
  Remove-Variable plainToken -ErrorAction SilentlyContinue
}
