# Manager Runbook

This is the one-page operating guide for a pilot manager.

## Daily Use

- Open the board at `board.<client-domain>`.
- Start with the red or oldest cards first.
- Use the stage strip to see what is done, blocked, awaiting approval, or active.
- Use the event history to understand why the system made or avoided a change.

## Vendor Replies

- A vendor reply can complete a stage only when the unit and stage are clear and the sequence guard allows it.
- If the system is unsure, it asks you to decide instead of guessing.
- A photo is stored for your review; the system does not inspect workmanship.
- Voice notes and unsupported files are forwarded for review and do not update stages.

## Approval Cards

- `Send`: releases the approved draft and activates the next vendor stage.
- `Edit`: changes the draft and keeps it waiting for approval.
- `Hold`: sends nothing and records that you held the message.
- Nothing goes to a vendor until you press `Send`.

## Board Controls

- `Mark done`: manually completes a stage through the same guard used for vendor replies.
- `Skip`: marks a stage skipped where appropriate; skipped stages count as satisfied downstream.
- `Snooze`: suppresses a stall alert temporarily.
- `Cancel`: closes an active turn and cancels open approval queue rows.

## What To Do When It Is Unsure

- Read the vendor text and candidate unit/stage.
- If it is clearly the right unit, manually advance or respond from the approval card.
- If it is unclear, contact the vendor yourself. Do not force a stage update.

## Failures

- If the board is down, use your normal make-ready process and tell the operator.
- If vendor messages stop arriving, do not ask vendors to retry repeatedly; tell the operator.
- If a wrong unit is suggested, do not approve it. Report the event history entry.
- Infrastructure errors go to the operator, not to vendors.

## Boundaries

- This is not the PMS system of record.
- It does not assess deposits, tenant liability, wear and tear, screening, listings, ads, or occupied-unit maintenance.
- It coordinates vacant-unit turn work only.
