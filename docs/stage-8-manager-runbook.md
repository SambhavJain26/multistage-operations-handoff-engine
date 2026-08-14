# Manager Runbook

## Daily Use

- Open the Make-Ready Operations Interface in Airtable.
- Start with Stalled, Due Soon, Awaiting Approval, and Partially Sent.
- Open a turn to read its linked stages, vendor messages, evidence, drafts, and delivery results.
- Add new turns through the Airtable Turn Intake form. Don't edit synced operating records.

## Vendor Replies

Vendors may reply in Telegram or by email. The automation uses OpenAI to understand the wording, then fixed rules verify the sender, unit, assigned stage, duplicate status, and work sequence.

A clear completion can move a stage. Questions, delays, unusual requests, financial language, unclear wording, voice notes, and unsupported files stay unchanged and come to you for review.

## Approval Cards In Telegram

- `Send both` sends the approved text by email and Telegram.
- `Edit` lets you replace the draft before approving it.
- `Hold` sends nothing.
- `Retry Email` or `Retry Telegram` repeats only a failed channel.

Both vendor destinations must be configured before Send both works. The next stage activates after the first successful delivery. A failed second channel reads `Partially Sent` in Airtable and produces a Telegram alert.

## Other Manager Controls

- `Done` marks verified work complete through the Sequence Guard.
- `Skip` records that the stage wasn't required.
- `Snooze` pauses a stall alert for 24 hours.
- `Chase` prepares a vendor update for approval; it doesn't send on its own.
- `Cancel` closes the turn and its open work.
- `/health` returns current operating measures.

## When The Automation Is Unsure

Read the AI summary and the original vendor message. If the unit or request isn't clear, contact the vendor through the client's normal process. Don't force a completion.

## Failures

- Airtable stale: continue normal work and tell the builder. Postgres keeps the authoritative state.
- One delivery fails: use the failed-channel Retry control after the contact or service is fixed.
- Both deliveries fail: the stage stays inactive until one approved delivery succeeds.
- OpenAI fails: no stage changes; review the message manually.
- Workflow failure: the builder receives the alert. Vendors receive no automatic recovery message.

## Boundaries

This automation coordinates vacant-unit turn stages. It doesn't replace the PMS, assess workmanship, decide deposits or tenant liability, process invoices, screen tenants, publish listings, manage ads, handle occupied maintenance, or contact vendors without manager approval.
