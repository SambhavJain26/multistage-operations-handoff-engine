[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$stageTemplateSource = Join-Path $repoRoot "fixtures\stage-template.json"
$dataConfigDir = Join-Path $repoRoot "data\config"
$stageTemplateTarget = Join-Path $dataConfigDir "stage_template.json"
$photosDir = Join-Path $repoRoot "data\photos"

function Invoke-AppPsqlFile {
  param([string]$ContainerPath)
  docker exec make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -f $ContainerPath
  if ($LASTEXITCODE -ne 0) {
    throw "psql file failed: $ContainerPath"
  }
}

function Invoke-AppPsqlScalar {
  param([string]$Sql)
  $result = docker exec make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -tAc $Sql
  if ($LASTEXITCODE -ne 0) {
    throw "psql scalar failed."
  }
  return ($result | Select-Object -First 1).Trim()
}

Invoke-AppPsqlFile "/docker-entrypoint-initdb.d/migrations/001-schema.sql"

$nonFixtureCount = [int](Invoke-AppPsqlScalar "SELECT (SELECT count(*) FROM ""turn"" WHERE is_fixture = false) + (SELECT count(*) FROM vendor WHERE is_fixture = false);")
if ($nonFixtureCount -gt 0) {
  throw "Refusing to reset: found $nonFixtureCount non-fixture turn/vendor row(s). Remove or export prospect data first."
}

New-Item -ItemType Directory -Force -Path $dataConfigDir | Out-Null
Copy-Item -LiteralPath $stageTemplateSource -Destination $stageTemplateTarget -Force

New-Item -ItemType Directory -Force -Path $photosDir | Out-Null
$resolvedPhotos = Resolve-Path $photosDir
if (-not $resolvedPhotos.Path.StartsWith($repoRoot.Path, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Refusing to clear photos outside repository: $($resolvedPhotos.Path)"
}

Get-ChildItem -LiteralPath $resolvedPhotos.Path -Force | Remove-Item -Recurse -Force

Invoke-AppPsqlFile "/docker-entrypoint-initdb.d/seed/seed.sql"

Write-Host "Demo fixture data reset complete."
Write-Host "Stage template copied to data/config/stage_template.json."
