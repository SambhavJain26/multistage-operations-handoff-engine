# Stage 4 Intake And Matching

Stage 4 adds controlled intake and inbound normalization only. It does not complete stages from vendor replies, call OpenAI, create outbound drafts, send vendor messages, or add manager decision callbacks.

## Local Import

From the repository root:

```powershell
.\scripts\reset-demo.ps1
.\scripts\import-stage-3-workflows.ps1
.\scripts\import-stage-4-workflows.ps1
.\scripts\check-stage-4.ps1
```

The Stage 4 import script generates fresh workflow exports before import. It activates the generic intake, matcher, router, and `/vendor-in` workflows. The vendor Telegram trigger remains inactive unless `-ActivateTelegram` is passed.

## Configuration

Add these optional values to local `.env`:

```dotenv
VENDOR_IN_DEMO_TOKEN=local-stage-4-vendor-in-token
VENDOR_TELEGRAM_CHAT_ID=
```

`VENDOR_IN_DEMO_TOKEN` authenticates `POST /webhook/vendor-in` through `?token=`, `X-Demo-Token`, or `X-Vendor-In-Token`.

`VENDOR_TELEGRAM_CHAT_ID` is local-only test data. Do not commit a real chat ID.

## Turn Intake

The manager intake form is published through n8n's Form Trigger. Query the registered path when needed:

```powershell
docker exec make-ready-postgres psql -U make_ready_demo -d make_ready_demo -tAc "SELECT ""webhookPath"" FROM webhook_entity WHERE ""workflowId"" = 'wf4-turn-intake' AND method = 'POST' LIMIT 1;"
```

Open the returned path under `http://localhost:5678/form/<path>`.

New turns are inserted with `is_fixture=false`, `status='active'`, 11 stages, and `NOTICE` active immediately. `target_ready_date` defaults to `moveout_date + 5 days` when omitted.

For scripted submission, use `multipart/form-data` and the rendered browser field IDs (`field-0` through `field-10`). n8n maps those back to the configured form fields during execution.

## Generic Vendor Inbound

Example:

```powershell
curl.exe -sS -X POST "http://localhost:5678/webhook/vendor-in" `
  -H "Content-Type: application/json" `
  -H "X-Vendor-In-Token: local-stage-4-vendor-in-token" `
  -d '{"sender_ref":"placeholder_rivera_painting","text":"done with 12b"}'
```

The response includes `accepted`, `event_id`, `outcome`, `envelope`, and `match`. Stage 4 logging records `classification.status='deferred_stage_5'` and `stage_state_mutated=false`.

## Optional Telegram Verification

Telegram requires a public HTTPS `WEBHOOK_URL` in the running n8n container. After changing `.env`, recreate n8n so Compose applies the new environment:

```powershell
docker compose up -d --force-recreate n8n
.\scripts\import-stage-4-workflows.ps1 -ActivateTelegram
```

The import script updates the local fixture Rivera Painting sender mapping to `VENDOR_TELEGRAM_CHAT_ID` for test equivalence. The generic fixture sender remains available through `phone_e164`.

No vendor reply is sent in Stage 4. Unknown, ambiguous, duplicate-like, or photo-only messages notify the manager only when `MANAGER_TELEGRAM_CHAT_ID` was set before import.
