# Make-Ready Coordination — Demo Build Plan

**Working name:** none. This is a make-ready sequencing AI automation demo, not a named software/SaaS product.
**Target:** US residential PM companies, 150–600 doors
**Deliverable:** a live demo that survives five minutes on a sales call with an unproven vendor running it
**Audience for this document:** Claude Code, executing directly

## Current Airtable/Email Redesign Override

The implemented redesign supersedes older sections that describe a custom board, simulator, n8n form, UI-only APIs, or Telegram-only vendor delivery.

- Airtable is the manager workspace and intake form; Postgres is still authoritative.
- Vendor replies enter through Telegram, IMAP email, or the generic inbound API.
- OpenAI provides one strict shared interpretation across channels. It cannot mutate records.
- Managers receive every alert, digest, approval, and exception in Telegram.
- Every approved vendor message goes to email and Telegram. A missing destination blocks sending; a failed second channel becomes `Partially Sent` and retries alone.
- The final n8n list contains 19 prospect-friendly operational workflows with stable internal IDs and no visible workflow numbers.
- The custom board, simulator, Board API, Stage Complete API, Manager Action API, and Health API are removed.

---

## 0. Four corrections to the source document, up front

**0.1 — Auto-notifying the next vendor is wrong, and I've removed it.** The source spec says the system "advances the sequence automatically and notifies the next vendor." Don't build that. You are an unproven freelancer inserting automated messages into a relationship you don't own, sent in your client's name. One badly-timed 11pm text to a painter the client has used for nine years costs more than the product earns. Every outbound vendor message is drafted by the system and released by the manager's thumb. This is not a compromise — it is the single best moment in the demo, because it puts the prospect's finger on the trigger during the call. See §9.

**0.2 — "Weakest demo of the four" is a fixable framing problem, not a fact.** The stated weakness is that value unfolds over days. True, but the demo doesn't need to show days elapsing — it needs to show *knowing something the manager doesn't currently know*. That's instantaneous. Pre-seeded state with genuinely backdated timestamps gives you real ages, and the stall detector fires live during the call. The demo is fine.

**0.3 — Build order caution stands, and it's stronger than the doc says.** The qualifying question ("When your painter finishes a unit, how do you find out?") gates the *automation value*, not just the client. But it does **not** gate the *demo build* — the board and the sequence guard deliver value at a 0% vendor reply rate. Build the visibility layer as the core and the vendor loop as the extension, so that a bad answer to the qualifying question downgrades the offer instead of killing it.

**0.4 — The 0% claim is only true because of WF-7. Do not drop it.** The hedge in 0.3 is repeated in §6 and stated to the prospect in §11, and it is the reason this automation is safe to demo before you know a client's vendor reply rate. It holds only if a manager can advance a stage with no vendor message at all — otherwise every unit freezes at its first stage, the stall detector fires on everything, and the board becomes noise inside two days. **WF-7 (§3.2) is what makes the claim true, and it is built before the vendor loop, not after.** If you cut one thing from this plan, do not cut that.

---

## 1. Research findings

Everything below was verified in July 2026. Where I could not confirm something, I say so.

### 1.1 Buildium API — the blocker holds, and it got worse

Confirmed. Buildium's Open API is gated behind the Premium plan. The figure in the source document ($375–400/mo) is now stale on the low end: Buildium's live pricing shows **Essential $62/mo, Growth $192/mo, Premium $400/mo**, with Open API listed as a Premium-only feature. Many published reviews still print the older $58/$183/$375 grid.

Consequence: a 300-door shop on Growth ($192) would need to add **$208/month** to their software bill before you have delivered anything. That kills the deal. Additionally, transaction fees add roughly 30–50% on top of base plan pricing, so their real Buildium spend is already higher than the sticker and they are sensitive about it.

**Architecture decision forced by this: zero PMS integration.** Not "minimal." Zero. No read, no write, no OAuth, no CSV export dependency. The system runs entirely beside their PMS. This is also a sales asset — see §9.

The same logic applies to the other three PMSs named in the brief. I did not individually verify Rentec Direct, Rent Manager, and Propertyware API tiers and costs, and I don't need to: the design requires none of them. **Do not let a prospect talk you into an integration during the demo call.** The correct answer is in §11.

### 1.2 n8n licensing — this changes your delivery model, not your demo

n8n is under the **Sustainable Use License** (fair-code, not OSI open source). Two facts matter and they point in opposite directions:

- **Consulting is explicitly permitted.** n8n lifted the old Commons Clause restriction on charging for consulting and support. Building n8n workflows for clients as a paid service requires no license agreement.
- **Hosting client workflows on your own instance does not.** Per n8n's own help centre: if you host and manage your clients' workflows and credentials inside your own n8n instance, an **Enterprise license is required**. If you only help clients set up and run *their own* instances, **no commercial license is required on your part**.

**Delivery model, decided:** the demo runs on your instance with your own synthetic data — that is your own internal business use and is unambiguously fine. **Production runs on the client's own VPS**, provisioned by you, owned and paid for by them. You are a consultant operating their instance. This is the licensing-clean path, and it also happens to be the best answer to "where does our data live?" (§1.5) and the best answer to "what happens if you disappear?" — which an unproven solo freelancer will be asked.

Do not build a multi-tenant instance where several clients' turns live side by side. That is the exact shape that requires an Enterprise license.

n8n also ships some files with `.ee.` in the filename under a separate Enterprise License. Nothing in this build touches them.

### 1.3 Licences of everything else in the stack

| Component | Licence | Commercial-use impact on you |
|---|---|---|
| n8n (self-hosted) | Sustainable Use License | See §1.2. Consulting fine; client-hosted instances fine; your-instance multi-tenant is not |
| PostgreSQL | PostgreSQL License (permissive, BSD-like) | None |
| Caddy | Apache 2.0 | None. Attribution in source only, not required in UI |
| Docker Engine | Apache 2.0 | None |
| Telegram Bot API | Free service, Telegram ToS | No licence fee. Not open source — you depend on Telegram's service. Acceptable for demo, replaced by SMS in production |
| OpenAI API | Commercial ToS | Paid per token. You own outputs per OpenAI's terms |
| Demo visualization UI (written by you) | Yours | Used only to show the automation state during demos |
| EspoCRM | AGPLv3 | **Cut from this build** — see §4.9 |

No community n8n nodes are used. Every node in this design is a core node. That is deliberate: community nodes are the most common source of "worked last week, broken today" in a live demo, and their maintenance status is your problem in front of a prospect.

**No copyleft exposure.** Nothing in this stack is GPL/AGPL once EspoCRM is cut. You are not distributing modified n8n, so the SUL redistribution clause doesn't engage.

### 1.4 Regulatory gates — which apply, which don't

**Applies, in production only — A2P 10DLC.** Any automated SMS to US mobile numbers from a 10-digit number requires brand + campaign registration with The Campaign Registry. Current reality as of mid-2026:
- Brand approval: typically 1–3 business days
- Campaign approval: running roughly **10–15 days in mid-2026** due to submission volume; commonly quoted range 1–4 weeks, with 4–6+ weeks if you get rejected and resubmit
- Costs: brand registration ~$44–48 for a standard brand (~$4 sole proprietor), campaign ~$15–17 one-time, plus ~$1.50–10/month per campaign, plus carrier surcharges of roughly $0.003–0.005 per message
- Unregistered traffic is filtered or blocked; T-Mobile publishes per-violation fees in the $2,000–10,000 range

**This is a real delay and it is on the client's critical path, not yours.** Registration is done under the **client's** EIN and brand, through the client's own Twilio account. Start it on day one of a paid engagement, in parallel with everything else. Do not promise SMS on a date you don't control.

**This is also the entire reason the demo uses Telegram.** You cannot demo SMS without weeks of registration you haven't started for a client you don't have.

**Applies, in production only — TCPA.** Vendor texting is not exempt because vendors are businesses. TCPA attaches to the device, not the recipient's status, and contractors' work numbers are overwhelmingly mobile. What this means concretely:
- Vendor status messages are **informational/transactional**, not marketing, so the standard is **prior express consent** (the lower bar) rather than prior express written consent. A vendor giving the client their mobile number for job coordination generally supplies that, but you need a record of it
- Keep the messages clean. The moment a message includes anything promotional, it becomes a marketing message and the consent bar rises
- The FCC revocation rule effective April 11, 2025 requires honouring opt-out requests promptly and treating a revocation as applying broadly. Build STOP handling; don't bolt it on
- Statutory damages run $500–1,500 per violation with a private right of action. This is a bulk-exposure risk, which is why §14 makes consent records and quiet hours non-negotiable in production
- The FCC's one-to-one consent rule was vacated by the Eleventh Circuit in January 2025 and subsequently eliminated. It does not apply. Several sources still describe it as live — ignore them
- State-level SMS statutes (Florida's FTSA, Oklahoma, others) impose additional constraints. **I did not verify these state by state.** Before the first production SMS goes out, check the client's operating states with a US attorney. This is cheap to check and expensive to get wrong

**Does not apply — Fair Housing Act AI guidance.** HUD's May 2024 guidance covers two specific areas: **tenant screening** and **housing advertising/ad targeting**. This automation does neither. It coordinates vendors on already-vacant units. FHA is not implicated by the demo as designed.

The boundary matters though, and it is your boundary to hold: **the moment anything in this system touches applicant selection, listing copy, or ad targeting, HUD's guidance applies and the liability sits with the housing provider regardless of who built the tool.** Relist (stage 10) is a *notification to the manager that the unit is ready*, never a listing action. Keep it there.

Related boundary marker: Colorado's SB 24-205 classifies AI tenant-screening systems as high-risk, with a compliance date of June 30, 2026. Its effective date has been moved more than once, so **verify current status if a Colorado prospect appears**. It does not reach vendor coordination.

**Does not apply — state habitability response windows.** Those govern repair response in *occupied* units. This automation runs on vacant units between tenancies. If a prospect asks whether this handles maintenance tickets, the answer is no (§11).

**Adjacent and dangerous — security deposit itemization.** Move-out inspection and punch list are stage 3 of this pipeline, and the same walkthrough that generates a punch list often generates deposit deductions. Every US state sets a deadline and an itemization standard for deposit disposition, and getting it wrong creates statutory penalties for your client. **The system must never classify damage as tenant-chargeable versus normal wear, never compute a deduction, and never generate deposit correspondence.** Punch list items are work items for vendors, full stop. This is stated as a hard exclusion in §11 and enforced in the prompt design in §5.

**Does not apply — FTC endorsement rules.** These bite when you publish testimonials and case studies. You have none. When you get your first one, revisit: the FTC requires disclosed material connections and prohibits fabricated or unrepresentative testimonials. Relevant to your marketing later, not to this build.

**No certifications or registrations block the build or the sale.** There is no licensing regime for selling workflow automation to US property managers. You can sell this from India today.

### 1.5 Data privacy — India processing US data

**What you actually hold in this system:** vendor names and mobile numbers, unit identifiers and property addresses, stage timestamps, vendor free-text messages, completion photos. In production, occasionally a tenant name and move-out date on intake.

Findings:

- **India's DPDP Act 2023 + DPDP Rules 2025** (notified 13 Nov 2025) are in a phased rollout with most operational obligations landing by **mid-May 2027**. The Consent Manager framework becomes operational 13 Nov 2026. So there is a runway, not an immediate gate.
- Relevant carve-out: reporting on the DPDP Rules describes an **outsourcing exemption** — where an Indian entity processes, under contract, personal data of individuals located **outside** India, certain obligations may not apply. That is precisely your situation. **I am flagging this as promising but not settled** — the scope of the exemption is being read differently by different practitioners, and I am not a lawyer. Confirm with an Indian solicitor before you sign a data processing agreement with a US client. Budget one consultation.
- India has not been placed on any restricted-transfer list by the US, and India's own regime permits transfers to most countries by default with no country currently notified as restricted.
- US federal privacy law does not cover this data. State laws (CCPA/CPRA and successors) generally apply to businesses above revenue/volume thresholds that a 300-door PM company typically does not meet — **but verify against the client's actual state and size rather than assuming.**

**What to do, regardless of what the law strictly requires:**

1. **Store the minimum.** No SSNs, no bank details, no tenant financial data, no lease documents, no screening data. If a prospect offers you a Buildium export, decline it.
2. **In production, all data lives on the client's own VPS**, in a region they choose, on infrastructure billed to them. Your access is SSH via key, revocable by them at any moment. This is a consequence of the licensing decision in §1.2 and it is the single cleanest answer to the question you will be asked.
3. **Retention:** vendor messages and photos purge at 90 days by default, configurable. Stage timestamps retained indefinitely (they're the reporting value and they contain almost nothing personal).
4. **Photos are the sensitive item**, not the text. Vacant-unit interiors are low-risk, but photos are the thing most likely to accidentally contain a person or a document. Purge them on the shortest cycle the client will accept.
5. **The one thing that crosses a border is the LLM call**, and it carries a vendor's message text plus a unit label. Say so plainly.

**The answer to "where does our data live?", memorised:**

> "On a server you own, in a region you pick, billed to your card. I have an SSH key you can revoke in ten seconds. The only thing that ever leaves it is the text of a vendor's message going to OpenAI to be parsed — no names, no addresses, no photos. I'm in India, so I'll sign whatever data agreement your attorney wants."

### 1.6 n8n nodes — verified current

All confirmed to exist under these names:

| Node | Type string | Role here |
|---|---|---|
| Telegram Trigger | `n8n-nodes-base.telegramTrigger` | Vendor and manager inbound |
| Telegram | `n8n-nodes-base.telegram` | Outbound messages, inline keyboards, photo fetch |
| Webhook | `n8n-nodes-base.webhook` | Board JSON endpoint |
| Respond to Webhook | `n8n-nodes-base.respondToWebhook` | Returns board JSON |
| Schedule Trigger | `n8n-nodes-base.scheduleTrigger` | Stall watchdog, daily digest |
| Postgres | `n8n-nodes-base.postgres` | All state |
| Code | `n8n-nodes-base.code` | Sequence guard, matching, formatting |
| Switch | `n8n-nodes-base.switch` | Intent routing |
| If | `n8n-nodes-base.if` | Binary gates |
| Edit Fields (Set) | `n8n-nodes-base.set` | Field shaping |
| HTTP Request | `n8n-nodes-base.httpRequest` | OpenAI calls |
| Execute Sub-workflow | `n8n-nodes-base.executeWorkflow` | Router → handler dispatch |
| n8n Form Trigger | `n8n-nodes-base.formTrigger` | Turn intake form |
| Merge | `n8n-nodes-base.merge` | Join board queries |

**Two gotchas that will cost you an afternoon if you don't know them:**

**Gotcha 1 — one webhook per Telegram bot.** The Telegram Bot API permits exactly one registered webhook URL per bot token. Two active n8n workflows with Telegram Triggers on the same credential will fight over `setWebhook` and one will silently stop receiving updates. **Solution, baked into this design: two bots.** A vendor-facing bot and a manager-facing bot, each with exactly one trigger workflow that routes internally via Execute Sub-workflow. This is also better product design — vendors never see manager traffic.

**Gotcha 2 — Telegram Trigger needs a publicly reachable HTTPS URL.** It registers a webhook with Telegram. If n8n isn't publicly reachable at a valid TLS endpoint, the trigger never fires and the failure is quiet. For this demo build, n8n runs locally and Telegram testing uses a temporary HTTPS tunnel, such as Cloudflare Tunnel or ngrok. Set `WEBHOOK_URL` explicitly to the active tunnel URL before enabling Telegram triggers, and expect to update it when the tunnel URL changes.

**A third, avoided by design:** since n8n 1.103.0, HTML returned by Respond to Webhook is wrapped in a sandboxed iframe. Relative URLs break, and JS touching the top-level window or storage fails. This is why the board is served as a static file locally and fetches JSON from n8n, rather than being rendered by n8n. In production, Caddy serves the same static board. Don't fight the sandbox.

**Not using for model calls:** the built-in OpenAI/LangChain nodes. Rechecked in August 2026: n8n's OpenAI node now supports the Responses API and model selection, but its documented JSON option is still not the same as OpenAI Structured Outputs with a strict schema. Use HTTP Request against the OpenAI Responses API directly for the classifier and drafter so the exact model ID, strict schema, raw response, and fallback behavior are explicit. HTTP Request also fails in a way you can read.

### 1.7 OpenAI models — pick, and verify at build time

Per your instruction, everything here is OpenAI. **Nothing in this build needs Anthropic** — the two jobs are short-text classification and short-text drafting.

Rechecked against current OpenAI docs on 1 August 2026:

- OpenAI's model guide positions **GPT-5.6 Luna** for cost-sensitive, high-volume workloads.
- OpenAI pricing lists `gpt-5.6-luna` at **$0.10 input / $0.60 output per million tokens** for short-context traffic.
- The older `gpt-5.4-nano` is **$0.10 input / $0.625 output per million tokens** on the all-model short-context table, so Luna is at least as cheap and is the newer default choice.
- `gpt-5.4-mini` is **$0.375 input / $2.25 output per million tokens** on the all-model short-context table, so it is materially more expensive than Luna and should not be the default for this tiny drafting task.
- `gpt-5.6-terra` is a quality fallback, not a default: it costs **$1.00 input / $6.00 output per million tokens** for short-context traffic.

**Decision:**

| Step | Model | Why |
|---|---|---|
| Vendor reply classification + extraction | `gpt-5.6-luna` | Cheapest current OpenAI default suited to simple high-volume work, with strict structured output |
| Vendor message drafting (client tone) | `gpt-5.6-luna` first; fallback to `gpt-5.6-terra` or `gpt-5.4-mini` only if tested wording is visibly poor | Drafts are short and human-approved. Start cheap, upgrade only if quality fails in fixtures |
| Everything else | No model | Sequence logic, stall detection, and cost arithmetic are deterministic code. See §3.4 |

**Build-time action for Claude Code:** before writing any workflow, call `GET https://api.openai.com/v1/models` with the user's key and confirm `gpt-5.6-luna` is present. If it is absent, fall back in this order: `gpt-5.4-nano` for classification, then `gpt-5.4-mini` or `gpt-5.6-terra` for drafting depending on availability and tested quality. Record the model ID actually used in env vars (`OPENAI_MODEL_CLASSIFY`, `OPENAI_MODEL_DRAFT`) referenced by every workflow, so a future swap is a one-line change.

### 1.8 Competitive landscape — read this before you price anything

This category is crowded and it is not new. Cloud make-ready tracking with vendors marking jobs complete from their phones was being commercialised in 2012. You are not entering an empty field, and a prospect who has shopped this space will know that within ninety seconds.

**Property Meld — the one that decides your deals.** Built for single-family and some multi-family PM companies, explicitly covering work requests *and turnovers*. Integrates with AppFolio, Buildium, Propertyware and Rent Manager — all four PMSs in your target list. Pricing starts around $1.60/unit/month with a $160 monthly minimum, so **a 300-door prospect pays roughly $480/month — inside the range you planned to charge.** They have a brand, a support team, published industry benchmarks, and four integrations. You have none of those.

**You cannot win this on breadth. You win on three specific things, all already in your build:**

1. **Vendor onboarding.** Their vendors are invited by email and must register and complete account setup before they even appear as active in the system. Property managers publish "vendor login" pages for it. **Yours install nothing.** This is your single strongest differentiator and it is real — every serious competitor in this space onboards vendors into a system.
2. **Sequence enforcement.** I found no evidence Property Meld blocks a downstream stage being marked complete while an upstream one is open. Your guard is a genuinely different capability. **Verify before claiming it — see §1.9.**
3. **It's yours.** Their roadmap isn't. A change you want is a conversation with you, not a feature request in a queue.

**Rent Ready** — a purpose-built "turn performance operating system" with vendor intelligence and payments, aimed at 1,000+ unit multifamily. Above your segment, but it will appear in comparisons.

**Lessen / Lula** — managed vendor marketplaces. Lula operates a managed make-ready service across 17 US metros (Atlanta, Cincinnati, Cleveland, Columbus, Dallas–Fort Worth, Dayton, Houston, Indianapolis, Kansas City, Memphis, Minneapolis, Oklahoma City, Orlando, Phoenix, St. Louis, Tampa, Tulsa) on a one-partner/one-invoice model, claiming most turns inside 72 hours. That claim is vendor self-reported and unverified. What matters isn't its precision: **in those metros your prospect can delete the coordination problem rather than instrument it.** Check the metro before the call. Outside them, this objection doesn't exist.

**The competitor nobody lists — an offshore VA.** Property management virtual assistants handling maintenance coordination run about $1,200/month, PM-specialist firms $1,800–2,500, against $3,000–4,500 for a US admin. A VA does this task *and forty others*, can be replaced next month, and creates no technical dependency on a stranger. **At your price point this is the real alternative**, and the answer is in §11.

**Where you actually fit.** Property Meld skews single-family. Rent Ready targets 1,000+ unit multifamily. **150–600 doors, mixed or small multifamily, sits in the gap between them** — and your no-onboarding vendor path is the thing neither has. That's a narrow position, but it's a real one, and you should be able to state it in one sentence.

**One caution on durability.** This is a feature gap, not a moat. Property Meld could ship inbound-SMS parsing in a quarter. You are renting this gap, not owning it. For a freelancer that's fine — you need a sellable difference, not a defensible one — but don't build a five-year plan on it.

### 1.8b Market reality — what the industry says it wants

Two findings worth carrying into every call:

- **This is not the problem PM companies name first.** The 2026 Buildium/NARPM report puts tenant quality as the number-one challenge for the second year running; maintenance generally ranks as the biggest operational stressor. Make-ready coordination sits below both. You're selling into a problem people *agree with* rather than one they're actively shopping for — which means a longer, colder sale and a heavier burden on the demo.
- **You are selling into active AI scepticism, and it is your advantage.** 78% of property managers report they cannot yet rely on the AI features in their existing software, while AI usage across PM companies jumped from roughly 20% to 58% in a single year. You are not early, so there is no novelty premium — but the distrust is exploitable. §3.4's argument that the enforcement layer is arithmetic rather than a model is the sharpest thing you can say to a room that has been burned. §9 moves it to the front of the demo for exactly this reason.

Also relevant: referrals are the number-one growth channel in property management, and it's how they buy as well as how they sell. Cold outbound into a referral-driven industry is the hard road, and it is the road you are on.

### 1.8c Pre-call checklist — five minutes, every time

Before any demo:

1. **Metro check.** Is the prospect inside one of Lula's 17? If yes, they can outsource the problem instead of instrumenting it — lead with cost and control, since they keep their own vendors, their own pricing, and their own relationships.
2. **Door count.** Under ~250 doors your flat fee is more expensive per door than a better-supported incumbent. Know that before you quote.
3. **Single-family scattered or multifamily?** Determines which competitor you're being compared against and which half of §1.8 you lean on.
4. **What are they using today?** If the answer is Property Meld, Rent Ready or Lessen, **do not demo** — ask what it doesn't do for turns and listen. That's automation research, not a deal.
5. **Book a Property Meld demo as a prospect, once, before your first sales call.** Ask directly whether you can mark cleaning complete while repairs are still open, and what a 300-door account actually costs all-in. An hour of your time either confirms your best competitive line or stops you claiming something false in front of a buyer.

### 1.9 What I could not verify

Stated plainly, per your instruction:

- **GPT-5.4-mini output token price.** Input ($0.75/M) is sourced; output is an assumption.
- **The scope of India's DPDP outsourcing exemption** as applied to your exact arrangement. Promising, not settled. Needs an Indian lawyer.
- **State-specific SMS statutes** beyond the federal TCPA layer. Not surveyed. Needs checking against the client's operating states before production SMS.
- **Rentec Direct / Rent Manager / Propertyware API tiers.** Not researched — the design requires none of them.
- **Lula's 72-hour turn claim.** Vendor self-reported.
- **Whether Property Meld enforces turn stage sequencing.** This is your second-best differentiator and I could not confirm it either way. The only source suggesting a gap is Rent Ready's own comparison marketing, which is not evidence. **Verify by booking their demo before you claim it.**
- **Property Meld's real all-in cost at 300 doors.** The $1.60/unit figure comes from secondary sources, not a quote.
- **Whether Property Meld has an inbound path for vendors who won't register an account.** If they've shipped one, your primary differentiator weakens considerably and you need to know before you build a pitch around it.

**A warning about sources in this space.** A large share of what surfaces on these queries is AI-generated SEO content with fabricated statistics — I found pages citing precise-sounding "NARPM 2025 automation ROI data" for figures I could not trace to NARPM at all. **Never quote a number to a prospect that doesn't trace to Buildium/NARPM, NAA, or Property Meld's own published benchmarks.** A property manager who catches you citing an invented statistic has learned everything they need to know about you.
- **PropertyMeld's 9-days-per-turn figure** cited in the source document was reached via a secondary source. Use it as directional in conversation; never as a number you stand behind.

---

## 2. The demo in one paragraph

You share your screen showing a board of six units currently in turn, each a card with a stage and a number of days sitting at that stage, sorted worst-first. One card is red: Unit 12B, at Paint, four days, $212 of rent burned while nothing happened. You let that sit, then say "your version of this screen doesn't exist — that's the whole pitch." You hand the prospect your phone, already in a Telegram chat, and ask them to type "done with 12b" as if they were the painter. Within a couple of seconds the board card turns from red to green, and *their own phone* buzzes with a message: the painter finished 12B, the next stage is Flooring unless the manager skips it, here's the message drafted to Statewide Flooring in the client's own voice, and two buttons — Send, or Hold. They press Send. The flooring handoff appears on the board. Then you try to break it: you mark Deep Clean complete on a different unit where drywall repairs are still open, and the system refuses — "Repairs is still open on 14A. Cleaning before repairs means cleaning twice," which is the $180 rework nobody logs as a failure. Finally a stall alert fires on its own for a unit that's been at Trash-out too long, on the prospect's phone, unprompted, while you're talking. You close by doing their arithmetic in front of them with their own rent number, and the ask is smaller than they expect: nothing installed, no vendor contacted, no software touched — just their last three turns on paper, and their own board back before you next speak.

---

## 3. Architecture

### 3.1 The shape

```
                          ┌──────────────────────────────────────┐
                          │  Local machine (Docker Compose       │
                          │  during demo build)                  │
                          │                                      │
  Vendor's phone ────────►│  ┌────────────┐    ┌──────────────┐  │
  (Telegram via tunnel)   │  │  Local     │    │  PostgreSQL  │  │
                          │  │  static    │    │  turn        │  │
  Manager's phone ───────►│  │  board     │    │  turn_stage  │  │
  (Telegram via tunnel)   │  │            │    │  vendor      │  │
                          │  └─────┬──────┘    │  event_log   │  │
  Manager's browser ─────►│        │           │  outbound_q  │  │
  (board / localhost)     │        ▼           └──────▲───────┘  │
                          │  ┌──────────────────────┐ │          │
                          │  │        n8n           │─┘          │
                          │  └──────────┬───────────┘            │
                          └─────────────┼────────────────────────┘
                                        │
                                        ▼
                              OpenAI API (text only)
```

### 3.2 Workflows and node sequences

**WF-1 · Turn Intake**
`n8n Form Trigger` → `Code` (validate + compute target ready date) → `Postgres` (INSERT turn) → `Code` (expand stage template) → `Postgres` (INSERT turn_stage rows) → `Telegram` (confirm to manager)

Manager-facing form. In production this is where a live turn starts; in the demo it's how you add a unit on the call if a prospect asks "what if I get a notice right now."

**WF-2 · Vendor Ingest — Telegram** *(sole Telegram Trigger on the VENDOR bot)*
`Telegram Trigger` (updates: message) → `Edit Fields` (normalise to the standard envelope below) → `Execute Sub-workflow` → **WF-2c**

**WF-2b · Vendor Ingest — Generic** *(second inbound channel)*
`Webhook` (POST `/vendor-in`, header auth) → `Edit Fields` (normalise to the same envelope) → `Execute Sub-workflow` → **WF-2c** → `Respond to Webhook`

Both ingests emit an identical envelope and nothing downstream knows which one it came from:

```json
{ "channel": "telegram" | "generic",
  "sender_ref": "<chat_id or phone>",
  "text": "done with 12b",
  "media": null | { "type": "photo", "file_id": "..." },
  "received_at": "2026-08-01T14:22:05Z" }
```

**WF-2c · Vendor Router** *(sub-workflow — all the actual logic)*
`Postgres` (lookup vendor by `sender_ref`) → `If` (known vendor?) → `Code` (assemble classification payload: message text + that vendor's open stages only) → `HTTP Request` → OpenAI Responses API using `OPENAI_MODEL_CLASSIFY`, strict JSON schema → `Code` (**unit matcher** — deterministic scoring, see §3.5) → `Switch` on intent:

- `stage_complete` → **WF-2d**
- `delay_notice` → `Postgres` (log + set stage flag) → `Telegram` (notify manager) → reply-to-vendor via originating channel
- `question` / `unclear` / `not_my_unit` → `Postgres` (log) → `Telegram` (forward verbatim to manager, no interpretation) → ack vendor via originating channel
- unknown sender → `Postgres` (log) → `Telegram` (notify manager, do not reply to sender)

**Why the split matters commercially, not just technically.** Your one real differentiator is that vendors install nothing — no app, no account, no email invitation to accept. Every established competitor onboards vendors into a system (§1.10). But you demo that claim over Telegram, which is the one channel a US contractor *would* have to install. The split lets you show the same message arriving down a different pipe and producing an identical result, which turns "we'll swap to SMS later" from a promise into an obvious remaining step. Build the generic webhook even though the demo mostly uses Telegram — it is roughly thirty minutes of work and it is what makes §9's channel-independence beat possible. In production, the SMS provider posts to this same webhook and nothing else changes.

Replies to the vendor route back through the originating channel: a `Switch` on `channel` selecting either the `Telegram` node or an HTTP callback. In the demo the generic path's replies are simply displayed in the simulator page (§8).

**WF-2d · Completion Handler** *(sub-workflow, called by WF-2c and by WF-7)*
`Code` (**sequence guard** — deterministic, §3.4) → `If` (guard passed?)

- **Fail** → `Postgres` (log blocked attempt) → `Telegram` (manager: "12B — Deep Clean reported complete but Repairs is still open. Advance anyway?" with Override/Keep-Blocked buttons) → `Telegram` (vendor: neutral ack only, never "you did that wrong")
- **Pass** → `If` (photo attached?) → `Telegram` (get file) → write to `/data/photos` → `Postgres` (UPDATE stage complete, timestamp, photo path) → `Code` (compute next stage + elapsed + $ burned) → `If` (next stage has assigned vendor?) → `HTTP Request` → OpenAI Responses API using `OPENAI_MODEL_DRAFT` (draft message in client voice) → `Postgres` (INSERT outbound_queue, status=awaiting_approval) → `Telegram` (manager: summary + draft + inline keyboard Send/Edit/Hold)

**WF-3 · Manager Router** *(sole Telegram Trigger on the MANAGER bot)*
`Telegram Trigger` (updates: message, callback_query) → `Switch` on callback action:

- `SEND:<queue_id>` → `Postgres` (fetch draft + vendor) → `Telegram` (send to vendor chat_id) → `Postgres` (mark sent, activate next stage, stamp activated_at) → `Telegram` (edit manager's message to "Sent to Maria's Cleaning ✓")
- `HOLD:<queue_id>` → `Postgres` (mark held) → `Telegram` (edit to "Held. Nothing sent.")
- `OVERRIDE:<stage_id>` → `Postgres` (force complete, log actor=manager, reason=override) → resume
- `SKIP:<stage_id>` → `Postgres` (mark skipped, counts as satisfied for successors)
- `SNOOZE:<stage_id>` → `Postgres` (push stall deadline)
- free text → forward to a manual-note handler

**WF-4 · Stall Watchdog**
`Schedule Trigger` (every 15 min demo / hourly production) → `Postgres` (SELECT active stages) → `Code` (age vs per-stage SLA, business-hours aware, respects snooze and per-turn alert dedupe) → `If` (breached and not already alerted?) → `Postgres` (stamp alerted_at) → `Telegram` (manager alert with $ burned + Snooze/Chase buttons)

Alerts go to the **manager, never the vendor.** The system is a coordination layer, not a debt collector. This is the rule from the source document and it's correct.

**WF-5 · Daily Digest**
`Schedule Trigger` (07:00 client TZ) → `Postgres` (board query) → `Code` (format, worst-first) → `Telegram` (manager)

**WF-6 · Board API**
`Webhook` (GET `/board`, header auth) → `Postgres` (board query) → `Postgres` (metrics query, §3.7) → `Merge` → `Code` (shape + compute live ages and $ figures at request time) → `Respond to Webhook` (JSON, `Access-Control-Allow-Origin` set to the board's own origin)

Ages and dollar figures are computed **at request time**, never stored. Two consequences: the board is always truthful about "right now," and pre-seeded demo data with backdated timestamps produces genuine ages rather than hardcoded ones.

**WF-7 · Manual Stage Advance** *(manager-only — this is what makes §0.4 true)*
`Telegram Trigger` callback `DONE:<stage_id>` (handled inside WF-3) **or** `Webhook` (POST `/stage/complete` from the board, header auth) → `Code` (**same sequence guard as WF-2d**, §3.4) → `If` (guard passed?)

- **Fail** → `Postgres` (log blocked attempt) → return the same block message a vendor completion would trigger, with the same Override button
- **Pass** → `Postgres` (UPDATE stage complete, `completed_via='manual'`, actor recorded) → `Code` (compute next stage) → `If` (next stage has an assigned vendor?) → draft + `outbound_queue` + approval card, by calling WF-2d

Two rules, both non-negotiable:

1. **A manual advance goes through the guard.** A manager marking Deep Clean done while Repairs is open gets blocked and offered an override, the same as a vendor would. The guard exists to prevent rework, and rework is caused by managers sending cleaners in early at least as often as by vendors reporting out of order. A guard you can bypass by using a different button is not a guard.
2. **It is recorded as manual.** `completed_via` is what separates "the vendor told us" from "we found out ourselves," and that distinction is the entire basis of §3.7. Without it you cannot compute the one number this automation lives on.

Entry points: a `Mark done` button on every daily-digest line and every stall alert, and a per-card control on the board. Both hit the same logic.

### 3.3 Human-in-the-loop gates — the complete list

There are exactly four, and you should be able to recite them:

| # | Gate | What is blocked | Who releases |
|---|---|---|---|
| 1 | **Outbound vendor message** | Every single message to any vendor. No exceptions, no auto-send timer, no "approved category" | Manager, per message |
| 2 | **Sequence violation** | Any stage advance that breaks the ordering rules | Manager, explicit override, logged |
| 3 | **Unrecognised input** | Any vendor message the classifier isn't confident about, and any message from an unknown sender | Manager reads verbatim and decides |
| 4 | **Stage skip / cancel** | Skipping a stage, cancelling a turn | Manager only. Vendors cannot skip stages |

Everything the system does autonomously is **read-only or manager-facing**: updating its own board, computing ages, alerting the manager. It never takes an action in the outside world without a human press. That sentence is worth memorising for the call.

### 3.4 What is deterministic, and why that's the pitch

The LLM is used in exactly two places: parsing a vendor's free text into a structured guess, and drafting message wording a human reads before sending. **Both are places where a mistake is cheap and immediately visible.**

Everything that must never be wrong is plain code with no model in the path:

- Sequence ordering rules and the rework guard
- Stage age and SLA breach calculation
- Vacancy-day and dollar arithmetic
- Which vendor gets which message
- Whether a stage may advance

Say this on the call, in these words: **"The part that enforces the order isn't AI. It's arithmetic. It can be wrong about what your painter meant. It cannot be wrong about whether repairs are finished."** For a seller with no track record, a visibly narrow blast radius is worth more than a visibly clever system.

Sequence rules, hard-coded:

| Stage | Requires complete (or explicitly skipped) |
|---|---|
| PAINT | REPAIRS |
| FLOORING | PAINT |
| DEEP_CLEAN | REPAIRS, PAINT, FLOORING |
| QA_PHOTOS | DEEP_CLEAN |
| all of 3–10 | MOVEOUT |

### 3.5 The unit matcher — deterministic, and the thing most likely to embarrass you

Vendors don't write unit numbers cleanly. They write "done with the one on maple," "12b finished," "unit 12 ✅," "all set at the maple st property." Matching is done in code, not by the model, because the model will confidently guess and a wrong-unit advance is the most visible failure mode there is.

Scoring, in order:
1. Exact unit label match (case-insensitive, whitespace/punctuation stripped) → score 100
2. Unit label appearing as a token → 90
3. Street name match against the property address → 70
4. **Vendor has exactly one open stage across all turns** → 60 (this covers the majority of real messages and costs nothing)
5. Otherwise → 0

**Threshold ≥ 70 to act. Below that, do not guess** — route to the manager with the vendor's message verbatim and the candidate units listed as buttons. Ambiguity becomes a one-tap manager decision, not a wrong update.

This is also a demo moment (fixture F02, §7): a genuinely ambiguous message producing "I'm not sure which unit — 12B or 14A?" reads as *careful* rather than *broken*, and it is the single most credible thing the system can do in front of someone who has been burned by software that confidently did the wrong thing.

### 3.6 Why this design over the alternative

**Rejected: PMS integration (Buildium API) as the source of turn state.** Forces a $208/month plan upgrade before the client has paid you a rupee. Non-starter. (§1.1)

**Rejected: email-in from vendors instead of Telegram.** Vendors don't email; IMAP polling adds a delay that destroys the live moment; and it makes the demo depend on deliverability you don't control.

**Rejected: WhatsApp Business API.** Higher real-world vendor adoption than Telegram in some markets, but requires Meta business verification, pre-approved message templates, and per-conversation pricing. Weeks of approval for a demo you want running now.

**Rejected: Google Sheets as the state store.** The source document suggests it for demos. Don't. Concurrent writes during a live demo, API quota exposure, and no transactional guarantee on the sequence guard. Postgres is already in the n8n Docker stack — it costs nothing to use the right tool.

**Rejected: an LLM agent that decides what to do next.** Nondeterministic behaviour on exactly the logic that must never be wrong, more expensive, slower on a live call, and impossible to explain to a sceptical buyer.

**Rejected: EspoCRM as the board.** It's a sales CRM. Bending its Kanban into an age-ranked ops board costs more effort than writing a single demo visualization page, and AGPLv3 adds copyleft to an otherwise clean stack for zero benefit.

---

### 3.7 The two metrics — the feature no competitor will ship

The source document is emphatic that vendor reply rate decides whether this automation works at all: below roughly 30% the board is fiction, above 60% it works. Your pilot offer stakes the engagement on it. §11 promises the prospect you will measure it.

**So measure it.** With `completed_via` in place from WF-7, both numbers are plain SQL:

```sql
-- Vendor reply rate, rolling 30 days
SELECT round(100.0 * count(*) FILTER (WHERE completed_via = 'vendor_reply')
             / nullif(count(*), 0)) AS vendor_reply_rate
FROM turn_stage
WHERE vendor_id IS NOT NULL
  AND status IN ('complete','skipped')
  AND completed_at > now() - interval '30 days';

-- Auto-handled rate: inbound vendor messages resolved with no manager decision
SELECT round(100.0 * count(*) FILTER (WHERE event_type = 'stage_complete')
             / nullif(count(*), 0)) AS auto_handled_rate
FROM event_log
WHERE actor_type = 'vendor'
  AND created_at > now() - interval '30 days';
```

**Vendor reply rate** answers "is this automation working for this client." **Auto-handled rate** answers "is it removing work or creating it" — if most inbound messages end up as a manager decision, you have built a notification flow with extra steps, and you want to know that before the client says it.

Surface both in three places: the board header permanently (§8), the weekly digest with the prior week for trend, and a `/health` command on the manager bot.

**Why this is a competitive feature and not just hygiene.** No incumbent has any incentive to put a number on screen whose purpose is to tell a customer the product isn't working for them. You do, because your only credibility lever is a visible willingness to disqualify yourself (§9). This is the cheapest feature in the build and the hardest for a better-funded competitor to copy, because copying it means displaying their own churn signal to their own customers.

---

## 4. Tech stack

| Component | What it does | Cost | Licence | Why it beat the alternative |
|---|---|---|---|---|
| **n8n** (self-hosted, Docker) | All orchestration | Free | Sustainable Use License | Already your stack. Consulting explicitly permitted; client-hosted production is licence-clean (§1.2) |
| **PostgreSQL 16** (Docker) | All state | Free | PostgreSQL License | Ships with the n8n compose stack. Transactional, which the sequence guard needs. Beat Google Sheets on concurrency and quota risk |
| **Local static server** | Demo board hosting | Free | Yours / local tooling | Enough for local build and screen-share testing. Beat n8n-rendered HTML by dodging the iframe sandbox (§1.6). Caddy moves to production |
| **Telegram Bot API** (2 bots) | Vendor and manager messaging | Free | Free service | Native n8n nodes, no registration delay, real message on the prospect's real phone during the call. Beat SMS on the only axis that matters right now: you can use it today (§1.4) |
| **OpenAI `gpt-5.6-luna`** | Vendor reply classification + short draft rewriting | Low token cost | Commercial ToS | Current OpenAI docs position Luna for cost-sensitive workloads, and live pricing makes it cheaper than the older `gpt-5.4-nano` on output. Use it first for both model steps |
| **Demo visualization board** — one HTML file, vanilla JS | Shows the automation state during the demo | Free | Yours | No build step, no npm, no framework churn, opens in any browser. See §8 |
| **Tunnel** — Cloudflare Tunnel or ngrok | Temporary public HTTPS URL for local Telegram webhook testing | Free or low cost | Provider terms | Required only when testing Telegram triggers locally. The generic webhook and simulator do not need it |
| **Docker + Compose** | Local runtime | Free | Apache 2.0 | Runs n8n and Postgres on this machine and gives a clean later path to production |
| **Caddy 2** | Production TLS, reverse proxy, static board hosting | Free | Apache 2.0 | Production only for now. Automatic Let's Encrypt with a two-line config |
| **Client-owned VPS + domain** | Production deployment | Client-paid | — | Production/pilot only. Required for stable SMS/webhook operations after a client exists |

**Total fixed cost during demo build: $0 beyond OpenAI token usage.** Everything runs locally. VPS/domain/Caddy are production-stage items (§14).

**Explicitly not in the demo automation stack:** EspoCRM (§3.6), Twilio (production only, client's account), any n8n community node, any paid SaaS, or any free-tier service that is critical to the board/manual-control path. The tunnel is a dev/testing convenience for Telegram only.

**§4.9 — On EspoCRM:** it stays in your toolkit for its actual job, which is tracking *your* sales pipeline as you prospect. It has no role inside this automation.

---

## 5. Data model

### 5.1 Schema

```sql
CREATE TABLE vendor (
  id              SERIAL PRIMARY KEY,
  name            TEXT NOT NULL,
  trade           TEXT NOT NULL,          -- paint | clean | flooring | repairs | trashout | inspect
  telegram_chat_id TEXT UNIQUE,           -- demo channel
  phone_e164      TEXT,                   -- production channel, unused in demo
  consent_source  TEXT,                   -- production: how consent was captured
  consent_at      TIMESTAMPTZ,
  opted_out_at    TIMESTAMPTZ,            -- STOP handling; NULL = contactable
  active          BOOLEAN DEFAULT TRUE
);

CREATE TABLE turn (
  id              SERIAL PRIMARY KEY,
  unit_label      TEXT NOT NULL,          -- "12B"
  property_address TEXT NOT NULL,         -- "418 Maple St"
  rent_monthly    NUMERIC(10,2) NOT NULL, -- drives every dollar figure shown
  notice_date     DATE,
  moveout_date    DATE,                   -- vacancy clock starts here
  target_ready_date DATE,
  status          TEXT DEFAULT 'active',  -- active | complete | cancelled
  is_fixture      BOOLEAN DEFAULT TRUE,   -- FALSE = real prospect data, never auto-wiped
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE turn_stage (
  id              SERIAL PRIMARY KEY,
  turn_id         INT REFERENCES turn(id) ON DELETE CASCADE,
  seq             INT NOT NULL,           -- 0..10
  stage_code      TEXT NOT NULL,
  stage_name      TEXT NOT NULL,
  status          TEXT DEFAULT 'pending', -- pending|active|complete|skipped|blocked
  vendor_id       INT REFERENCES vendor(id),
  sla_hours       INT NOT NULL,
  activated_at    TIMESTAMPTZ,            -- age clock starts here
  completed_at    TIMESTAMPTZ,
  completed_via   TEXT,                   -- vendor_reply | manual | override | skip
                                          -- REQUIRED: this is what makes §3.7 computable
  completed_by    TEXT,                   -- vendor chat_id, or manager, or 'system'
  alerted_at      TIMESTAMPTZ,            -- stall dedupe
  snooze_until    TIMESTAMPTZ,
  evidence_photo  TEXT,                   -- path on disk
  UNIQUE (turn_id, seq)
);

CREATE TABLE outbound_queue (
  id              SERIAL PRIMARY KEY,
  turn_id         INT REFERENCES turn(id),
  stage_id        INT REFERENCES turn_stage(id),
  vendor_id       INT REFERENCES vendor(id),
  channel         TEXT DEFAULT 'telegram',
  draft_text      TEXT NOT NULL,
  status          TEXT DEFAULT 'awaiting_approval', -- awaiting_approval|sent|held|rejected
  created_at      TIMESTAMPTZ DEFAULT now(),
  decided_at      TIMESTAMPTZ,
  sent_at         TIMESTAMPTZ
);

CREATE TABLE event_log (
  id              SERIAL PRIMARY KEY,
  turn_id         INT,
  stage_id        INT,
  actor_type      TEXT,                   -- vendor | manager | system
  actor_id        TEXT,
  channel         TEXT,                   -- telegram | generic | board | digest
  event_type      TEXT,                   -- reply_received | stage_complete | guard_blocked |
                                          -- override | msg_drafted | msg_sent | msg_held |
                                          -- stall_alert | unmatched | unknown_sender |
                                          -- manual_advance
  raw_text        TEXT,
  parsed_json     JSONB,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_stage_active ON turn_stage(status, activated_at);
CREATE INDEX idx_vendor_chat  ON vendor(telegram_chat_id);
```

**`event_log` is not optional.** It is what lets you answer "why did it do that?" live on a call, and in production it is the audit trail behind every message sent in the client's name. Write to it on every branch, including the ones that do nothing.

### 5.2 Stage template

| seq | stage_code | stage_name | sla_hours | Notes |
|---|---|---|---|---|
| 0 | NOTICE | Notice received | — | Clock starts, information gathering |
| 1 | PRE_INSPECT | Pre-move-out inspection | 48 | 7–14 days before move-out |
| 2 | MOVEOUT | Move-out / keys returned | — | **Vacancy clock starts** |
| 3 | INSPECT_PUNCH | Inspection + punch list | 24 | Within 24 hours |
| 4 | TRASHOUT | Trash-out | 24 | Most common bottleneck — instrument first |
| 5 | REPAIRS | Repairs / trades | 72 | Must precede paint |
| 6 | PAINT | Paint | 48 | Must precede flooring |
| 7 | FLOORING | Flooring | 48 | |
| 8 | DEEP_CLEAN | Deep clean | 24 | Must be last before QA |
| 9 | QA_PHOTOS | QA walkthrough + photos | 12 | |
| 10 | RELIST | Relist | — | **Notification only, never a listing action** (§1.4) |

Stored as a JSON template so it's configurable per client without a schema change. SLA hours are per-client tunable — say so when a prospect tells you their painter always takes four days.

### 5.3 LLM step 1 — vendor reply classification

**Model:** `gpt-5.6-luna` · **Temperature:** 0 · **Max output tokens:** 150
**Request:** Responses API with `text.format: { type: "json_schema", name: "vendor_reply", schema: {...}, strict: true }`

```json
{
  "name": "vendor_reply",
  "strict": true,
  "schema": {
    "type": "object",
    "additionalProperties": false,
    "required": ["intent", "unit_hint", "stage_hint", "eta_text", "confidence"],
    "properties": {
      "intent": {
        "type": "string",
        "enum": ["stage_complete", "stage_started", "delay_notice",
                 "question", "not_my_unit", "unclear"]
      },
      "unit_hint": {
        "type": ["string", "null"],
        "description": "Unit or address text quoted from the message, verbatim. Null if absent."
      },
      "stage_hint": {
        "type": ["string", "null"],
        "description": "Work type mentioned, verbatim. Null if absent."
      },
      "eta_text": {
        "type": ["string", "null"],
        "description": "Timing the vendor states, verbatim. Null if absent."
      },
      "confidence": {
        "type": "number",
        "description": "0.0-1.0, the model's confidence in the intent field only."
      }
    }
  }
}
```

**System prompt:**

```
You classify short text messages sent by trade contractors to a US property
manager about work on vacant rental units. You do not take actions, make
decisions, or write replies. You only classify.

Rules:
- Return only the JSON object defined by the schema. No prose.
- Copy unit_hint, stage_hint and eta_text VERBATIM from the message.
  Do not normalise, expand, correct spelling, or infer a unit that is
  not written in the message.
- If a unit is not explicitly mentioned, unit_hint MUST be null. Never
  guess from context or from the vendor's history.
- intent definitions:
    stage_complete  - the work is finished
    stage_started   - the work has begun but is not finished
    delay_notice    - the vendor cannot do the work as expected, or is late
    question        - the vendor is asking something
    not_my_unit     - the vendor says this is not their job or wrong unit
    unclear         - anything else, including greetings and ambiguity
- If the message could plausibly be two intents, return "unclear" and set
  confidence below 0.5. Choosing "unclear" is always acceptable and is
  preferred over a confident wrong answer.
- Photos with no text are not your concern; you will not receive them.
- Never assess property damage, tenant responsibility, wear and tear,
  security deposits, or cost. If the message raises any of these, return
  intent "question" and copy nothing further.
```

**Prompt design notes for Claude Code:**
- The user message carries only the vendor's text plus a compact list of that vendor's open stages (`unit_label | stage_name` pairs). Nothing else. Keeps input under ~350 tokens and keeps addresses and tenant data out of the request where possible.
- The "verbatim, never infer" rule is what makes the deterministic matcher in §3.5 the sole authority on which unit is meant. Do not soften it.
- The deposit/damage clause exists because move-out inspection messages routinely mention damage, and a model that helpfully opines on tenant liability creates the exposure described in §1.4.
- `confidence < 0.6` → route to manager, regardless of intent.

### 5.4 LLM step 2 — vendor message drafting

**Model:** `gpt-5.6-luna` first; test `gpt-5.6-terra` or `gpt-5.4-mini` only if draft quality is weak · **Temperature:** 0.3 · **Max output tokens:** 120

**Template-first, model-second.** Build the message deterministically, then pass it to the model for tone only. If the API call fails or returns anything over 320 characters, **send the raw template** — nobody on the call will know the difference, and this is your live-failure insurance (§10).

```
You rewrite one short work-assignment message from a US property management
company to a trade contractor they already work with.

Constraints:
- Under 320 characters. One or two sentences.
- Keep every fact from the input exactly as given: unit, address, work type,
  and the name of the company sending it.
- Plain American English, the way a busy person types. No greetings like
  "I hope this finds you well". No emoji. No exclamation marks.
- Never apologise, never chase, never imply the contractor is late, never
  mention days elapsed, cost, or other vendors.
- Never state a deadline that was not given to you.
- End with the sender's company name.
- Return only the message text.
```

**Input to the model:**
```
Company: {{client_company_name}}
Voice sample from the client: {{tone_sample}}
Draft: {{deterministic_template_output}}
```

`tone_sample` is two or three real messages the client already sends their vendors, captured at onboarding. In the demo it's a plausible sample you wrote. This is what makes the drafted message read as *theirs* rather than as software — and it is a specific, honest thing to point at when a prospect asks what the AI is actually doing.

**Cost per stage transition: roughly $0.0012.** Both calls are short-text. Nothing in this build processes a long document, so there is no caching or local-extraction cost risk to manage.

---

## 6. Build plan — sequenced, action by action

No time estimates anywhere in this section, by instruction. The ordering is a dependency chain, not a schedule. Each step states what "done" means so Claude Code can self-verify before moving on.

Work in the order given. Every step depends on the one before it.

### Phase A — Foundation

**A1. Prepare the local runtime.**
Install or verify Docker Desktop / Docker Engine and the Compose plugin on this machine.
*Done when:* `docker compose version` returns locally.

**A2. Bring up the stack.**
`docker-compose.yml` with two services: `n8n`, `postgres`. Named volumes for `n8n_data`, `pg_data`, `photos`, and a local board directory mounted where the static server can read it. Do not add Caddy for the demo build.
*Done when:* n8n loads at `http://localhost:5678` and Postgres is reachable from n8n.

**A3. Configure n8n environment.**
Set `GENERIC_TIMEZONE` to the demo client's timezone, `N8N_ENCRYPTION_KEY`, and basic auth on the editor. Set `N8N_DEFAULT_BINARY_DATA_MODE=filesystem`. Leave `WEBHOOK_URL` local until Telegram testing.
*Done when:* the editor loads locally and a Webhook node can be called from `localhost`.

**A3b. Configure a tunnel for Telegram testing.**
Use Cloudflare Tunnel, ngrok, or an equivalent temporary HTTPS tunnel forwarding to local n8n. When testing Telegram triggers, set `WEBHOOK_URL` to that tunnel URL and restart n8n before activating the trigger workflows.
*Done when:* a Webhook node's production URL uses the active HTTPS tunnel URL and a test request through the tunnel reaches local n8n. **If it shows localhost, Telegram triggers will silently never fire.**

**A4. Create the database.**
Apply the §5.1 schema to a `make_ready_demo` database. Create a dedicated `make_ready_demo` Postgres role — do not reuse n8n's own database user.
*Done when:* all five tables and both indexes exist, and a Postgres credential in n8n runs `SELECT 1`.

**A5. Create both Telegram bots.**
Via BotFather: `<name>_vendor_bot` and `<name>_manager_bot`. Store both tokens as separate n8n credentials, clearly named.
*Done when:* `getMe` succeeds for both tokens and the two credentials are distinguishable at a glance in the n8n UI.

**A6. Store OpenAI credentials and verify models.**
Create an n8n OpenAI API credential and use it from HTTP Request nodes through predefined credential authentication. Then run the model check in §1.7 and record the resolved IDs.
*Done when:* `GET /v1/models` returns 200 and `gpt-5.6-luna` is confirmed present, or documented fallbacks are recorded.

### Phase B — State and seed

**B1. Write the stage template as JSON** matching §5.2, stored at `/data/config/stage_template.json` and read by WF-1.
*Done when:* a Code node loads it and emits 11 stage rows.

**B2. Write `seed.sql`** creating the fixture world from §7.1: one company, three properties, six vendors, six turns at varied stages and ages. **All timestamps must be computed relative to `now()`**, never hardcoded — `now() - interval '4 days'`, not a date literal.
*Done when:* re-running `seed.sql` a week later still produces a four-day-old stall.

**B3. Write two scripts, not one.**

- `reset_demo.sh` — deletes fixture data only (`WHERE is_fixture = true`), re-runs `seed.sql`, clears `/data/photos`. **It must abort with a loud error if any row has `is_fixture = false`.**
- `load_prospect.sh <csv>` — loads a prospect's real turns with `is_fixture = false`, alongside the fixtures or on a clean board.

*Done when:* `reset_demo.sh` restores the opening state in under five seconds, and refuses to run once prospect data is loaded.

**Why two scripts.** The closing ask in §9 gets you a prospect's last three turns, which you load onto a live board they can look at. A single truncate-everything reset would wipe exactly that data on the morning of your next demo. You would then be explaining to a warm prospect that you deleted the numbers they sent you. Build the guard now — you will run `reset_demo.sh` reflexively before every call, which is precisely when the accident happens.

### Phase C — Read path (the part that sells)

**C1. Build the sequence guard as a standalone Code node** encoding the §3.4 table. Pure function: `(requestedStageCode, allStagesForTurn) -> { allowed: bool, blockedBy: [stageName], reason: string }`. Skipped counts as satisfied.
*Done when:* unit-tested against fixtures F05 (block), F12 (skip then allow), and a normal advance (allow).

**Moved forward deliberately.** In the original ordering this sat in the vendor phase, which implied the guard is part of the automation. It isn't — it protects manual advances too, and WF-7 depends on it. Build it first and both paths call the same function.

**C2. Build WF-6, Board API.** Webhook GET `/board` with header auth → Postgres board query → Postgres metrics query (§3.7) → Merge → Code (compute `hours_at_stage`, `days_vacant`, `dollars_burned = round(rent_monthly/30 * days_vacant)`, `health` in {green, amber, red}) → Respond to Webhook JSON with CORS for the board origin.
*Done when:* `curl` returns all six seeded turns worst-first with ages that increase if you wait and re-run, **and** a `metrics` object carrying `vendor_reply_rate` and `auto_handled_rate`.

**C3. Build WF-7, Manual Stage Advance.** Webhook POST `/stage/complete` → sequence guard (C1) → on pass, mark complete with `completed_via='manual'`; on fail, return the block payload with an override token.
*Done when:* marking Paint done on 12B from `curl` advances the board, and marking Deep Clean done on 14A is refused with "Repairs still open" — **with no vendor and no Telegram involved anywhere in the flow.**

**This step is the hedge.** Until C3 exists, the claim in §0.3 and §11 that the board works at a 0% vendor reply rate is false, and a prospect who pilots it will find that out before you do.

**C4. Build the board page** per §8. Single `index.html` in the local board directory, vanilla JS, polls `/board` every 10s. Includes the `DEMO DATA` badge, the reply-rate header, the per-card `Mark done` control wired to C3, and the empty turn-history panel.
*Done when:* it renders on a laptop and a phone, the red card is unmistakable from across a room, `Mark done` advances a stage and gets refused correctly on 14A, and stopping n8n makes the page show "reconnecting" rather than a blank screen or a stack trace.

**C5. Build WF-5, Daily Digest.** Reuse C2's query and Code node. Every line carries a `Mark done` button hitting C3.
*Done when:* manually triggering it puts a correctly-ordered summary in the manager Telegram chat, and pressing `Mark done` on a line advances that stage.

**Checkpoint — and it is a bigger one than it looks.** At this point you have a complete, honest, demoable automation with no vendor automation at all: a live turn board, a rework guard that works on manual entry, a stall detector, a daily digest, and a metric that reports how much of it is running itself. You can demo this, pilot this, and charge for this workflow at a 0% vendor reply rate. Everything in Phase D is an accelerator bolted onto an automation that already stands up. Do not start Phase D until this checkpoint is genuinely true.

### Phase D — Write path

**D1. Build WF-1, Turn Intake.** Form Trigger with fields: unit label, property address, monthly rent, notice date, expected move-out date, and a vendor assignment per stage. Code node computes target ready date, inserts the turn, expands the stage template.
*Done when:* submitting the form makes a new card appear on the board within one poll cycle, with all eleven stages pending.

**D2. Build the unit matcher as a standalone Code node** implementing §3.5 scoring, returning `{ turnId, stageId, score, candidates[] }`.
*Done when:* F01 scores 100, F02 scores below threshold and returns two candidates, F03 resolves to the correct other unit, F04 hits the single-open-stage rule at 60 and correctly falls below threshold.

*(The sequence guard was built in C1 — both the manual and vendor paths call that same node. Do not write a second copy.)*

**D3. Build WF-2c, Vendor Router**, through classification only — envelope in → vendor lookup → payload assembly → OpenAI call → matcher → parsed output written to `event_log`. No actions yet. **Build it as a sub-workflow from the start**, taking the §3.2 envelope as input; do not build it inside a Telegram trigger and refactor later.
*Done when:* a hand-crafted envelope passed via Execute Sub-workflow produces a correctly-shaped `event_log` row, with no Telegram node involved.

**D4. Build the two ingests.** WF-2 (Telegram Trigger → normalise → WF-2c) and WF-2b (Webhook POST `/vendor-in` → normalise → WF-2c → Respond).
*Done when:* the same text sent via Telegram and via `curl` to `/vendor-in` produces two `event_log` rows that are identical except for `channel` and `sender_ref`. **This equivalence is the demo beat in §9 — verify it explicitly rather than assuming it.**

**D5. Build the SMS simulator page.** One static HTML file beside the board at `sim.html`: a sender dropdown (the three demo vendors), a text box, a Send button posting to `/vendor-in`, and a panel showing replies. Style it to look like a plain phone messaging thread, not like a developer tool.
*Done when:* you can drive a complete stage advance from the simulator with Telegram closed.

**D6. Run the classification fixture set.** Send each of F01–F18 and check the parsed output.
*Done when:* all produce correctly-shaped rows and the whole set costs under $0.05.

**D7. Build WF-2d, Completion Handler**, wiring the C1 guard and D2 matcher in. WF-7 already calls this workflow, so build it as a sub-workflow taking `{stage_id, completed_via, completed_by}`. Guard fail → manager prompt with Override button. Guard pass → stage complete with `completed_via='vendor_reply'` → next stage computed → draft generated → `outbound_queue` row → manager Telegram message with Send/Hold inline keyboard.
*Done when:* F01 end-to-end puts an approval card on the manager phone with a readable draft, **nothing has been sent to any vendor**, and the board's reply-rate metric moves.

**D8. Build WF-3, Manager Router.** Callback handling for SEND, HOLD, OVERRIDE, SKIP, SNOOZE, DONE. Each edits the original Telegram message to show the outcome rather than posting a new one.
*Done when:* pressing Send delivers the message to the vendor bot chat, activates the next stage, updates the board, and changes the manager's card to "Sent ✓" — all within about three seconds.

**D9. Add photo handling.** On `stage_complete` with a photo: Telegram getFile → download → `/data/photos/<turn>/<stage>.jpg` → path stored → board shows a thumbnail.
*Done when:* F07 (photo, no text) stores the image and asks the manager which unit it belongs to instead of guessing.

### Phase E — The absence detector

**E1. Build WF-4, Stall Watchdog.** Schedule every 15 minutes in demo mode. Age computed from `activated_at` against `sla_hours`, respecting `snooze_until` and `alerted_at` dedupe.
*Done when:* it fires exactly once for the seeded stalled unit, includes the dollar figure, and does not re-fire on the next run.

**E2. Add business-hours suppression.** No alerts outside 08:00–19:00 client time; queue and release at the next window.
*Done when:* an alert generated at 02:00 client time is delivered at 08:00.

**E3. Add the Chase button** to stall alerts — drafts a follow-up to the silent vendor and puts it in `outbound_queue` awaiting approval. **It does not send.** Same gate as everything else.
*Done when:* pressing Chase produces an approval card, not a sent message.

### Phase F — Demo hardening

**F1. Add a global failure catch.** Configure an Error Workflow on every workflow that writes to `event_log` and sends a single quiet Telegram message to *you*, not the manager. During a demo, you need to know something broke before the prospect notices.
*Done when:* deliberately breaking the OpenAI credential produces exactly one alert to you and no visible change on the board.

**F2. Add the LLM fallback path.** If the drafting call fails or returns over 320 characters, use the deterministic template and log the fallback. If the classification call fails, route the raw message to the manager as `unclear`.
*Done when:* with the OpenAI key deliberately invalid, the full F01 path still completes and still puts an approval card on the phone. **This is the single most important robustness item in the build** — it means an OpenAI outage costs you tone quality, not the demo.

**F3. Run the full fixture set F01–F20 in one session** against a freshly reset database. Record the outcome of each.
*Done when:* every fixture behaves as §7 specifies and total OpenAI spend for the run is under $0.05. F19 and F20 involve no model call at all — if they do, the manual path is wired wrong.

**F4. Rehearse the §9 script end to end, timed, three times.** Reset between each.
*Done when:* you land under five minutes without hurrying, and you have said the §11 limitations out loud at least twice so they come out naturally rather than defensively.

**F5. Record a screen capture of a successful run.** Roughly 90 seconds, no narration.
*Done when:* the file is on your laptop, playable offline. This is your last-resort fallback (§10).

**F6. Export the local demo.** Export all workflows plus `docker-compose.yml`, `seed.sql`, `reset_demo.sh`, the board files, and tunnel setup notes to a private repo.
*Done when:* you could rebuild the entire local demo on a fresh machine using only the repo and credentials.

---

## 7. Test fixtures

You have no client data, so the fixture world *is* your credibility. Build all of it. The messy cases matter more than the clean ones — a demo where everything works perfectly reads as staged, and a prospect who has bought software before knows it.

### 7.1 Seed world

**One company:** Cedar Ridge Property Management (fictional — never use a real company name).

**Three properties:** 418 Maple St (units 12A, 12B, 14A), 2201 Oak Ave (units 3, 7), 55 Birch Ct (single-family).

**Six vendors** — plausible small-operator names and trades: Rivera Painting (paint), Maria's Cleaning Co (clean), Dale Hutchins (repairs), QuickHaul Junk Removal (trashout), Statewide Flooring (flooring), Cedar Ridge in-house (inspect). Give three of them Telegram chat IDs you control from separate accounts so you can play them live.

**Six turns**, all timestamps relative to `now()`:

| Unit | Rent | State at demo open | Purpose |
|---|---|---|---|
| 12B Maple | $1,450 | **Paint, active 4 days** (SLA 48h) | The red card. Your opening shot |
| 14A Maple | $1,600 | Deep Clean pending, **Repairs still open** | The guard-rail demo |
| 3 Oak | $1,200 | **Trash-out, active 30 hours** | Fires the live stall alert during the call |
| 7 Oak | $1,325 | Flooring, active 6 hours, healthy | Proves green exists and the board isn't rigged |
| 12A Maple | $1,450 | QA + photos, nearly done | Shows the end state and a completion photo |
| 55 Birch | $2,100 | Notice received, move-out in 6 days | Shows the pipeline before the vacancy clock starts |

Combined, the board shows **$1,847 of rent currently burning** across six units. Have that number ready; it's the one the prospect will stare at.

### 7.2 Message fixtures

| ID | Message sent | What it tests | Expected behaviour |
|---|---|---|---|
| F01 | `done with 12b` | Happy path | Score 100 → guard passes → stage complete → draft to cleaner → approval card |
| F02 | `finished the one on maple` | **Ambiguity** (three Maple units) | Street match 70 but multiple candidates → below threshold → manager asked "12A, 12B or 14A?" with buttons |
| F03 | `all set at oak, unit 7` | Address + unit together | Resolves to 7 Oak, not 3 Oak |
| F04 | `done` (bare, from a vendor with two open stages) | Single-open-stage rule failing correctly | Score 0 → manager asked which unit |
| F05 | Cleaner sends `12b cleaned` **before repairs closed on 14A**, then `14a cleaned` | **The rework guard** | 12B allowed; 14A blocked with "Repairs still open" + Override button. Vendor gets a neutral ack, never a scolding |
| F06 | `cant get there till thursday, sorry` | Delay notice | intent=delay_notice → manager notified with the vendor's exact words → no stage change |
| F07 | Photo, no caption | Photo-only completion | Image stored, manager asked which unit and stage. **No guessing** |
| F08 | `is the water back on at 12b?` | Question, not status | Forwarded verbatim to manager. No stage change, no auto-reply beyond an ack |
| F09 | `finshed unit 12b ✅` | Typo + emoji | Still matches. Proves it survives how people actually type |
| F10 | `done with 12b` sent twice, 30 seconds apart | **Duplicate** | Second reply gets a friendly ack, no second stage advance, no second draft, no second approval card |
| F11 | Message from an unknown chat ID | Unknown sender | Logged, manager notified. **No reply to the sender.** No data disclosed |
| F12 | Manager presses Skip on Flooring for 12B, then cleaner reports done | Legitimate skip | Skipped counts as satisfied → Deep Clean allowed |
| F13 | Manager cancels 55 Birch (tenant renewed) | Turn cancellation mid-sequence | Turn drops off the board, pending stages closed, no orphan alerts later |
| F14 | Painter reports done on 12B and 12A within a minute | Same vendor, two units | Two separate stage advances, two separate approval cards, correct vendors on each |
| F15 | Vendor sends a voice note | Unsupported media | Graceful: manager told "voice message from Rivera Painting, listen in Telegram." **Not silence, not a crash** |
| F16 | Message at 02:00 client time | Quiet hours | Stage updates immediately; manager alert held until 08:00 |
| F17 | `the tenant trashed this place, that carpet is coming out of their deposit` | **The dangerous one** | intent=question → forwarded verbatim → **no damage assessment, no deposit language generated, no classification of tenant liability** (§1.4) |
| F18 | `done with 12b` sent via the generic webhook instead of Telegram | **Channel independence** | Identical `event_log` row and identical board result, differing only in `channel` and `sender_ref`. This is the §9 demo beat — verify it, don't assume it |
| F19 | Manager marks Paint done on 12B from the board, no vendor message at all | **The 0% reply-rate path** | Stage completes with `completed_via='manual'`, board advances, reply-rate metric drops accordingly |
| F20 | Manager marks Deep Clean done on 14A from the digest while Repairs is open | **Guard applies to managers too** | Blocked with the same message and the same Override button a vendor would get |

**F17 is not optional and it is not paranoia.** Move-out messages mention damage constantly. Run it in front of a prospect if the moment allows — a system that visibly refuses to opine on a deposit deduction is a system that looks like it was built by someone who knows what they're doing.

**F02, F05, F07 and F10 are the four that make it feel real.** A demo without them is a demo of a script.

**F19 and F20 are the two that prove the automation stands up without vendors.** If either fails, the claim in §0.3 and §11 that the board works at a 0% reply rate is not true yet, and you should not make it on a call.

---

## 8. Demo Visualization UI

**Yes, build it.** The board is demo visualization, not a software product surface. It is the thing that makes the automation visible at a 0% vendor reply rate, and it is your opening shot. A Telegram-only demo would be a demo of plumbing.

**One screen. One HTML file. No framework, no build step, no npm.**

**What it shows:**
- **A `DEMO DATA — Cedar Ridge is fictional` badge**, top right, permanently. It corroborates the disclosure you make in the first fifteen seconds (§9) and stops the board quietly implying a client you don't have
- Header: `6 units in turn · $1,847/mo burning right now` — computed live, never hardcoded
- **Second header line: `Vendor reply rate 64% · Auto-handled 71% (30 days)`** from §3.7. Permanent, not tucked in a settings page. This is the number you point at in §9 and the one no competitor will display
- **A `Mark done` control on every card**, hitting WF-7. It's how the board works at a 0% reply rate, and on a demo call it's how you advance a unit without waiting for a vendor
- **An empty panel: `Turn history — collecting from day one. First report at 30 days.`** You have no history and §13 defers reporting, but an unexplained absence reads as a missing feature. Naming it on screen turns "it can't do that" into "that comes later" and sets up the renewal conversation from the first demo
- One card per turn, **sorted by health then by hours at stage, worst first**
- Each card: unit label, address, current stage, **hours or days at that stage as the largest element on the card**, days vacant, dollars burned, assigned vendor, completion-photo thumbnail if present
- Colour: green under 50% of SLA, amber 50–100%, **red over SLA**
- Below each card, a one-line stage strip: `✓ ✓ ✓ ✓ ● ○ ○ ○` — done, current, pending. A prospect reads it instantly without explanation
- A footer line showing the most recent event from `event_log`, which quietly proves the thing is live

**How it's built:** `index.html` with inline CSS and a `fetch()` on a 10-second timer against WF-6. Served locally during the demo build. In production, Caddy serves the same static file at `board.<domain>`. Auth by a token in the query string for the demo; §14 replaces it.

**Design constraints that actually matter for a screen-share:**
- The age number is the biggest text on the card. Not the unit, not the stage. The number is what the automation is exposing
- Red must be obvious on a compressed video call at low bandwidth. Test it over an actual Zoom/Meet screen-share before you rely on it
- Dark background. It photographs and compresses better and looks less like a spreadsheet
- **No animation on refresh.** When a card changes state during the demo it should be noticed because it changed, not because it moved
- Must survive the API being down: show the last-known board with a "reconnecting" strip, never a blank page or an error object

**One companion page: `sim.html`.** A sender dropdown, a text box, a Send button posting to `/vendor-in`, and a panel showing replies. Styled like a plain phone messaging thread, not a developer tool. Its entire purpose is the fifteen-second beat in §9 where the same message arrives down a different pipe and the board reacts identically — which is how you defend the "vendors install nothing" claim while demoing on Telegram (§1.8, §11).

**Explicitly not building:** login, user management, turn editing in the browser, charts, reporting views, mobile-responsive layouts beyond "readable on a phone." All of it is §13.

---

## 9. The demo script

**Total runtime: 4:55.** The prospect touches the system at 1:40. Everything before that earns the right to hand them the phone; everything after is them convincing themselves.

**Before the call:** run `reset_demo.sh`. Open the board. Open Telegram on your phone in the Rivera Painting chat. Have the prospect's monthly rent number from discovery — if you don't have it, get it in the first minute.

---

**0:00–0:40 · The board, in silence first**

Share the screen. Say nothing for three seconds. Then:

> "This is every unit Cedar Ridge has in turn right now. Six units. Fourteen hundred and eighty dollars of rent burning this month while nothing happens. Sorted worst first."

Don't explain the interface. It doesn't need explaining, and that's the point.

**0:40–1:10 · The red card**

> "12B has been sitting at paint for four days. The SLA is two. Nobody at Cedar Ridge knows that right now — it looks exactly like the other five in an inbox. Two hundred and twelve dollars, on one unit, because nobody found out the painter finished."

Pause. Let them look at it.

> "That's the whole problem. The work isn't slow. The gaps are."

**1:10–2:05 · They play the painter** ← *hand over here*

> "Type this on my phone. You're my painter."

Hand them the phone, already in the Rivera Painting chat. They type `done with 12b`.

Board updates within a couple of seconds. Card flips red to green.

**2:05–2:50 · THE MOMENT — their phone buzzes** ← *strongest moment, deliberately not at the end*

Their own phone (you added them as the manager during discovery, or you're sending to a second phone in view) shows:

```
12B Maple — Paint complete (Rivera Painting)
4d 2h at this stage · $212 vacancy cost

Next: Flooring — Statewide Flooring

Draft:
"Statewide - 12B at 418 Maple is ready for
flooring. Painting's done. - Cedar Ridge"

[ Send ]  [ Edit ]  [ Hold ]
```

> "Nothing has gone out yet. It never does. It writes the message in your voice and waits for you. Press Send."

They press it. The flooring handoff lands on the board. If you skip Flooring for this rehearsal, the next handoff is Deep Clean instead.

> "That's the handoff that normally takes two days."

**Why this is placed at 2:05 and not at the close:** they need the remaining two minutes to poke at it, and a demo that peaks in the last ten seconds gives them nowhere to put their scepticism except into the pause after you stop talking.

**2:50–3:35 · Break it on purpose**

> "Now let me show you the thing that costs more than the waiting."

Send `14a cleaned` from the cleaner's account. It refuses:

```
Blocked — 14A Maple
Deep Clean reported complete, but Repairs
is still open.
Cleaning before drywall repair means
cleaning twice.
[ Override anyway ]  [ Keep blocked ]
```

> "Second clean, one-eighty, plus two days. Nobody logs that as a failure — it goes in the file as 'turnover took eleven days.' That's the arithmetic I mentioned at the start. It doesn't have an opinion."

**3:35–4:00 · The alert fires by itself**

Unit 3 Oak crosses its trash-out SLA. It arrives on their phone unprompted, while you're mid-sentence. Don't trigger it — let it land.

> "I didn't do that. Trash-out on 3 Oak crossed thirty hours. That one's the point — the system doesn't need your vendors to be reliable. It needs to notice when they aren't, which is the thing you currently can't do."

**4:00–4:30 · Their arithmetic, then the ask**

Point at the reply-rate figure in the board header first:

> "Sixty-four percent. That's how often vendors actually replied, instead of someone marking it by hand. It sits on that screen permanently, and it's the number that decides whether you keep paying me. If it comes in under thirty, I'll tell you this isn't working for you and we'll stop. Nobody else you're evaluating will put that number in front of you, because it's the number that gets them fired."

Then do the maths out loud with **their** numbers, not Cedar Ridge's:

> "You said your average turn is eleven days and a typical unit rents for sixteen hundred. That's fifty-three a day. If this takes three days off a turn and you do ninety turns a year, that's fourteen thousand dollars. I'm going to charge you five hundred a month."

Then stop talking.

### The closing ask

**Ask for this — the smallest commitment that exists:**

> "Here's what I want, and it's less than you're expecting. Don't give me access to anything. Don't tell your vendors. Send me your last three turns on paper — unit, rent, the dates each stage started and finished, as best you remember. I'll put your board up with your numbers on it, and you look at it before we speak again. If seeing your own turns on that screen doesn't change anything for you, we stop and I won't chase you."

Why this and not the two-week vendor pilot: the pilot requires them to expose vendor relationships to a stranger from another country with no track record. That's a large commitment dressed up as a small one. Three turns on paper costs them ten minutes, risks nothing, requires no software access, no PMS integration, no vendor contact, no payment — and it lands you their real rent numbers, their real stage lag, and their attention on a board with their own units on it.

**If they say yes immediately, escalate to the qualifying gate — it doubles as the second ask:**

> "One more thing, and it's the question that decides whether any of this is worth building for you. Next time you send your painter to a unit, ask him to text you 'done' when he finishes. Just once. Tell me in a week whether he did. If he didn't, I'll tell you this automation isn't for you and we'll stop — the board still works, but the vendor loop won't."

Offering to disqualify yourself is the strongest move available to someone with no case studies, and unlike a testimonial, it costs nothing and can't be faked.

**What to hand over:** the phone, at 1:40, for the vendor message. After the call, if they send three turns, load them into the local board and either walk them through it on the next screen-share or expose a temporary read-only tunnel link for that review window. A stable board URL waits until production/pilot deployment.

---

## 10. Failure recovery

Rehearse the recovery lines out loud. Fumbling a failure costs more than the failure.

| What breaks | What the prospect sees | What you do | What you say |
|---|---|---|---|
| **OpenAI API down or slow** | Slight delay, then a plainer draft message | Nothing — F2 fallback fires automatically | *"That draft came from the template rather than the model — the model's having a moment. Notice the workflow didn't stop."* This is a **win**: unplanned proof of graceful degradation |
| **Telegram delayed** (occasional 5–20s) | Board updates, phone lags | Keep talking about the board | *"Telegram's queuing — it'll land."* Never refresh repeatedly in front of them; it reads as panic |
| **Your internet drops** | Screen-share dies, Telegram tunnel may stop | Reconnect on your phone hotspot. The local board still exists; Telegram may need the tunnel restarted | *"My connection dropped. The board is local, so I'll bring the screen back first and keep going from the manager controls."* Have the hotspot **already paired before the call** |
| **Local Docker/n8n stops** | Board actions or webhooks fail | Play the F5 recording | *"Rather than debug my local machine while you watch, here's a recording of the same run, and I'll send you a working review link or screen-share it this afternoon."* Then actually do it |
| **Tunnel or Telegram trigger silently not firing** | Nothing happens after they type | Do not debug live. Move to the guard-rail demo, which runs off board/manager-side controls | *"That channel isn't coming through — let me show you the piece that matters more anyway."* |
| **Wrong unit matched live** | Visible mistake | **Do not apologise, do not minimise** | *"That's exactly what I'd want you to see. It scored below the threshold and asked instead of guessing — the alternative is software that confidently updates the wrong unit, which is worse."* If it actually guessed wrong, own it: *"That's a bug, I'll fix it and send you the log."* You'll be believed |
| **They type something you didn't anticipate** | Manager gets an "unclear" forward | Let it happen | *"It didn't understand and it didn't pretend to. That's the design — when it's unsure, you decide."* |
| **Prospect asks a question you can't answer** | — | — | *"I don't know. I'll find out and tell you today."* With no track record, this is worth more than a confident wrong answer, and you will be tested on it |

**The one thing you must have physically ready:** the F5 recording, downloaded locally, playable with no internet. Not on a cloud drive. On the laptop.

**Kill switch:** if two things break in the same call, stop demoing. *"I'm going to stop here rather than keep poking at it. Let me send you a working link this afternoon and we'll talk Thursday."* A short call you ended deliberately beats a long one that unravelled.

---

## 11. What I must not claim

Say these before the prospect finds them. With no track record, naming your own limitations is the only credibility lever you actually own — and every one of these gets discovered in week one of a paid engagement anyway.

| A prospect will assume | The truth | Say this |
|---|---|---|
| "It talks to Buildium" | It has **no** connection to any PMS. Zero read, zero write | *"It doesn't touch Buildium at all — that's deliberate. Their API needs the Premium plan at four hundred a month, and I'm not making you upgrade your software to try my thing. This runs beside it."* |
| "It knows the unit is done" | It knows a **vendor said** it's done | *"It knows what your painter told you, faster than you'd have found out. It doesn't know the work is actually finished — you still QA the unit."* |
| "It checks the photos" | Photos are stored and displayed. **Nothing looks at them** | *"The photo is proof for you, not for the system. It doesn't inspect the work. I wouldn't trust a model to tell you a wall is properly painted, and neither should you."* |
| "It schedules and books vendors" | It drafts a message and waits for you | *"It never books anyone. It writes the message and waits for your thumb. Every single outbound, every time."* |
| "It'll chase my vendors" | It escalates to **you**, never nags the vendor | *"It never chases anyone in your name without you pressing send. If a vendor goes quiet it tells you, not them. I'm not putting your relationship with a painter you've used for nine years in the hands of my software."* |
| "It handles maintenance tickets" | Vacant-unit turnover only | *"Different product. This runs on empty units between tenants. Occupied-unit maintenance has habitability deadlines and I'm not touching those."* |
| "It sorts out the deposit" | **Hard exclusion.** It never assesses damage, wear and tear, tenant liability, or deductions | *"It will never say a word about a deposit. Your state has a deadline and an itemisation standard on that, and the penalty for getting it wrong lands on you. Punch list items go to vendors as work. Nothing else."* |
| "It texts my vendors" | **Not yet.** The demo is Telegram. SMS needs 10DLC registration under **their** EIN | *"Telegram's a stand-in and I'd rather say so than let you find out. In production your painter texts the same number he texts you on now — nothing to install, no account, no app. I'm on Telegram today because real SMS needs carrier registration under your business name, which I can't start until you're a client. The part that reads 'done with 12b' and works out which unit that is doesn't care what pipe it came down — I'll show you the same message arriving two different ways."* |
| "It's the system of record" | It's a coordination layer. Their PMS stays the record | *"Buildium stays your system of record. This is the layer that tells you which unit is stuck. If you turned it off tomorrow you'd lose visibility, not data."* |
| "It works if vendors ignore it" | The **board** does. The **automation** doesn't | *"Straight answer: if your vendors don't reply, the automation is worth nothing and the board is still worth something. That's why I want you to test one text with your painter before you pay me anything."* |
| "It predicts how long a turn will take" | It reports elapsed time. No forecasting | *"It tells you what's happened, not what will. Forecasting off your own history is a real thing to build later, once there's history to build it from."* |
| "You've done this before" | You haven't | *"You'd be my first client in property management. That's why the pilot is structured so you can walk at any point and why I'm telling you what it can't do before you ask."* |

### 11b. The four competitive questions

These aren't limitations, they're comparisons — and you will be asked all four. Each answer concedes ground on purpose. With no track record, a concession you volunteer is worth more than a claim you defend.

**"We're already looking at Property Meld. Why you?"**

> *"Property Meld's a good product and if you're already on it you should probably stay. Two differences. Their vendors have to accept an email invite and set up an account before they're in the system — mine text a number the way they text you now, nothing to install. And theirs will let you mark cleaning done while repairs are still open; mine won't, which is the rework thing I just showed you. If neither of those matters to you, buy theirs. They've got a support team and I'm one person."*

**"Why not just hire a VA for twelve hundred a month?"**

> *"Hire the VA — I'm serious. A VA is better than me at ninety percent of what you need. But at six in the evening your VA has gone home and you still can't tell me which of your fourteen units is stuck and for how long. I'm four hundred a month sitting underneath the VA, not instead of them. If you're choosing one, choose the VA."*

**"What happens if you disappear?"** — *volunteer this, don't wait to be asked.*

> *"Everything runs on a server in your name, on your card. I'll put the whole thing in a repo you own with a page of notes on how to run it. If I vanish tomorrow you keep the system, and any n8n developer can pick it up — it's a standard open-source tool, not my private invention. That's not generosity, it's me removing the main reason not to try this."*

The client-owned instance is already required by n8n's licensing (§1.2), so this costs you nothing and converts your biggest structural weakness into a design choice.

**"You're in India. What about when something breaks at nine in the morning my time?"**

> *"My evening is your morning, so let me be exact about what I'll commit to. Anything broken gets a reply from me by the start of your next business day. And the system doesn't need me to be awake — if it stops, it stops quietly and nothing wrong goes out to your vendors, because no message reaches a vendor without your thumb. What I won't pretend is that I'm on call at nine your time. If you need that, you need a US vendor."*

The fail-safe argument is your strongest structural answer here. Every outbound action is human-gated (§3.3), so an outage costs visibility for a few hours, never a wrong message to a contractor. Say it.

**Never claim:** a percentage improvement in turn times, a reply rate, a payback period, or that anyone else is using this. You have no data. The Phoenix 14-days-to-5-days figure and the NAA benchmarks are **someone else's numbers about the industry** — attribute them as such, every time. *"There's an operator in Phoenix who got turns from fourteen days to five by fixing sequencing. That's their number, not mine — I'm showing you the mechanism, not promising the result."*

---

## 12. Cost breakdown

### Build

| Item | Cost |
|---|---|
| Local Docker runtime | $0 |
| Temporary tunnel for Telegram testing | $0 if using a free tunnel; otherwise provider-dependent |
| OpenAI — development iteration (~200 short Luna calls) | ~$0.05 |
| OpenAI — full fixture run F01–F20, run five times | ~$0.15 |
| Telegram | $0 |
| Tool licences | $0 |
| **Runtime API spend to build and test** | **under $0.25** |

Your $10 budget is not at risk from the product's own API calls — they round to nothing. **The real spend is Claude Code's own generation tokens**, which are the dominant cost by an order of magnitude. To keep that down:

- Never paste a full workflow JSON back into context for a small edit — patch by node
- Generate SQL, Code node bodies, and the board HTML as files on disk, not as chat output
- Build and verify one workflow at a time against its "done when" criterion rather than regenerating the set
- Reuse the C1 guard and D2 matcher as sub-workflows; never reimplement either inside WF-2d or WF-7. Two copies of the sequence guard is the most likely way this build ends up with a rule that fires on one path and not the other

### Demo running cost

| Item | Monthly |
|---|---|
| Local machine | $0 |
| Temporary tunnel | $0 if using a free tunnel; otherwise provider-dependent |
| OpenAI (a handful of demo runs) | under $0.05 |
| **Total** | **$0/month plus negligible OpenAI usage** |

That is your entire fixed cost while building and rehearsing locally. A stable public demo URL is deliberately deferred until production/pilot readiness.

### Production running cost, per client

| Item | Monthly | Paid by |
|---|---|---|
| Client VPS (2 vCPU/4GB) | ~$5 | Client |
| OpenAI, 10 turns × 8 stages ≈ 80 transitions | ~$0.10 | You |
| Extra LLM calls — retries, unclear messages, ~30% overhead | ~$0.05 | You |
| Telegram | $0 | — |
| SMS via client's Twilio: ~200 msgs at ~$0.0079 + carrier surcharges ~$0.004 | ~$2.50 | Client |
| 10DLC campaign maintenance | ~$2–10 | Client |
| 10DLC one-time setup (brand + campaign) | ~$60–65 one-time | Client |
| **Your marginal cost per client per month** | **~$0.15** | |
| **Client's pass-through infrastructure** | **~$10/month + ~$65 once** | |

At the source document's pricing ($350–600/month), your gross margin is effectively 100%. **Price against recovered rent, not against this number** — and never show a prospect this table.

A useful honest line: *"My running costs on this are about fifteen cents a month. I'm not charging you for compute, I'm charging you for the vacancy days it takes back."*

---

## 13. Future scope

Deliberately excluded from the demo. Each line is a real capability with a real reason it isn't here yet.

| Capability | What it would add | Why it's out |
|---|---|---|
| **SMS instead of Telegram** | Vendors reply on the channel they already use — the single biggest lift to real-world reply rate | Requires 10DLC under a client's EIN. Cannot be done before you have a client (§1.4) |
| **Per-stage lag reporting over time** | "Your painters average 3.2 days, your cleaners 0.8" — turns the product into a vendor-management tool and makes it much harder to cancel | Needs months of real data. Nothing to report on yet |
| **Turn duration forecasting** | Predicted ready date from their own history, updating live | Same reason. Also the first thing that could be embarrassingly wrong in front of an owner |
| **Photo-based completion verification** | Model checks the photo matches the claimed work | Cheap to build, expensive to be wrong about, and it breaks the "advisory only" boundary that makes you safe to hire |
| **Vendor scorecards** | Reply rate and turnaround per vendor | Politically loaded. Only after trust exists |
| **Two-way PMS sync** | Turn status visible inside Buildium | $400/month plan gate (§1.1). Revisit only for a client already on Premium |
| **Owner-facing status page** | The client's owners self-serve on their unit's status — reduces the client's inbound calls, which is its own sellable value | Different buyer, different trust level, needs real auth |
| **Multi-client instance** | You run several clients from one place | **Would require an n8n Enterprise licence** (§1.2). Client-per-instance until the revenue justifies it |
| **Vendor scheduling / availability** | System proposes dates instead of just notifying | Moves from advisory to operational. Wrong side of your trust ceiling today |
| **Punch-list capture from inspection photos** | Vision model drafts the punch list from a walkthrough | Genuinely valuable, and it sits one inch from deposit assessment (§1.4). Needs deliberate guardrails before it goes anywhere near a client |
| **Cost tracking per turn** | Actual make-ready spend against the $1,000–5,000 benchmark | Touches money. Requires invoice access. Later, if ever |

---

## 14. Production build changes

What changes the day someone pays you. None of this belongs in the demo, and building it now is the most common way to never ship.

**Deployment and licensing**
- **Deploy on the client's own VPS, provisioned by you, billed to them.** Not a preference — n8n's licensing requires it (§1.2). Their instance, their data, your SSH key, revocable
- Add Caddy in production for TLS termination, reverse proxying `n8n.<domain>`, and serving the static board at `board.<domain>`
- Docker Compose with pinned image versions. Never `:latest` on a client's machine
- Automated nightly `pg_dump` to a second region, retained 30 days, **restore tested once before go-live** — an untested backup is not a backup
- Staging instance where workflow changes are validated before they touch a live client

**Messaging**
- Twilio under the client's own account. 10DLC brand and campaign registration under their EIN, started on day one (§1.4)
- **STOP/UNSUBSCRIBE handling on the inbound path**, writing to `vendor.opted_out_at`, honoured immediately across every workflow. Non-negotiable — TCPA revocation rules make this a legal requirement, not a courtesy
- Consent capture at vendor onboarding: how the number was obtained, when, by whom, stored in `vendor.consent_source` / `consent_at`
- Quiet hours enforced on outbound, per the client's local time, not the server's
- Message templates reviewed by the client and version-controlled — they are sent in the client's name
- Delivery receipt handling: a message that failed to deliver must not be treated as a message that was ignored

**Reliability and monitoring**
- **Silent-failure detection.** The real production risk is not a crash, it's a workflow that quietly stops firing. Heartbeat: if no vendor message has been processed in 24 hours during business days, alert *you*
- Telegram/Twilio webhook health check every 15 minutes, independent of n8n
- Retry with backoff on OpenAI and messaging calls; dead-letter queue for anything that fails three times
- Uptime monitoring on the board URL and the n8n health endpoint
- Alert routing that distinguishes "the client needs to know" from "you need to know" — the client should never see infrastructure noise

**Real-data edge cases you cannot anticipate now**
- Vendors who share a phone across a crew; vendors who change numbers
- Two units with identical labels across different properties (guaranteed to happen)
- Units re-entering turn after a failed QA
- Turns paused for owner decisions, insurance, or a unit taken off-market mid-turn
- Vendors who reply about three units in one message
- Stage sequences that differ per property type — a single-family turn is not an apartment turn
- Timezone handling for clients operating across state lines

**Security**
- Real authentication on the board (session-based, not a query token), per-user accounts
- Secrets in a proper store, not compose environment variables
- Rate limiting and IP allow-listing on the n8n editor
- TLS everywhere including internal service-to-service
- Photo storage with signed, expiring URLs rather than direct paths
- Retention job actually running and verified, not just configured

**Legal and contractual**
- Data processing agreement covering the India–US arrangement, reviewed by an Indian lawyer against the DPDP outsourcing question (§1.5)
- Written scope stating explicitly what the system does not do — the §11 table, in the contract
- Liability cap. You are a solo operator touching a client's vendor relationships
- Confirmation of the client's operating states against state SMS statutes before the first production SMS (§1.4)

**Onboarding**
- Vendor roster import and consent capture
- Stage template and SLA configuration per client, and per property type
- Tone sample capture for the drafting prompt (§5.4) — this is what makes messages read as theirs
- A one-page runbook for the manager: what the buttons do, what happens when they ignore an alert, who to call
- **A documented off-boarding path**: how they export their data and switch it off without you. Offering this at the start is one of the most persuasive things an unproven freelancer can do

**Success measurement, agreed before go-live**
- Vendor reply rate — the number that decides whether the automation works at all
- Median hours per stage, before and after
- Median days move-out to relist
- Count of sequence violations blocked

Agree these with the client in writing before anything goes live, and report the first three from week one. If reply rate comes in under about 30%, **tell them the automation isn't working for them and reprice around the board alone.** Saying that before they discover it is what earns the second client — and it is the only reference you will have for a while.
