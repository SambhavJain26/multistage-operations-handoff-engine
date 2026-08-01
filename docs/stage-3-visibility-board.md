# Stage 3 Visibility Board And Manual Control

Stage 3 builds the local-first board and guarded manual completion path. It does not parse vendor replies, call OpenAI, send vendor messages, handle photos, or add production authentication.

## Local Config

Add these values to `.env` and restart n8n:

```text
BOARD_DEMO_TOKEN=local-stage-3-demo-token
BOARD_ALLOWED_ORIGIN=http://localhost:8080
MANAGER_TELEGRAM_CHAT_ID=
```

Use a stronger `BOARD_DEMO_TOKEN` for any non-local review window. The static board uses the query token so browser requests avoid CORS preflight.

## Import Workflows

Generate and import the Stage 3 workflows:

```powershell
.\scripts\import-stage-3-workflows.ps1
```

This activates the board and manual-completion webhooks only. It keeps Telegram digest workflows inactive unless explicitly requested.

To activate the manager digest and callback router:

1. Send a message to the manager bot.
2. Run `.\scripts\read-telegram-chat-ids.ps1`.
3. Set `MANAGER_TELEGRAM_CHAT_ID` in `.env`.
4. Set `WEBHOOK_URL` to the active HTTPS Cloudflare Tunnel origin.
5. Restart n8n.
6. Run:

```powershell
.\scripts\import-stage-3-workflows.ps1 -ActivateTelegram
```

Do not activate the Telegram Trigger while `WEBHOOK_URL` is `http://localhost:5678`.

## Board

Serve the static board:

```powershell
python -m http.server 8080 --directory board
```

Open:

```text
http://localhost:8080/?token=local-stage-3-demo-token
```

The board polls `http://localhost:5678/webhook/board` every 10 seconds, stores the last-known state in local storage, and shows a reconnecting strip instead of going blank when n8n is unavailable.

## Verification

From a clean fixture reset and imported workflows:

```powershell
.\scripts\check-stage-3.ps1
```

The check verifies:

- unauthorized board API returns `401`;
- authorized board API returns six active turns;
- 12B is the first red stalled card;
- 14A Deep Clean is blocked because Repairs is still open;
- 12B Paint completes with `completed_via='manual'`;
- 12B advances to Flooring, because Flooring is not skipped in the seed data;
- vendor reply rate drops after the manual completion.
