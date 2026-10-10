# Repository Guidelines

This repository is the planning and implementation workspace for a local-first n8n make-ready sequencing AI automation demo. Treat it as an automation project, not a software product, SaaS, or compiled app. Core behavior will live in n8n workflow exports, Postgres schema/state, synthetic fixtures, demo visualization UI, and helper scripts.

## Read Order And Authority

Before changing scope or implementation details, read:

1. `progress-notes.md`: current status, locked decisions, deviations, and open items.
2. `build-plan.md`: staged implementation plan and verification gates.
3. `make-ready-demo-build-plan.md`: controlling detailed automation/workflow/demo spec.
4. `03-make-ready-coordination.md` and `foundation-3-turnover-makeready.md`: background only.

If documents conflict, prefer the newest decision in `progress-notes.md`, then update stale docs instead of guessing.

## Project Structure

Current files are planning docs only. When implementation begins, use:

- `n8n-workflows/`: importable workflow JSON exports, named like `wf-3-board-api.json`.
- `db/postgres/`: schema, migrations, seed SQL, reset SQL.
- `fixtures/airtable-schema.json`: typed Airtable manager-workspace contract; no custom board or simulator assets.
- `scripts/`: setup, import/export, reset, fixture, and verification helpers.
- `fixtures/`: F01-F20 payloads, expected outputs, demo photos.
- `prompts/`: classification and drafting prompts/schemas if kept outside workflow JSON.
- `docs/`: runbooks, production caveats, demo notes.
- `tmp/` and `data/`: generated local artifacts only; keep ignored once created.

Use lowercase hyphenated filenames. Use `snake_case` for database columns and JSON fields unless an external API requires otherwise.

## Local Services And Commands

Expected local services are n8n at `http://localhost:5678`, Postgres on `127.0.0.1:5432`, and the visualization board on a local static server. Telegram testing requires a temporary HTTPS tunnel into local n8n; do not use a VPS/domain/Caddy until production or paid pilot readiness.

Useful commands:

- `rg --files`: list repository files.
- `rg "term" .`: search docs and future source.
- `Get-Content -Raw <file>`: read docs/scripts without truncation.
- `git status --short`: check worktree state if git is initialized.
- `docker images`: check available images before pulling new ones.
- `docker compose config`: validate Compose configuration.
- `docker compose ps`: inspect service status.
- `docker compose logs n8n`: inspect n8n startup/import/runtime failures.
- `Get-Content -Raw .\n8n-workflows\<file>.json | ConvertFrom-Json | Out-Null`: validate workflow JSON.
- `node concept-brief/scripts/render-brief.cjs`: render solution brief template and validate layout.
- `node concept-brief/scripts/render-brief.cjs --data <file.json>`: render personalized prospect solution brief PDF.

Do not assume Docker images, API keys, Telegram bots, OpenAI credentials, tunnel accounts, or n8n credentials already exist. Document missing prerequisites before depending on them.

Because `db/postgres` is mounted into `/docker-entrypoint-initdb.d`, do not put app schema or seed `.sql` files at the top level of `db/postgres`; fresh Postgres volumes may auto-run them against the admin bootstrap database. Keep app SQL in subdirectories such as `db/postgres/migrations/` and run it explicitly against `make_ready_demo`.

## Architecture Rules

- n8n orchestrates workflows; Postgres is durable state.
- Do not use Google Sheets or n8n Data Tables for core state.
- Airtable is the manager-facing mirror and turn-intake form. Postgres remains authoritative; Airtable sync failures must never change sequencing state.
- Use two Telegram bots: vendor-facing and manager-facing.
- Vendor messages arrive through Telegram, email, or the generic inbound API. The manager chooses the outbound channel per approval with `Email`, `Message`, or `Both`.
- All manager alerts, approvals, digests, and controls stay in Telegram.
- Approval cards always show all three channel buttons. Choosing a channel the vendor has no destination for records `configuration_blocked` and alerts the manager; it never sends silently. After one channel succeeds, activate the stage; retry only a failed second channel.
- Queue finalization must compare sent deliveries against the number of channels actually authorized. Never hardcode a two-channel assumption.
- Build the generic `/vendor-in` webhook so Telegram is only one channel.
- Use HTTP Request for OpenAI Responses API calls requiring strict JSON schema, exact model IDs, raw errors, or fallback control.
- Default model is `gpt-5.6-luna`; use `gpt-5.6-terra` or `gpt-5.4-mini` only if fixture-tested draft quality requires it.
- Never add autonomous outbound vendor messaging. Draft only; the manager releases it by choosing a channel. Ignoring a card is a valid decision and leaves the draft as an open approval.
- Reuse one deterministic sequence guard and one deterministic unit matcher everywhere.

## n8n Workflow Rules

Prefer editable workflow JSON exports over manual-only UI changes. Name every node descriptively; never leave defaults like `Code`, `If`, `Set`, or `HTTP Request`.

Before capturing workflow canvases for a demo or work sample, use n8n's Tidy Up broom on every workflow, then Zoom to Fit. Inspect the loaded canvas to confirm every node and connection is visible, and capture enlarged sections for labels that are too small in the full view.

Capture enlarged sections again at native editor zoom; do not enlarge crops from a Zoom to Fit screenshot. Pair saved execution evidence with the originating input, manager release and observable business output where applicable. Crop unrelated UI and flatten privacy redactions into the image pixels before embedding, then verify that PDF images contain only the sanitized pixels and that links, attachments and metadata contain no private details.

Use n8n credentials by name only. Never hardcode bearer tokens, Telegram bot tokens, OpenAI keys, tunnel URLs, or secrets in workflow JSON.

Known n8n gotchas to account for:

- Active webhooks may use the active workflow snapshot, not the editor draft.
- Imported Webhook nodes in local n8n may need a fixed top-level `webhookId` when the production URL must use a stable path.
- After import/activation, restart or reload active workflows if needed, then verify with a real execution or database row.
- Respond to Webhook status-code expressions may be unreliable in some local n8n versions; prefer separate Respond nodes with literal status codes when 404/200 behavior matters.
- Imported workflow `id` values must fit n8n database limits; keep generated IDs under 36 characters.
- Keep imported workflow IDs stable for Execute Sub-workflow references and webhook records, but use prospect-friendly visible workflow names in n8n. Stage numbers such as `WF-3` belong in internal IDs/files only, not in final demo display names.
- Strict IF nodes require boolean values. Normalize truthy strings or draft bodies to booleans in Code nodes before routing.
- Telegram Trigger needs a public HTTPS `WEBHOOK_URL`; localhost will not work.
- Telegram `getUpdates` cannot be used while that bot has an active webhook. To identify already-configured project chats without disrupting live delivery, use `getChat` against the local configured chat IDs instead.
- Publish/activate Telegram Trigger workflows only after real chat IDs and `WEBHOOK_URL` are set.
- Local Cloudflare Tunnel runs, when needed, should stay as a temporary sidecar container or host process outside `make-ready-n8n`. Do not install or run cloudflared inside the n8n container; remove the temporary tunnel when live Telegram testing is done.
- Docker Compose `restart` does not apply `.env` changes to existing containers. After changing `WEBHOOK_URL` for Telegram testing, run `docker compose up -d --force-recreate n8n` before import/activation.
- Telegram Trigger node names should avoid spaces; space-bearing names can produce webhook-path mismatches.
- Telegram inline keyboards should use explicit fixed-collection rows/buttons. Do not pass the whole `inlineKeyboard` object as a single expression.
- Telegram `answerQuery` responses may not preserve upstream callback context; reattach chat/message IDs before edit-message or audit nodes need them.
- Code nodes may be sandboxed; do not assume `process.env` exists.
- Postgres nodes that update then reselect rows must return every field later expressions use.
- Postgres nodes must preserve control fields such as `test_mode`, source channel, message IDs, and routing outcome when downstream dispatch depends on them.
- Optional Postgres steps that must allow downstream work need `alwaysOutputData`.
- Execute Sub-workflow nodes may emit no downstream items when the called workflow exits through routed branches. For ingestion connectors, treat the core workflow as a database-writing side effect and reselect by stable identifiers before post-processing.
- In n8n 2.29 local regular deployment mode, `n8n import:workflow --activeState=fromJson` is rejected. Import workflows inactive, publish required workflow IDs with `n8n publish:workflow --id=<id>`, then restart n8n.
- Imported Execute Sub-workflow nodes are most reliable with type version 1 and a plain `workflowId` string. Newer workflow-selector JSON can import but fail at runtime with "No information about the workflow to execute found."
- Execute Sub-workflow calls that load database context must explicitly carry caller metadata, such as `actor_id`, `channel`, Telegram callback IDs, and override fields, through the load query. Otherwise downstream audit rows and callback answers can silently fall back to defaults.
- `$env` access can be blocked inside n8n Code nodes and expressions. For local demo workflow exports, prefer import-time substitution into temporary JSON copies instead of runtime `$env` lookups.
- Import-time substitution of real Telegram chat IDs must be gated behind the explicit Telegram activation flag. Non-Telegram local imports should leave manager/vendor chat placeholders intact so fixture checks do not accidentally send live Telegram messages when `.env` still contains real chat IDs.
- After n8n restart, active webhook registration can lag behind container readiness; wait for webhook records or a real successful HTTP probe before verification.
- Form Trigger submissions can produce generic keys like `field-0`; normalize before SQL or AI steps.
- Direct scripted Form Trigger submissions must use `multipart/form-data` and the rendered field IDs such as `field-0`, not only semantic field names.
- Imported Form Trigger workflows may register under workflow/node-prefixed form paths. Query n8n's webhook records or test the registered `/form/...` path after import.
- Form Trigger workflows should use the Form completion step, not Respond to Webhook.
- AI structured output may be wrapped; downstream code should handle wrapped and direct JSON shapes.
- Airtable Interface setup is presentation configuration and remains a documented manual step after API schema provisioning. Managers get Interface-only access and use the intake form as their only Airtable write surface.
- Airtable Web API record mutations should batch at most 10 records and use typed values. Keep durable external-record mappings and payload hashes for idempotent reconciliation.
- Airtable select values must exactly match manifest choices, and linked-record IDs may require a later reconciliation pass after parent mappings are first created. Use `$input.all()` in Code nodes; do not rely on the legacy `items` variable.
- Code embedded inside a JavaScript workflow generator needs doubled backslashes for emitted regex and newline escapes. Compile every generated Code node before accepting the export.
- PostgreSQL data-modifying CTEs share one statement snapshot. Do not insert a row in one CTE and then rely on updating that same row in a later CTE; generate required tokens and subjects before the insert.
- Email replies must resolve by `In-Reply-To` or `[MR-...]` token before sender/unit fallback. Thread context never overrides the assigned-vendor sender check.
- A local single-inbox email demo may use the same Gmail address for the automation and fixture vendors only when self-originated messages without `In-Reply-To` are ignored. In that mode, test replies must use the email client's Reply action. Do not use this shortcut for a client mailbox.
- Dual delivery needs one durable row per channel. Never infer success for both channels from one provider response, never repeat a successful channel during retry, and refresh the failed channel's destination from the current vendor record before retrying.
- Repeated live-model rehearsal can expose small variance. Prefer deterministic post-model boundaries and document every boundary in `progress-notes.md`.
- Error Workflow verification should use durable signals such as `event_log` rows or execution records, not only webhook HTTP status. In local n8n 2.29, a Webhook workflow that throws before a Respond node can still return HTTP 200 with an empty body while the Error Workflow fires correctly.
- Stage 7 live fixture rehearsal requires distinct Telegram sender chat IDs per vendor identity. Do not reuse the manager/prospect chat as a vendor sender or builder alert target.
- Stage 7 fixture resets reseed vendor chat IDs back to placeholders. Any guided live Telegram runner must reapply the real fixture vendor group chat IDs after every reset before prompting for vendor messages.
- When substituting placeholder chat IDs at import time, do not compare the configured value to the substituted literal in downstream SQL guards. Use a placeholder pattern check such as `stage7-%-missing`; otherwise a real builder chat ID can be treated as missing and suppress builder alerts.
- Manager Telegram callback workflows must preserve `telegram_callback_query_id` through any Execute Sub-workflow and SQL result before calling Telegram `answerQuery`; dropping it causes a false `Bad Request: query is too old... or query ID is invalid` error after the state mutation succeeds.
- One-off `n8n execute` commands can collide with the running task broker. Prefer isolated `docker compose run --rm --no-deps n8n execute ...` or stop the service before CLI execution, then restart it.
- In PowerShell, piping JSON into native commands can introduce a UTF-8 BOM. If `n8n import:workflow` fails with an unexpected token at the start, verify the file is clean and import through Bash or another BOM-safe path.
- Telegram Trigger nodes need a fixed top-level `webhookId` just like Webhook nodes. Without it n8n derives an unstable path and secret token, and after a restart every real Telegram update is rejected with `Wrong response from the webhook: 403 Forbidden` while the tunnel, workflows, and logs all look healthy. Diagnose from `getWebhookInfo`, not the n8n log.
- `scripts/reset-demo.ps1` resets Postgres only. Airtable keeps previously synced records, and because reset changes Postgres IDs the old rows survive as orphans. For a clean mirror: reset Postgres, reapply vendor contacts, delete records in the six Airtable operating tables, clear `airtable_record_map`, then let reconciliation rebuild.
- A full Airtable rebuild needs two reconciliation passes. Stages sync before Turn and Vendor mappings exist, so link fields are stripped on the first pass and populate on the next when the payload hash changes.
- n8n Code nodes default to run-once-for-all-items. A node that reads `$json` or `$('Node').item` sees only the first input item. When an upstream HTTP node emits one response per batch, walk `$input.all()` and pair against `$('Node').all()` by index, or the later batches are silently dropped.
- n8n `emailReadImap` in `simple` format exposes raw headers under `metadata`, not `headers` or `headerLines`. Header lookups must check `metadata` or `In-Reply-To` and `Message-ID` read as empty, which makes the single-inbox guard ignore genuine vendor replies.
- A `trycloudflare` quick tunnel can collapse while `cloudflared` keeps running. The hostname stops resolving, n8n keeps serving the stale `WEBHOOK_URL`, and Telegram callbacks disappear with no error surfaced anywhere. Probe `WEBHOOK_URL/healthz` before any live Telegram step and treat a failed probe, not the user's button press, as the first suspect.
- `scripts/import-make-ready-workflows.ps1` exits 1 under Windows PowerShell 5.1 even when import and publish succeed, because `docker compose restart` writes progress to stderr and PowerShell wraps it as `NativeCommandError`. Verify activation from the n8n database rather than trusting the exit code.
- A workflow can sit inactive in `workflow_entity` with nothing in the n8n log to show for it, because n8n only logs workflows it tries to activate. The symptom is silence: vendor messages and button presses do nothing. Check `SELECT id, active FROM workflow_entity` rather than reading logs, then `n8n publish:workflow --id=<id>` and restart. `scripts/prepare-demo-recording.ps1` names the offending IDs on failure.
- `ConvertFrom-Json -Depth` is PowerShell 7 only. Repo scripts must omit it so they run under Windows PowerShell 5.1.
- Reset applies migrations in lexical order before fixture cleanup. If a later stage has already written rows with expanded enum/check values, older migrations must not temporarily narrow those constraints during re-application.

## Testing And Verification

Use the F01-F20 fixtures in `make-ready-demo-build-plan.md`. Each stage must satisfy its "Done when" checks in `build-plan.md` before moving forward.

Core invariants:

- Manual and vendor completions use the same guard.
- Before asking the user to press a Telegram control or perform any external action, verify that the exact control/action is currently available in the live destination. Do not infer a newly added control is visible from workflow source alone; confirm it through a live provider result, stored message record, or user-visible evidence.
- Ambiguous unit matches ask the manager instead of guessing.
- Duplicate replies do not double-advance or double-draft.
- OpenAI failure falls back safely.
- Reset scripts wipe fixture data only and abort when non-fixture prospect data exists.

Fixture reports should record schema validity, branch taken, safety-boundary behavior, latency, token usage, and estimated OpenAI cost.

Record completed checks, failures, and deviations in `progress-notes.md`.

## Security And Configuration

Never commit `.env`, credentials, real client data, prospect CSVs, database dumps with non-fixture rows, tunnel URLs, Telegram tokens, OpenAI keys, or completion photos. Use placeholders in examples.

Before adding or pulling Docker images, check local images first. Build destructive reset paths for local fixture data only. Never run reset/delete scripts against client infrastructure, production databases, or production workflows.

## Commit And Completion Guidelines

Use short imperative or conventional commits, for example `docs: update local tunnel guidance` or `feat: add sequence guard fixtures`.

Documentation deliverables default to `.md`. Do not create DOCX, PDF, slides, or other derivative formats unless the user explicitly requests that format.

Before finishing implementation work, decide whether the task exposed a durable command, workaround, gotcha, or rule. If yes, update `CLAUDE.md`, `AGENTS.md` (both files must stay identical apart from this note), and `progress-notes.md`. For documentation-only planning edits, do not auto-commit unless the user asks.

After every completed task, commit and push changes to `main`. If push fails because no remote or authentication is configured, report that clearly and include the local commit hash if a commit was created. Never commit secrets, local data, generated temp output, or n8n credential exports.
