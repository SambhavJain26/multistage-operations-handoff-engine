# Stage 5 Vendor Completion Loop

Stage 5 enables vendor replies to complete matched active stages, create manager-approved outbound drafts, and activate the next vendor only after manager Send.

## Local Import

Regenerate and import the Stage 5 workflow set:

```powershell
.\scripts\import-stage-5-workflows.ps1
```

This imports the Stage 3 board/guard exports, Stage 4 intake/matcher/ingest exports, and the Stage 5 completion/action exports. Vendor and manager Telegram Trigger workflows remain unpublished unless `-ActivateTelegram` is used.

## Local Verification

Run:

```powershell
.\scripts\check-stage-5.ps1
```

The check resets fixture data as needed and verifies:

- `done with 12b` completes Paint and creates one awaiting approval draft for Flooring.
- No vendor send is logged before manager Send.
- Board API shows 12B Flooring as `awaiting_approval`.
- Duplicate completion creates no second draft.
- Edit, Send, Hold, vendor mismatch, low-confidence fallback, guard block, and Cancel paths behave safely.

The local manager action API is:

```text
POST http://localhost:5678/webhook/manager-action
```

Use `X-Demo-Token` with `BOARD_DEMO_TOKEN`. Supported local actions are `SEND`, `EDIT`, `HOLD`, `SKIP`, `SNOOZE`, and `CANCEL`.

## Telegram Verification

Live Telegram delivery is optional and requires:

- Fresh HTTPS `WEBHOOK_URL` pointing to local n8n.
- `MANAGER_TELEGRAM_CHAT_ID`.
- `VENDOR_TELEGRAM_CHAT_ID`.
- Recreated n8n container after changing `.env`.

Then run:

```powershell
.\scripts\import-stage-5-workflows.ps1 -ActivateTelegram
```

Do not record tunnel URLs or chat IDs in committed files.

## Boundaries

- No autonomous vendor sends exist. Send/Edit/Hold are manager actions.
- OpenAI classification uses the Responses API node shape and falls back deterministically if the call fails.
- Drafting is deterministic in the local Stage 5 path and recorded as a fallback draft; model tone rewrite can be hardened during Stage 7 fixture rehearsal if needed.
- Photo-only and unsupported-media handling stay minimal until Stage 6.
