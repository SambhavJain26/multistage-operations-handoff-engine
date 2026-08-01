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
- `board/`: demo visualization files such as `index.html` and `sim.html`; not a production app surface.
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

Do not assume Docker images, API keys, Telegram bots, OpenAI credentials, tunnel accounts, or n8n credentials already exist. Document missing prerequisites before depending on them.

Because `db/postgres` is mounted into `/docker-entrypoint-initdb.d`, do not put app schema or seed `.sql` files at the top level of `db/postgres`; fresh Postgres volumes may auto-run them against the admin bootstrap database. Keep app SQL in subdirectories such as `db/postgres/migrations/` and run it explicitly against `make_ready_demo`.

## Architecture Rules

- n8n orchestrates workflows; Postgres is durable state.
- Do not use Google Sheets or n8n Data Tables for core state.
- Use two Telegram bots: vendor-facing and manager-facing.
- Build the generic `/vendor-in` webhook so Telegram is only one channel.
- Use HTTP Request for OpenAI Responses API calls requiring strict JSON schema, exact model IDs, raw errors, or fallback control.
- Default model is `gpt-5.6-luna`; use `gpt-5.6-terra` or `gpt-5.4-mini` only if fixture-tested draft quality requires it.
- Never add autonomous outbound vendor messaging. Draft only; manager approves Send/Edit/Hold.
- Reuse one deterministic sequence guard and one deterministic unit matcher everywhere.

## n8n Workflow Rules

Prefer editable workflow JSON exports over manual-only UI changes. Name every node descriptively; never leave defaults like `Code`, `If`, `Set`, or `HTTP Request`.

Use n8n credentials by name only. Never hardcode bearer tokens, Telegram bot tokens, OpenAI keys, tunnel URLs, or secrets in workflow JSON.

Known n8n gotchas to account for:

- Active webhooks may use the active workflow snapshot, not the editor draft.
- Imported Webhook nodes in local n8n may need a fixed top-level `webhookId` when the production URL must be a clean path such as `/webhook/board`.
- After import/activation, restart or reload active workflows if needed, then verify with a real execution or database row.
- Respond to Webhook status-code expressions may be unreliable in some local n8n versions; prefer separate Respond nodes with literal status codes when 404/200 behavior matters.
- Imported workflow `id` values must fit n8n database limits; keep generated IDs under 36 characters.
- Strict IF nodes require boolean values. Normalize truthy strings or draft bodies to booleans in Code nodes before routing.
- Telegram Trigger needs a public HTTPS `WEBHOOK_URL`; localhost will not work.
- Publish/activate Telegram Trigger workflows only after real chat IDs and `WEBHOOK_URL` are set.
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
- After n8n restart, active webhook registration can lag behind container readiness; wait for webhook records or a real successful HTTP probe before verification.
- Form Trigger submissions can produce generic keys like `field-0`; normalize before SQL or AI steps.
- Direct scripted Form Trigger submissions must use `multipart/form-data` and the rendered field IDs such as `field-0`, not only semantic field names.
- Imported Form Trigger workflows may register under workflow/node-prefixed form paths. Query n8n's webhook records or test the registered `/form/...` path after import.
- Form Trigger workflows should use the Form completion step, not Respond to Webhook.
- AI structured output may be wrapped; downstream code should handle wrapped and direct JSON shapes.
- Board and detail pages are demo visualizations by default. Show model outputs, guard outcomes, and event details in plain language first; keep raw JSON behind collapsed technical audit controls.
- Repeated live-model rehearsal can expose small variance. Prefer deterministic post-model boundaries and document every boundary in `progress-notes.md`.
- One-off `n8n execute` commands can collide with the running task broker. Prefer isolated `docker compose run --rm --no-deps n8n execute ...` or stop the service before CLI execution, then restart it.
- In PowerShell, piping JSON into native commands can introduce a UTF-8 BOM. If `n8n import:workflow` fails with an unexpected token at the start, verify the file is clean and import through Bash or another BOM-safe path.

## Testing And Verification

Use the F01-F20 fixtures in `make-ready-demo-build-plan.md`. Each stage must satisfy its "Done when" checks in `build-plan.md` before moving forward.

Core invariants:

- Manual and vendor completions use the same guard.
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

Before finishing implementation work, decide whether the task exposed a durable command, workaround, gotcha, or rule. If yes, update `AGENTS.md` and `progress-notes.md`. For documentation-only planning edits, do not auto-commit unless the user asks.

After every completed task, commit and push changes to `main`. If push fails because no remote or authentication is configured, report that clearly and include the local commit hash if a commit was created. Never commit secrets, local data, generated temp output, or n8n credential exports.
