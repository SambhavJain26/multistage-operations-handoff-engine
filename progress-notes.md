# Make-Ready Sequencing Progress Notes

This file is the running handoff record for future sessions. Read it before starting any stage.

## Current Status

- 2026-08-17 manager approval controls changed by user decision. The approval card now shows `Email`, `Message`, and `Both` instead of `Send both`, `Edit`, and `Hold`. This supersedes the earlier locked decisions that every approved vendor message must go out on both channels and that approval must include Send/Edit/Hold. Rationale recorded by the user: `Edit` and `Hold` added no value in the demo, an ignored card is already visible in the database, and a vendor reachable on only one channel should still be reachable. Dual delivery is now a manager choice (`Both`), not an invariant.
- 2026-08-17 single-channel delivery verified live: `SEND_EMAIL` on queue 60 created exactly one email delivery row, no Telegram row, moved the queue to `sent`, and activated 12B Deep Clean.
- 2026-08-17 live Telegram Reply completion verified end to end. A Telegram reply to the 12B Flooring handoff completed only 12B Flooring while Statewide Flooring also had 7 Oak Flooring active. The interpreter recorded `unit_hint=12B`, confidence 0.95, and an explicit ambiguity note that the reply context identified 12B. 7 Oak stayed active and no duplicate advance occurred.
- 2026-08-17 pre-recording cleanup completed. Airtable had drifted to 12 turns, 100 stages, and 12 vendors against a Postgres truth of 6/66/6 because a fixture reset changes Postgres IDs while previously synced Airtable records remain as orphans. `scripts/reset-demo.ps1` does not touch Airtable. Cleanup order that produced a clean mirror: reset Postgres, reapply the real vendor contacts, delete every record in the six Airtable operating tables, clear `airtable_record_map`, then let reconciliation rebuild. Plan for this whenever fixtures are reset before a recording.
- 2026-08-17 Airtable linked records need two reconciliation passes after a full rebuild. The first pass writes Stages before Turn and Vendor mappings exist, so the link fields are stripped; the payload hash then differs on the next pass and the links populate. Verified 66/66 Turn and Vendor links after the second cycle.
- 2026-08-17 the Airtable `Channels` field on Approvals & Deliveries was hardcoded to `['Email','Telegram']`. It now aggregates the actual `outbound_delivery` channels so the mirror reflects the manager's per-approval choice.
- 2026-08-17 manager digest verified live. `docker compose run --rm --no-deps n8n execute --id=demo-manager-operations` fires the manual digest trigger; the sent message carried Done, Skip, Snooze, Chase, Cancel for the worst unit plus a second Done, with correct `DONE:`/`SKIP:`/`SNOOZE:`/`CHASE:`/`CANCEL:` callback data.
- 2026-08-17 Airtable mapping bug found and fixed. `Capture Airtable Record IDs` ran in the default run-once-for-all-items mode but was written per item: it read `$json` and `$('Build Airtable Batches').item`, so only the first batch's record IDs were saved. Vendors and Turns sort first and therefore mapped, while Stages, Communications, and Approvals never recorded a mapping. The Airtable records themselves were correct because `performUpsert` merges on `External ID`; only the local `airtable_record_map` was incomplete. Consequences were unresolved linked-record fields and a full re-upsert of every row on each five-minute cycle because the payload-hash short-circuit could never match. The capture node now walks every response item and pairs it with the batch at the same index.
- 2026-08-17 email reply ingestion bug found and fixed. n8n `emailReadImap` in `simple` format exposes raw headers under `metadata`, but the normalizer only checked `headers`/`headerLines`. `In-Reply-To` therefore read as empty, and the single-inbox guard correctly classified a genuine Gmail reply as a self-originated non-reply and ignored it. The `header()` helper now also reads `metadata`. Verified that outbound copies, bounces, and auto-replies are still ignored.
- 2026-08-17 environment instability observed. Docker Desktop was killed twice (n8n exit 137) and the `trycloudflare` quick tunnel collapsed twice. The tunnel failure mode is silent: `cloudflared` keeps running and n8n keeps a `WEBHOOK_URL` whose hostname no longer resolves, so Telegram callbacks vanish with no error anywhere in the demo. Always probe `WEBHOOK_URL/healthz` before a live Telegram test.
- 2026-08-15 live-consolidation correction: do not instruct a user to press a Telegram control until its exact live message/control has been verified. A partial-delivery alert was plain text while its original approval card contained only Send both/Edit/Hold; source changes alone did not make a retry button visible on that old message.
- Airtable/email/AI redesign is implemented in source: the custom board and simulator are removed; 19 operational workflows now cover Airtable intake/sync, IMAP intake, shared AI interpretation, deterministic matching/guarding, Telegram manager control, and independent email/Telegram delivery.
- Static verification is complete. Live Airtable provisioning, IMAP/SMTP delivery, and the redesigned n8n import remain unverified on this machine because no Airtable or mailbox credentials are configured and Docker was stopped at implementation start.
- Stage 8 production pilot readiness pack is implemented.
- Stage 7 is complete for implementation and live fixture verification.
- The old recording-script document has been replaced by `docs/operating-guide.md`, a manual operating/testing guide with no fixture-runner commands except `scripts/reset-demo.ps1`.
- `docs/how-the-system-works.md` has been rewritten as a prospect/client-facing explainer with service and workflow responsibilities but without implementation details such as variables or schemas.
- Local n8n demo workflow display names have been cleaned up: visible names no longer include stage/WF numbers, internal workflow IDs remain stable, and the local-only Stage 7 error-smoke workflow is omitted from the normal demo-visible n8n list.
- Live Telegram F01-F20 verification passed on 2026-08-03 with one manager bot, one vendor bot, separate private Telegram groups per fixture vendor identity, and a separate builder alert group. The local report is ignored at `data/stage-7-reports/stage7-live-patch7-20260803-105747.json`.
- Local runtime, credentials, schema, stage template, and fixture seed data have been verified.
- `build-plan.md` created with eight staged sessions.
- Git repository initialized on `main`; remote target is private GitHub repo `make-ready-sequencing`.
- Framing corrected: this is an AI automation installed around a client's existing tools, not a named software/SaaS product. Airtable replaces the retired custom visualization UI.

## Source Documents Read

- `03-make-ready-coordination.md`
- `foundation-3-turnover-makeready.md`
- `make-ready-demo-build-plan.md`

## Stage Progress

| Stage | Name | Status | Notes |
|---|---|---|---|
| 1 | Local Environment And Tooling Setup | Complete | Docker Compose stack, n8n, Postgres, placeholder board, docs, smoke scripts, n8n credentials, OpenAI model check, Telegram `getMe`, Postgres credential execution, and Cloudflare Tunnel reachability are verified. |
| 2 | Data Model, Stage Template, And Fixtures | Complete | Schema, stage template, Cedar Ridge fixture seed, reset/load scripts, prospect CSV example, Telegram chat-ID helper, and Stage 2 verification checks added. |
| 3 | Visibility Board And Manual Control | Complete | Board API, static board, reusable guard, guarded manual completion, manager digest send, and Telegram callback completion are implemented and verified locally. |
| 4 | Intake, Channel Normalization, And Matching | Complete | Manager intake form, deterministic unit matcher, generic `/vendor-in`, vendor Telegram ingest export, shared router/logger, duplicate handling, and manager notices are implemented. Vendor replies log only and do not mutate stages. |
| 5 | Vendor Completion Loop With Human Approval | Complete | Vendor completion, manager approval queue, Send/Edit/Hold/Cancel helpers, fallback classification/drafting, and Stage 5 verification are implemented. Live Telegram Send remains optional and requires a fresh tunnel/chat IDs. |
| 6 | Stall Detection, Digest, Simulator, And Photos | Complete | Stall watchdog, Chase approval drafts, health metrics, simulator, photo/unsupported media handling, and board thumbnails/history are implemented and verified locally. |
| 7 | Full Fixture Testing And Demo Hardening | Complete | Error workflow, fixture runner/report, config, docs, static checks, and guided live F01-F20 Telegram/generic/manager fixture run are complete. |
| 8 | Production Pilot Readiness | Complete | Client-owned VPS/Caddy templates, production env contract, readiness checks, backup/restore/monitoring/SMS readiness docs, manager runbook, contract exclusions, and success metrics are implemented. |
| Redesign | Airtable, Email, And Shared AI | Implemented; live external verification pending | Custom UI/API workflows removed; Airtable typed schema/provisioning/sync/intake, IMAP/SMTP, dual delivery, strict AI interpreter, fixtures, checks, imports, and current docs added. |

## Decisions Locked For Now

- Manager approval controls are `Email`, `Message`, and `Both`. There is no Edit or Hold button. Ignoring a card is a valid decision because the draft remains an open approval in Postgres.
- Delivery channel is a manager choice per message, not an invariant. `Both` still creates two independent attempts and retries only the failed channel.
- Every approval card always shows all three buttons. Choosing a channel the vendor has no destination for records `configuration_blocked` and alerts the manager instead of silently failing.
- Use Postgres for demo state, not Google Sheets.
- Use Airtable as the manager-facing operating mirror and turn-intake form. Managers don't edit synced operating tables.
- Receive vendor replies through Telegram, email, or the generic inbound API.
- Deliver every approved vendor message through email and Telegram; block when either destination is missing and retry only failed channels.
- Keep all manager alerts, approvals, digests, and controls in Telegram.
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
- Surface vendor reply rate and auto-handled rate in Airtable, the weekly digest, and manager `/health` command.
- After every completed task, commit and push changes to `main` unless blocked; report the commit hash or push failure.

## Open Questions / Validation Items

- Provision a real Airtable base with `scripts/setup-airtable.ps1`, configure the Interface/form, and run the live schema check.
- Create the named IMAP and SMTP credentials, import with all connector switches, then run the live threaded reply, dual delivery, partial failure, and failed-channel retry tests.
- Vendor Telegram trigger remains inactive by default. Optional Stage 4 live Telegram verification has been completed once locally; repeat it only with a fresh HTTPS tunnel, container-recreated `WEBHOOK_URL`, and local-only `VENDOR_TELEGRAM_CHAT_ID`.
- Confirm the domain/VPS provider only when a named pilot client exists.
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

## Stage 3 Implementation Notes

- Added Stage 3 n8n workflow exports in `n8n-workflows/`:
  - `wf-3-sequence-guard.json`
  - `wf-3-stage-complete-core.json`
  - `wf-3-board-api.json`
  - `wf-3-stage-complete-api.json`
  - `wf-3-daily-digest.json`
  - `wf-3-manager-router.json`
- Added deterministic workflow generator `scripts/generate-stage-3-workflows.js` so the exports can be regenerated without hand-editing escaped node code.
- Added import helper `scripts/import-stage-3-workflows.ps1`.
  - n8n 2.29.10 rejected `import:workflow --activeState=fromJson` in regular deployment mode, so the helper imports inactive, publishes required workflow IDs, and restarts n8n.
  - The helper writes temporary JSON copies under ignored `data/tmp-stage-3-workflow-import/` as UTF-8 without BOM.
  - Telegram workflows stay unpublished unless `-ActivateTelegram` is used with `MANAGER_TELEGRAM_CHAT_ID` and an HTTPS `WEBHOOK_URL`.
  - Guard and completion-core workflow queries explicitly preserve caller metadata so board and Telegram callback paths audit the correct `actor_id`, `channel`, and callback IDs after database context is loaded.
- Added verification SQL and script:
  - `db/postgres/verify-stage-3.sql`
  - `scripts/check-stage-3.ps1`
- Replaced the Stage 1 placeholder board with the real single-file board at `board/index.html`.
  - Polls `http://localhost:5678/webhook/board`.
  - Uses query-token auth to avoid CORS preflight for the static local board.
  - Stores last-known board state in `localStorage`.
  - Shows reconnecting/error status instead of going blank.
  - Renders the permanent demo badge, board metrics, worst-first cards, stage strip, latest event, manual completion control, and turn-history placeholder.
- Added Stage 3 runbook at `docs/stage-3-visibility-board.md`.
- Added Stage 3 local config placeholders to `.env.example` and passed them through `docker-compose.yml`.
- Sequence guard behavior implemented:
  - Skipped stages count as satisfied.
  - Paint requires Repairs.
  - Flooring requires Paint.
  - Deep Clean requires Repairs, Paint, and Flooring.
  - QA/photos requires Deep Clean.
  - Relist requires QA/photos.
  - Stages after Move-out require Move-out.
  - 14A Deep Clean returns a clear Repairs-open reason.
- Manual stage completion behavior implemented:
  - Board `POST /webhook/stage/complete` uses the shared completion core.
  - Successful manual completion writes `completed_via='manual'`, logs `manual_advance`, and activates the next pending stage when the completed stage was active.
  - 12B Paint advances to Flooring, not Deep Clean, because the seeded Flooring stage is not skipped.
- Verified:
  - Stage 3 workflow JSON files parse with `ConvertFrom-Json`.
  - `docker compose config` succeeds with the Stage 3 environment additions.
  - `scripts/import-stage-3-workflows.ps1` imports and publishes the four non-Telegram workflows.
  - `GET /webhook/board` without token returns `401`.
  - `GET /webhook/board?token=local-stage-3-demo-token` returns six active turns in the reset opening state.
  - Board sorting puts 12B first as a red stalled card after reset.
  - 14A Deep Clean from the board path returns `409` with "Repairs still open on 14A. Cleaning before repairs means cleaning twice."
  - 12B Paint from the board path completes via manual, logs the event, lowers vendor reply rate, and activates Flooring.
  - `scripts/check-stage-3.ps1` passes after a fresh reset.
  - Static board server returned `200` at `http://localhost:8080`.
  - Browser smoke test with local Chrome passed at 1280x900 and 390x844: six cards, demo badge, metrics, Mark done, turn history, no horizontal overflow.
  - Browser-side API abort shows the reconnecting strip while keeping last-known board state.
  - `scripts/read-telegram-chat-ids.ps1` found the manager chat ID in local Telegram updates; the value is intentionally not recorded here.
  - Manual isolated digest execution via `docker compose run --rm --no-deps n8n execute --id=wf3-daily-digest` succeeded and Telegram returned `ok=true` with six `Done ...` inline buttons.
  - A temporary Cloudflare Tunnel was run through Docker and `WEBHOOK_URL` was set locally to the HTTPS tunnel origin; the tunnel URL is intentionally not recorded.
  - `.\scripts\import-stage-3-workflows.ps1 -ActivateTelegram` activated the manager digest and callback router with the HTTPS webhook.
  - Real Telegram callback button press was verified on the manager digest: `Done 12B Paint` completed stage `1316`, wrote `completed_by` from the manager Telegram user ID, logged `manual_advance` with `channel='digest'`, advanced 12B to Flooring, and the manager-router execution completed successfully.
  - After the callback, the board API showed 12B moved out of the first red-card slot and vendor reply rate dropped to 66%.
- Final Stage 3 callback verification mutated the DB at the time, but later Stage 4 verification ended with a fixture reset. Current intended local demo DB state is the six-turn opening fixture state.

## Stage 4 Implementation Notes

- Added Stage 4 n8n workflow exports in `n8n-workflows/`:
  - `wf-4-turn-intake.json`
  - `wf-4-unit-matcher.json`
  - `wf-4-vendor-router.json`
  - `wf-4-vendor-in-api.json`
  - `wf-4-vendor-telegram-ingest.json`
- Added deterministic workflow generator `scripts/generate-stage-4-workflows.js`.
- Added import and verification helpers:
  - `scripts/import-stage-4-workflows.ps1`
  - `scripts/check-stage-4.ps1`
  - `db/postgres/verify-stage-4.sql`
- Added Stage 4 migration `db/postgres/migrations/002-stage-4-event-log.sql`.
  - Adds `form` as an event channel.
  - Adds event types `turn_intake`, `vendor_inbound`, `manager_match_needed`, and `duplicate_inbound`.
- Updated `scripts/reset-demo.ps1` to apply all migration files in lexical order.
- Updated fixture vendors to include generic placeholder sender refs in `phone_e164`, while keeping Telegram placeholder IDs separate in `telegram_chat_id`.
- Updated reset seed cleanup so Stage 4 demo sender events without `turn_id` are removed during fixture reset.
- Added `.env.example` placeholders and Compose pass-through for:
  - `VENDOR_IN_DEMO_TOKEN`
  - `VENDOR_TELEGRAM_CHAT_ID`
- Added Stage 4 runbook at `docs/stage-4-intake-and-matching.md`.
- Turn intake behavior implemented:
  - Manager Form Trigger creates `is_fixture=false`, `status='active'` turns.
  - `NOTICE` is active immediately; the other ten stages are pending.
  - `target_ready_date` defaults to `moveout_date + 5 days`.
  - In-house stages use Cedar Ridge in-house; selected vendor stages use the submitted vendors.
- Vendor ingest behavior implemented:
  - `POST /webhook/vendor-in` accepts JSON or form-derived n8n webhook bodies.
  - Auth accepts `?token=`, `X-Demo-Token`, or `X-Vendor-In-Token` against the import-time `VENDOR_IN_DEMO_TOKEN`.
  - Unknown senders log `unknown_sender`, disclose no match candidates, and do not reply to the sender.
  - Known senders log inbound envelopes and deterministic match results.
  - OpenAI classification remains deferred with `classification.status='deferred_stage_5'`.
  - Duplicate-like messages within 60 seconds log `duplicate_inbound`.
  - Ambiguous, below-threshold, duplicate-like, unknown, or photo-only messages notify the manager only when `MANAGER_TELEGRAM_CHAT_ID` was configured before import.
  - No inbound path completes, skips, advances, drafts, or sends vendor messages in Stage 4.
- Unit matcher behavior implemented:
  - Candidate pool is all active turns and their current active stages.
  - Exact normalized unit label scores 100.
  - Unit label token scores 90.
  - Street-name match scores 70.
  - Known sender with exactly one active assigned stage and no unit/street hint scores 60.
  - Only one untied candidate at score 70 or higher is selected automatically.
- n8n/local gotchas found and documented:
  - Active webhooks can return 404 briefly while n8n is still activating workflows after restart; verification waits for webhook registration.
  - n8n Form Trigger requires `multipart/form-data` and rendered field IDs like `field-0` for direct script submission, even when configured field names are present.
  - Docker Compose `restart` does not apply `.env` changes such as `WEBHOOK_URL`; recreate n8n before Telegram activation.
  - Windows `curl.exe` can mangle inline JSON passed from PowerShell variables; the Stage 4 checker sends JSON bodies from temporary UTF-8 files.
- Verified:
  - `node scripts/generate-stage-4-workflows.js` regenerates exports.
  - All `wf-4-*.json` files parse with `ConvertFrom-Json`.
  - PowerShell parser accepts `scripts/import-stage-4-workflows.ps1` and `scripts/check-stage-4.ps1`.
  - `docker compose config` succeeds with the Stage 4 environment additions.
  - `scripts/reset-demo.ps1` applies migrations in lexical order.
  - `scripts/import-stage-3-workflows.ps1` refreshed the Stage 3 baseline.
  - `scripts/import-stage-4-workflows.ps1` imports and publishes the non-Telegram Stage 4 workflows; vendor Telegram remains inactive by default.
  - `scripts/check-stage-4.ps1` passes:
    - Unauthorized `/vendor-in` returns 401.
    - Malformed `/vendor-in` returns 400.
    - F01 `done with 12b` from Rivera scores 100, logs `vendor_inbound`, selects 12B Paint, and leaves 12B Paint active.
    - Immediate duplicate F01 logs `duplicate_inbound`.
    - F02 `finished the one on maple` returns multiple Maple candidates and logs manager-match-needed behavior.
    - F03 `all set at oak, unit 7` resolves to unit 7 Oak.
    - F04 bare `done` from Rivera scores 60 and needs manager choice.
    - Unknown sender logs `unknown_sender` with no match disclosure.
    - Fixture stage statuses and outbound queue count do not change during inbound tests.
    - Intake form submission creates test turn `99Z-STAGE4`, board shows it with `NOTICE` active and 11 stages, cleanup removes it, and reset succeeds.
  - `scripts/check-stage-3.ps1 -SkipReset` passes after Stage 4 import, confirming board/manual Stage 3 behavior still works.
  - Final local DB state was reset to the opening fixture state after checks.
- Optional Telegram verification completed after the Stage 4 commit:
  - Captured the vendor bot chat ID from a real user-to-bot message; the value is intentionally not recorded.
  - Started a temporary Cloudflare Tunnel container into local n8n and recreated n8n so the container used the HTTPS `WEBHOOK_URL`.
  - Ran `scripts/import-stage-4-workflows.ps1 -ActivateTelegram`; vendor Telegram ingest activated successfully.
  - Sent real vendor Telegram text `done with 12b stage4 tg verify 20260801-1939`.
  - Telegram ingest logged `vendor_inbound` with Rivera Painting as a known vendor, `classification.status='deferred_stage_5'`, selected 12B Paint at score 100, `needs_manager=false`, and `stage_state_mutated=false`.
  - Sent the same text through generic `/webhook/vendor-in` with the placeholder Rivera sender; the stored event matched Telegram on event type, raw text, vendor, classification, selected unit/stage, score, and non-mutation. It differed only by `channel`, `sender_ref`, and received timestamp.
  - Confirmed 12B Paint stayed active and outbound queue count stayed zero.
  - Cleaned up by importing Stage 4 without `-ActivateTelegram`, restoring local `.env` to localhost `WEBHOOK_URL` and blank `VENDOR_TELEGRAM_CHAT_ID`, recreating n8n, stopping the temporary tunnel container, and resetting fixtures. Post-cleanup, `wf4-vendor-telegram-ingest` is inactive, non-Telegram Stage 4 workflows are active, Rivera fixture sender mapping is restored, and verification event rows are gone.

## Stage 5 Implementation Notes

- Added Stage 5 migration `db/postgres/migrations/003-stage-5-approval-loop.sql`.
  - Adds `awaiting_approval` and `cancelled` stage states.
  - Expands `outbound_queue` with source stage, approved text, deterministic text, draft fallback metadata, decision metadata, and approval context.
  - Adds Stage 5 event types for draft, edit, send, hold, skip, snooze, cancellation, and approval-pending state.
- Made `db/postgres/migrations/002-stage-4-event-log.sql` forward-compatible with Stage 5 event/channel values so repeated resets do not temporarily narrow constraints while later-stage rows still exist.
- Updated Stage 3 generator/export:
  - Board API now treats `active` and `awaiting_approval` as visible current stages.
  - Sequence guard carries opaque vendor-router context through to Stage 5 completion while still evaluating only deterministic sequence rules.
- Updated `board/index.html` to show `awaiting_approval` stage dots and a clear "manager approval pending" note.
- Added Stage 5 workflow exports:
  - `wf-5-vendor-completion-handler.json`
  - `wf-5-manager-action-core.json`
  - `wf-5-manager-action-api.json`
- Added `scripts/generate-stage-5-workflows.js`.
  - Overwrites `wf-4-vendor-router.json` with Stage 5 classification/routing behavior.
  - Overwrites `wf-3-manager-router.json` with callback parsing for Stage 5 manager actions while preserving the single manager Telegram Trigger design.
  - Uses HTTP Request node shape for OpenAI Responses API classification, with deterministic fallback classification when the OpenAI call fails or returns an unusable shape.
  - Reuses `wf4-unit-matcher` and `wf3-sequence-guard`; no duplicate matcher or guard was added.
- Added import and verification helpers:
  - `scripts/import-stage-5-workflows.ps1`
  - `scripts/check-stage-5.ps1`
  - `db/postgres/verify-stage-5.sql`
- Stage 5 behavior implemented:
  - `stage_complete` vendor messages can complete only the matched active stage when it is assigned to that vendor.
  - The completed stage is marked `completed_via='vendor_reply'`.
  - The next external-vendor stage moves to `awaiting_approval`, not `active`.
  - A deterministic draft is inserted into `outbound_queue` as `awaiting_approval`; the draft row records model/fallback metadata.
  - Duplicate completions within 60 seconds log `duplicate_inbound` and do not create a second draft.
  - Send/Edit/Hold actions are available through the manager action core and local `/manager-action` verification webhook.
  - Send marks the queue `sent` and activates the awaiting stage. In local non-Telegram verification this records `delivery_mode='local_state_only'`; live Telegram delivery still requires optional tunnel/chat-ID verification.
  - Edit updates the draft text and keeps it awaiting approval.
  - Hold records `held` and sends nothing.
  - Cancel marks the turn cancelled, closes pending/active/awaiting stages, cancels open queue rows, and removes the turn from the active board.
  - Vendor messages from the wrong assigned vendor route to manager review instead of mutating the active stage.
- Verified:
  - `node scripts/generate-stage-3-workflows.js`, `node scripts/generate-stage-4-workflows.js`, and `node scripts/generate-stage-5-workflows.js` regenerate parseable exports.
  - `scripts/import-stage-5-workflows.ps1` imports and publishes the non-Telegram Stage 5 workflow set.
  - `scripts/check-stage-3.ps1` passes with the Stage 5 board/guard changes.
  - `scripts/import-stage-4-workflows.ps1` followed by `scripts/check-stage-4.ps1` passes, confirming the Stage 4 non-mutation baseline still works when Stage 4 is imported.
  - `scripts/import-stage-5-workflows.ps1` followed by `scripts/check-stage-5.ps1` passes:
    - F01 completes 12B Paint, creates exactly one awaiting approval draft for 12B Flooring, and logs no send before manager Send.
    - The board shows 12B Flooring as `awaiting_approval`.
    - Duplicate F01 creates no second draft.
    - Edit stores revised draft text and still requires approval.
    - Send marks the queue sent and activates Flooring.
    - Hold records held with no send.
    - Cleaner message `14a cleaned` is blocked as a stage/vendor mismatch and does not mutate 14A Repairs.
    - Low-confidence fallback routes to manager review.
    - Existing sequence guard still blocks 14A Deep Clean while Repairs is open.
    - Cancel removes 55 Birch from the active board.
  - Final local DB state was reset to the opening fixture state after checks.
- Post-Stage 5 live Telegram fix:
  - During a live Telegram F01 rehearsal, 12B Paint completed and 12B Flooring moved to `awaiting_approval`, but the manager approval card was not delivered.
  - Root cause was the completion handler comparing the import-substituted manager chat ID against itself, which made the approval-card gate false when a real chat ID was configured.
  - Updated the Stage 5 generator/export so the approval card is sent when a queue row exists and the manager chat ID is not blank or the placeholder sentinel.
  - Re-ran `scripts/import-stage-5-workflows.ps1` and `scripts/check-stage-5.ps1`; local Stage 5 verification passed. Live Telegram delivery still depends on a fresh HTTPS tunnel and real chat IDs.

## Stage 6 Implementation Notes

- Added Stage 6 migration `db/postgres/migrations/004-stage-6-stall-media.sql`.
  - Adds Stage 6 event types for held stall alerts, Chase drafts, weekly/health checks, photo storage/clarification, and unsupported media.
  - Adds `media_asset` for photo-only and unsupported-media rows that cannot safely attach to a stage.
  - Keeps `turn_stage.alerted_at`, `snooze_until`, and `evidence_photo` as the primary stage-level state.
- Made Stage 4 and Stage 5 event-type constraints forward-compatible with Stage 6 so reset does not temporarily narrow checks while later-stage rows exist.
- Added `scripts/generate-stage-6-workflows.js`.
  - Regenerates from Stage 3/4/5 exports, then applies Stage 6-owned changes to the board, vendor router, manager action core/API, daily digest, manager router, health workflows, stall watchdog, and weekly digest.
  - Preserves the existing `wf3-sequence-guard` and `wf4-unit-matcher`; no second guard or matcher was added.
- Added workflow exports:
  - `wf-6-stall-watchdog.json`
  - `wf-6-health-core.json`
  - `wf-6-health-api.json`
  - `wf-6-weekly-digest.json`
- Added `scripts/import-stage-6-workflows.ps1`.
  - Imports all Stage 3-6 workflow exports.
  - Publishes non-Telegram local workflows by default.
  - Substitutes real Telegram chat IDs only when `-ActivateTelegram` is explicitly used, so local checks do not accidentally send manager messages when `.env` contains live chat IDs.
- Stall watchdog behavior implemented:
  - Checks active external-vendor stages against `sla_hours`.
  - Ignores `awaiting_approval` stages.
  - Respects `snooze_until`.
  - Uses `alerted_at` to dedupe business-hours alerts.
  - Holds outside-hours alerts with `stall_alert_held` events and leaves `alerted_at` blank so the alert remains eligible during the next 08:00-18:00 America/Phoenix window.
  - Sends manager-only Telegram alerts only when imported with live Telegram activation.
- Chase behavior implemented:
  - Manager `CHASE` creates one `outbound_queue` draft in `awaiting_approval` for the current active external-vendor stage.
  - Chase logs `chase_drafted`.
  - No vendor send occurs before manager Send.
- Manager and metrics surfaces implemented:
  - Daily digest now uses worst-first board ordering and exposes Done, Skip, Snooze, Chase, Cancel, and a second Done action through callback data.
  - Manager router handles `/health` messages when Telegram is active.
  - Health API and manager health command use the same vendor reply rate and auto-handled rate SQL as the Board API.
  - Weekly digest workflow records `weekly_digest` and can send metrics when Telegram activation is configured.
- Media behavior implemented:
  - Generic `/vendor-in` accepts media-only payloads when `media_type` is present.
  - Vendor Telegram normalization carries photo, voice, and unsupported document metadata.
  - Captioned photo completions store `turn_stage.evidence_photo`, add a `media_asset` row, and log `photo_stored`.
  - Photo-only messages store a `media_asset` row with `needs_manager`, log `manager_photo_match_needed`, and do not mutate stages.
  - Voice notes and unsupported media store `media_asset.status='unsupported'`, log `unsupported_media`, notify the manager when Telegram is configured, and do not mutate stages.
- Updated `board/index.html`.
  - Shows completion photo thumbnails when `evidence_photo` is present.
  - Shows latest manager/vendor/system events in a real history panel.
  - Keeps raw event details behind collapsed technical audit controls.
- Added `board/sim.html`.
  - Plain phone-style simulator for the generic `/vendor-in` path.
  - Supports text, photo-only, and voice-note fixture buttons.
- Added Stage 6 verification:
  - `scripts/check-stage-6.ps1`
  - `db/postgres/verify-stage-6.sql`
- Verified:
  - `node scripts/generate-stage-3-workflows.js`, `node scripts/generate-stage-4-workflows.js`, `node scripts/generate-stage-5-workflows.js`, and `node scripts/generate-stage-6-workflows.js` regenerate parseable JSON exports.
  - `scripts/import-stage-6-workflows.ps1` imports and publishes the local Stage 6 workflow set.
  - `scripts/check-stage-3.ps1` passes after Stage 6 changes.
  - `scripts/import-stage-4-workflows.ps1` followed by `scripts/check-stage-4.ps1` passes.
  - `scripts/import-stage-5-workflows.ps1` followed by `scripts/check-stage-5.ps1` passes.
  - `scripts/import-stage-6-workflows.ps1` followed by `scripts/check-stage-6.ps1` passes:
    - 3 Oak Trash-out logs exactly one business-hours `stall_alert`.
    - Re-running the watchdog does not duplicate 3 Oak's alert.
    - Snooze suppresses 3 Oak's alert.
    - Outside-hours run logs `stall_alert_held` and does not stamp `alerted_at`; business-hours run later alerts.
    - Chase creates one awaiting approval queue row and no `msg_sent`.
    - Health API metrics match Board API metrics.
    - Captioned photo completion stores `evidence_photo`, logs `photo_stored`, and exposes the photo through the Board API.
    - Photo-only stores media for manager review and does not mutate Paint.
    - Voice note stores unsupported media and does not crash or mutate stages.
    - `board/sim.html` exists and posts to `/vendor-in`.
  - Final local DB state was reset to the opening fixture state after checks.
- Live Telegram photo/Send verification remains optional and requires a fresh HTTPS `WEBHOOK_URL`, real manager chat ID, real vendor chat ID, and `scripts/import-stage-6-workflows.ps1 -ActivateTelegram`.

## Stage 7 Implementation Notes

- Added Stage 7 migration `db/postgres/migrations/005-stage-7-hardening.sql`.
  - Allows `workflow_error` in `event_log`.
  - Made Stage 4, Stage 5, and Stage 6 event-type migrations forward-compatible with `workflow_error` so reset can reapply migrations while Stage 7 rows exist.
- Added Stage 7 local/live config placeholders:
  - `BUILDER_TELEGRAM_CHAT_ID`
  - `RIVERA_TELEGRAM_CHAT_ID`
  - `MARIAS_TELEGRAM_CHAT_ID`
  - `DALE_TELEGRAM_CHAT_ID`
  - `STATEWIDE_TELEGRAM_CHAT_ID`
  - `VENDOR_TELEGRAM_CHAT_ID` remains Rivera's fallback.
- Added Stage 7 workflow generator `scripts/generate-stage-7-workflows.js`.
  - Regenerates Stage 3-6 workflows first.
  - Adds `wf-7-error-handler.json` with an Error Trigger, Postgres `workflow_error` logging, and builder-only Telegram notification when `BUILDER_TELEGRAM_CHAT_ID` is substituted.
  - Adds `wf-7-error-smoke.json` as a local authorized webhook that intentionally throws so the Error Workflow path can be checked.
  - Sets `settings.errorWorkflow='wf7-error-handler'` on every Stage 3-7 workflow except the error handler itself.
- Added Stage 7 import helper `scripts/import-stage-7-workflows.ps1`.
  - Applies idempotent migrations in lexical order before import.
  - Imports 20 workflows, publishes `wf7-error-handler` first, then publishes dependent workflows.
  - Keeps Telegram workflows unpublished unless `-ActivateTelegram` is used.
  - With `-ActivateTelegram`, requires HTTPS `WEBHOOK_URL` in `.env` and inside the n8n container, distinct live vendor chat IDs, a manager chat ID, and a separate builder chat ID.
  - Supports `-ClassifyModelOverride` for fallback rehearsal without editing stored OpenAI credentials.
- Added Stage 7 fixture/check assets:
  - `fixtures/stage-7-fixtures.json` records F01-F20 definitions and expected behavior.
  - `scripts/check-stage-7.ps1` validates workflow JSON, registered webhooks, error handler linkage, and error-smoke logging by default.
  - `scripts/check-stage-7.ps1 -RequireTelegram` runs a guided live fixture session because Telegram cannot impersonate inbound vendor users.
  - Reports are written to ignored `data/stage-7-reports/`.
- Added Stage 7 runbook `docs/stage-7-demo-hardening.md`.
  - Documents live tunnel/chat prerequisites, fixture operation, failure handling, demo rehearsal, offline recording, and rebuild path.
- Updated stale demo wording in `make-ready-demo-build-plan.md`.
  - 12B Paint now hands off to Flooring / Statewide Flooring unless Flooring is skipped, matching the implemented stage template.
- Verification completed locally without live Telegram activation:
  - `node scripts/generate-stage-7-workflows.js`
  - PowerShell parser checks for `scripts/import-stage-7-workflows.ps1` and `scripts/check-stage-7.ps1`
  - All workflow JSON exports parse with `ConvertFrom-Json`
  - `docker compose config`
  - `scripts/import-stage-7-workflows.ps1`
  - `scripts/check-stage-7.ps1`
  - `scripts/check-stage-3.ps1`
  - `scripts/import-stage-4-workflows.ps1` then `scripts/check-stage-4.ps1`
  - `scripts/import-stage-5-workflows.ps1` then `scripts/check-stage-5.ps1`
  - `scripts/import-stage-6-workflows.ps1` then `scripts/check-stage-6.ps1`
  - Final `scripts/import-stage-7-workflows.ps1` then `scripts/check-stage-7.ps1`
- Runtime gotcha found:
  - In local n8n 2.29.10, `wf-7-error-smoke` can return HTTP 200 with an empty body even though its Code node throws. The Error Workflow still fires and inserts exactly one `workflow_error` row per smoke call, so Stage 7 verification keys off `event_log`, not HTTP status.
- Live verification completed on 2026-08-03:
  - A fresh Cloudflare Tunnel was started for local n8n and `scripts/import-stage-7-workflows.ps1 -ActivateTelegram` completed with Telegram workflows active.
  - `.env` was populated locally with manager, builder, Rivera, Maria, Dale, and Statewide chat IDs. The file remains ignored and was not committed.
  - F01-F20 passed in a guided live run. Live Telegram coverage included F01, F02, F05, F10, F12, F15, manager Send callback, and builder error alert delivery. Generic webhook coverage included F03, F04, F06-F09, F11, F13-F14, and F16-F20.
  - Local ignored report: `data/stage-7-reports/stage7-live-patch7-20260803-105747.json`.
  - Best-effort model cost recorded as `$0.00` because exercised branches used deterministic fallback or did not expose response usage in the checked outputs.
- Stage 7 hardening fixes found during live verification:
  - `scripts/check-stage-7.ps1` now reapplies live fixture vendor chat mappings after each reset when `-RequireTelegram` is used. `reset-demo.ps1` reseeds placeholder chat IDs, so live fixture runs must restore the real group IDs after every reset.
  - `scripts/generate-stage-7-workflows.js` now treats only `stage7-%-missing` as a missing builder chat placeholder. Import-time substitution of the real `BUILDER_TELEGRAM_CHAT_ID` must not also make the SQL `NULLIF()` guard suppress builder alerts.
  - `scripts/generate-stage-6-workflows.js` now preserves `telegram_callback_query_id` through `wf5-manager-action-core` so `wf3-manager-router` can acknowledge callback buttons after manager actions without a false builder workflow alert.
  - F06, F08, and F17 checker assertions key off `classification.intent` plus `stage_state_mutated=false`. A safe `manager_match_needed` outcome is expected when intent is known but unit/stage confidence remains below the automatic action threshold.
  - F14 setup clears the 12A active stage before activating 12A Paint to avoid the `uniq_one_active_stage_per_turn` partial unique constraint.
- Post-Stage 8 local demo cleanup:
  - `scripts/generate-stage-7-workflows.js` now rewrites visible workflow names to prospect-friendly labels such as `Board API`, `Vendor Telegram Ingest`, and `Builder Error Handler`; stable IDs such as `wf3-board-api` are preserved because webhooks and Execute Sub-workflow nodes depend on them.
  - `scripts/import-stage-7-workflows.ps1` now omits `wf7-error-smoke` by default so the n8n editor shows only the 19 runtime workflows. Use `-IncludeErrorSmoke` for Stage 7 hardening checks, then rerun the import without that switch before a demo.
  - The current local n8n instance was updated in place and restarted; `n8n list:workflow` shows 19 workflows with no `WF-3`/`WF-7` display prefixes and no visible `Error Smoke` workflow.
  - `make-ready-stage7-tunnel` is a temporary Cloudflare Tunnel sidecar from live Telegram verification. It should remain separate from the n8n container while live Telegram webhooks are active and can be stopped/removed when Telegram testing is done.
- Verification after the fixes:
  - `node scripts/generate-stage-7-workflows.js`
  - `scripts/import-stage-7-workflows.ps1 -ActivateTelegram`
  - `docker compose config`
  - all workflow JSON exports parse with `ConvertFrom-Json`
  - `fixtures/stage-7-fixtures.json` contains 20 fixtures
  - n8n has 19 non-error workflows linked to `wf7-error-handler`
  - required static webhooks are registered for board, vendor-in, manager-action, and error-smoke
  - `scripts/check-stage-3.ps1` passed
  - `scripts/check-stage-5.ps1` passed
  - `scripts/check-stage-6.ps1` passed
  - `scripts/check-stage-7.ps1` passed in non-interactive static/error-handler mode
  - `scripts/check-stage-4.ps1` was not used as a Stage 7 gate after full import because it is a Stage 4-isolated checker: it expects `/vendor-in` to stop at `matched_logged`, while the composed Stage 7 runtime correctly continues to Stage 5 completion/approval behavior.
  - Final local fixture state was reset clean and the four live vendor group mappings were reapplied.

## Stage 8 Implementation Notes

- Added inert production readiness templates:
  - `.env.production.example` is committed as a placeholder contract and explicitly unignored in `.gitignore`.
  - `docker-compose.production.yml` adds a production-shaped Caddy/Postgres/n8n stack with explicit non-`latest` image tags.
  - `Caddyfile.production` reverse-proxies `n8n.<client-domain>` behind Caddy basic auth. The removed custom board is not part of the production template.
- Added `scripts/check-stage-8-production-readiness.ps1`.
  - Validates production env placeholders are replaced, required secrets are long enough, `WEBHOOK_URL` is HTTPS and matches `N8N_HOST`, SMS remains disabled, retention defaults are sane, images are pinned, and required Caddy directives are present.
  - Runs `docker compose --env-file <env> -f docker-compose.production.yml config` unless `-SkipComposeConfig` is passed.
- Added Stage 8 docs:
  - `docs/stage-8-production-pilot-readiness.md`
  - `docs/stage-8-manager-runbook.md`
  - `docs/stage-8-contract-exclusions.md`
  - `docs/stage-8-success-metrics.md`
- Production posture locked:
  - Readiness pack only; no VPS/domain was provisioned.
  - SMS design only; `SMS_ENABLED=false` is enforced by the check script.
  - First pilot auth is reverse-proxy/basic-auth in front of n8n; custom app accounts remain deferred.
  - Client-owned single-client instance remains the only production delivery model.
- Verification completed:
  - PowerShell parser check passed for `scripts/check-stage-8-production-readiness.ps1`.
  - `scripts/check-stage-8-production-readiness.ps1 -EnvFile .env.production.example -SkipComposeConfig` fails as expected on placeholder/default values.
  - A generated ignored dummy env under `data/stage-8-check/dummy.env` passes `scripts/check-stage-8-production-readiness.ps1`, including `docker compose config`.
  - A generated ignored Compose copy with `caddy:latest` fails as expected on the pinned-image check.
- No real client data, tunnel URL, chat ID, Twilio credential, API key, database dump, or `.env.production` file was committed.

## Airtable, Email, And AI Proof-Of-Concept Notes

- Removed the custom board, simulator, board host/configuration, and UI-only API workflows. Postgres remains authoritative and Airtable is the intended manager-facing workspace and intake form.
- Added a typed Airtable schema manifest plus setup and validation scripts for Turns, Stages, Vendors, Communications, approvals/deliveries, and turn intake.
- Added vendor email ingestion and dual-channel Telegram/email delivery records. A manager approval creates independent channel attempts; a partial failure can be retried without duplicating a successful channel.
- Added one shared AI Message Interpreter for normalized Telegram, email, and generic API messages. Deterministic sender matching, unit matching, sequencing, duplicate checks, and safety rules remain authoritative.
- Manager approvals, alerts, digests, and exception handling remain Telegram-only. No autonomous vendor messaging was introduced.
- Local proof-of-concept verification passed for workflow generation/JSON parsing, Compose configuration, database migration/reset, Airtable schema validation, AI fallback, channel-parity fixtures, and manager action safety paths.
- The local n8n instance contains 19 prospect-friendly operational workflows. Thirteen credential-independent core workflows are active. Airtable intake, email ingest, Telegram ingest/router, and scheduled digests remain inactive until real external credentials are configured.
- External Airtable base creation, Airtable Interface layout, and live IMAP/SMTP delivery are intentionally not required to complete this proof of concept. They are client-specific connection steps, not additional product development.
- Post-redesign runtime audit on 2026-08-15: the local Compose stack runs only `make-ready-n8n` and `make-ready-postgres`; the Caddy/production template is inert and does not affect the demo. The current saved `WEBHOOK_URL` is a temporary tunnel value, so Telegram workflows must remain inactive until a fresh HTTPS tunnel is started and n8n is recreated with that URL.
- Telegram inventory on 2026-08-15: `scripts/read-telegram-chat-ids.ps1` now uses Telegram `getChat` for configured IDs rather than `getUpdates`, which Telegram rejects while a webhook is active. Confirmed vendor bot `@make_ready_vendor_demo_bot` in Stage7 Rivera, Marias, Dale, and Statewide groups; manager bot `@make_ready_manager_demo_bot` has the direct manager chat and Stage7 Builder alert group. QuickHaul has not yet been configured.
- Single-inbox email demo support on 2026-08-15: all fixture vendors may use `sambhavn8n@gmail.com` and that same Gmail may be the IMAP/SMTP account. `Vendor Email Ingest` now ignores a self-originated email without `In-Reply-To`; Gmail Reply messages retain the header and are accepted. This is explicitly local-demo-only, with fixture E16 and a generated-workflow simulation confirming outbound copy ignored and threaded reply accepted.
