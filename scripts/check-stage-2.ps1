[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

docker exec make-ready-postgres psql -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/verify-stage-2.sql
if ($LASTEXITCODE -ne 0) {
  throw "Stage 2 verification failed."
}

Write-Host "Stage 2 verification passed."
