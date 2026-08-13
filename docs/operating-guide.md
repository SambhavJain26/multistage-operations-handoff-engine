# Make-Ready Automation Operating Guide

This guide is for operating and testing the demo by hand. It is not a sales script and it is not a fixture-runner reference.

Use this when you want to understand what the automation does, what to click, what message to send, and what should change on the board.

The only script this guide asks you to run is the demo reset:

```powershell
.\scripts\reset-demo.ps1
```

Everything else below is done from the board, the vendor simulator, Telegram, or n8n's own workflow list.

## What Should Be Running

Before testing, these pieces should already be up:

- n8n at `http://localhost:5678`.
- Postgres behind n8n.
- The board page from `board/index.html`.
- The vendor simulator page from `board/sim.html`.
- For live Telegram tests only: the Cloudflare Tunnel sidecar and the live Telegram workflows.

Open the board from whichever local static page is already serving the repo. In the usual local setup, that is:

```text
http://localhost:8080/board/index.html
```

Open the simulator at:

```text
http://localhost:8080/board/sim.html
```

The normal demo-visible workflow list in n8n should contain 19 workflows. The names should be clean, with no `WF-3` or `WF-7` prefixes.

Expected workflow names:

| Workflow | What you use it for |
|---|---|
| Board API | Feeds the live board. |
| Stage Complete API | Handles `Mark done` from the board. |
| Stage Complete Core | Applies manual completion after the guard passes. |
| Sequence Guard | Blocks stages that are out of order. |
| Turn Intake Form | Adds a new turn from a manager form. |
| Vendor Inbound API | Receives simulator and generic inbound messages. |
| Vendor Telegram Ingest | Receives live vendor Telegram messages. |
| Vendor Message Router | Reads vendor messages and decides the safe next step. |
| Unit Matcher | Matches vendor text to the right unit. |
| Vendor Completion Handler | Completes a stage and creates the next approval draft. |
| Manager Action API | Receives manager action requests from local controls. |
| Manager Action Core | Applies Send, Edit, Hold, Skip, Snooze, Chase, and Cancel. |
| Manager Telegram Router | Handles manager Telegram messages and button presses. |
| Manager Daily Digest | Sends the manager's daily turn summary when live Telegram is active. |
| Health API | Shows health metrics. |
| Health Core | Computes reply rate, auto-handled rate, dollars burning, and stalled count. |
| Stall Watchdog | Finds stages that have gone past their allowed time. |
| Weekly Metrics Digest | Sends the weekly metric summary when live Telegram is active. |
| Builder Error Handler | Logs workflow failures and alerts only the builder. |

`Error Smoke` is not part of the normal demo workspace. It is a hardening check workflow and should be imported only when you are testing the error handler.

## Start From A Clean Demo State

Run:

```powershell
.\scripts\reset-demo.ps1
```

Then open the board.

Expected opening state:

- Six Cedar Ridge fixture units are visible.
- `12B / 418 Maple St` is the worst card and should be red.
- `12B` is at `Paint`.
- `14A / 418 Maple St` is blocked later in the sequence because repairs are still open.
- `3 / 7 Oak Ave` has an old `Trash-out` stage and is ready to prove stall detection.
- The board shows four headline metrics: units in turn, dollars burning now, vendor reply rate, and auto-handled rate.
- The board history section shows recent manager, vendor, and system events.

If the board shows a reconnecting strip, it is showing the last-known state. That is intentional. It means the board page is still alive but the Board API is not responding.

## Test 0: Add A Turn From Intake

Use this when you want to prove the manager can add a new turnover without touching the database.

Steps:

1. Open n8n.
2. Open `Turn Intake Form`.
3. Open the form URL from the workflow.
4. Submit a fictional unit with a move-out date, monthly rent, and selected vendors.
5. Return to the board.

Expected result:

- A new active turn appears on the board.
- `Notice received` is the first active stage.
- The rest of the standard stages are created behind it.
- Vendor-assigned stages use the vendors selected in the form.

What this proves:

The automation can start a new turn from manager intake, not only from seeded demo data.

## Test 1: Read The Board

Open the board and look at the first card.

What to expect:

- Cards are sorted worst first.
- Red means the current stage is past its allowed time.
- Amber means the stage is nearing risk.
- Green means it is not currently late.
- The large age number is time at the current stage.
- `Rent burned` is based on the unit's move-out date and monthly rent.
- The stage strip shows every stage in the turn.

How to read the stage strip:

| Letter | Meaning |
|---|---|
| `D` | Done. |
| `S` | Skipped. |
| `A` | Active now. |
| `W` | Waiting for manager approval. |
| `P` | Pending. |
| `X` | Cancelled. |

What this proves:

The automation is not only reacting to messages. It also gives the manager a live view of which turns are stuck.

## Test 2: Complete A Stage From The Board

Use this when you want to prove the system works even if no vendor replies.

Steps:

1. Start from a clean reset.
2. On the `12B` card, leave the selected stage as `Paint`.
3. Click `Mark done`.
4. Watch the toast message and the board refresh.

Expected result:

- `12B Paint` completes.
- The next stage becomes `Flooring`.
- The event logs as a manual manager action.
- Vendor reply rate goes down because this completion came from the manager, not from a vendor.

What this proves:

The board is useful even at a 0% vendor reply rate. A manager can still move turns forward, and the same sequence guard is used.

## Test 3: Block An Out-Of-Order Stage

Use this to prove the rework guard.

Steps:

1. Start from a clean reset.
2. Find `14A / 418 Maple St`.
3. In the stage dropdown, choose `Deep clean`.
4. Click `Mark done`.

Expected result:

- The board refuses the completion.
- You should see a reason similar to: `Repairs still open on 14A. Cleaning before repairs means cleaning twice.`
- No stage should complete.
- The card should remain in the active turn list.

What this proves:

The system does not let someone mark cleaning done while repairs are still open. That is the core sequencing rule.

## Test 4: Send A Vendor Completion Through The Simulator

Use the simulator when you do not want to touch Telegram.

Steps:

1. Start from a clean reset.
2. Open `board/sim.html`.
3. Pick `Rivera Painting`.
4. Click `Done 12B`, or type `done with 12b`.
5. Click `Send`.
6. Return to the board.

Expected result:

- The simulator should reply with an outcome like `completed_awaiting_approval`.
- `12B Paint` completes through the vendor path.
- `12B Flooring` moves to waiting for manager approval.
- The board shows an approval note: the next vendor has not been contacted yet.
- Nothing is sent to Statewide Flooring until the manager approves it.

What this proves:

A vendor-style message can complete the current assigned stage, but the next outbound message is still human-gated.

## Test 5: Prove That A Bare Message Does Not Guess

Steps:

1. Start from a clean reset.
2. Open `board/sim.html`.
3. Pick `Rivera Painting`.
4. Type `done`.
5. Click `Send`.

Expected result:

- The simulator should report `manager_match_needed` or another manager-review outcome.
- No stage should complete.
- No approval draft should be created.

What this proves:

The system does not guess the unit when the message is too vague.

## Test 6: Prove Ambiguous Unit Handling

Live Telegram is the best way to test this, but the lesson is the same in the generic path.

Message to send as Rivera Painting:

```text
finished the one on maple
```

Expected result:

- The system sees that more than one Maple unit could match.
- It asks for manager review instead of picking one.
- No stage changes.

What this proves:

The unit matcher is conservative. It asks instead of updating the wrong unit.

## Test 7: Prove Typo Tolerance

Steps:

1. Start from a clean reset.
2. Open `board/sim.html`.
3. Pick `Rivera Painting`.
4. Type `finshed unit 12b`.
5. Click `Send`.

Expected result:

- The message still matches `12B`.
- `Paint` completes.
- `Flooring` waits for manager approval.

What this proves:

The automation can handle common vendor typos without needing polished messages.

## Test 8: Prove Duplicate Protection

Steps:

1. Start from a clean reset.
2. Open `board/sim.html`.
3. Pick `Rivera Painting`.
4. Send `done with 12b`.
5. Send the same message again within a minute.

Expected result:

- The first message completes `12B Paint`.
- The second message is treated as a duplicate.
- There should not be a second approval card or a second draft for the same stage.

What this proves:

A vendor double-texting does not double-advance the sequence.

## Test 9: Prove Questions And Delays Do Not Mutate The Turn

Use these messages one at a time from the simulator.

As `Dale Hutchins`:

```text
cant get there till thursday, sorry
```

As `Rivera Painting`:

```text
is the water back on at 12b?
```

Expected result:

- Delay messages route to manager review.
- Questions route to manager review.
- No stage completes.
- No vendor handoff draft is sent.

What this proves:

The system separates useful status updates from completion claims. A question is not treated as work done.

## Test 10: Prove Photo And Voice Handling

Photo-only test:

1. Start from a clean reset.
2. Open `board/sim.html`.
3. Pick `Rivera Painting`.
4. Click `Photo only`.

Expected result:

- The photo is stored for manager review.
- No stage completes.
- The system does not inspect the photo or decide whether the work is good.

Voice-note test:

1. Start from a clean reset.
2. Open `board/sim.html`.
3. Pick `Rivera Painting`.
4. Click `Voice note`.

Expected result:

- The message is logged as unsupported media.
- No stage completes.
- The manager should review it manually.

What this proves:

Photos are evidence for a human. Voice notes do not break the workflow, but the system does not try to interpret them.

## Test 11: Prove Deposit Language Is Not Assessed

Steps:

1. Start from a clean reset.
2. Open `board/sim.html`.
3. Pick `Rivera Painting`.
4. Send:

```text
the tenant trashed this place, that carpet is coming out of their deposit
```

Expected result:

- The message routes to manager review.
- No stage completes.
- The system does not decide tenant liability.
- The system does not write deposit language.

What this proves:

Deposit assessment is outside the automation. This is a hard boundary.

## Test 12: Manager Approval After Vendor Completion

This requires live Telegram manager approval cards.

Steps:

1. Start from a clean reset.
2. From the Rivera vendor Telegram group, send:

```text
done with 12b
```

3. Watch the manager Telegram group or manager direct chat.
4. Wait for the approval card.
5. Press `Send`.
6. Return to the board.

Expected result:

- `12B Paint` completes.
- The manager receives a draft handoff to Statewide Flooring.
- Before `Send`, the next vendor has not been contacted.
- After `Send`, the queue marks as sent and `Flooring` becomes active.

What this proves:

The automation can draft the next handoff, but the manager releases it.

## Test 13: Edit Or Hold A Draft

This requires a manager approval card.

After a vendor completion creates a draft:

- Press `Edit` if you want to change the text before sending.
- Press `Hold` if you do not want to contact the next vendor yet.

Expected result:

- `Edit` keeps the draft under manager control.
- `Hold` sends nothing.
- The next vendor is not contacted until `Send`.

What this proves:

The manager stays in control of every outbound message.

## Test 14: Cancel A Turn

Use this when you want to prove the system can safely close a turn that no longer needs work.

Expected behavior:

- The turn moves to cancelled.
- Open stages close.
- Open approval drafts close.
- The turn drops from the active board.
- Future stall alerts should not fire for that turn.

You can test this from manager controls when available. In a live demo, use the manager Telegram button if the daily digest or approval flow has exposed it.

## Test 15: Skip, Snooze, And Chase

These actions are manager controls. They are most visible from live Telegram manager cards or the daily digest.

Skip:

- Use it when a stage is not needed for this turn, such as Flooring on a unit that does not need flooring work.
- Expected result: the skipped stage counts as satisfied for later sequence checks.

Snooze:

- Use it when a stage is stalled but the manager already knows why.
- Expected result: the stage stays active, but stall alerts pause until the snooze expires.

Chase:

- Use it when the manager wants to follow up with the current vendor.
- Expected result: the system drafts a follow-up message for approval.
- Nothing is sent until the manager presses `Send`.

What this proves:

Manager controls change the workflow state without removing human approval.

## Test 16: Health And Metrics

Use the board header for the main numbers.

Expected metrics:

- `Units in turn`: active fixture turns still on the board.
- `Burning now`: total vacancy dollars currently accruing.
- `Vendor reply rate`: how many completions came from vendor messages.
- `Auto-handled`: how many inbound messages reached a safe automated outcome.

With live Telegram active, the manager can also send:

```text
/health
```

Expected result:

- The manager gets the same metric family the board uses.
- The numbers should agree with the board's current state.

## Test 17: Daily And Weekly Digests

These are manager-facing Telegram summaries.

Daily digest:

- Workflow: `Manager Daily Digest`.
- Purpose: sends a worst-first list of active turns with manager action buttons.
- Expected result: the manager sees the stuck units first and can use Done, Skip, Snooze, Chase, or Cancel from the digest.

Weekly digest:

- Workflow: `Weekly Metrics Digest`.
- Purpose: sends a weekly operating summary.
- Expected result: the manager sees the same metric family as the board and health check.

To test without waiting for the schedule, open the workflow in n8n and run it from the n8n UI.

What this proves:

The manager does not have to keep the board open all day. The automation can push summaries and controls into Telegram.

## Test 18: Stall Detection

The opening fixture includes `3 / 7 Oak Ave` at `Trash-out`, already past its allowed time.

To test without waiting for the schedule, open `Stall Watchdog` in n8n and run it from the n8n UI.

Expected behavior when the watchdog runs:

- The manager gets a stall alert for the overdue stage.
- The alert is manager-only.
- No vendor is chased automatically.
- Running the watchdog again should not create repeated alerts for the same stage.
- Outside business hours, the alert can be held until the next allowed window.

What this proves:

The system catches silence. It does not nag the vendor by itself.

## Test 19: Live Telegram Vendor Identities

Use live Telegram when you want the closest demo to real operation.

The live fixture setup expects separate vendor sender groups:

- Rivera Painting.
- Maria's Cleaning Co.
- Dale Hutchins.
- Statewide Flooring.

Why separate groups matter:

- The vendor sender identity is part of the match.
- Reusing the manager group as a vendor sender breaks the test.
- Reusing one vendor group for all vendors makes different vendors look like the same sender.

Messages worth testing:

| Vendor | Message | Expected result |
|---|---|---|
| Rivera Painting | `done with 12b` | Paint completes, Flooring waits for manager approval. |
| Rivera Painting | `finished the one on maple` | Manager review, no stage change. |
| Rivera Painting | same `done with 12b` twice | One completion, one duplicate. |
| Maria's Cleaning Co | `12b cleaned` | Works only when Deep Clean is the active allowed stage. |
| Rivera Painting | voice note | Unsupported media, manager review. |

## What Not To Expect

The automation does not:

- Prove the work is finished.
- Inspect photos.
- Send a vendor message without manager approval.
- Chase vendors on its own.
- Read or write Buildium, AppFolio, Rent Manager, Propertyware, or any other PMS.
- Handle occupied maintenance.
- Decide deposit deductions.
- Screen tenants.
- List the unit.
- Forecast turn duration.
- Replace a manager's QA walkthrough.

## If Something Looks Wrong

Use this quick map.

| Symptom | Likely place to look | Normal explanation |
|---|---|---|
| Board is blank or stale | Board API | n8n is not reachable, or the board token does not match. |
| Telegram messages do nothing | Vendor Telegram Ingest | Live Telegram needs the tunnel and HTTPS webhook URL. |
| Manager buttons do nothing | Manager Telegram Router | Callback routing or live Telegram registration needs attention. |
| Vendor completion creates no draft | Vendor Completion Handler | The stage may not be assigned to that vendor, or the guard blocked it. |
| Completion is blocked | Sequence Guard | A prerequisite stage is still open. |
| Message asks for manager review | Vendor Message Router or Unit Matcher | This is often correct behavior for vague, ambiguous, delayed, or unsafe messages. |
| Builder receives an error alert | Builder Error Handler | A workflow failed; the manager/prospect should not receive that alert. |

## Clean Demo Run Order

For a simple end-to-end manual test:

1. Run the demo reset script.
2. Open the board and confirm six units.
3. Add one fictional turn through `Turn Intake Form`.
4. Reset again.
5. Mark `12B Paint` done from the board.
6. Reset again.
7. Send `done with 12b` through the simulator.
8. Confirm `Flooring` waits for manager approval.
9. Reset again.
10. Send vague, duplicate, question, photo-only, and voice-note messages through the simulator.
11. Reset again.
12. Use live Telegram for the real manager approval card.
13. Confirm no vendor message leaves without manager `Send`.

That covers the system's core promise: intake, visibility, sequence enforcement, conservative matching, vendor completion, manager approval, stall detection, manager summaries, and safe failure behavior.
