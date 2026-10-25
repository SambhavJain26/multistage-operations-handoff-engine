# Quick start script for make-ready-sequencing
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
Push-Location $repoRoot

try {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Starting Make-Ready Sequencing Environment" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    # 1. Check .env
    $envFile = Join-Path $repoRoot ".env"
    if (-not (Test-Path $envFile)) {
        Write-Host "No .env found. Copying from .env.example..." -ForegroundColor Yellow
        Copy-Item (Join-Path $repoRoot ".env.example") $envFile
    }

    # 2. Verify Docker
    try {
        docker info > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Docker daemon is not running. Please start Docker Desktop and re-run." -ForegroundColor Red
            return
        }
    } catch {
        Write-Host "Docker is not detected in PATH. Please ensure Docker Desktop is installed and running." -ForegroundColor Red
        return
    }

    # 3. Start Docker Compose stack
    Write-Host "Spinning up local containers via docker compose..." -ForegroundColor Green
    docker compose up -d

    Write-Host ""
    Write-Host "Services successfully initialized:" -ForegroundColor Green
    Write-Host "- n8n Workflow Editor: http://localhost:5678" -ForegroundColor White
    Write-Host "- PostgreSQL Database: 127.0.0.1:5432" -ForegroundColor White
    Write-Host ""
    Write-Host "To shut down: docker compose down" -ForegroundColor Gray
} finally {
    Pop-Location
}
