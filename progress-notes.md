# Make-Ready Sequencing Progress Notes

This file is the running handoff record for future sessions. Read it before starting any stage.

## Current Status

- Stage 2 is complete.
- Local runtime, credentials, schema, stage template, and fixture seed data have been verified.
- `build-plan.md` created with eight staged sessions.
- Git repository initialized on `main`; remote target is private GitHub repo `make-ready-sequencing`.
- Framing corrected: this is an AI automation demo, not a named software/SaaS product. Any UI is only for demo visualization.

## Source Documents Read

- `03-make-ready-coordination.md`
- `foundation-3-turnover-makeready.md`
- `make-ready-demo-build-plan.md`

## Stage Progress

| Stage | Name | Status | Notes |
|---|---|---|---|
| 1 | Local Environment And Tooling Setup | Complete | Docker Compose stack, n8n, Postgres, placeholder board, docs, smoke scripts, n8n credentials, OpenAI model check, Telegram `getMe`, Postgres credential execution, and Cloudflare Tunnel reachability are verified. |
| 2 | Data Model, Stage Template, And Fixtures | Complete | Schema, stage template, Cedar Ridge fixture seed, reset/load scripts, prospect CSV example, Telegram chat-ID helper, and Stage 2 verification checks added. |
| 3 | Visibility Board And Manual Control | Not started | Core 0% vendor-reply path. |
| 4 | Intake, Channel Normalization, And Matching | Not started | Inbound paths should log only until completion loop is built. |
| 5 | Vendor Completion Loop With Human Approval | Not started | Must preserve manager approval for all outbound vendor messages. |
| 6 | Stall Detection, Digest, Simulator, And Photos | Not started | Absence detector and demo companion surfaces. |
| 7 | Full Fixture Testing And Demo Hardening | Not started | F01-F20, fallback behavior, rehearsal, recording, export/rebuild. |
| 8 | Production Pilot Readiness | Not started | Client-owned VPS, Twilio/10DLC, consent, STOP handling, backups, contract exclusions. |

## Decisions Locked For Now

- Use Postgres for demo state, not Google Sheets.
- Do not assign a product name. Refer to the work as the make-ready sequencing AI automation demo.
- Build and test the demo locally by default.
- Keep VPS, domain, and Caddy for production/pilot deployment only.
- Use a temporary HTTPS tunnel, such as Cloudflare Tunnel or ngrok, only when testing Telegram triggers against local n8n.
- Use two Telegram bots for demo: vendor-facing and manager-facing.
- Build a generic inbound webhook so the Telegram demo can prove channel independence.
- No PMS integration in the demo.
- No production SMS until a client exists and 10DLC can be registered under the client's identity.
- No autonomous outbound vendor messages. Draft only; manager releases.
- Manager approval must include Send, Edit, and Hold for draft vendor messages.
- Manager-only controls must include Cancel as well as Override, Skip, Snooze, and Done.
- Manual manager stage advance is required before vendor automation.
- The sequence guard must be deterministic and reused by manual and vendor paths.
- The unit matcher must be deterministic and reused by all inbound paths.
- Use direct HTTP Request nodes for OpenAI Responses API calls, not n8n's built-in OpenAI/LangChain nodes, when strict schema control or raw error handling matters.
- Default to `gpt-5.6-luna` for both classification and short draft rewriting unless live testing shows draft quality is insufficient.
- Keep `gpt-5.6-terra` or `gpt-5.4-mini` as draft-quality fallbacks, not defaults.
- Use only core n8n nodes; no community nodes in the demo.
- Stage 1 tunnel default is Cloudflare Tunnel.
- Stage 1 demo timezone is `America/Phoenix`.
- Stage 1 secret handling uses committed `.env.example`, an ignored local `.env`, scripted local Postgres credential import, and manual n8n credentials for external APIs.
- Surface vendor reply rate and auto-handled rate in the board header, weekly digest, and manager `/health` command.
- After every completed task, commit and push changes to `main` unless blocked; report the commit hash or push failure.

## Open Questions / Validation Items

- Run `scripts/read-telegram-chat-ids.ps1` again after sending messages to both Telegram bots; no updates were present during Stage 2 verification.
- Re-check `WEBHOOK_URL` against an active Cloudflare Tunnel when Telegram Trigger workflows are built and activated; no Telegram Trigger workflows exist yet.
- Confirm the domain/VPS provider only before Stage 8 production/pilot readiness.
- Verify Property Meld sequencing behavior before making competitive claims in sales.
- Check whether the prospect is in a metro where managed make-ready providers like Lula materially change the objection.
- Verify state-specific SMS laws before production SMS for any real client.
- Get legal advice before signing any data processing agreement involving India-US processing.

## Deviations From Original Documents

- The original source spec allowed automatic next-vendor notification; this plan follows the later demo build correction and requires manager approval.
- The original source spec suggested Google Sheets for demos; this plan follows the later demo build correction and uses Postgres.
- The original source spec framed vendor reply behavior as a product gate; this plan treats it as an automation gate while preserving a board/manual-control automation path at 0% vendor reply.

## Outstanding Risks

- Vendor reply rate may be too low for automation value.
- Telegram is only a demo stand-in; US vendors should not be expected to adopt it in production.
- The sequence-enforcement differentiator against competitors is not yet verified.
- OpenAI model availability/pricing may differ from the researched defaults and must be checked live.
- Telegram reliability during local testing depends on the tunnel and `WEBHOOK_URL`; a bad value can silently break Telegram triggers.

## Stage 1 Implementation Notes

- Added `docker-compose.yml` with `n8n` and `postgres` services only; no Caddy or business workflows.
- Added `db/postgres/00-init-databases.sh`, which creates separate `n8n` and `make_ready_demo` databases/roles on first Postgres boot.
- Added `.env.example`; an ignored local `.env` was created for this machine with dev-only local passwords so Docker Compose commands work.
- Added placeholder board at `board/index.html`; it is intentionally not the Stage 3 board UI.
- Added Stage 1 setup guide at `docs/stage-1-local-setup.md`.
- Added helper scripts:
  - `scripts/check-stage-1.ps1`
  - `scripts/import-postgres-credential.ps1`
  - `scripts/openai-model-check.ps1`
  - `scripts/telegram-getme-check.ps1`
- Verified:
  - `docker compose config` succeeds.
  - `docker compose up -d` starts `make-ready-postgres` and `make-ready-n8n`.
  - n8n health and editor HTTP checks return 200 at `http://localhost:5678`.
  - Postgres is reachable on `127.0.0.1:5432`.
  - `make_ready_demo` role can run `SELECT 1` against the `make_ready_demo` database after the neutral naming correction.
  - n8n credential `Make-Ready Postgres` imported with credential type `postgres`.
  - n8n temporary smoke workflow executed `SELECT 1` through `Make-Ready Postgres`; the smoke workflow was removed after verification.
  - n8n credential records confirmed in the local n8n database:
    - `Make-Ready OpenAI` (`openAiApi`)
    - `Make-Ready Vendor Telegram Bot` (`telegramApi`)
    - `Make-Ready Manager Telegram Bot` (`telegramApi`)
  - OpenAI `GET /v1/models` succeeds through `Make-Ready OpenAI`; `gpt-5.6-luna` is available and remains selected for both classification and drafting.
  - Telegram `getMe` succeeds for `@make_ready_vendor_demo_bot`.
  - Telegram `getMe` succeeds for `@make_ready_manager_demo_bot`.
  - Placeholder board returns 200 at `http://localhost:8080`.
  - `cloudflared` is installed: version 2026.7.2.
  - A temporary Cloudflare Tunnel reached local n8n `/healthz` successfully; the temporary URL was not recorded because tunnel URLs must not be committed.
  - n8n public settings report community nodes disabled.
  - Temporary decrypted credential export used for live checks was removed from the n8n container.
- Non-blocking runtime note: current local n8n image logs a Python task runner warning because Python 3 is not present in the container. The JS task runner registers and n8n starts normally; Stage 1 workflows are not blocked.

## Stage 2 Implementation Notes

- Added app schema in `db/postgres/migrations/001-schema.sql`.
- Added Cedar Ridge relative-time seed in `db/postgres/seed/seed.sql`.
- Added committed stage template source at `fixtures/stage-template.json`; `scripts/reset-demo.ps1` copies it to ignored runtime path `data/config/stage_template.json`.
- Added prospect import contract at `docs/prospect-csv-format.md` and fictional sample CSV at `fixtures/prospect-turns.example.csv`.
- Added helper scripts:
  - `scripts/reset-demo.ps1`
  - `scripts/load-prospect.ps1`
  - `scripts/check-stage-2.ps1`
  - `scripts/read-telegram-chat-ids.ps1`
  - `scripts/reset_demo.sh`
  - `scripts/load_prospect.sh`
- Schema decisions:
  - Added `vendor.is_fixture` so fixture vendor rows can be reset safely without touching future prospect vendor data.
  - Added partial unique index `uniq_one_active_stage_per_turn` to prevent multiple active stages per turn.
  - Added partial unique index `uniq_outbound_awaiting_per_stage_vendor` for later duplicate draft prevention.
  - Kept app SQL under `db/postgres/migrations/` and `db/postgres/seed/` so Docker's first-boot init hook does not accidentally run app schema/seed SQL against the admin database.
- Verified:
  - `scripts/reset-demo.ps1` applies schema, clears fixture rows only, copies the stage template, and reseeds six fixture turns.
  - Re-running reset restores 12B Paint at about 96 hours and 3 Oak Trash-out at about 30 hours.
  - `scripts/check-stage-2.ps1` verifies required tables, indexes, fixture counts, active-stage uniqueness, stage ages, current-stage calculations, vacancy days, dollars burned, vendor reply rate, and auto-handled rate.
  - Seeded current-stage summary returns six active fixture turns.
  - Seeded metrics currently compute to vendor reply rate 68% and auto-handled rate 72%.
  - `scripts/load-prospect.ps1` imports the sample CSV as two `is_fixture=false` turns.
  - `scripts/reset-demo.ps1` refuses to run while non-fixture rows exist.
  - Sample prospect rows were removed after testing; final local DB state is six fixture turns and zero non-fixture turns.
  - n8n workflow count remains zero after Stage 2 verification.
  - `scripts/read-telegram-chat-ids.ps1` runs without printing tokens; no bot updates were present yet.
