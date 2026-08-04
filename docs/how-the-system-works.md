# How The System Works

This is a reference document for the builder, not for editing code. Its purpose is one
thing: at every point, know which workflow, and where useful which node, is responsible for
a given piece of data or a given decision. If the board shows something and the question is
"what put that there," the answer is in this file.

Scope: the runtime that runs day to day, Stages 3 through 7 (visibility board,
intake and matching, vendor completion loop, stall detection, and hardening). Stage 8
production/pilot material (VPS, Caddy, backup, SMS design) is a separate track and is only
pointed to at the end.

## The One-Paragraph Version

A vendor's text message, or a manager's tap on the board, both resolve to the same place: a
Postgres database of turns and stages. Nothing advances a stage without passing through one
shared guard that checks whether the prerequisite stages are actually done. Nothing leaves
for a vendor without a manager pressing Send on a drafted message. The system knows what a
vendor said. It does not know that the work is actually finished, and it is not built to.

## The Workflows

| Workflow (n8n name) | ID | What it owns | What starts it |
|---|---|---|---|
| Sequence Guard | `wf3-sequence-guard` | The one deterministic rule set for whether a stage is allowed to complete | Called by other workflows (Execute Workflow), never triggered directly |
| Stage Complete Core | `wf3-stage-complete-core` | Applying a completion after the guard passes, activating the next pending stage, logging the event | Called by Stage Complete API and by the manager's Telegram `DONE` callback |
| Stage Complete API | `wf3-stage-complete-api` | The authenticated `POST /webhook/stage/complete` entry point | Webhook, hit by the board's "Mark done" control |
| Board API | `wf3-board-api` | The read model behind the board: sorted turns, health color, dollars burned, latest event | Webhook, polled by `board/index.html` every 10 seconds |
| Manager Daily Digest | `wf3-daily-digest` | The 7am worst-first summary with Done/Skip/Snooze/Chase/Cancel buttons | Schedule Trigger (daily 7:00) and a manual trigger for testing |
| Manager Telegram Router | `wf3-manager-router` | Parses every manager message and every button press from one Telegram trigger: `/health`, `DONE:`, `SEND:`/`HOLD:`/`EDIT:`, `SKIP:`/`SNOOZE:`/`CHASE:`, `CANCEL:` | Telegram Trigger on the manager bot (message + callback_query) |
| Turn Intake Form | `wf4-turn-intake` | Creating a new turn and its 11 stage rows from a manager form submission | Form Trigger |
| Unit Matcher | `wf4-unit-matcher` | Scoring inbound text against active stages to find the unit it refers to | Called by the Vendor Message Router |
| Vendor Inbound API | `wf4-vendor-in-api` | The authenticated generic `POST /webhook/vendor-in` entry point | Webhook, used by SMS-equivalent testing and `board/sim.html` |
| Vendor Message Router | `wf4-vendor-router` | Vendor lookup, OpenAI classification with deterministic fallback, calling the matcher, deciding what happens next | Called by both inbound channels |
| Vendor Telegram Ingest | `wf4-vendor-telegram-ingest` | Normalizing Telegram vendor messages, photos, and voice notes into the shared envelope shape | Telegram Trigger on the vendor bot |
| Manager Action API | `wf5-manager-action-api` | The authenticated `POST /webhook/manager-action` entry point | Webhook, used by the board's approval controls |
| Manager Action Core | `wf5-manager-action-core` | Applying Send, Hold, Edit, Skip, Snooze, Cancel, and Chase as one set of state changes | Called by Manager Action API and by the Telegram router |
| Vendor Completion Handler | `wf5-vendor-completion-handler` | Re-checking the guard, marking a stage complete, storing an evidence photo if present, drafting the next vendor's message, sending the approval card | Called by the Vendor Message Router when a message is classified as a completion |
| Health API | `wf6-health-api` | The authenticated `GET /webhook/health` endpoint | Webhook |
| Health Core | `wf6-health-core` | Computing vendor reply rate, auto-handled rate, active turns, dollars burning, and stalled-stage count | Called by Health API, the manager's `/health` command, and the weekly digest |
| Stall Watchdog | `wf6-stall-watchdog` | Finding stages past their SLA, deduping alerts, holding alerts outside business hours | Schedule Trigger (every 15 minutes) and a `POST /webhook/stall-watchdog` for manual/demo runs |
| Weekly Metrics Digest | `wf6-weekly-digest` | The Monday 8am metrics summary to the manager | Schedule Trigger (weekly) |
| Builder Error Handler | `wf7-error-handler` | Catching any workflow failure, logging it, alerting the builder (never the manager or a vendor) | n8n's Error Trigger, set as `settings.errorWorkflow` on every other workflow |

A 20th file, `wf7-error-smoke`, exists in `n8n-workflows/`. It is a local-only diagnostic
that intentionally throws so the error path can be exercised. It is left out of the normal
import so it never appears in the n8n editor's demo-visible workflow list.

## The Main Path, In Execution Order

**A turn starts.** `Turn Intake Form` runs `Normalize Intake Submission`, then
`Insert Intake Turn And Stages`, a single query that creates the turn row and all 11 stage
rows in one pass, with `NOTICE` active and everything else pending.

**A vendor replies.** Whichever channel it arrives on, Telegram or the generic webhook, the
first job is normalizing to the same envelope shape and handing off to one router.

- Telegram: `VendorTelegramTrigger` reads photo, voice, or document fields, runs
  `Normalize Vendor Telegram Message`, then `Call Vendor Router From Telegram`.
- Generic: `POST Vendor In Webhook` runs `Normalize Vendor In Request`, checks
  `Vendor In Authorized?` and `Vendor In Valid?`, then `Unwrap Vendor Envelope` before
  `Call Vendor Router`.

**The router decides what the message means.** Inside `Vendor Message Router`:
`Load Vendor Context` looks the sender up by `telegram_chat_id`/`phone_e164`. `Known Vendor?`
branches: unknown senders go straight to `Prepare Unknown Event` and get logged with no reply
and no candidate disclosure. Known senders go through `Build OpenAI Classification Request`,
`Classify Vendor Message With OpenAI` (a direct HTTP call to the Responses API with a strict
JSON schema, model `gpt-5.6-luna`), and `Parse Classification Or Fallback`, which falls back
to a regex classifier if the model call fails, times out, or returns something unusable.
`Call Unit Matcher` scores the message against every currently active stage. `Prepare Known
Route` then applies one priority order: unsupported media, then duplicate-like, then
photo-only, then low-confidence or unclear classification, then an ambiguous match, then a
vendor/stage mismatch, then, only if none of those fired, a genuine `stage_complete`.

**A completion is confirmed.** `Should Complete Stage?` sends the message on to
`Vendor Completion Handler`, which runs `Normalize Completion Candidate` and then
`Call Sequence Guard`, the same sub-workflow the board's manual path uses. If the guard
returns `allowed: false`, `Log Vendor Guard Block` records the reason and nothing changes. If
it passes, `Complete Stage And Queue Next` marks the stage complete, stores the evidence
photo if the message carried one, and either activates the next stage directly (if it is an
in-house/`inspect` trade) or sets it to `awaiting_approval` and inserts a draft into
`outbound_queue`. `Format Completion Notification` and `Send Manager Approval Card` put a
Send/Edit/Hold card in the manager's Telegram.

**A manager acts.** The approval card's buttons, the board's own approval controls, and the
daily digest's Done/Skip/Snooze/Chase/Cancel buttons all resolve to the same place:
`Apply Manager Action` inside `Manager Action Core`, reached either through
`Manager Action API` or through `Manager Telegram Router`'s callback parsing
(`Parse Manager Update`). `SEND` activates the next stage. `CANCEL` closes every open stage
and queued draft for that turn in the same statement.

**The board reads it back.** `GET Board Webhook` runs `Normalize Board Auth`, then
`Load Board State`, a single query joining the current active/awaiting stage, the last five
events, and the 30-day vendor-reply-rate and auto-handled-rate metrics for every active turn.
`Shape Board Response` computes each card's age, dollars burned, and red/amber/green health,
then sorts worst first.

## What Lives In The Database Rather Than The Orchestrator

There are no views, functions, or triggers anywhere in `db/postgres/`. Every piece of logic
that looks like a stored procedure is actually a `WITH` chain inside a plain `SELECT` or
`INSERT`, living inside a workflow's Postgres node (`Evaluate Sequence Guard`'s rule map is
the one piece of business logic written in JavaScript rather than SQL; the completion and
approval chains are pure CTEs). Two constraints do real enforcement work that is easy to miss
by reading workflow JSON alone:

- **`uniq_one_active_stage_per_turn`**, a partial unique index on `turn_stage(turn_id) WHERE
  status = 'active'`. A turn can never have two active stages at once. This is why the
  board always has exactly one current stage per unit, enforced by Postgres itself, not by
  application code remembering to check.
- **`uniq_outbound_awaiting_per_stage_vendor`**, a partial unique index on
  `outbound_queue(stage_id, vendor_id) WHERE status = 'awaiting_approval'`. This is what
  actually stops a duplicate "done" message from creating a second approval card, not the
  60-second duplicate-detection window in the router (that window is a fast, best-effort
  check; this index is the hard backstop).

A row-level CHECK on `turn_stage` also guarantees that a stage cannot be `complete` or
`skipped` without `completed_at` and `completed_via` both being set, so the audit trail can
never show a silently-finished stage.

Every allowed value, by column:

| Column | Allowed values |
|---|---|
| `vendor.trade` | `paint`, `clean`, `flooring`, `repairs`, `trashout`, `inspect` |
| `"turn".status` | `active`, `complete`, `cancelled` |
| `turn_stage.status` | `pending`, `active`, `awaiting_approval`, `complete`, `skipped`, `blocked`, `cancelled` |
| `turn_stage.completed_via` | `vendor_reply`, `manual`, `override`, `skip` |
| `outbound_queue.channel` | `telegram`, `generic`, `board`, `digest` |
| `outbound_queue.status` | `awaiting_approval`, `editing`, `sent`, `held`, `rejected`, `cancelled` |
| `event_log.actor_type` | `vendor`, `manager`, `system` |
| `event_log.channel` | `telegram`, `generic`, `board`, `digest`, `seed`, `import`, `form`, `system` |
| `media_asset.channel` | `telegram`, `generic` |
| `media_asset.media_type` | `photo`, `voice`, `unsupported` |
| `media_asset.status` | `received`, `stored`, `needs_manager`, `unsupported` |

`event_log.event_type` allows 30 values, covering every branch above: `reply_received`,
`stage_complete`, `guard_blocked`, `override`, `msg_drafted`, `msg_sent`, `msg_held`,
`msg_edit_requested`, `msg_edited`, `msg_rejected`, `stall_alert`, `stall_alert_held`,
`chase_drafted`, `weekly_digest`, `health_check`, `photo_received`, `photo_stored`,
`manager_photo_match_needed`, `unsupported_media`, `unmatched`, `unknown_sender`,
`manual_advance`, `stage_seeded`, `prospect_imported`, `turn_intake`, `vendor_inbound`,
`manager_match_needed`, `duplicate_inbound`, `classification_fallback`, `draft_fallback`,
`stage_awaiting_approval`, `stage_skipped`, `stage_snoozed`, `turn_cancelled`,
`workflow_error`. If a branch fires and it is not in this list, the insert fails loudly
rather than silently logging something unrecognized.

The 11-stage template itself (`fixtures/stage-template.json`) is JSON documentation of the
dependency graph (which stages require which others complete first), not an enforced
constraint. The actual enforcement of that graph is `Evaluate Sequence Guard`'s rule map, in
the Sequence Guard workflow, not the database.

## What It Deliberately Refuses To Do

It never sends a vendor a message on its own. Every draft sits in `outbound_queue` as
`awaiting_approval` until a manager presses Send, edits it, or puts it on Hold. It never
reads or writes any property management system; it runs entirely beside one, with zero
integration of any kind.
It never inspects a photo; `media_asset` rows store and display images for a human to look
at, and nothing in the workflow set evaluates their content. It never assesses damage, wear
and tear, tenant liability, or deposit deductions, a hard exclusion with no code path that
touches that subject. It never chases a vendor on its own; a stalled stage produces a
manager-only alert, and Chase only ever drafts a message for the manager to approve. It never
guesses at an ambiguous match; below the unit matcher's score-70 threshold, or with more than
one untied candidate, the message routes to the manager instead of picking a unit.

## What It Genuinely Cannot Do

These are limits of what the system can know, not gaps in what was built. It cannot know a
stage is actually finished, only that a vendor reported it finished; the manager still QAs
the unit. It cannot judge whether a photo shows good work. It cannot forecast how long a turn
will take; it reports elapsed time, never a prediction. It cannot deliver production SMS yet;
Telegram is a demo stand-in, and real SMS needs 10DLC carrier registration under a client's
own business identity, which cannot start before a client exists. It cannot function as a
system of record; the client's PMS keeps that role, and turning this off costs visibility,
not data. It cannot promise a vendor reply rate; the automation's value is conditional on it,
which is why the visibility board is built to still work at 0%.

## Troubleshooting

Each symptom below names the workflow to open first.

- **Board shows stale or blank state.** Open `Board API`. Check `Load Board State`'s
  execution and confirm the webhook registered after the last n8n restart;
  registration can lag container readiness for a few seconds.
- **Board shows a "reconnecting" strip and nothing updates.** The frontend is intentionally
  showing last-known state rather than going blank. Confirm `BOARD_DEMO_TOKEN` matches what
  `board/index.html` is sending and that `Board API` itself is reachable.
- **A Telegram trigger never fires.** Open whichever Telegram-triggered workflow is
  affected (`Vendor Telegram Ingest` or `Manager Telegram Router`) and confirm `WEBHOOK_URL`
  is HTTPS inside the running n8n container, not just in `.env` on the host; a
  `docker compose up -d --force-recreate n8n` is required after changing it, a plain
  `restart` does not pick it up.
- **A manager approval card never arrives after a vendor completion.** Open
  `Vendor Completion Handler` and check `Send Manager Approval?`; it is gated on
  `MANAGER_TELEGRAM_CHAT_ID` being neither blank nor the import-time placeholder sentinel.
- **A vendor message was logged but nothing else happened.** Open `Vendor Message Router`
  and read the logged event's `outcome` field; most non-completion outcomes
  (`manager_match_needed`, `low_confidence`, `stage_vendor_mismatch`, `duplicate_like`) are
  correct behavior, not a bug, and route to the manager on purpose.
- **A stage completion returns a block instead of completing.** Open `Sequence Guard`; the
  response's `reason` and `blocked_by` fields name exactly which prerequisite stage is still
  open.
- **A Telegram button press throws "query is too old or invalid."** Open
  `Manager Telegram Router` and confirm `telegram_callback_query_id` survived every
  Execute Sub-workflow hop back to `Answer Manager Callback`; it is easy for this field to
  get dropped by a Postgres node that reselects columns without including it.
- **Any workflow fails outright.** Open `Builder Error Handler` and read the corresponding
  `workflow_error` row in `event_log`; a Telegram alert only reaches the builder if
  `BUILDER_TELEGRAM_CHAT_ID` was substituted with a real chat ID at import time, never the
  manager or a vendor.

## Production

Stage 8 covers what changes for a real client: a client-owned VPS, Caddy TLS in front of n8n
and the board, backup and restore, monitoring, and the SMS design that stays disabled until a
client exists to register it under. None of that is expanded here; see
`docs/stage-8-production-pilot-readiness.md`.
