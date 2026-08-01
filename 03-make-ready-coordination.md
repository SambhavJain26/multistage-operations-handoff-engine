# Problem 3 — Make-Ready / Unit Turn Coordination

**Build order: THIRD — and CONDITIONAL**
**Verdict: Validated problem, high-variance delivery. Build only when one question is answered yes.**
**Segment: US residential property management, 150–600 doors**

---

## Quick Summary

| | |
|---|---|
| **What it is** | Automated stage-by-stage vendor handoff tracking during unit turnover |
| **Who buys** | Owner/principal — this is a revenue-recovery purchase |
| **Why conditional** | Depends entirely on whether the client's vendors will reply to a text |
| **Build time** | 3–4 days — the most complex of the four |
| **Token cost to build and test** | Under $0.50 — mostly deterministic logic |
| **Trust barrier** | Medium — it coordinates their vendors |
| **Price** | $1,000–1,800 setup, $350–600/month |

---

## ⚠️ Read This Before Anything Else

This product has the **best hard-dollar ROI** of the four and the **highest delivery risk**. Those aren't in tension — they're the same fact viewed twice.

The entire product rests on one empirical question you cannot answer from research:

> **Will this client's vendors reply to a text message?**

If yes, this is arguably the strongest thing you can sell. If no, you're automating a handoff that doesn't exist, and you'll fail visibly in front of a paying client.

**The qualifying question, asked in discovery:**

> *"When your painter finishes a unit, how do you find out?"*

| Answer | Action |
|---|---|
| "He texts me" / "He sends a photo" | **Build it.** Your best product |
| "I call him Thursday" / "I drive by" | **Walk away.** No signal to automate |
| "He marks it in the portal" | Probe — is that real or aspirational? |

That question costs nothing and moves this from your third product to unbuildable. Ask it before you write a line of code for any specific client.

---

## The Problem

### What actually happens

A tenant gives notice. A fixed sequence has to run before a new tenant can move in, and each stage is usually a different person or contractor:

1. Pre-move-out inspection (7–14 days before move-out)[^1]
2. Move-out and key return — **the vacancy clock starts here**
3. Inspection within 24 hours, producing the punch list[^2]
4. Trash-out / clearing
5. Repairs and trades
6. Paint
7. Flooring
8. Final deep clean
9. QA walkthrough and photos
10. Relist

The handoffs between these stages are managed by the property manager over phone calls and text messages, from memory, while managing forty other things.

### Where the time actually goes

This is the finding that defines the product:

> *"A standard apartment make-ready takes 5–10 days from move-out to rent-ready... Most of the calendar beyond that is coordination lag between trades, not hands-on work."*[^3]

**The work isn't slow. The gaps between the work are slow.**

The painter finishes Tuesday at 2pm. The property manager doesn't find out until Thursday morning. The cleaners get called Thursday afternoon and can't come until Monday. That's six days of nothing happening on a unit that was ready for the next step on Tuesday.

### The second failure mode: sequence errors cause rework

This is underappreciated and worth selling on. The correct order is **repairs and trades first, then paint, then flooring, then final deep clean and QA walkthrough.** Reverse any of those and you re-clean, re-paint, or re-walk the unit at least once.[^2]

Cleaning before paint means cleaning twice. Flooring before plumbing means pulling up new flooring. These aren't hypothetical — they're the documented reason most turns run twice as long as they should.

### Why it stays broken

Because the coordinator is a human holding fifteen units in their head. There's no view of "which unit is stuck and for how long." A unit that's been idle for four days looks identical to one that's actively being worked on, because both look like nothing in an inbox.

---

## Real-Life Examples

### Example 1 — The single missed handoff

> A one-bedroom renting at $1,500/month — about $50/day — sits empty four extra days because the property manager didn't realise the painter had finished and forgot to call the cleaning crew.
>
> $200 in lost rent from one missed phone call, on one unit.
>
> A company managing 300 units with 40% annual turnover runs about 120 turns a year. Four wasted days on each is **$24,000 annually from communication gaps alone** — before anyone has done anything wrong.

### Example 2 — The rework

> A unit turn is running late, so the coordinator sends the cleaners in on Wednesday to "get ahead."
>
> The drywall repair hasn't happened yet. On Friday the repair tech patches two walls, sanding dust settles across every surface, and the cleaners have to come back. Second clean: $180. Two additional days.
>
> Nobody logs this as a failure. It goes in the file as "turnover took 11 days."

### Example 3 — What good looks like

> One operator reduced average turnover time from 14 days to 5 days in the Phoenix market specifically by eliminating sequencing bottlenecks and coordinating stages in the correct order rather than waiting on multiple vendors whose schedules created cascading delays.[^4]
>
> Nine days per turn. At $50/day across 120 turns, that's $54,000 a year in recovered rent — from sequencing, not from working harder.

**Example 3 is your sales close.** It proves the size of the prize without you having to claim it yourself.

---

## Evidence This Is a Real Problem

### Neutral industry benchmarks — the strongest source in this entire product line

NAA's 2024 Income/Expense IQ benchmarks, published August 2025:[^3]

- **Turnover costs up 17.5% year over year**
- **Vacancy and rent loss at $1,323 per unit — the fourth consecutive annual increase**
- **Repairs and maintenance up 28.2% cumulatively since 2021**

This is a trade association benchmark, not vendor marketing. It's the highest-quality evidence in any of the four documents.

### The mechanism is independently confirmed

The "coordination lag, not hands-on work" finding[^3] describes the industry rather than selling a fix for it. The correct sequence and its rework consequences are documented consistently across independent operator guides.[^2][^5]

### Performance gap

PropertyMeld data shows the average property management company takes **9 days or more** per turn, with some taking 2–3 weeks, against a best-practice benchmark of 3–7 days.[^6] Total make-ready cost runs **$1,000–5,000 per unit** over **5–10 days**.[^7]

### Practitioner voice

A mid-sized Texas operator, quoted directly: losing *2–3 days just waiting for vendors to confirm or show up*, with phone tag between tenants and contractors consuming **10–15 hours a week per portfolio**.[^8]

### Known bottleneck

Trash-out and junk removal is repeatedly identified as the most common single bottleneck delaying the entire timeline.[^7] Worth knowing — it's often the first stage to instrument.

### Honest counter-evidence — and it's the strongest of the four

**This is the only one of the four products with a credible non-software alternative.**

Lula operates a managed make-ready service across 17 US metros — Atlanta, Cincinnati, Cleveland, Columbus, Dallas–Fort Worth, Dayton, Houston, Indianapolis, Kansas City, Memphis, Minneapolis, Oklahoma City, Orlando, Phoenix, St. Louis, Tampa, Tulsa — on a one-partner, one-inspection, one-invoice model, with most turns finishing within 72 hours because coordination sits inside their operation instead of the manager's calendar.[^9]

**Check your prospect's metro before pitching.** In those 17 cities, a manager can outsource the problem entirely rather than automate it. Outside them, they can't.

**Second counter-argument, and it's fair:** an independent research pass concluded this is a weak candidate for custom low-code development specifically because it depends on external vendors updating status and is fragile when they don't.

**The counter to the counter:** if a vendor goes silent, the escalation fires and the manager is told *"unit 12 has been idle at painting for 48 hours."* Surfacing the stall is most of the value. The system doesn't need vendors to be reliable — it needs to detect when they aren't, which is exactly what the manager currently can't do.

That defence holds **only above a certain vendor reply rate.** Below roughly 30%, the board is fiction. Above 60%, it works. Hence the conditional.

---

## Ideal Buyer

### Profile

| Attribute | Target |
|---|---|
| Doors | 250–600 |
| Turnover rate | 30%+ annually — you need volume of turns |
| Vendors | Uses outside contractors, not only in-house staff |
| Vendor behaviour | **Vendors already communicate by text** — non-negotiable |
| Metro | Outside Lula's 17 markets, ideally |
| Buyer | Owner/principal — this is a P&L conversation |

### Strong buying signals

- They can quote their average days-to-turn — means they measure it and it bothers them
- They've recently lost a tenant-ready unit to a scheduling gap
- Their maintenance coordinator is visibly juggling a whiteboard or spreadsheet of units in turn
- Seasonal turn spikes (student markets, summer moves) they dread
- They mention rework — recleaning, repainting

### Qualifying questions

1. **"When your painter finishes a unit, how do you find out?"** — the gate. Everything depends on this
2. *"How many units are in turn right now, and how long has each been sitting?"* — if they can't answer instantly, that's the pitch
3. *"What's your average days from move-out to relisted?"* — anchors the ROI arithmetic
4. *"Do your vendors text you, or do you call them?"* — confirms the channel
5. *"Roughly what's your monthly rent on a typical unit?"* — you need this for the close

### Disqualifiers

- In-house maintenance team handles the whole turn — no handoffs to instrument
- Vendors don't text
- Under 30 turns a year — not enough volume
- Located squarely in a Lula metro and they already use them

---

## Positioning and Sales

### The framing

This is the only product of the four where you **sell revenue recovery, not time savings.** Don't dilute that.

> *"Every day a unit sits empty is rent you never get back. Most of those days aren't work — they're waiting for someone to find out the previous step finished. This closes that gap."*

### The close that does the work

**Do the arithmetic live, on their numbers, during the call.**

> *"You said your average turn is 11 days and your typical rent is $1,600 — that's about $53 a day. If we take three days off each turn and you're doing 90 turns a year, that's roughly $14,000 a year. I'm charging you $500 a month."*

Nothing else in this product line converts to a live number that cleanly. Use it.

### Sell the visibility before the automation

The board is easier to sell than the automation, and it's the part that works regardless of vendor reply rate:

> *"Before anything gets automated, you'd have one screen showing every unit in turn, what stage it's at, and how many days it's been sitting there. Most people find that alone changes how they run turns."*

This is a smart hedge. If vendor replies turn out patchy, the visibility layer still delivers value and your client still gets something real.

### The rework angle

Underused and persuasive:

> *"Half the delay isn't waiting — it's doing things twice. If cleaning happens before drywall repair, you clean twice. The system enforces the order, so that stops happening."*

### Objection handling

**"My vendors won't use an app."**
> "Agreed, and I wouldn't ask them to. They reply to a text or send a photo — exactly what they do now. There's nothing to install and no account to create."

**"I already know what's happening with my units."**
> "Probably true for the three you thought about this morning. How about the one at [address] — what stage is it at and how long has it been there?" *(Usually a pause. That pause is the product.)*

**"We tried a system like this and vendors ignored it."**
> "That's the main thing that kills these, so let's find out before you pay me anything. Pick five vendors, I'll run a two-week pilot on real turns, and we look at reply rates. If they don't reply, I'll tell you it won't work and we stop."

That offer is your single best credibility move on this product. It's also honest, which is why it works.

---

## The Build

### What the automation does

1. **Starts the clock** at notice-to-vacate, not move-out — Phase 1 is information gathering[^2]
2. **Creates a turn record** with the configured stage sequence
3. **Notifies** the assigned vendor when their stage becomes active
4. **Accepts completion** by SMS reply or photo — nothing to install
5. **Advances** the sequence automatically and notifies the next vendor
6. **Enforces order** — blocks and warns if a downstream stage is marked done out of sequence
7. **Escalates** stalls: no reply within a configured window → manager alert
8. **Displays** a live board of every unit in turn with stage and days elapsed
9. **Reports** turn duration and per-stage lag over time

### Stage model

Configurable per client, defaulting to the documented correct sequence:[^2]

| # | Stage | Typical duration | Notes |
|---|---|---|---|
| 0 | Notice received | — | Clock starts; gather info |
| 1 | Pre-move-out inspection | 1 day | 7–14 days before move-out[^1] |
| 2 | Move-out / keys returned | — | **Vacancy clock starts** |
| 3 | Inspection + punch list | 1 day | Within 24 hours[^2] |
| 4 | Trash-out | 1 day | Most common bottleneck[^7] |
| 5 | Repairs / trades | 1–3 days | **Must precede paint** |
| 6 | Paint | 1–2 days | **Must precede flooring** |
| 7 | Flooring | 1–2 days | |
| 8 | Deep clean | 1 day | **Must be last before QA** |
| 9 | QA walkthrough + photos | 0.5 day | |
| 10 | Relist | — | Turn complete |

**Encode the ordering constraints as hard rules.** If someone marks Deep Clean complete while Repairs is still open, the system flags it rather than advancing. That single rule prevents the most expensive rework mode.

### n8n architecture

**Implementation amendment, 2026-08-01:** the later demo build plan supersedes the rough architecture below on four points. Use Postgres, not Google Sheets, even for the demo. Do not auto-notify the next vendor; draft the message and wait for manager approval. Build and test locally by default, using a temporary HTTPS tunnel only for Telegram trigger testing. Keep VPS/domain/Caddy for production or a paid pilot.

```
[Webhook / Form: notice received]
        ↓
[Postgres: create turn record + stage rows]
        ↓
[Telegram/SMS draft: manager approves before vendor contact]
        ↓
        ⟳ ─────────────────────────────────┐
[Webhook: vendor reply received]           │
        ↓                                  │
[Code node: match reply → unit + stage]    │
        ↓                                  │
[IF: photo attached? → store]              │
        ↓                                  │
[Code node: sequence validation]           │
        ↓  out-of-order → flag, don't advance
[Postgres: mark stage complete, advance]   │
        ↓                                  │
[Telegram/SMS draft: manager Send/Hold] ───┘

──── separate scheduled workflow ────

[Schedule Trigger: every 4 hours]
        ↓
[Postgres: read all active turns]
        ↓
[Code node: compute stage age vs threshold]
        ↓
[Switch: stalled? → Telegram alert to manager]

──── daily ────

[Schedule Trigger: 07:00]
        ↓
[Build board digest → email/Telegram to manager]
```

**Node notes:**
- Use **Telegram** for the demo — free Bot API, real phone, zero friction. Swap to SMS (client's own Twilio account) in production
- Vendor replies are free text. Parse with a small LLM call or simple keyword matching: "done", "finished", "complete", "ready" plus unit identifier
- Store state in Postgres from the start
- Use local Docker for the demo build; expose local n8n through a temporary HTTPS tunnel only when testing Telegram triggers
- Every outbound vendor message is manager-approved. No autonomous vendor sends
- **No Buildium integration required** — this runs entirely alongside their PMS

### Why this takes 3–4 days when the logic looks simple

State machines have many failure paths, and most of your build time is edge cases:

- Vendor replies "done" twice
- Two stages marked complete out of order
- A vendor replies about the wrong unit
- A stage is skipped legitimately (no flooring needed this turn)
- A turn is cancelled mid-sequence (tenant renews after giving notice)
- A vendor never replies at all
- Manager manually overrides a stage

Claude Code compresses code generation. It does not compress deciding what should happen in each of these cases.

### Cost to run

| Item | Cost |
|---|---|
| n8n self-hosted | Free |
| Telegram (demo) | Free |
| LLM (reply parsing only) | ~$0.001 per reply |
| Storage | Free |
| SMS in production | Client's own Twilio, ~$0.008/msg |
| **Monthly at 10 turns, 8 stages each** | **Under $0.20 + client's SMS** |

---

## The Demo

Weaker than the other three, because value unfolds over days rather than seconds. Compensate deliberately.

**Pre-seed the demo** with three units already mid-turn at different stages and different ages — one healthy, one stalled 3 days at paint, one nearly complete.

**Run it in this order:**

1. **Lead with the board, not the automation.** "Here's every unit in turn right now." The stalled one is red. Let that sit for a second.
2. "That one's been at paint for three days. Nobody knew until now."
3. **Then trigger the live event.** Send a Telegram message as the painter: *"unit 12 done"*
4. Board updates. Cleaner receives a notification — **on the prospect's phone if you've added them as a test vendor**
5. **Show the guard rail.** Try to mark Deep Clean complete on a unit where repairs are still open. It refuses and explains why. "This is where the rework comes from."
6. **Close on their arithmetic.** Days saved × their daily rent × their annual turns.

**The pilot offer:**

> *"Pick five vendors and two live turns. Two weeks, no charge. We'll look at one number at the end: what percentage of the time your vendors replied. If it's low, I'll tell you this isn't worth building and we'll stop."*

Offering to disqualify yourself is the most credible thing you can do without a track record.

---

## Pricing

| Component | Price |
|---|---|
| Setup / onboarding | $1,000–1,800 |
| Monthly | $350–600 |
| First two clients | $600 setup, $300/month |

**Price this against recovered rent, not against hours.** It's the only one of the four where the client's own numbers justify a higher price than you'd otherwise dare charge — and where they can verify the return within one turn cycle.

---

## Risks and Limitations

| Risk | Reality | Mitigation |
|---|---|---|
| **Vendor reply rate** | The product lives or dies here | Qualify before building. Run a free two-week pilot. Measure the rate |
| **Managed-service competitors** | Lula operates in 17 metros with 72-hour turns[^9] | Check the metro. Compete on cost and control, not speed |
| **Most complex build of the four** | 3–4 days, many edge cases | Budget the time honestly. Don't quote 2 days |
| **Weakest demo of the four** | Value unfolds over days | Pre-seed state. Lead with the board. Trigger one live event |
| **Slower to prove than it looks** | Needs a full turn cycle, 2–4 weeks | Set expectations. Report per-stage lag from week one |
| **Vendor relationships aren't yours** | You're inserting into a relationship you don't own | Never message a vendor without the client's name on it |

### The rule to never break

**Never let the system chase a vendor in a way that damages the client's relationship with them.** Messages go out in the client's name, in the client's tone, at reasonable hours. Escalation goes to the *manager*, never to the vendor as a nag. You're a coordination layer, not a debt collector.

---

## Citations

[^1]: Renova One, "The Complete Guide to Apartment Unit Turnover." https://renovaone.com/the-complete-guide-to-apartment-unit-turnover/ — pre-move-out inspection scheduled 7–14 days before move-out; notice-date logging and target lease-ready date calculation.

[^2]: Lula, "Apartment Make-Ready Checklist + Free Toolkit (2026)." https://lula.life/articles/apartment-make-ready-checklist — three-phase model; correct sequence of repairs → paint → flooring → deep clean → QA; rework consequences of reversing; 3–5 day target vs typical 2× that.

[^3]: NAA 2024 Income/Expense IQ benchmarks, published August 2025 — turnover costs +17.5% YoY; vacancy and rent loss $1,323/unit, fourth consecutive annual increase; repairs and maintenance +28.2% cumulative since 2021. Cited via Lula's make-ready guide.

[^4]: Breasy, "Rental Turnover Checklist for Landlords." https://joinbreasy.com/knowledge/rental-turnover-checklist-for-landlords/ — GPS Renting reduced average turnover from 14 days to 5 days in Phoenix by eliminating sequencing bottlenecks.

[^5]: TurnOver LA, "Apartment Turnover Checklist: 150-Point Make-Ready Guide." https://www.turnoverla.com/guides/apartment-turnover-checklist — five-phase sequence: move-out walkthrough, deep clean, paint and wall prep, repairs and hardware, final walkthrough with photo documentation.

[^6]: PropertyMeld data — average property management company takes 9+ days per turn vs 3–7 day best practice. Reached via secondary source; treat as directional.

[^7]: Dropcurb, "Apartment Make Ready Checklist: Unit Turn Guide (2026)." https://dropcurb.com/blog/apartment-make-ready-checklist — $1,000–5,000 per unit over 5–10 days; trash-out as most common bottleneck.

[^8]: Mid-sized Texas operator quoted in vendor case study — 2–3 days waiting on vendor confirmation; 10–15 hours per week of phone tag per portfolio. Single anonymous quote; treat as illustrative.

[^9]: Lula managed make-ready service — 17 US metros, one-partner/one-invoice model, most turns within 72 hours. https://lula.life/ — vendor self-reported.
