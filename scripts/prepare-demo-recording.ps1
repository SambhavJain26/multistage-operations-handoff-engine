# Prepares the local demo for a recording in one command.
#
# Order matters and is the result of several painful sessions:
#   1. reset Postgres fixtures            (scripts/reset-demo.ps1)
#   2. reapply real vendor contacts       (reset reseeds them to placeholders)
#   3. empty the Airtable operating tables (reset does not touch Airtable, so old rows survive as orphans)
#   4. clear airtable_record_map
#   5. wait for TWO reconciliation passes  (linked records are empty after the first)
#   6. verify board, workflows, tunnel, webhooks
#
# Windows PowerShell 5.1 compatible. No ConvertFrom-Json -Depth, no ternary, no && chaining.

[CmdletBinding()]
param(
  [switch]$SkipAirtable,   # leave Airtable alone. Much faster, but orphans from a previous reset will remain
  [switch]$SkipTunnel,     # skip the Telegram tunnel probe, for a non-Telegram rehearsal
  [int]$ReconcileTimeoutMinutes = 12
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot
$envPath = Join-Path $repoRoot ".env"
$problems = @()
$notes = @()

function Step([string]$text) { Write-Host ""; Write-Host "== $text" -ForegroundColor Cyan }
function Ok([string]$text)   { Write-Host "   ok   $text" -ForegroundColor Green }
function Warn([string]$text) { Write-Host "   WARN $text" -ForegroundColor Yellow; $script:problems += $text }
function Note([string]$text) { Write-Host "   note $text" -ForegroundColor DarkGray; $script:notes += $text }
function Fail([string]$text) { Write-Host "   FAIL $text" -ForegroundColor Red;    $script:problems += $text }

function Get-EnvValue([string]$Name) {
  if (-not (Test-Path -LiteralPath $envPath)) { return "" }
  $line = Get-Content -LiteralPath $envPath | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s*=" } | Select-Object -Last 1
  if (-not $line) { return "" }
  return ($line -replace "^\s*$([regex]::Escape($Name))\s*=\s*", "").Trim().Trim('"').Trim("'")
}

function Invoke-DemoSql([string]$Sql) {
  $out = $Sql | docker exec -i make-ready-postgres psql -U postgres -d make_ready_demo -t -A -v ON_ERROR_STOP=1
  if ($LASTEXITCODE -ne 0) { throw "SQL failed: $Sql" }
  return $out
}

# ---------------------------------------------------------------- 0. runtime

Step "Runtime"

docker version --format '{{.Server.Version}}' 2>&1 | Out-Null
if (-not $?) {
  Fail "Docker engine is not reachable. Start Docker Desktop and run this again."
  Write-Host ""
  Write-Host "NOT READY TO RECORD" -ForegroundColor Red
  exit 1
}
Ok "Docker engine reachable"

$running = docker compose ps --format "{{.Name}}" 2>$null
if (($running -join " ") -notmatch "make-ready-n8n") {
  Write-Host "   starting the stack..."
  docker compose up -d | Out-Null
  Start-Sleep -Seconds 25
}
Ok "make-ready-n8n and make-ready-postgres are up"

# ---------------------------------------------------------------- 1. fixtures

Step "Resetting fixture data"
& (Join-Path $PSScriptRoot "reset-demo.ps1") | Out-Null
Ok "Postgres fixtures reset to the opening state"

# ---------------------------------------------------------------- 2. contacts

Step "Reapplying real vendor contacts"
# reset-demo reseeds vendors with placeholder chat IDs and example.com addresses.
# Without this step no vendor can be messaged and no vendor reply can be matched.
$map = @(
  @{ Name = "Rivera Painting";        Trade = "paint";    Tg = "RIVERA_TELEGRAM_CHAT_ID";    Em = "RIVERA_VENDOR_EMAIL" },
  @{ Name = "Maria's Cleaning Co";    Trade = "clean";    Tg = "MARIAS_TELEGRAM_CHAT_ID";    Em = "MARIAS_VENDOR_EMAIL" },
  @{ Name = "Dale Hutchins";          Trade = "repairs";  Tg = "DALE_TELEGRAM_CHAT_ID";      Em = "DALE_VENDOR_EMAIL" },
  @{ Name = "Statewide Flooring";     Trade = "flooring"; Tg = "STATEWIDE_TELEGRAM_CHAT_ID"; Em = "STATEWIDE_VENDOR_EMAIL" },
  @{ Name = "QuickHaul Junk Removal"; Trade = "trashout"; Tg = "QUICKHAUL_TELEGRAM_CHAT_ID"; Em = "QUICKHAUL_VENDOR_EMAIL" }
)
$statements = @()
foreach ($m in $map) {
  $tg = Get-EnvValue $m.Tg
  $em = Get-EnvValue $m.Em
  if ([string]::IsNullOrWhiteSpace($tg)) { throw "Missing $($m.Tg) in .env" }
  if ([string]::IsNullOrWhiteSpace($em)) { throw "Missing $($m.Em) in .env" }
  $n = $m.Name.Replace("'", "''")
  $statements += "UPDATE vendor SET telegram_chat_id='$($tg.Replace("'","''"))', email_address='$($em.Replace("'","''"))' WHERE name='$n' AND trade='$($m.Trade)' AND is_fixture=true;"
}
Invoke-DemoSql ($statements -join "`n") | Out-Null
$placeholders = (Invoke-DemoSql "SELECT count(*) FROM vendor WHERE is_fixture AND trade <> 'inspect' AND telegram_chat_id LIKE 'placeholder%';").Trim()
if ($placeholders -ne "0") { Fail "$placeholders fixture vendors still hold placeholder chat IDs" } else { Ok "5 vendor Telegram and email contacts restored (values not printed)" }

# ---------------------------------------------------------------- 3. Airtable

if ($SkipAirtable) {
  Step "Airtable"
  Note "Airtable skipped by request. Records from before this reset are still in the base, so counts will not match Postgres."
} else {
  Step "Rebuilding the Airtable mirror"

  $baseId = Get-EnvValue "AIRTABLE_BASE_ID"
  if ([string]::IsNullOrWhiteSpace($baseId)) { throw "Missing AIRTABLE_BASE_ID in .env" }

  $raw = docker exec make-ready-n8n n8n export:credentials --all --decrypted
  if ($LASTEXITCODE -ne 0) { throw "Could not read n8n credentials." }
  $parsed = $raw | ConvertFrom-Json
  $creds = if ($parsed -is [array]) { $parsed } else { @($parsed) }
  $cred = $creds | Where-Object { $_.type -eq "airtableTokenApi" } | Select-Object -First 1
  if (-not $cred) { throw "No Airtable credential found in n8n." }
  $headers = @{ Authorization = "Bearer $($cred.data.accessToken)" }

  $tables = @("Turns", "Stages", "Vendors", "Communications", "Approvals & Deliveries", "Turn Intake")
  $deleted = 0
  foreach ($table in $tables) {
    $enc = [uri]::EscapeDataString($table)
    while ($true) {
      $page = Invoke-RestMethod -Uri "https://api.airtable.com/v0/$baseId/$enc`?pageSize=100" -Headers $headers -TimeoutSec 30
      if (-not $page.records -or $page.records.Count -eq 0) { break }
      $ids = @($page.records | ForEach-Object { $_.id })
      for ($i = 0; $i -lt $ids.Count; $i += 10) {
        $chunk = $ids[$i..([Math]::Min($i + 9, $ids.Count - 1))]
        $qs = ($chunk | ForEach-Object { "records[]=$_" }) -join "&"
        Invoke-RestMethod -Uri "https://api.airtable.com/v0/$baseId/$enc`?$qs" -Headers $headers -Method Delete -TimeoutSec 30 | Out-Null
        $deleted += $chunk.Count
        Start-Sleep -Milliseconds 250
      }
    }
  }
  Ok "Emptied the six operating tables ($deleted records). Table structure untouched."

  Invoke-DemoSql "DELETE FROM airtable_record_map;" | Out-Null
  Ok "Cleared airtable_record_map"

  # Pass 1: records get created. Pass 2: linked records populate, because Stages sync
  # before the Turn and Vendor mappings exist and the link fields are stripped first time.
  Step "Waiting for two reconciliation passes (this is the slow part)"
  $deadline = (Get-Date).AddMinutes($ReconcileTimeoutMinutes)
  $pass1 = $false
  while ((Get-Date) -lt $deadline) {
    $stages = (Invoke-DemoSql "SELECT count(*) FROM airtable_record_map WHERE entity_type='stage';").Trim()
    if ($stages -eq "66") { $pass1 = $true; break }
    Start-Sleep -Seconds 15
  }
  if ($pass1) { Ok "Pass 1 complete, 66 stages mapped" } else { Fail "Pass 1 did not complete within $ReconcileTimeoutMinutes minutes" }

  if ($pass1) {
    $pass2 = $false
    while ((Get-Date) -lt $deadline) {
      Start-Sleep -Seconds 30
      $links = (Invoke-DemoSql "SELECT count(*) FROM airtable_record_map WHERE entity_type IN ('turn','vendor');").Trim()
      $recent = (Invoke-DemoSql "SELECT count(*) FROM airtable_record_map WHERE entity_type='stage' AND last_synced_at > now() - interval '90 seconds';").Trim()
      if ($links -eq "12" -and $recent -eq "0") { $pass2 = $true; break }
    }
    if ($pass2) { Ok "Pass 2 settled, linked records populated" } else { Warn "Pass 2 did not clearly settle. Check the Stages table has Turn and Vendor filled before filming Airtable." }
  }
}

# ---------------------------------------------------------------- 4. verify

Step "Verifying"

$active = (docker exec make-ready-postgres psql -U postgres -d n8n -t -A -c "SELECT count(*) FILTER (WHERE active) FROM workflow_entity;").Trim()
if ($active -eq "7") { Ok "7 of 7 workflows active" } else { Fail "$active of 7 workflows active" }

$leftovers = (Invoke-DemoSql "SELECT (SELECT count(*) FROM outbound_queue) + (SELECT count(*) FROM outbound_delivery) + (SELECT count(*) FROM turn WHERE NOT is_fixture);").Trim()
if ($leftovers -eq "0") { Ok "No leftover approvals, deliveries or non-fixture turns" } else { Warn "$leftovers leftover rows across approvals, deliveries and non-fixture turns" }

if (-not $SkipTunnel) {
  $webhookUrl = (docker exec make-ready-n8n printenv WEBHOOK_URL).Trim()
  $tunnelOk = $false
  try {
    $probe = Invoke-WebRequest -Uri "$webhookUrl/healthz" -UseBasicParsing -TimeoutSec 15
    if ($probe.StatusCode -eq 200) { $tunnelOk = $true }
  } catch { $tunnelOk = $false }
  if ($tunnelOk) {
    Ok "Telegram tunnel responds (host not printed)"
  } else {
    Fail "Telegram tunnel is NOT reachable. Telegram buttons and vendor messages will silently do nothing."
    Write-Host "        fix:  .\scripts\start-demo-telegram-tunnel.ps1" -ForegroundColor Yellow
    Write-Host "        then: docker compose up -d --force-recreate n8n" -ForegroundColor Yellow
  }
} else {
  Note "Tunnel probe skipped by request"
}

Step "Opening board"
$board = Invoke-DemoSql @"
SELECT t.unit_label || ' ' || split_part(t.property_address,' ',2) || ' - ' || ts.stage_name
       || ' - ' || round(extract(epoch FROM now()-ts.activated_at)/3600) || 'h of ' || ts.sla_hours || 'h'
FROM turn_stage ts JOIN turn t ON t.id=ts.turn_id
WHERE ts.status='active'
ORDER BY (CASE WHEN ts.sla_hours>0 AND extract(epoch FROM now()-ts.activated_at)/3600/ts.sla_hours >= 1 THEN 3
               WHEN ts.sla_hours>0 AND extract(epoch FROM now()-ts.activated_at)/3600/ts.sla_hours >= 0.5 THEN 2
               ELSE 1 END) DESC, extract(epoch FROM now()-ts.activated_at) DESC;
"@
$board -split "`n" | Where-Object { $_.Trim() } | ForEach-Object { Write-Host "   $_" }

# ---------------------------------------------------------------- 5. verdict

Write-Host ""
if ($problems.Count -eq 0) {
  Write-Host "READY TO RECORD" -ForegroundColor Green
  if ($notes.Count -gt 0) {
    Write-Host ""
    Write-Host "Skipped by request:" -ForegroundColor DarkGray
    $notes | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkGray }
  }
  Write-Host ""
  Write-Host "Before you hit record:" -ForegroundColor Gray
  Write-Host "  - fixture ages advance in real time, so record soon after this finishes" -ForegroundColor Gray
  Write-Host "  - clear old cards, digests and alerts out of the Telegram chats" -ForegroundColor Gray
  Write-Host "  - sort the Airtable Stages view by Turn then Sequence, or film stages from inside a Turn" -ForegroundColor Gray
  Write-Host "  - fire a fresh digest:" -ForegroundColor Gray
  Write-Host "      docker compose run --rm --no-deps n8n execute --id=demo-manager-operations" -ForegroundColor Gray
  Write-Host "  - stall alerts will fire for the overdue units during business hours. Let them land, then delete them." -ForegroundColor Gray
  exit 0
} else {
  Write-Host "NOT READY. $($problems.Count) issue(s):" -ForegroundColor Red
  $problems | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
  exit 1
}
