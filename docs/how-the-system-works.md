# How The Make-Ready Coordination Automation Works

Vacant-unit turns often slow down between trades. One vendor finishes, the manager doesn't hear about it quickly, and the next vendor starts late. The work may be complete, but the handoff isn't.

This automation watches those handoffs. It reads vendor updates, checks the correct unit and work sequence, prepares the next message, and asks the manager for approval before contacting a vendor.

## What The Client Uses

Managers work in two familiar places:

- **Airtable** shows active turns, current stages, due work, communications, approvals, delivery results, and performance measures. Its form also collects new turns.
- **Telegram** sends manager alerts and approval cards. Managers choose a delivery channel, skip, snooze, chase, cancel, or mark work done there.

Vendors can use **Telegram or email**. The manager decides per message whether it goes by email, by Telegram, or both, and vendor replies from either channel follow the same decision process.

There is no separate custom dashboard.

## A Typical Handoff

1. A painter emails, "12B is finished," as a reply to the job message.
2. The automation connects that reply to the painter, unit, and Paint stage.
3. OpenAI reads the wording and identifies the likely intent.
4. Fixed safety checks confirm the sender, unit, stage, prior work, and duplicate status.
5. Paint completes only when every check passes.
6. The automation prepares the Flooring handoff.
7. The manager receives the draft in Telegram and presses Email, Message, or Both.
8. After approval, the vendor receives the message on the chosen channels.
9. Airtable shows each delivery result and the newly active stage.

The same flow works when the first update arrives in Telegram.

## What Each Service Does

| Service | Responsibility |
|---|---|
| Airtable | Manager workspace, turn-intake table, linked records, evidence, approval status, and operating tables. |
| Telegram | Vendor messages plus all manager alerts, decisions, and approvals. |
| Client email mailbox | Receives vendor replies through IMAP and sends approved messages through SMTP. |
| n8n | Runs the workflows and moves information between each service. |
| OpenAI | Interprets free-form vendor messages, writes manager summaries, and improves factual drafts. |
| Postgres | Keeps the private, authoritative history of turns, stages, messages, approvals, and delivery attempts. |
| Caddy | Provides HTTPS access to n8n on a client-owned production server. |

Airtable mirrors Postgres. If Airtable has an outage, the underlying turn state remains intact and sync catches up later.

## The Main Workflows

| Workflow group | What it does |
|---|---|
| Airtable Workspace | Reads new Airtable intake records and keeps the operating tables current. |
| Vendor Communications | Receives email, Telegram, and other approved inbound messages, then interprets and routes them safely. |
| Stage Update | Applies permitted completions, checks the work order, and prepares the next handoff. |
| Manager Operations | Sends Telegram approval cards, manager controls, daily updates, and health information. |
| Vendor Delivery | Sends approved vendor messages through email and Telegram and records each delivery separately. |
| Monitoring | Watches for stalled work and prepares the weekly metrics update. |
| Builder Error Handler | Alerts the operator when a workflow or external service fails. |

## How AI Is Used

Vendor messages don't follow a script. A person may write "wrapped up," "all good except the closet," "materials delayed," or ask a question the automation hasn't seen before.

OpenAI turns that wording into a structured interpretation: intent, unit and stage references, dates, a manager summary, a suggested reply, confidence, and safety flags. It sees the known vendor, active assignments, reply thread, and a small amount of recent context.

AI doesn't receive tools and can't change a record. It proposes meaning. Fixed rules decide whether the system may act.

## When A Stage Completes Automatically

All of these conditions must pass:

- OpenAI identifies `stage_complete` with at least 80% confidence.
- The email thread points to the exact job, or the fixed unit matcher finds one strong match.
- The sender matches the vendor assigned to that stage.
- The message isn't a duplicate and has no safety flag.
- Earlier required stages are complete or skipped.

If one check fails, the stage stays put. The manager gets a summary instead.

## Questions And Unclear Messages

Questions, delays, schedule changes, access problems, materials issues, invoices, deposits, tenant liability, unrelated messages, and low-confidence interpretations don't move a stage.

OpenAI summarizes the message and may prepare a reply. Telegram shows that draft to the manager. The vendor hears nothing until the manager approves it.

Unknown senders also go to the manager. The automation doesn't reveal unit information to an unverified sender.

## Manager-Chosen Delivery

The manager picks the channel on every approval: Email, Message, or Both. A vendor reachable on only one channel can still be contacted there.

Choosing `Both` creates two separate delivery attempts. If Telegram succeeds and email fails, the next stage becomes active after the successful delivery, Airtable reads `Partially Sent`, and the manager gets a Telegram alert. Retrying email doesn't repeat Telegram.

If the chosen channel has no destination on file, nothing is sent and the manager gets a configuration alert.

No automatic chasing. No silent resend.

## What The Automation Does Not Do

- It doesn't replace the client's property management system.
- It doesn't judge workmanship from a photo.
- It doesn't decide deposits, tenant liability, damage, wear and tear, invoices, or payments.
- It doesn't screen tenants, publish listings, manage ads, or handle occupied maintenance.
- It doesn't contact a vendor without manager approval.
- It doesn't enable SMS in the current build.

The scope stays narrow: coordinate vacant-unit turn stages, catch delayed handoffs, and keep the manager in control.

## What A Pilot Measures

The pilot tracks vendor reply rate, messages handled without manual interpretation, median time per stage, move-out-to-relist time, vacancy loss, delivery failures, and unsafe sequence attempts blocked.

Those numbers answer the real question: did faster, safer handoffs reduce avoidable vacancy time without taking decisions away from the manager?
