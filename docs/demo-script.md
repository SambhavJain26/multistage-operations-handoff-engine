# Demo Script: Make-Ready Sequencing Automation

Solo recorded screen walkthrough for YouTube. First person, unnamed presenter. Target
length: computed below from the actual narration word count, not estimated (see
"Timing Math").

## The framing this script protects

This is custom automation built inside a property manager's own make-ready process. It is
not a product, not software with an account, and not a dashboard to sell. Any screen shown
in this video exists only so a human can see what the automation did. It runs on
infrastructure the client owns.

**Never say:** my platform, my tool, my product, the app, users, sign up, subscribers.
**Say instead:** the board, the automation, the intake workflow, the manager, the vendor.

## Language rules (read before scripting scenes, not after)

These come directly from this project's own honesty boundary
(`make-ready-demo-build-plan.md` §11) and hold regardless of how the recording goes.

**Never say:**
- "It knows the unit is done." It knows a vendor *reported* it done.
- "It checks the photos." Photos are stored and displayed. Nothing inspects them.
- "It schedules or books vendors." It drafts a message and waits for a human.
- "It chases vendors." It escalates a stall to the manager. It never nags a vendor.
- "It talks to [any PMS]." It has no PMS integration of any kind, deliberately.
- "It handles maintenance tickets" or "the deposit." Vacant-unit turnover only, and it never
  assesses damage, wear and tear, or deductions. Hard exclusion, no exceptions.
- "It predicts how long a turn will take." It reports elapsed time. No forecasting.
- Any percentage improvement in turn time, any reply rate as a promise, any payback period,
  or that anyone else is currently using this. There is no track record yet, and pretending
  otherwise is the one mistake this script cannot make.

**Say instead:** "it knows what a vendor said," "a manager still reviews it," "it drafts,
a person sends," "this runs beside your existing system, not instead of it."

## Workflows shown on screen

| Workflow (n8n name) | What it's doing in this video |
|---|---|
| Board API | Renders the live board in every scene |
| Vendor Telegram Ingest | Normalizes the painter's and cleaner's Telegram messages |
| Vendor Message Router | Classifies each message and decides what happens next |
| Sequence Guard | Blocks the out-of-order cleaning attempt in Scene 5 |
| Vendor Completion Handler | Completes the paint stage and drafts the flooring handoff |
| Manager Action Core | Applies Send when the approval card button is pressed |
| Stall Watchdog | Fires the trash-out alert in Scene 6 |

## YouTube package

### Title (options, character counts measured by slicing the string, not estimated)

1. "A Property Management Automation That Blocks Vendors Working Out of Order" (73 chars)
2. "Inside a Make-Ready Automation: Live Board, Guard Rail, Stall Alert" (67 chars)
3. "How a Vendor Text Updates a Property Management Board in Seconds" (64 chars)

Use option 2. At 67 characters it fits inside the roughly 70-character visible window with
no truncation and names all three things shown.

### Description

First 100 characters must stand alone before YouTube's "Show more" cutoff. Measured by
slicing the actual string (not estimated): at 101 characters total, the visible cutoff
lands one character before the closing period, on a full word, not mid-word.

> A vendor's text updates a live board in seconds. A guard rail blocks stages marked done
> out of order.

Full description:

```
A vendor's text updates a live board in seconds. A guard rail blocks stages marked done out
of order.

This is custom automation built inside a property manager's own make-ready process, not
a product or a piece of software you buy and log into. Every screen here exists so a
human can see what the automation did. It runs on infrastructure the client owns.

What this video shows:
- A live board of units mid-turnover, sorted worst first
- A vendor completing a stage by text, no app, no account
- A manager approving the next vendor's message before it sends
- A stage blocked from completing out of order, with the reason why
- A stall alert firing on a vendor who's gone quiet

It knows what a vendor told it. It does not know the work is actually finished, and it
never touches a property management system, a deposit, or a vendor's own account.

If you run a property management company and want to see your own numbers on a board
like this, reach out.

0:00 The board, in silence
0:54 The red card
1:52 A vendor replies by text
2:40 The manager approves the handoff
3:27 Blocking a stage out of order
4:20 A stall alert fires on its own
5:19 Reply rate, honestly, and the close
```

### Chapters

Taken directly from the "Starts at" column of the timing table in "Timing math" below, not
written independently. YouTube requires the first chapter to start at 0:00 and each chapter
to be at least 10 seconds; every scene here clears that.

```
0:00 The board, in silence
0:54 The red card
1:52 A vendor replies by text
2:40 The manager approves the handoff
3:27 Blocking a stage out of order
4:20 A stall alert fires on its own
5:19 Reply rate, honestly, and the close
```

### Hashtags

`#PropertyManagement` `#Automation` `#n8n`

Three, per this project's platform limits reference (YouTube: 3-5 recommended, first 3 in
the description surface as clickable tags above the title).

## Staging instructions

Run these in order, every time, before recording. Each step names the real file it comes
from.

1. `scripts/reset-demo.ps1`: restores the six fixture turns to their opening state.
2. `scripts/import-stage-7-workflows.ps1 -ActivateTelegram`: republishes all workflows with
   Telegram active and reapplies the real vendor chat-ID mappings for Rivera Painting,
   Maria's Cleaning Co, Dale Hutchins, and Statewide Flooring from `.env`. Reset alone
   resets these back to placeholders; this step is what makes live Telegram sends work
   against the right vendor identities again.
3. Confirm a fresh Cloudflare Tunnel is running into local n8n and `WEBHOOK_URL` in `.env`
   and inside the running n8n container is the tunnel's HTTPS origin, not `localhost`. If
   `WEBHOOK_URL` changed, run `docker compose up -d --force-recreate n8n` before continuing.
4. Open the board at its local URL and confirm all six units are showing, 12B first and red.
5. Record Scenes 1 through 4 now, using the board and the Rivera Painting Telegram identity.
   Do not run step 6 until these are captured; it will change 12B's state.
6. Immediately before Scene 5, run this SQL against the app database (verbatim from
   `scripts/check-stage-7.ps1`'s `Setup-DeepCleanGuard` function, lines 214-253):

   ```sql
   UPDATE turn_stage ts
   SET status = CASE
       WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS','PAINT') THEN 'complete'
       WHEN ts.stage_code = 'FLOORING' THEN 'skipped'
       WHEN ts.stage_code = 'DEEP_CLEAN' THEN 'active'
       ELSE 'pending'
     END,
     activated_at = CASE WHEN ts.stage_code = 'DEEP_CLEAN' THEN now() ELSE activated_at END,
     completed_at = CASE WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS','PAINT','FLOORING') THEN now() - interval '1 hour' ELSE NULL END,
     completed_via = CASE
       WHEN ts.stage_code = 'FLOORING' THEN 'skip'
       WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS','PAINT') THEN 'manual'
       ELSE NULL
     END,
     completed_by = CASE WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS','PAINT','FLOORING') THEN 'stage-7-setup' ELSE NULL END
   FROM "turn" t
   WHERE t.id = ts.turn_id AND t.unit_label = '12B' AND t.property_address = '418 Maple St' AND t.is_fixture = true;

   UPDATE turn_stage ts
   SET status = CASE
       WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT') THEN 'complete'
       WHEN ts.stage_code = 'DEEP_CLEAN' THEN 'active'
       ELSE 'pending'
     END,
     activated_at = CASE WHEN ts.stage_code = 'DEEP_CLEAN' THEN now() ELSE NULL END,
     completed_at = CASE WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT') THEN now() - interval '1 hour' ELSE NULL END,
     completed_via = CASE WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT') THEN 'manual' ELSE NULL END,
     completed_by = CASE WHEN ts.stage_code IN ('NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT') THEN 'stage-7-setup' ELSE NULL END
   FROM "turn" t
   WHERE t.id = ts.turn_id AND t.unit_label = '14A' AND t.property_address = '418 Maple St' AND t.is_fixture = true;
   ```

   This leaves REPAIRS, PAINT, and FLOORING on 14A at `pending`, not complete or skipped,
   which is what makes the guard block the next step. It also advances 12B past this scene;
   that is expected and does not need to be undone.
7. Record Scene 5 now (the Maria's Cleaning Co Telegram identity).
8. Immediately before Scene 6, note the current time. 3 Oak's trash-out stage is already
   past its 24-hour SLA at any point after step 1 (seeded at roughly 30 hours old), so the
   alert is ready to fire on cue. Trigger it live with:

   ```
   POST /webhook/stall-watchdog?token=<BOARD_DEMO_TOKEN>
   Body: { "force_hour": 10 }
   ```

   `force_hour` overrides the business-hours check in `wf6-stall-watchdog` so the alert
   fires regardless of actual recording time. This is a real parameter the workflow accepts,
   not a workaround.
9. Record Scene 6, then Scene 7.

**Dollar figures used in the script below** are computed from `db/postgres/seed/seed.sql`'s
relative day offsets (12B moves out 6 days before reset, 14A 4 days, and so on), assuming
recording happens the same calendar day as the reset in step 1. Read the actual number off
the board before recording each scene and adjust the spoken line if it differs by more than
a few dollars; the underlying math (rent ÷ 30 × days vacant) does not change.

## Timing math

Narration word count, counted directly from the blockquoted lines in the scenes below by
extracting every `> ` line per scene and running a word count against it (not eyeballed):
**752 words.** (Recounted after two filler-word trims made during the AI-writing-detection
pass; the table below reflects the current text, not an earlier draft.)

At 130 words per minute (unhurried delivery) plus 12% for pauses and on-screen actions:

```
752 / 130 = 5.785 minutes of raw speech
5.785 × 1.12 = 6.479 minutes total
```

**Total runtime: approximately 6:29.** Inside the 6-10 minute target, at the lower end of
it. Per-scene timestamps below are each scene's own word count run through the same
formula, then summed cumulatively, so the chapter list cannot drift from the scenes. If any
narration line changes, rerun the word count and this whole table before touching a
timestamp by hand.

| Scene | Words | Duration (with overhead) | Starts at | Ends at |
|---|---|---|---|---|
| 1. The board, in silence | 104 | 53.8s | 0:00 | 0:54 |
| 2. The red card | 112 | 57.9s | 0:54 | 1:52 |
| 3. A vendor replies by text | 94 | 48.6s | 1:52 | 2:40 |
| 4. The manager approves the handoff | 90 | 46.5s | 2:40 | 3:27 |
| 5. Blocking a stage out of order | 103 | 53.2s | 3:27 | 4:20 |
| 6. A stall alert fires on its own | 115 | 59.4s | 4:20 | 5:19 |
| 7. Reply rate, honestly, and the close | 134 | 69.3s | 5:19 | 6:29 |
| **Total** | **752** | **388.7s** | | **6:29** |

## Scenes

### Scene 1: The board, in silence (0:00-0:54)

**Workflow on screen:** Board API.
**Screen:** The board, freshly reset, full view. No cursor movement for the first three
seconds.

> I build custom automation like this, inside a property manager's actual day-to-day
> workflow. This one handles unit turnover between tenants.
>
> This is the live board for it. Six units, all mid-turnover, sorted worst first.
>
> I'm not going to explain the interface. Watch it for a second instead.
>
> Eleven hundred ninety-one dollars burning today, and nobody had to open a spreadsheet or
> call anyone to know that number. It's computed from real timestamps, live.
>
> This isn't software you buy and log into. It's an automation built inside a property
> manager's own vendor process, and this board exists so a human can see what it's doing.

### Scene 2: The red card (0:54-1:52)

**Workflow on screen:** Board API (the health/age calculation behind the red card).
**Screen:** Zoom or highlight on the 12B card.

> Look at 12B. It's been sitting at paint for four days. The allowed time for paint is two.
>
> Ten seconds ago, nobody here knew that. In an inbox, this unit looks exactly like the
> other five. Nothing marks it as different until someone goes looking.
>
> Two hundred ninety dollars of rent lost on this one unit alone since move-out, and that
> number keeps moving as long as nobody finds out painting is finished.
>
> The actual work isn't what's slow. Repairs takes a day, paint takes a day. What's slow is
> the gap between one vendor finishing and someone finding out, so the next vendor can
> start.
>
> That gap is what this closes.

### Scene 3: A vendor replies by text (1:52-2:40)

**Workflow on screen:** Vendor Telegram Ingest, then Vendor Message Router.
**Screen:** Switch to a second window or phone showing the Rivera Painting Telegram
account. Type and send. Cut back to the board.

> Here's how a vendor reports a stage is done. I'm switching to a second account now, the
> one Rivera Painting would text from.
>
> Nothing installed. No account created. The same channel a contractor already uses to text
> a client.
>
> "Done with 12b."
>
> Back on the board. Give it a few seconds. 12B moves off paint.
>
> That message went through an automation that checks who's texting, works out which unit
> and stage they mean, and confirms it against the vendor actually assigned to that stage.
> All of that happened before anything on the board changed.

### Scene 4: The manager approves the handoff (2:40-3:27)

**Workflow on screen:** Vendor Completion Handler, then Manager Action Core.
**Screen:** The manager's Telegram, showing the approval card with Send / Edit / Hold
buttons. Press Send.

> But the stage didn't just advance on its own. Look at what happened on the
> manager's side.
>
> A draft. Twelve B is ready for flooring, addressed to Statewide Flooring, written like a
> normal handoff message. Painting's done, ready for the next trade.
>
> Nothing has gone out to a vendor yet. It never does automatically. Every outbound message
> sits here until a person presses Send, Edit, or Hold.
>
> I'm going to press Send.
>
> That's the handoff that, without this, normally costs a day or two of nobody knowing
> painting was finished.

### Scene 5: Blocking a stage out of order (3:27-4:20)

**Workflow on screen:** Sequence Guard.
**Screen:** Switch to the Maria's Cleaning Co Telegram account (14A staged per step 6
above). Type and send. Cut back to the board showing the blocked result.

> Now the part that costs more than waiting ever does.
>
> I staged unit 14A ahead of time so repairs are still open, and deep clean is the stage
> marked active. That's not something a vendor message can normally cause. I set it up
> specifically to show this.
>
> Watch what happens when the cleaner reports the unit done anyway.
>
> "14a cleaned."
>
> Blocked. Repairs still open on 14A. Cleaning before repairs means cleaning twice.
>
> Nobody writes that down as a mistake when it happens for real. It just shows up months
> later as this turn took eleven days instead of six, and nobody remembers why.

### Scene 6: A stall alert fires on its own (4:20-5:19)

**Workflow on screen:** Stall Watchdog.
**Screen:** Trigger the webhook from step 8 above off-camera or in a small terminal window.
Cut to the manager's phone receiving the alert.

> One more piece, and I'm not staging this by hand. I'm just telling the watchdog to check
> right now instead of waiting for its normal fifteen-minute clock.
>
> Trash-out on unit 3 crossed its allowed time about six hours ago. Twenty-four hours
> allowed, thirty hours in, and nobody flagged it.
>
> The alert lands on the manager's phone the same way the approval card did. Nothing sent to
> a vendor, just a notice that something's gone quiet.
>
> This is the actual point of the whole thing. It doesn't need every vendor to be reliable.
> It needs to notice the moment one isn't, which is the part a person currently can't do
> without checking every unit by hand.

### Scene 7: Reply rate, honestly, and the close (5:19-6:29)

**Workflow on screen:** Board API (header metrics).
**Screen:** Back to the full board, header metrics visible.

> One number on this board matters more than the others: vendor reply rate.
>
> That's the percentage of stage completions that came from a vendor's own message, instead
> of a manager marking it by hand afterward. It sits on this screen permanently, not a
> report I send once and never update.
>
> Here's the honest limit of all of it. This system knows what a vendor told it. It does not
> know the work is actually finished. Someone still walks the unit.
>
> It doesn't touch a property management system. It doesn't decide anything about a
> deposit. And nothing reaches a vendor without a person pressing Send.
>
> If you run a property management company and want to see your own units on a board like
> this, reach out, and I'll walk through your own numbers with you.

## Fallback lines

Adapted from `make-ready-demo-build-plan.md` §10 for a solo recording with no prospect on
the line.

| What breaks | What to do | What to say |
|---|---|---|
| OpenAI classification is slow or fails | Nothing. `Vendor Message Router`'s fallback classifier fires automatically. Keep talking. | "That draft came from the fallback template, not the model. Notice the automation didn't stop. That's the design." |
| Telegram delivery lags (5-20 seconds) | Keep the board or the previous screen in view. Do not refresh repeatedly. | "Telegram's queuing. It'll land." |
| Local Docker or n8n stops mid-recording | Stop, fix it off-camera, resume from the last completed scene. Do not debug live on the recording. | Cut the footage; no line needed in the final edit. |
| The tunnel or a Telegram trigger silently isn't firing | Do not troubleshoot on camera. Switch to the board's manual controls to demonstrate the same guard behavior instead. | "I'll show this from the board side instead, it runs through the same guard." |
| The unit matcher picks the wrong unit live | Do not apologize or minimize on camera. If it scored below threshold and asked instead of guessing, that is correct behavior. | "It scored below the threshold and asked instead of guessing. The alternative is software that confidently updates the wrong unit, which is worse." |
| A vendor message classifies as something unexpected | Let it play out on camera if it's safe to do so; it demonstrates the manager-review fallback. | "It didn't understand, and it didn't pretend to. That's the design. When it's unsure, a person decides." |

## Pre-recording checklist

- [ ] `scripts/reset-demo.ps1` completed with no errors
- [ ] `scripts/import-stage-7-workflows.ps1 -ActivateTelegram` completed, all workflows
      active
- [ ] Cloudflare Tunnel running, `WEBHOOK_URL` confirmed HTTPS inside the n8n container
- [ ] Board open and confirmed showing all six fixture units, 12B first and red
- [ ] Rivera Painting and Maria's Cleaning Co Telegram accounts open and reachable
- [ ] Manager Telegram open and reachable, notifications visible on screen
- [ ] Actual dollar figures on the board checked against the Timing Math section's assumed
      numbers; narration adjusted if they differ by more than a few dollars
- [ ] `Setup-DeepCleanGuard` SQL ready to paste, not yet run
- [ ] Stall watchdog `force_hour` request ready to fire, not yet sent
- [ ] Screen recording software running and confirmed capturing audio
- [ ] This script's language rules section reread immediately before recording
