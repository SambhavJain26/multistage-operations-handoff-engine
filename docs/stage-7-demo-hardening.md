# Stage 7 Demo Hardening

Stage 7 turns the local Stage 3-6 build into a rehearsable demo package. It does not add production SMS, PMS integration, or autonomous vendor messaging.

## Import

Local static/error-handler import:

```powershell
.\scripts\import-stage-7-workflows.ps1
```

Live Telegram fixture import:

```powershell
.\scripts\import-stage-7-workflows.ps1 -ActivateTelegram
```

Live import requires:

- Fresh HTTPS `WEBHOOK_URL` pointing to local n8n.
- Recreated n8n container after changing `.env`: `docker compose up -d --force-recreate n8n`.
- `MANAGER_TELEGRAM_CHAT_ID`.
- `BUILDER_TELEGRAM_CHAT_ID`, separate from the manager/prospect chat.
- Distinct `RIVERA_TELEGRAM_CHAT_ID`, `MARIAS_TELEGRAM_CHAT_ID`, `DALE_TELEGRAM_CHAT_ID`, and `STATEWIDE_TELEGRAM_CHAT_ID`.

`VENDOR_TELEGRAM_CHAT_ID` remains supported as Rivera's fallback for older local setup.

## Verification

Static wiring and error-handler smoke:

```powershell
.\scripts\check-stage-7.ps1
```

Full guided live run:

```powershell
.\scripts\check-stage-7.ps1 -RequireTelegram
```

The live checker prompts for inbound Telegram messages because Telegram Bot API webhooks cannot impersonate vendor users. The script verifies results in Postgres and writes a timestamped report under ignored `data/stage-7-reports/`.

Before accepting Stage 7, run the existing gates, then finish with a fresh Stage 7 import/check:

```powershell
.\scripts\check-stage-3.ps1
.\scripts\import-stage-4-workflows.ps1
.\scripts\check-stage-4.ps1
.\scripts\import-stage-5-workflows.ps1
.\scripts\check-stage-5.ps1
.\scripts\import-stage-6-workflows.ps1
.\scripts\check-stage-6.ps1
.\scripts\import-stage-7-workflows.ps1 -ActivateTelegram
.\scripts\check-stage-7.ps1 -RequireTelegram
```

Do not run the Stage 4-isolated checker as a final gate after the fully composed Stage 7 import. Stage 4 expects `/vendor-in` to stop at `matched_logged`; Stage 7 correctly continues the same input into Stage 5 completion and manager approval.

## Failure Handling

Stage 7 adds `WF-7 Builder Error Handler` and links all Stage 3-7 demo workflows to it through `settings.errorWorkflow`.

Behavior:

- Every handled workflow failure writes one `workflow_error` event to `event_log`.
- A concise Telegram alert is sent only to `BUILDER_TELEGRAM_CHAT_ID` when configured.
- Manager/prospect chats do not receive infrastructure errors.

The error-smoke webhook is local-only demo infrastructure:

```text
POST http://localhost:5678/webhook/stage-7-error-smoke?token=<BOARD_DEMO_TOKEN>
```

It intentionally throws so the handler path can be verified.
In local n8n 2.29, this webhook can still return HTTP 200 with an empty body when the response-node path fails; use the `workflow_error` event row as the verification signal.

## Rehearsal Checklist

Run three timed rehearsals from reset. Target under five minutes without rushing.

- Open `http://localhost:8080/board/index.html` or the static server URL used locally.
- Open the Rivera vendor Telegram chat before the call.
- Keep the manager phone/chat visible for Send/Edit/Hold approval.
- Approval cards appear in the Telegram chat configured by `MANAGER_TELEGRAM_CHAT_ID`; if that ID is a direct user chat, the card is not in the manager group.
- Keep `board/sim.html` ready for the channel-independence beat.
- Say the scope limitations out loud: no PMS, no SMS in demo, no autonomous sends, no photo inspection, no deposit assessment.
- If Telegram fails, do not debug live; pivot to board/manual guard controls.
- If n8n or Docker fails, play the offline recording.

## Offline Recording

Record a 90-second successful run with no narration and store it locally outside the repo, for example:

```text
data/local-recordings/stage-7-fallback-demo.mp4
```

Do not commit recordings, tunnel URLs, chat IDs, or credential exports.

## Rebuild Path

A fresh local rebuild needs:

- Repo files.
- `.env` based on `.env.example`.
- n8n credentials named `Make-Ready Postgres`, `Make-Ready OpenAI`, `Make-Ready Vendor Telegram Bot`, and `Make-Ready Manager Telegram Bot`.
- `docker compose up -d`.
- `.\scripts\reset-demo.ps1`.
- `.\scripts\import-stage-7-workflows.ps1` or `.\scripts\import-stage-7-workflows.ps1 -ActivateTelegram`.

For live Telegram, set a fresh tunnel URL in `.env`, recreate n8n, import with `-ActivateTelegram`, then run `check-stage-7.ps1 -RequireTelegram`.
