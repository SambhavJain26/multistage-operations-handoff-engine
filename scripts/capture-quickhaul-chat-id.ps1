[CmdletBinding()]
param(
  [string]$MessageText = "QuickHaul ready"
)

$ErrorActionPreference = "Stop"
$escaped = $MessageText.Replace("'", "''")
$sql = @"
SELECT sender_ref
FROM communication_message
WHERE channel = 'telegram'
  AND lower(normalized_text) = lower('$escaped')
ORDER BY received_at DESC
LIMIT 1;
"@
$chatId = $sql | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -tA
if ($LASTEXITCODE -ne 0) { throw "Could not query the demo database." }
$chatId = (($chatId | Select-Object -First 1) -as [string]).Trim()
if ($chatId -notmatch '^-?[0-9]+$') { throw "No Telegram message matching '$MessageText' has reached Vendor Communications yet." }
$update = "UPDATE vendor SET telegram_chat_id='$chatId' WHERE name='QuickHaul Junk Removal' AND trade='trashout';"
$update | docker exec -i make-ready-postgres psql -q -U make_ready_demo -d make_ready_demo -v ON_ERROR_STOP=1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Could not map QuickHaul to the captured Telegram chat." }
Write-Host "QuickHaul Telegram chat mapping captured."
