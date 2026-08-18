# Customer Language — US Residential Property Management, Make-Ready Sequencing

Created: 2026-08-18

Vocabulary reference for writing to property managers about unit turnover. Companion to `docs/build-1-content-strategy/customer-language.md` (vendor insurance paperwork) and `docs/build-2-content-strategy/customer-language.md` (maintenance triage). Same buyer, third working vocabulary.

**Do not assume the other two files transfer.** Build 2's file defines *turn* in one line as a thing that happens and costs about $4,000. Here it is the entire subject, with its own stage names, dependencies and failure modes. Build 2's vocabulary is about **events arriving**. This one is about **order and silence**.

## Source quality — read this first

Same constraint as both earlier builds: **primary practitioner voice is still unreached.** Reddit is blocked, BiggerPockets and the Facebook groups need a login. Nothing below is a property manager talking to another property manager unprompted.

Available, in descending order of trustworthiness:

1. **Industry benchmark reporting with method disclosed** — the 2026 State of the Property Management Industry report, NAA Income/Expense IQ. Numbers, not voice, but the numbers are good.
2. **Operator-authored make-ready guides and checklists** — written to be useful rather than to sell, and the sequencing vocabulary in them is operational.
3. **Vendor help documentation** — Property Meld's own onboarding pages, HappyCo's pricing page. These are facts about how the products behave, stated by the products. The strongest competitive evidence in this file.
4. **Category marketing** — make-ready software vendors trying to sound like the buyer. Pain phrasing tends to mirror real complaints; treat claims as claims.

**What is missing:** the shorthand and the irritation. How a coordinator actually talks about the unit that has been sitting at paint for a week. Treat everything below as directionally right and tonally unverified.

---

## Terminology

| Term | Usage |
|---|---|
| **doors** | Unit of company scale. "A 300-door portfolio." Never "units" for company size |
| **turn** / **turnover** | The whole process, move-out to rent-ready. Both used natively, interchangeably |
| **make-ready** | The same thing, slightly more formal, common in multifamily. Safe unglossed |
| **rent-ready** | The end state. The unit can be shown and leased |
| **stage** | One step of the turn. Our eleven are Notice, Pre-move-out inspection, Move-out, Inspection and punch list, Trash-out, Repairs, Paint, Flooring, Deep clean, QA and photos, Relist |
| **punch list** | The defect list produced by the move-out inspection. Drives the repairs scope |
| **trash-out** | Clearing what the previous resident left. Commonly the first physical stage and a frequent bottleneck |
| **trade** | The vendor specialism: repairs, paint, flooring, cleaning |
| **handoff** | One vendor finishing and the next being told to start. **The word this build is about** |
| **days vacant** | Days since move-out. Drives the money |
| **days on market / list-to-lease** | Listed to signed. Downstream of rent-ready and not what we affect. Do not blur the two |
| **vacancy loss** / **rent loss** | Rent not collected because the unit is empty. NAA reports it as a per-unit annual figure |
| **turn cost** | The spend to make a unit ready, typically $1,000-5,000 |
| **rework** | Doing a stage twice because something later undid it. The cost of bad sequencing |
| **second visit** / **second trip** | What rework looks like on an invoice. Industry reporting puts this at 20-25% of turnover repairs |
| **scattered site** | Single-family and small multifamily spread across a metro, versus one large property. Most of this ICP |
| **in-house vs outside vendor** | Whether trades are employees or subcontractors. Only outside-vendor operators have the handoff problem |

**The distinction that carries the honesty:** this automation affects **days vacant**, not **days on market**. It gets the unit rent-ready sooner. It does not lease it. Any copy blurring turn time into leasing speed is overclaiming and an operator will catch it.

**Who actually does this work.** A maintenance coordinator, ops manager, or in smaller shops the owner. The owner signs. Write about the work, not the reader's own hands.

---

## The sequence, and why it is the subject

The enforced order in this build:

| # | Stage | Depends on |
|---|---|---|
| 4 | Trash-out | Move-out |
| 5 | Repairs / trades | Move-out |
| 6 | Paint | Repairs |
| 7 | Flooring | Paint |
| 8 | Deep clean | Repairs, Paint, Flooring |
| 9 | QA and photos | Deep clean |
| 10 | Relist | QA and photos |

A skipped stage counts as satisfied. Skipping is a decision, not a violation.

**Two sequencing facts worth knowing before writing:**

**"Flooring before paint" is the most common sequencing failure in unit turnover**, usually caused by material arriving late and someone trying to make up time. The costs are protection, drip risk, and sometimes replacing new flooring. Our order (paint, then flooring) matches the operational consensus.

**A painter may argue the opposite and they are not simply wrong.** In new construction and some renovation contexts, flooring-first is defensible and trade forums disagree openly. Do not write the rule as a universal law of building. Write it as the order this client's turn runs in, encoded once so nobody has to remember it at 4pm on a Friday. Overstating it invites a contractor in the comments to be correct at your expense.

---

## Pain phrasing worth borrowing

From `03-make-ready-coordination.md` and industry sources:

- "A standard apartment make-ready takes 5-10 days from move-out to rent-ready. **Most of the calendar beyond that is coordination lag between trades, not hands-on work.**" — the single most useful sentence available to this build
- "When my painter finishes a unit, how do I find out?" — the qualifying question
- "How many units are in turn right now, and how long has each been sitting?"
- "Nobody logs this as a failure. It goes in the file as 'turnover took 11 days.'"
- A mid-sized Texas operator: losing "2-3 days just waiting for vendors to confirm or show up," with phone tag consuming **10-15 hours a week per portfolio**

**Three findings that matter more than the phrasing:**

**The lost days are not recorded as lost.** They are absorbed into the total. No operator has a field called "days spent not knowing the painter was done." This is why the problem persists at companies that measure everything else, and it is the strongest argument available: you cannot fix what your reporting has no name for.

**Silence and progress look identical.** A vendor who finished and said nothing produces exactly the same signal as a vendor who never started: nothing. This is structurally the opposite of build 2, which reacts to messages arriving. Here the absence of a message is the event. Nothing else in either previous build makes this argument.

**Over-coordination is under-discussed.** Sources cover slow turns extensively. Almost nothing quantifies the cost of a coordinator spending 10-15 hours a week chasing status by phone, which the owner pays for as salary rather than as vacancy. That asymmetry is open ground.

---

## The numbers

Use these. They are sourced, current, and specific enough to survive scrutiny.

| Fact | Figure | Source |
|---|---|---|
| Turns taking nine days or longer | **49%** of companies studied; 45% under nine, largest cluster 5-7 days | State of the PM Industry 2026 |
| Best-practice benchmark | 3-7 days | PropertyMeld data via internal research |
| Recovered rent from compressing turns | 200 units, 100 turns/yr at $1,500: **$20,000-50,000/yr** going from 7-14 days to 3-5 | Lula |
| Cost of one extra vacant day | **$50-100** in lost rent | US Tech Automations |
| Turnover repairs needing a second visit | **20-25%** | US Tech Automations |
| Expedited work premium | **30-50%** above scheduled | US Tech Automations |
| Turnover costs year over year | **+17.5%**; vacancy and rent loss **$1,323/unit**, fourth consecutive annual rise | NAA 2024 Income/Expense IQ |
| Repairs and maintenance since 2021 | **+28.2%** cumulative | NAA |
| Total make-ready cost | **$1,000-5,000** per unit over 5-10 days | Dropcurb |
| Sequencing improvement, single operator | 14 days to **5 days** in Phoenix by removing sequencing bottlenecks | GPS Renting via Breasy |
| National vacancy / list-to-lease | 7.3% / 41 days median | Lula |

**The derived figure, and how to present it.** A 300-unit company at 40% turnover runs about 120 turns a year. Four wasted days each is roughly **$24,000 a year from communication gaps alone**. This is arithmetic from the internal research, not a measured result. Present it as a worked example a reader can redo with their own numbers, never as a benchmark or a promise.

**The 20-25% second-visit figure is the strongest number in the set.** It prices the sequencing problem directly and nothing in builds 1 or 2 has an equivalent.

---

## The competitive landscape

**This category is occupied by capable products.** Any copy implying otherwise is false and easily disproved.

**Dedicated make-ready tools:** Make Ready Manager, TurnTrack, AppWorks, SuiteSpot, HappyCo, plus Rent Manager's own Make Ready module. **Adjacent:** Property Meld (maintenance, with turn workflows). **Different purchase entirely:** Lula, which performs the make-ready work itself in defined metros.

**Sequencing enforcement already exists.** Automated turnover systems advertise preventing "progression to the next stage until all previous stage tasks are complete and verified." **Do not claim ordering enforcement as unique.** It is table stakes in the category and claiming it will read as either ignorant or dishonest.

**The two facts that actually define the position:**

**HappyCo publishes a 500-unit minimum.** These are enterprise multifamily products with per-unit pricing and unit floors. A 150-600 scattered-door operator sits at or below that floor. This is a segment gap, not a capability gap, and it is the more honest of the two arguments.

**Property Meld's own documentation describes the vendor onboarding path:** the vendor receives an emailed invite, clicks through, fills in details, creates a password and signs up, and "completing the registration process is necessary to access Property Meld and start managing work orders." Meanwhile the selling point of rival communication tools is explicitly that contractors "won't need to download any new apps."

That is the differentiator with teeth: **the vendor does nothing new.** They reply from the email or messaging app they already have. Every portal-based competitor needs the vendor to become a user first, and vendor adoption is where these deployments actually die.

**Copy implications:**

- Never imply nobody has solved this. Six-plus products are selling into it.
- Never claim sequencing enforcement as unique.
- Lead the difference with vendor adoption and portfolio size, not features.
- Name the competitor a prospect should buy when they should buy it. Above 500 units, tell them to look at the enterprise tools. On Rent Manager already, tell them to try the module they are paying for.
- Do not compete on price per door. A flat monthly fee against per-unit pricing is a structural difference; turning it into a discount claim wastes it.
- Avoid the category's worn vocabulary: streamline, centralize, end-to-end, seamless, effortless, "never miss an update," "single source of truth."

---

## Conventions to get right

**Stage names.** Use the eleven as named above. They match common operator usage. Do not invent a twelfth or rename one for a better line.

**Expected duration, not SLA.** Each stage carries an expected duration used to decide when something has gone quiet. Call it an expected duration or a response target. **Never SLA and never deadline** — an SLA is a commitment not being made, and a deadline implies a contractual window not being defined.

**Vacancy math.** Daily rent is monthly rent divided by 30. Days vacant counts from move-out, not from notice. A unit under notice but not yet vacated has burned nothing, and copy that counts it is wrong.

**Turn time, not lease-up time.** See the terminology note. This affects rent-ready date only.

**The reply-rate floor.** Below roughly a 30% vendor reply rate the automated half of this is fiction and the honest answer is to say so. Above roughly 60% it works well. This conditional appears in the internal research and should survive into the copy rather than being quietly dropped.

---

## Rules for the copy

1. Use **turn**, **make-ready**, **doors**, **trade**, **punch list**, **trash-out** and **rent-ready** unglossed. This audience uses them daily.
2. Never write **units** for company size.
3. Never blur **days vacant** with **days on market**.
4. Say **expected duration** or **response target**. Never SLA, never deadline.
5. Do not claim the problem is unrecognized, and do not claim sequencing enforcement as unique.
6. Do not disparage the competitors. Name who should buy them.
7. Never present the $24,000 example as a measured result. It is arithmetic offered for the reader to redo.
8. Never present fixture verification as a customer outcome. There is no client yet. Say so plainly when it comes up.
9. There is **no board and no dashboard** in this build. One was built and deleted. Never describe a screen the client logs into.
10. Write the paint-before-flooring rule as this client's operating order, not as a universal law of construction.
11. Flag any phrase that is invention rather than sourced, so it can be replaced after real practitioner research.

---

## Sources

- [State of the Property Management Industry 2026](https://www.tricapnc.com/pdf/state-of-the-pm-industry-report.pdf) — 45% of companies turning units in under nine days, 49% at nine or more, largest cluster 5-7 days
- [Lula — How to Reduce Days Vacant on Rental Properties (2026)](https://lula.life/articles/how-to-reduce-days-vacant-on-rental-properties) — the 200-unit worked example, $20,000-50,000 recovered; national vacancy 7.3% and 41-day median list-to-lease
- [Lula — What Is a Make Ready?](https://lula.life/articles/what-is-a-make-ready) — make-ready definition, checklist and cost framing
- [US Tech Automations — Unit Turnover Delays Cost Property Managers Thousands (2026)](https://ustechautomations.com/resources/blog/property-management-unit-turnover-pain-solution-2026) — $50-100 per vacant day; 20-25% of turnover repairs requiring a second visit; 30-50% expedite premium
- [Vizismart — The Complete Make-Ready Guide for Property Managers](https://www.vizismart.com/post/the-complete-make-ready-guide-for-property-managers-reduce-turnover-time-cut-costs-and-automate-y) — "flooring before paint" as the most common sequencing failure; trade sequencing and rework
- [HappyCo — Pricing](https://happy.co/pricing) — per-unit, per-month pricing with a published 500-unit minimum
- [HappyCo — Make Ready](https://happy.co/solutions/processes/make-ready) — real-time digital turn boards, color-coded stages
- [Property Meld — Accepting Invite and Registering (Vendor)](https://help.propertymeld.com/hc/en-us/articles/45762651982355-Accepting-Invite-and-Registering-Vendor) — the vendor registration path, in their own documentation
- [Make Ready Manager](https://www.makereadymanager.com/) — cloud make-ready boards with a vendor mobile app
- [TurnTrack](https://blog.turntrack.online/blog/what-software-do-property-managers-use-3-alternatives) — role-based make-ready workflows with photo documentation
- [AppWorks — Make Ready Board](https://appworkco.com/solutions/make-ready-board/) — make-ready board positioning
- [SuiteSpot](https://www.suitespot.ai/platform) — unit turnover and mobile property operations
- [Rent Manager — How to Stay on Track with Unit Turnovers](https://www.rentmanager.com/how-to-stay-on-track-with-unit-turnovers/) — the PMS-native Make Ready feature
- [Heymarket — Business Text Messaging for Property Management](https://www.heymarket.com/blog/business-text-messaging-for-property-management/) — contractors not needing to download apps as an explicit selling point
- [Renova One — The Complete Guide to Apartment Unit Turnover](https://renovaone.com/the-complete-guide-to-apartment-unit-turnover/) — pre-move-out inspection 7-14 days ahead; stage structure
- [Dropcurb — Apartment Make Ready Checklist](https://dropcurb.com/blog/apartment-make-ready-checklist) — $1,000-5,000 per unit over 5-10 days; trash-out as common bottleneck
- [Breasy — Rental Turnover Checklist](https://joinbreasy.com/knowledge/rental-turnover-checklist-for-landlords/) — GPS Renting reducing average turnover from 14 to 5 days in Phoenix by removing sequencing bottlenecks
- NAA 2024 Income/Expense IQ (published August 2025), cited via Lula's make-ready guide — turnover costs +17.5% YoY, vacancy and rent loss $1,323/unit, repairs and maintenance +28.2% since 2021
- Internal: `03-make-ready-coordination.md`, `foundation-3-turnover-makeready.md`, `make-ready-demo-build-plan.md`, `AGENTS.md`, `.agents/product-marketing.md` v2
