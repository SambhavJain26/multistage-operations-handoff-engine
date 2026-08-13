# How The Make-Ready Automation Works

This document is for prospects and clients. It explains what the system does, what services are involved, and what stays under human control.

It avoids implementation details. No schemas. No variables. No code paths.

## The Short Version

The automation tracks vacant units through the make-ready sequence: notice, inspection, trash-out, repairs, paint, flooring, deep clean, QA, and relist.

It watches for two things:

- **A stage finished.** A vendor reports that work is done, or a manager marks it done.
- **A stage is stuck.** A unit has been sitting too long at the same step.

When a vendor says a stage is done, the system checks the unit, checks the vendor, checks the sequence, and then updates the board only if the action is safe.

When the next vendor needs to be contacted, the system drafts the message. The manager decides whether to Send, Edit, or Hold.

Nothing goes to a vendor without a manager pressing Send.

## What The Client Sees

The manager sees a live board of units in turn.

Each card shows:

- The unit and address.
- The current make-ready stage.
- How long it has been sitting there.
- Whether it is healthy, close to late, or already late.
- Vacancy dollars burned so far.
- The vendor assigned to the current stage.
- Recent events, such as vendor replies, manual completions, stalls, and blocked actions.

The board sorts the worst units first. The point is not to make another dashboard. The point is to make stalled units hard to miss.

## What The Vendor Does

In the demo, vendors use Telegram. In production, the intended channel is SMS after the client's Twilio and 10DLC requirements are ready.

The vendor does not log in, install an app, or learn a portal.

They send plain messages like:

- `done with 12b`
- `finished unit 7 oak`
- `running late on 14a`
- a completion photo

The system reads the message, identifies the sender, matches the unit, and decides whether it is safe to act.

## What The Manager Controls

The manager stays in control of every outbound vendor message.

When one vendor reports completion, the automation can prepare the next handoff. For example:

1. Rivera Painting says `done with 12b`.
2. The system confirms Rivera is assigned to Paint on 12B.
3. The system checks that Paint is allowed to complete.
4. The board moves 12B from Paint to the next stage.
5. The system drafts a message to Statewide Flooring.
6. The manager gets Send, Edit, and Hold.

Only Send contacts the next vendor.

Edit lets the manager change the message first. Hold keeps the message from going out.

## The Services And Tools Used

| Service or tool | What it does |
|---|---|
| n8n | Runs the automation workflows. It receives messages, calls the right workflow, and moves work through the process. |
| Postgres | Stores the durable record: turns, stages, vendors, messages, approvals, photos, and event history. |
| Board | Gives the manager a live view of every active turn and the current state of each unit. |
| Telegram | Demo messaging channel for vendor replies, manager approval cards, and manager alerts. |
| OpenAI | Reads short vendor messages and classifies intent, such as done, delayed, question, unclear, or not my unit. |
| Cloudflare Tunnel | Gives local n8n a temporary public HTTPS URL during live Telegram testing. |
| Caddy | Production-ready reverse proxy and HTTPS layer for a future client-owned deployment. It is not part of the local demo path. |
| Twilio | Planned production SMS provider. It stays disabled until a client has approved SMS registration, consent records, and legal review. |

## The Main Workflows

These are the workflow names a client may see during a walkthrough.

| Workflow | Plain-English job |
|---|---|
| Board API | Feeds the board with current units, stage ages, vacancy dollars, and recent events. |
| Turn Intake Form | Adds a new turn and creates the standard make-ready stages. |
| Vendor Telegram Ingest | Receives vendor Telegram messages during the demo. |
| Vendor Inbound API | Receives generic inbound messages, including the simulator and future SMS-style traffic. |
| Vendor Message Router | Decides what a vendor message means and whether it needs manager review. |
| Unit Matcher | Matches a vendor message to the right unit without guessing on vague messages. |
| Sequence Guard | Enforces the work order, such as repairs before paint and paint before flooring. |
| Vendor Completion Handler | Completes a valid vendor-reported stage and prepares the next handoff draft. |
| Manager Action Core | Applies manager decisions: Send, Edit, Hold, Skip, Snooze, Chase, Cancel, and Done. |
| Manager Telegram Router | Handles manager Telegram commands and button presses. |
| Stall Watchdog | Finds units sitting too long at one stage and alerts the manager. |
| Health Core | Calculates reply rate, auto-handled rate, stalled stages, and active turn metrics. |
| Builder Error Handler | Alerts the builder if a workflow fails. It does not alert vendors or prospects. |

## How A Vendor Completion Moves Through The System

Here is the normal path.

1. A vendor sends a message.
2. n8n receives it through Telegram or the generic inbound path.
3. The system looks up the sender.
4. OpenAI helps classify the message.
5. The Unit Matcher checks which active unit the message refers to.
6. The Sequence Guard checks whether that stage is allowed to finish.
7. Postgres records the event and updates the stage.
8. The board refreshes.
9. If the next stage needs an outside vendor, the system drafts the handoff.
10. The manager chooses Send, Edit, or Hold.

If anything is unclear, the system asks the manager instead of guessing.

## How Sequence Protection Works

Make-ready work has a real order.

Repairs should happen before paint. Paint should happen before flooring. Deep clean should happen after repairs, paint, and flooring. QA comes after deep clean.

The Sequence Guard enforces that order.

Example:

If a cleaner reports `14a cleaned` while repairs are still open, the system blocks the completion and explains why:

```text
Repairs still open on 14A. Cleaning before repairs means cleaning twice.
```

That is the point. The system does not reward speed if the sequence creates rework.

## How The System Handles Unclear Messages

The system is conservative by design.

| Vendor message | What happens |
|---|---|
| `done with 12b` | Completes the matching active stage if the vendor and sequence are correct. |
| `done` | Asks the manager which unit. |
| `finished the one on maple` | Asks the manager when more than one Maple unit could match. |
| `cant get there till thursday` | Routes to manager review as a delay. |
| `is the water back on at 12b?` | Routes to manager review as a question. |
| Duplicate `done with 12b` | Logs the duplicate and does not create a second handoff. |
| Unknown sender | Logs the message and does not reveal unit matches to that sender. |

Wrong confident automation is worse than asking. This system asks.

## Photos And Voice Notes

Photos are stored and shown to the manager when they arrive.

The system does not inspect the image or decide whether the work is good. A photo is evidence for a human, not proof for the automation.

Voice notes and unsupported files are saved as manager-review items. They do not complete stages.

## Stall Alerts And Chasing

The Stall Watchdog checks active stages against their allowed time.

If a stage is overdue, the manager gets an alert.

The system does not chase the vendor on its own. If the manager wants to follow up, the system can draft a Chase message, but the manager still has to approve it before anything is sent.

## Metrics The Manager Sees

The board and health workflow track:

- Units currently in turn.
- Vacancy dollars burning now.
- Vendor reply rate.
- Auto-handled rate.
- Stalled stage count.
- Recent workflow events.

These are operating metrics, not promises. They help the client see whether the automation is useful with their vendors.

## What Runs Locally In The Demo

The demo runs on the builder's local machine:

- n8n runs the workflows.
- Postgres stores the demo state.
- The board runs as a local page.
- Telegram reaches local n8n through a temporary Cloudflare Tunnel.
- OpenAI handles short message classification and draft wording when needed.

The demo uses fictional Cedar Ridge data. It does not contain client data.

## What Changes For A Paid Pilot

The Stage 8 readiness pack defines the production approach.

For a real client:

- The system runs on a VPS owned and paid for by the client.
- Caddy provides HTTPS for n8n and the board.
- Docker images are pinned to fixed versions.
- Backups and restore tests are required before go-live.
- Monitoring alerts the builder when workflow errors or silent failures appear.
- SMS stays disabled until the client has a paid Twilio account, approved 10DLC setup, vendor consent records, and legal review for the states where they operate.

This is a single-client setup. It is not a shared SaaS instance.

## What The System Does Not Do

It does not:

- Touch the client's PMS.
- Replace Buildium, AppFolio, Rent Manager, Propertyware, or any other system of record.
- Prove the work is finished.
- Inspect photos.
- Send a vendor message without manager approval.
- Chase a vendor without manager approval.
- Schedule or book vendors.
- Handle occupied maintenance.
- Decide security deposit deductions.
- Classify damage as tenant liability.
- Screen tenants.
- Write listings or run ads.
- Forecast turn duration.

Those limits are intentional. The system coordinates make-ready handoffs. It does not take over property management.

## The Honest Success Test

The system works best when vendors already text the manager when a stage is done.

The first question for any prospect is:

```text
When your painter finishes a unit, how do you find out?
```

If vendors already text, there is a signal to capture. If the manager has to call or drive by to find out, the board can still help, but the vendor automation will be weaker.

That is why vendor reply rate stays visible on the board. It tells the client whether the automation is working in their real operation.
