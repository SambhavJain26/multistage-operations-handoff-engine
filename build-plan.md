# Make-Ready Sequencing Staged Build Plan

This plan is based on a full read of:

- `03-make-ready-coordination.md`
- `foundation-3-turnover-makeready.md`
- `make-ready-demo-build-plan.md`

The target is a local-first live demo of a make-ready sequencing AI automation for US residential property managers, not a named software product or SaaS. Airtable is the manager-facing workspace and intake form; the custom board and simulator have been retired. The demo must prove the sequencing guard, AI interpretation, manager approval, and independent email/Telegram delivery. Everything runs on this machine during the demo build except external Airtable, email, OpenAI, and Telegram services.

## Airtable And Email Redesign Supersession

This section overrides historical Stage 1-8 references to the custom board, simulator, n8n Form Trigger intake, manager action APIs, or Telegram-only vendor delivery.

- Postgres remains authoritative. Airtable mirrors vendors, turns, stages, communications, approvals, and channel delivery states.
- Managers create turns through Airtable and operate approvals and controls through Telegram.
- Vendor intake supports Telegram, IMAP email, and the generic inbound API.
- OpenAI interprets every known-vendor free-form message. Deterministic sender, unit, duplicate, confidence, safety, and sequence checks control mutation.
- The manager chooses the channel on each approval with `Email`, `Message`, or `Both`. `Both` creates independent email and Telegram attempts; retry never duplicates a successful channel. Choosing a channel the vendor cannot receive records `configuration_blocked` and alerts the manager. This supersedes the earlier rule that every approved message must go out on both channels.
- The canonical import contains seven consolidated operational workflows and removes the UI-only APIs.
- SMS remains disabled.

## Important Spec Decisions And Conflicts

1. **Outbound vendor messages are human-gated.**
   The source spec says the automation should automatically advance and notify the next vendor. The demo build plan explicitly corrects this: every outbound vendor message is drafted by the automation and released by the manager. This plan follows the demo build plan. Do not auto-send vendor messages.

2. **Postgres is the demo state store.**
   The source spec allows Google Sheets for demos. The demo build plan rejects Sheets because the sequence guard needs transactional state and the live demo should not depend on Sheets quota or concurrent write behavior. This plan uses Postgres from the start.

3. **The manager workflow must work even if no vendor replies.**
   Manual manager advance through the same sequence guard remains a core workflow. Airtable visibility and Telegram controls remain useful at a 0% vendor reply rate.

4. **Turnover starts at notice, vacancy cost starts at move-out.**
   The documents agree once the terms are separated. The record begins at notice received. Vacancy-day and rent-loss arithmetic starts at move-out / keys returned.

5. **Telegram is demo-only.**
   The demo uses two Telegram bots because Telegram is available immediately and n8n supports it directly. Production SMS is deferred until a paid client exists because A2P 10DLC registration must happen under the client's business identity.

6. **No PMS integration.**
   Buildium/AppFolio/Rent Manager/etc. are out of scope for the demo. The system runs beside the PMS and does not read or write it.

7. **No deposit, tenant-screening, listing, or maintenance-ticket logic.**
   Punch-list stages are work coordination only. The system must not classify damage, compute tenant liability, generate deposit correspondence, select tenants, write listing copy, target ads, or handle occupied-unit maintenance.

8. **OpenAI model IDs must be verified at build time.**
   Current research points to `gpt-5.6-luna` as the cheapest good default for both classification and short draft rewriting. Stage 1 still includes a live model check and records the actual IDs used, with `gpt-5.6-terra` or `gpt-5.4-mini` kept only as quality fallbacks if Luna's draft wording is not good enough.

9. **Use direct HTTP calls to OpenAI for model calls.**
   Rechecked against current n8n and OpenAI docs. n8n's OpenAI node now supports the Responses API and model selection, but its documented JSON option is still weaker than OpenAI Structured Outputs with strict JSON schema. Use HTTP Request to call the OpenAI Responses API directly so strict schemas, exact model IDs, raw errors, and fallback branches are explicit.

10. **Use only core n8n nodes.**
   Do not add community nodes to the demo. They introduce avoidable maintenance and reliability risk in the exact environment that has to survive a live call.

11. **Competitive claims need validation before sales use.**
   The demo plan says sequence enforcement may be a differentiator versus Property Meld, but that was not verified. Do not claim competitors lack sequence enforcement until confirmed.

12. **Seed-data arithmetic must be computed, not hardcoded.**
    The demo build plan contains slightly different rent-burn figures in different sections. Treat those as illustrative, not constants. The board should compute live ages and dollars from relative fixture timestamps and rent values.

13. **VPS and Caddy are production-only for now.**
   The demo build runs locally in Docker. Telegram testing uses a temporary HTTPS tunnel to local n8n. Do not provision a VPS, buy a domain, or configure Caddy until Stage 8 production/pilot readiness.

## Stage 1 - Local Environment And Tooling Setup

**Goal:** Get a clean local demo runtime with required credentials verified before building workflows.

**In scope:**

- Install or verify Docker Desktop / Docker Engine and Docker Compose locally.
- Create a local Docker Compose stack for n8n and Postgres.
- Serve the board locally from a simple static server or local n8n-accessible static route; do not add Caddy for the demo build.
- Configure n8n environment for local use, including timezone, encryption key, editor auth, and filesystem binary data mode.
- Choose a tunnel option for Telegram testing, preferably Cloudflare Tunnel or ngrok, and document the command used.
- Set `WEBHOOK_URL` to the temporary HTTPS tunnel URL only while testing Telegram triggers.
- Create two Telegram bots: vendor bot and manager bot.
- Add Postgres, Telegram, and OpenAI credentials in n8n. Postgres can be scripted locally; Telegram and OpenAI require user-provided external tokens.
- Verify OpenAI model availability and record chosen classification/drafting model IDs.
- Confirm the workflows can be built with core n8n nodes only.

**Out of scope:**

- No business workflows.
- No board UI.
- No schema beyond what is needed for a connection test.
- No SMS, Twilio, or PMS integration.

**Verification:**

- `docker compose version` works locally.
- Local n8n loads at `http://localhost:5678`.
- Local Postgres is reachable from n8n.
- Local board loads in the browser.
- Generic webhook tests work locally without a tunnel.
- When Telegram is being tested, n8n webhook URLs show the active HTTPS tunnel URL, not localhost.
- Postgres credential in n8n can run `SELECT 1`.
- Both Telegram bot tokens pass `getMe`.
- OpenAI `GET /v1/models` succeeds, and selected model IDs are written into environment/config notes.

## Stage 2 - Data Model, Stage Template, And Fixtures

**Goal:** Create the durable state foundation and a believable demo world that can be reset safely.

**In scope:**

- Create the Postgres schema for vendors, turns, turn stages, outbound queue, and event log.
- Include audit fields needed for reply-rate and auto-handled-rate metrics.
- Store the default stage template as configurable JSON.
- Seed the fictional Cedar Ridge demo world:
  - Six vendors.
  - Six turns.
  - Relative timestamps only.
  - Varied stages: stalled paint, blocked deep clean, trash-out alert candidate, healthy flooring, near-complete QA, future move-out.
- Create reset/load operational scripts or equivalent n8n-safe procedures:
  - Reset fixture data only.
  - Refuse to wipe non-fixture prospect data.
  - Load prospect-provided turns as non-fixtures later.

**Out of scope:**

- No board API.
- No workflow automation.
- No Telegram event handling.
- No AI calls.

**Verification:**

- All tables, indexes, and constraints exist.
- Re-running the seed later still creates the intended "four days at paint" and "30 hours at trash-out" states.
- Reset restores the opening demo state quickly.
- Reset refuses to run if non-fixture rows exist.
- Basic SQL can calculate current stage, stage age, vacancy days, and dollars burned from the seeded data.

## Stage 3 - Visibility Board And Manual Control

**Goal:** Build the sellable core that works even with 0% vendor replies.

**In scope:**

- Build the sequence guard as one reusable deterministic function/workflow component.
- Implement hard ordering rules:
  - Paint requires repairs.
  - Flooring requires paint.
  - Deep clean requires repairs, paint, and flooring.
  - QA/photos requires deep clean.
  - Downstream make-ready stages require move-out.
  - Skipped stages count as satisfied.
- Build the Board API returning active turns, live ages, vacancy dollars, health color, stage strip, latest event, vendor reply rate, and auto-handled rate.
- Build the single-file visualization board served locally.
- Add `Mark done` on each card wired to manual stage advance.
- Ensure manual advance uses the same sequence guard as vendor completion will later use.
- Build or stub the daily digest enough to prove manager-side manual controls can call the same path.

**Out of scope:**

- No vendor inbound parsing.
- No outbound vendor sending.
- No OpenAI.
- No photo handling beyond displaying existing seeded thumbnails if present.
- No login/user management beyond demo token/header auth.

**Verification:**

- Board loads on desktop and phone.
- Board sorts worst-first and makes the stalled red card obvious.
- Ages and dollar figures change when time passes or timestamps are adjusted.
- `Mark done` on an allowed stage completes it with `completed_via='manual'`.
- Attempting Deep Clean on the seeded unit with Repairs still open is blocked with a clear rework reason.
- Vendor reply rate metric reflects manual completions rather than pretending automation handled them.
- If the Board API is unavailable, the visualization shows last-known state plus a reconnecting/error strip rather than a blank page.

## Stage 4 - Intake, Channel Normalization, And Matching

**Goal:** Add controlled input paths without allowing them to mutate turn state yet.

**In scope:**

- Build turn intake form/workflow for a manager to add a new turn.
- Normalize vendor inbound messages into one standard envelope.
- Build both inbound channels:
  - Telegram vendor bot trigger.
  - Generic `/vendor-in` webhook for future SMS and simulator use.
- Build the deterministic unit matcher:
  - Exact unit label.
  - Unit token match.
  - Street-name match.
  - Single-open-stage heuristic below action threshold unless explicitly allowed later.
  - Below-threshold routing to manager decision, not guessing.
- Log every inbound path to `event_log`.

**Out of scope:**

- No stage completion from vendor messages yet.
- No OpenAI classification if we choose to keep this as a purely deterministic session; otherwise only log classification output and do not act on it.
- No manager Send/Hold routing.
- No Chase button.

**Verification:**

- Submitting intake creates a new board card with all expected stages.
- The same message sent via Telegram and generic webhook creates equivalent event envelopes except for channel/sender.
- Matcher handles clean, ambiguous, typo, street-name, unknown-sender, and duplicate-like inputs without mutating stage state.
- Ambiguous matches produce candidate choices instead of an update.

## Stage 5 - Vendor Completion Loop With Human Approval

**Goal:** Wire the vendor-reply automation while preserving all human-in-the-loop gates.

**In scope:**

- Add OpenAI classification for short vendor messages using the Responses API and strict JSON schema output.
- Route `stage_started`, `delay_notice`, `question`, `not_my_unit`, and unclear messages without changing stage state unless a manager explicitly decides.
- Route low-confidence or unclear messages to the manager verbatim.
- Build completion handler:
  - Uses classifier output plus deterministic matcher.
  - Uses the same sequence guard from Stage 3.
  - Updates stage completion only when allowed.
  - Detects duplicates.
  - Logs every branch.
- Generate next-vendor draft messages:
  - Deterministic template first.
  - OpenAI tone rewrite second.
  - Fallback to deterministic template on failure or overlong output.
- Insert drafts into `outbound_queue` as `awaiting_approval`.
- Build manager router for the channel choices, Override, Skip, Snooze, Done, and Cancel. Historical note: Stage 5 shipped Send/Edit/Hold; the 2026-08-17 decision replaced those approval buttons with `Email`, `Message`, and `Both`.
- Ensure Send is the only action that contacts the next vendor.

**Out of scope:**

- No automatic vendor sends.
- No real SMS.
- No vendor scheduling or booking.
- No photo-based work verification.
- No deposit language or damage assessment.

**Verification:**

- `done with 12b` from the painter completes Paint, creates a draft to the cleaner, and shows approval buttons on the manager bot.
- Nothing is sent to the cleaner until the manager chooses a delivery channel.
- Pressing Edit lets the manager revise the draft and still requires a later Send.
- Pressing Hold sends nothing and records the decision.
- Pressing Send delivers the approved message and activates the next stage.
- A sequence violation is blocked and offers manager override.
- Duplicate completion does not advance the next stage twice or create a second draft.
- OpenAI failure still routes safely using fallback behavior.
- Cancelling a turn removes it from the active board, closes pending stages, and prevents orphan alerts.

## Stage 6 - Stall Detection, Digest, Simulator, And Photos

**Goal:** Complete the demo surface around absence detection, manager notifications, and channel-independence proof.

**In scope:**

- Build Stall Watchdog:
  - SLA age checks.
  - Alert dedupe.
  - Snooze support.
  - Business-hours suppression.
  - Manager-only alerts.
- Add Chase button that creates an approval draft but does not send.
- Finish Daily Digest with worst-first summary and manager controls.
- Add a weekly metric digest and a manager `/health` command showing vendor reply rate and auto-handled rate.
- Build `sim.html` as a plain phone-style generic inbound simulator.
- Add Telegram photo handling:
  - Store completion photos.
  - Display thumbnails.
  - Photo-only messages ask manager which unit/stage instead of guessing.
- Add unsupported-media handling, especially voice notes.

**Out of scope:**

- No computer vision on photos.
- No owner-facing reporting.
- No historical charts beyond the explicit "collecting from day one" panel.
- No production authentication overhaul.

**Verification:**

- Seeded trash-out stall fires exactly once.
- Snoozed stages do not re-alert until the snooze expires.
- Alerts outside business hours are held until the next allowed window.
- Chase creates an approval card, not an outbound message.
- Daily digest lines can trigger the same guarded manual advance path as the board.
- The board header, weekly digest, and `/health` command all report vendor reply rate and auto-handled rate consistently.
- The generic simulator can drive the same flow as Telegram and produces comparable event logs.
- Photo-only fixture stores the image and asks for manager clarification.

## Stage 7 - Full Fixture Testing And Demo Hardening

**Goal:** Make the demo reliable enough for a sales call and document known failure behavior.

**In scope:**

- Add global n8n error workflow/logging.
- Ensure failures alert the builder quietly, not the prospect.
- Run the full fixture suite F01-F20 from a clean reset.
- Record actual behavior for each fixture in progress notes.
- Rehearse the five-minute demo script end to end.
- Validate the board over a screen-share-like setup.
- Record an offline fallback screen capture.
- Export workflows and config or commit the demo assets to a private repo.

**Out of scope:**

- No production SMS.
- No client deployment.
- No new features while hardening.

**Verification:**

- All F01-F20 fixtures pass or have documented, accepted deviations.
- OpenAI key deliberately invalid still results in safe fallback behavior.
- Telegram trigger failure has a rehearsed non-live-debug path.
- Demo can be completed in under five minutes without rushing.
- Offline recording is available locally.
- A rebuild path exists from exported workflows/config.

## Stage 8 - Production Pilot Readiness

**Goal:** Prepare the demo automation for the first paying or pilot client without turning it into a multi-client SaaS.

**In scope:**

- Create a production deployment checklist for a client-owned VPS.
- Add Caddy TLS/reverse-proxy/static-board hosting for production.
- Pin Docker image versions.
- Add backup and restore procedure, including a restore test.
- Define production heartbeat monitoring, webhook health checks, retry/backoff, and a dead-letter path.
- Replace demo token auth with real authentication plan.
- Define Twilio/A2P 10DLC onboarding steps under the client's EIN.
- Add STOP/UNSUBSCRIBE handling design before any SMS goes live.
- Add vendor consent capture fields/process.
- Define quiet hours by client timezone.
- Define data retention for messages and photos.
- Draft a one-page manager runbook.
- Draft explicit contract exclusions:
  - No PMS system of record.
  - No deposit assessment.
  - No tenant screening.
  - No listing/ad automation.
  - No occupied-unit maintenance.
  - No automatic vendor chasing.
- Define success metrics:
  - Vendor reply rate.
  - Auto-handled rate.
  - Median hours per stage.
  - Median move-out-to-relist days.
  - Sequence violations blocked.

**Out of scope:**

- No multi-tenant hosting.
- No owner portal.
- No vendor scorecards.
- No turn forecasting.
- No photo verification.
- No PMS sync unless a specific paid client already has an API-capable plan and requests it separately.

**Verification:**

- A fresh client instance can be provisioned from documented steps.
- SMS legal/operational prerequisites are clearly separated from demo functionality.
- STOP and consent handling are designed before SMS is enabled.
- Backup restore is tested.
- Client can revoke access and still retain system/data ownership.
- Scope exclusions are written plainly enough to reuse in a proposal or contract.

## Session Operating Rules

- At the start of each future session, read `progress-notes.md` first, then this plan.
- Work on only the approved stage unless the user explicitly expands scope.
- Update `progress-notes.md` at the end of every session.
- Record deviations immediately, including why they happened.
- Do not advance to the next stage until the current stage's verification checks pass or the user explicitly accepts the gap.
- Reuse the same sequence guard everywhere. Do not implement a second copy.
- Reuse the same unit matcher everywhere. Do not implement a second copy.
- Log every meaningful branch to `event_log`, including branches that take no action.
- Never add an autonomous outbound vendor message path.
