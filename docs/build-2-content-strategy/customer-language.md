# Customer Language — US Residential Property Management, Maintenance

Created: 2026-08-13

Vocabulary reference for writing to property managers about maintenance triage. Companion to `docs/build-1-content-strategy/customer-language.md`, which covers the same ICP for vendor insurance paperwork. Same buyer, different working vocabulary — do not assume the COI file's terms transfer.

## Source quality — read this first

**Primary practitioner voice is still unreached.** Reddit is blocked in this environment, exactly as it was during build 1 research. BiggerPockets and the Facebook groups need a login. Nothing below is a property manager talking to another property manager unprompted.

What is available, in descending order of trustworthiness:

1. **Emergency-definition pages that management companies publish to their own residents.** The best source in this file and better than anything build 1 could reach. These are written by operators, for residents, with the specific goal of reducing after-hours call volume. There is no marketing incentive and the vocabulary is operational.
2. **Job descriptions** for maintenance coordinators and ops managers — actual duties in internal vocabulary.
3. **PMS and AI-triage vendor marketing** — second-hand, but these companies are trying to sound like the buyer, so pain phrasing tends to mirror real complaints.
4. **Industry survey reporting** (Buildium/NARPM) — numbers, not voice.

**What is still missing:** the shorthand, the irritation, the jokes. How a coordinator describes the Monday morning backlog to a colleague. Treat everything below as directionally right and tonally unverified, and mark anything that turns out to be my invention rather than sourced.

---

## Terminology

| Term | Usage |
|---|---|
| **doors** | The unit of scale. "A 300-door portfolio." Never "units" when describing company size |
| **work order** | The logged, assigned job. It exists *after* a human has decided what the request is. This distinction is load-bearing for us — see below |
| **request** / **service request** | What the resident sends. Unstructured, unclassified, pre-work-order |
| **triage** | Used natively across the industry for the assessment step. Safe unglossed; explaining it reads as talking down |
| **resident** | Industry-preferred, especially multifamily. Use as the default |
| **tenant** | Still widely used and correct in legal and habitability contexts. Not wrong, just older-register. Mixing both is normal and nobody will flinch |
| **after-hours** | Outside business hours. Roughly 76% of the week |
| **on-call** | The rotation for carrying the after-hours phone |
| **dispatch** | Sending a vendor to a property. The verb our product deliberately does not perform |
| **trade** | The vendor specialism — plumbing, electrical, HVAC, appliance |
| **truck roll** | Sending someone out. Used by the AI-triage category as the thing to avoid |
| **deflection** | The category's metric for requests resolved without a truck roll. Worth knowing; not a word to adopt |
| **turn** / **turnover** / **make-ready** | A resident leaving and the unit being prepared. ~$4,000 per unit |
| **maintenance limit** | The spending threshold above which owner approval is required. Typically $250–500 |
| **markup** | 10–20% added to vendor invoices as manager revenue |
| **habitability** | The legal standard. Non-waivable. Explains why some requests genuinely cannot wait |
| **response target** | Use this. Never "deadline" and never "SLA" in copy — an SLA is a commitment we are not making, and a deadline implies a legal window we are not defining |
| **Emergency / Urgent / Routine** | The industry-standard taxonomy, published by Buildium among others. Our own priority names match it exactly, which is worth quietly keeping |

**The work-order distinction is where our honesty lives.** Our system stops before the work order. It reads, classifies, collects missing detail, matches a vendor, and puts a decision in front of the manager. The manager still creates the work order in whatever PMS they run. Any copy that blurs request and work order is overclaiming, and a property manager will catch it instantly.

**Who actually does this work.** Usually a maintenance coordinator or ops manager, not the principal who signs. Same split build 1 found. Write about the work, not the reader's own hands.

---

## Pain phrasing worth borrowing

From discovery language in `foundation-2-maintenance-operations.md` and industry sources:

- "I check my phone before bed just in case." — the strongest single signal in the qualifying script
- "It goes in the portal and we deal with it Monday."
- "We had a flood last year that we found out about late."
- "Our coordinator handles it, she's great." — until asked what happens when she's on holiday
- "Not every late-night call is a true emergency," and treating everything with the same urgency "burns out both your team and your budget" (Buildium)
- "Many repair requests may feel urgent to tenants, [but] only certain issues qualify as emergencies" (Real Property Management)
- Industry burnout reporting: 40–60% of property managers report burnout symptoms, with on-call cited as the reason there is no genuinely off day

**Three findings that matter more than the phrasing:**

**The industry has already conceded that residents misjudge urgency.** Every operator emergency page exists to correct it. This changes how post 1 must be written: the claim "residents misjudge severity" is not news to them and asserting it as an insight will read as condescending. The novel part is the conclusion — *therefore the urgency field they fill in is decoration, and any process treating it as data is sorting on noise.* Lead with the conclusion, not the premise.

**Managers are not trained in triage either.** Nothing in the licensing or the job path teaches it. It is learned by absorption and it degrades under load. Same structural gap build 1 found with insurance: a post explaining the mechanics is genuinely useful rather than patronizing.

**Over-response is under-discussed.** Every source covers missed emergencies. Very few quantify the cost of dispatching a weekend plumber for a running toilet, even though operators feel it monthly and the owner sees it on the invoice. That asymmetry is an opening — the two-sided cost framing is available and mostly unoccupied.

---

## The competitive landscape

Not an empty space, and the shape is different from build 1's.

**Two distinct layers:**

**PMS incumbents** — Buildium, AppFolio, Rentvine, Yardi. Every one has a maintenance module. All of it is ticketing: storing, assigning, tracking a request a human already read and categorized. Rentvine's own AI-triage page concedes that staff must "review and confirm the assignment rather than building it from scratch." The classification step is what remains manual.

**The AI-triage category, and the direction it is heading:**

| Product | Pricing | Position |
|---|---|---|
| Property Meld | ~$1.60/unit/month Core, ~$2.00 Ops | The SMB/mid-market default, marketed as agentic AI that triages and dispatches on its own |
| Latchel | ~$25/unit/month managed; commonly resident-paid at $15–18 inside a benefits package | AI call center answering every call. Advertises "23% solved at intake" and **"48% of emergencies de-escalated"** |
| Vendoroo | From ~$3/door/month | End-to-end coordination, trained on 2M+ work orders, carrying an explicit **"If the AI makes an error, we will pay for it"** guarantee |

**The two facts that define our position:**

**Latchel sells automatic emergency de-escalation as a feature.** Our safety-rules layer is structurally escalate-only — it can raise a priority above the model's answer and can never lower one. Two products moving in opposite directions on the same decision. Write this factually. De-escalation backed by a staffed human call center is a legitimate design, and calling it reckless would be both unfair and easy to disprove. The honest sentence is that we made the opposite choice and here is why.

**Vendoroo's answer to the liability question is an indemnity.** That is a real answer, available to a company with insurance and a track record. Naming it plainly is stronger than pretending autonomy has no answer, and it sets up the actual differentiator: their answer is that they will pay when it is wrong; ours is that the decision never leaves the manager.

**Copy implications:**

- Never imply nobody has noticed this problem. Three funded companies and every major PMS are selling into it.
- The differentiator is not "I do AI maintenance triage." It is direction: everyone else is removing the human from dispatch, and this is built for the operator who wants the opposite.
- Never disparage the autonomous products. Some buyers should buy them, and saying so is the most credible thing in the pitch. The anti-persona is real.
- Do not compete on price per door. Flat fee versus per-unit is a genuine structural difference; turning it into a discount claim wastes it.
- Avoid the category's worn vocabulary: streamline, centralize, end-to-end, seamless, effortless, "never miss a request."

---

## Two conventions to get right

**Priority naming.** Emergency / Urgent / Routine matches the published Buildium taxonomy, which is what most of this segment recognizes. Some operators run P1–P4 instead. Our build already uses the standard three, so no explanation is needed. Do not invent a fourth level in copy.

**Response targets.** The commonly quoted convention is emergency within roughly 1 hour, urgent within 24, routine scheduled. Our config sets these per client and calls them response targets, not deadlines. Do not present any number as a legal window — habitability timelines vary by state and we are not giving legal advice.

**One deviation to avoid citing.** `02-maintenance-triage.md` proposed an aging ladder where a routine request open 10 days becomes urgent and 14 days triggers emergency review. **The build deliberately does not do this.** Age produces an OVERDUE board and digest status only, and never an emergency alert, per the architecture rule in `AGENTS.md`. Post 11 is built on that decision. Copy must not quote the old ladder.

---

## Rules for the copy

1. Use **triage**, **work order**, **doors**, **after-hours**, **on-call**, **dispatch** and **trade** unglossed. This audience uses them daily.
2. Default to **resident**; **tenant** is fine in legal or habitability sentences.
3. Never write **units** for company size.
4. Never blur **request** and **work order**. We stop before the work order and the copy must say so.
5. Say **response target**, never deadline or SLA.
6. Write about the work, not the reader's hands — the person feeling it is often the coordinator, not the buyer.
7. Do not claim the problem is unrecognized, and do not disparage the autonomous competitors.
8. Never state or imply an accuracy percentage across the full fixture set. See the constraint in `.agents/product-marketing.md`.
9. Flag any phrase that is my invention rather than sourced, so it can be replaced after real practitioner research.

---

## Sources

- [Buildium — How to Track Property Management Emergency Maintenance Issues](https://www.buildium.com/blog/how-to-track-property-management-emergency-maintenance-issues/) — Emergency/Urgent/Routine definitions, response targets, the burnout-and-budget line, and the recommendation to automate routing for water leaks and gas smells
- [Buildium / NARPM — 2026 State of the Property Management Industry Report](https://www.buildium.com/blog/2026-property-management-industry-trends/) — maintenance as #2 operational challenge; 38% of owners citing it as top stress; slow response as #1 non-renewal factor
- [Real Property Management Triad — After-Hours Rental Maintenance Guide](https://www.rpmtriad.com/after-hours-rental-maintenance-guide-661) — operator-authored emergency definitions; the concession that requests "may feel urgent to tenants" but only some qualify
- [Bay Management Group — Landlord Guide to After-Hours Emergency Maintenance Calls](https://www.baymgmtgroup.com/blog/handle-hours-calls-tenant/) — emergency vs non-emergency framing and expectation-setting with residents
- [Rentvine — Automated Maintenance, Work Orders, Vendor Coordination and AI Triage](https://www.rentvine.com/blog/automated-maintenance-work-orders-vendor-coordination-ai-triage) — the six workflow stages; the concession that staff must confirm AI vendor assignment
- [OxMaint — The Property Manager's Guide to Maintenance Work Order Prioritization](https://oxmaint.com/industries/property-management/property-manager-guide-maintenance-work-order-prioritization) — P1–P4 scheme; 15–25 requests per 100 doors per week
- [Latchel](https://latchel.com/) — AI call center claims; "23% solved at intake"; "48% of emergencies de-escalated"
- [Vendoroo](https://vendoroo.ai/) — end-to-end AI coordination claims; 2M+ work orders; "If the AI makes an error, we will pay for it"
- [Property Meld pricing](https://valuecore.ai/valuehub/organizations/propertymeld/pricing) — ~$1.60/unit Core, ~$2.00 Ops
- [SFAI Labs — Best AI Maintenance-Triage Tools for Small Property Managers](https://sfailabs.com/guides/best-ai-maintenance-triage-tools-small-property-managers) — category comparison and the agentic-versus-assisted distinction
- [HireOne — Property Management Burnout Prevention](https://hireonestaffing.com/property-management-burnout-prevention-15-strategies-for-dc-managers/) — 40–60% burnout reporting; on-call as the cause of no genuine off day
- Internal: `foundation-2-maintenance-operations.md`, `02-maintenance-triage.md`, `docs/build-description.md`, `AGENTS.md`
