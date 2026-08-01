[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$CsvPath
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$stageTemplatePath = Join-Path $repoRoot "fixtures\stage-template.json"

if (-not (Test-Path -LiteralPath $CsvPath)) {
  throw "CSV not found: $CsvPath"
}

$stageTemplate = Get-Content -Raw -LiteralPath $stageTemplatePath | ConvertFrom-Json
$stagesByCode = @{}
foreach ($stage in $stageTemplate) {
  $stagesByCode[$stage.stage_code] = $stage
}

function Invoke-AppPsqlFile {
  param([string]$ContainerPath)
  docker exec make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -f $ContainerPath
  if ($LASTEXITCODE -ne 0) {
    throw "psql file failed: $ContainerPath"
  }
}

function Sql-Literal {
  param([AllowNull()][string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) {
    return "NULL"
  }
  return "'" + $Value.Replace("'", "''") + "'"
}

function Get-CsvValue {
  param(
    [pscustomobject]$Row,
    [string]$Name
  )
  $property = $Row.PSObject.Properties | Where-Object { $_.Name -ieq $Name } | Select-Object -First 1
  if ($property) {
    return [string]$property.Value
  }
  return $null
}

Invoke-AppPsqlFile "/docker-entrypoint-initdb.d/migrations/001-schema.sql"

$rows = @(Import-Csv -LiteralPath $CsvPath)
if ($rows.Count -eq 0) {
  throw "CSV has no rows: $CsvPath"
}

$requiredColumns = @(
  "unit_label",
  "property_address",
  "rent_monthly",
  "notice_date",
  "moveout_date",
  "target_ready_date",
  "current_stage_code",
  "current_stage_activated_at"
)

$sqlStatements = New-Object System.Collections.Generic.List[string]
$sqlStatements.Add("BEGIN;") | Out-Null

foreach ($row in $rows) {
  foreach ($column in $requiredColumns) {
    if ([string]::IsNullOrWhiteSpace((Get-CsvValue -Row $row -Name $column))) {
      throw "Missing required column/value '$column' in CSV row: $($row | ConvertTo-Json -Compress)"
    }
  }

  $currentStageCode = (Get-CsvValue -Row $row -Name "current_stage_code").Trim().ToUpperInvariant()
  if (-not $stagesByCode.ContainsKey($currentStageCode)) {
    throw "Unknown current_stage_code '$currentStageCode'."
  }

  $currentStage = $stagesByCode[$currentStageCode]
  $unitLabel = Get-CsvValue -Row $row -Name "unit_label"
  $propertyAddress = Get-CsvValue -Row $row -Name "property_address"
  $rentMonthly = [decimal](Get-CsvValue -Row $row -Name "rent_monthly")
  $noticeDate = Get-CsvValue -Row $row -Name "notice_date"
  $moveoutDate = Get-CsvValue -Row $row -Name "moveout_date"
  $targetReadyDate = Get-CsvValue -Row $row -Name "target_ready_date"
  $currentActivatedAt = Get-CsvValue -Row $row -Name "current_stage_activated_at"

  $turnIdExpr = "(SELECT id FROM inserted_turn)"
  $sqlStatements.Add("INSERT INTO ""turn"" (unit_label, property_address, rent_monthly, notice_date, moveout_date, target_ready_date, status, is_fixture) VALUES ($(Sql-Literal $unitLabel), $(Sql-Literal $propertyAddress), $rentMonthly, $(Sql-Literal $noticeDate), $(Sql-Literal $moveoutDate), $(Sql-Literal $targetReadyDate), 'active', false);") | Out-Null

  foreach ($stage in $stageTemplate) {
    $stageCode = [string]$stage.stage_code
    $completedColumn = ($stageCode.ToLowerInvariant() + "_completed_at")
    $completedAt = Get-CsvValue -Row $row -Name $completedColumn

    if ($stageCode -eq $currentStageCode) {
      $status = "active"
      $activatedAtSql = Sql-Literal $currentActivatedAt
      $completedAtSql = "NULL"
      $completedViaSql = "NULL"
      $completedBySql = "NULL"
    } elseif (-not [string]::IsNullOrWhiteSpace($completedAt)) {
      $status = "complete"
      $activatedAtSql = Sql-Literal $completedAt
      $completedAtSql = Sql-Literal $completedAt
      $completedViaSql = "'manual'"
      $completedBySql = "'prospect_import'"
    } elseif ([int]$stage.seq -lt [int]$currentStage.seq) {
      $status = "complete"
      $hoursBack = ([int]$currentStage.seq - [int]$stage.seq) + 1
      $activatedAtSql = "$(Sql-Literal $currentActivatedAt)::timestamptz - interval '$hoursBack hours'"
      $completedAtSql = "$(Sql-Literal $currentActivatedAt)::timestamptz - interval '$($hoursBack - 1) hours'"
      $completedViaSql = "'manual'"
      $completedBySql = "'prospect_import'"
    } else {
      $status = "pending"
      $activatedAtSql = "NULL"
      $completedAtSql = "NULL"
      $completedViaSql = "NULL"
      $completedBySql = "NULL"
    }

    $sqlStatements.Add("INSERT INTO turn_stage (turn_id, seq, stage_code, stage_name, status, vendor_id, sla_hours, activated_at, completed_at, completed_via, completed_by) VALUES ((SELECT id FROM ""turn"" WHERE unit_label = $(Sql-Literal $unitLabel) AND property_address = $(Sql-Literal $propertyAddress) AND is_fixture = false ORDER BY id DESC LIMIT 1), $($stage.seq), $(Sql-Literal $stageCode), $(Sql-Literal $stage.stage_name), '$status', NULL, $($stage.sla_hours), $activatedAtSql, $completedAtSql, $completedViaSql, $completedBySql);") | Out-Null
  }

  $sqlStatements.Add("INSERT INTO event_log (turn_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json) VALUES ((SELECT id FROM ""turn"" WHERE unit_label = $(Sql-Literal $unitLabel) AND property_address = $(Sql-Literal $propertyAddress) AND is_fixture = false ORDER BY id DESC LIMIT 1), 'manager', 'prospect_import', 'import', 'prospect_imported', 'prospect CSV import', jsonb_build_object('unit_label', $(Sql-Literal $unitLabel), 'current_stage_code', $(Sql-Literal $currentStageCode)));") | Out-Null
}

$sqlStatements.Add("COMMIT;") | Out-Null
$sql = $sqlStatements -join [Environment]::NewLine

$sql | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1
if ($LASTEXITCODE -ne 0) {
  throw "Prospect CSV import failed."
}

Write-Host "Imported $($rows.Count) prospect turn row(s) as non-fixture data."
