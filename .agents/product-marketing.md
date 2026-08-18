# Product Marketing Context

**Document version:** v2
**Last updated:** 2026-08-18

> **v1 is superseded and must not be used.** It described a build that no longer exists: a custom visualization board (since deleted) and a Send / Edit / Hold approval card (replaced by Email / Message / Both). Any draft written from v1 will describe software the client would have to open, which is the opposite of the positioning.

## Product Overview

**One-liner:** Custom AI automation, built inside a property management company's existing tools, that watches every vacant unit's make-ready sequence, notices when a handoff has gone quiet, and drafts the next vendor's message for a manager to release.

**What it does:** Tracks each unit through an 11-stage make-ready sequence from notice to relist. It refuses to let a stage be completed out of order, including when the manager is the one asking. When a vendor reports a stage finished, by email, by Telegram, or through a generic inbound webhook, it matches the message to the right unit and stage, checks the order, marks the stage complete, and drafts the next vendor's handoff. Nothing reaches a vendor until the manager chooses a delivery channel. Everything the manager sees lives in Airtable and Telegram, both of which the client already owns.

**Product category:** None. Not a named software product, not SaaS, not an app. There is nothing to install, nothing to log into, and no seats. It is a custom automation build delivered as a service, closer to hiring someone to build and run an internal process than to buying a subscription.

**Product type:** Consulting / service delivery. Each client gets their own automation on their own infrastructure: their n8n instance, their database, their Airtable base, their mailbox. No multi-tenant platform, no shared accounts across clients.

**Business model:** One-time setup fee plus a monthly fee for the client's own instance. Setup $1,000-1,800, monthly $350-600. First two clients priced lower ($600 setup, $300/month) while the model is unproven. Priced against recovered rent, not hours worked.

## What the manager actually touches

There is no dashboard in this build. This matters more than any feature claim, because it is the proof that nothing is being sold as software.

| Surface | What happens there | Who owns it |
|---|---|---|
| Airtable | Turns, stages, vendors, communications, approvals and delivery results. Also the only place a manager types a new turn in | The client |
| Telegram | Alerts, approval cards, the daily digest, and the manager controls | The client |
| Vendor's own email or messaging app | Vendors receive handoffs and reply, with nothing to install and no account to create | The vendor |
| Postgres | The authoritative record. The manager never sees it | The client's server |

A custom board was built during development and then deleted. The client already had a better surface, and adding one more thing to open would have made this a product.

## Target Audience

**Target companies:** US residential property management companies, roughly 150-600 doors, 30%+ annual turnover, using outside vendors for at least some make-ready trades rather than an all in-house crew.

**Why that size band.** Above it, enterprise make-ready products are a genuine fit and should usually be bought instead. HappyCo, for one, publishes a 500-unit minimum. Below roughly 30 turns a year there is not enough repetition to justify any of this.

**Decision-makers:** Owner or principal. This is a P&L conversation. The maintenance coordinator or ops manager is the daily user and the internal champion, but rarely the signer.

**Primary use case:** Knowing which vacant units are stuck, at what stage, and for how long, without asking anyone, and being told when a handoff has gone quiet.

**Jobs to be done:**
- Recover rent lost in the gap between one vendor finishing and the next one being told to start.
- Stop paying twice for work done out of order.
- Find out that a stage is stalled without having to remember to check.

## Personas

| Persona | Cares about | Challenge | Value promised |
|---|---|---|---|
| Owner / principal (buyer) | Rent lost to vacancy, P&L impact | Suspects turns are slow but cannot point to where the days go | Days per stage and dollars burned computed from real timestamps, not from memory |
| Maintenance coordinator (daily user) | Not being blindsided, not booking cleaning before repairs are done | Tracks turns by memory, spreadsheet, or whiteboard | One ranked list each morning, plus a rule that blocks the expensive mistake |

## Problems & Pain Points

**Core problem:** Most of a turn's calendar is not work. It is waiting to find out the previous vendor finished. A vendor who finished and said nothing looks exactly like a vendor who never started, and both cost the same per day.

**What it costs them:**
- Roughly rent-monthly divided by 30 per vacant day, per unit.
- A second visit when stages run out of order. Industry reporting puts 20-25% of turnover repairs as needing a second visit.
- A 30-50% premium when work has to be expedited to make up lost days.

**Why alternatives fall short:**
- Whiteboards, spreadsheets and memory have no enforcement and no way to notice silence.
- Enterprise make-ready platforms carry unit minimums that exclude this segment.
- Portal-based tools require the vendor to accept an invite, register and create a password before they can respond at all.
- A PMS is not built for live per-turn sequencing, and its API often sits behind a higher pricing tier.

**Emotional tension:** The owner cannot tell the difference between a slow trade and a missed message, and does not fully trust that a vendor's "done" was ever acted on.

## Competitive Landscape

**Say plainly that this category is occupied.** It is, by capable products. Any copy implying nobody has noticed this problem is false and a property manager will know it.

| Competitor | What it is | Honest read |
|---|---|---|
| HappyCo | Real-time turn boards, multifamily operations | Strong product. 500-unit minimum puts it above this ICP |
| Make Ready Manager | Cloud make-ready boards with a vendor mobile app | Direct category match. Requires vendors to use the app |
| TurnTrack | Role-based make-ready workflows with photo documentation | Direct category match, purpose-built |
| AppWorks / SuiteSpot | Make-ready boards and turn management with vendor portals | Direct category match |
| Rent Manager | Make Ready module inside the PMS | If already on Rent Manager, this may be enough |
| Property Meld | Maintenance platform. Vendors must accept an emailed invite and register before they can respond | Registration friction is real and documented by them |
| Lula | Does the make-ready work itself, 72-hour turns, defined metros | A different purchase entirely. If they operate in the client's metro, sometimes the better answer |

**Sequencing enforcement is not a differentiator.** Automated turnover systems already advertise preventing progression until prior stages are complete. Do not claim to be alone in this.

**What is actually different:**
1. Vendors do nothing new. They reply from email or the messaging app they already use. No invite, no account, no download.
2. It fits a portfolio below the enterprise unit minimums.
3. It lives inside Airtable and Telegram the client already owns, rather than adding a system to open.
4. The client owns the instance and the infrastructure. If the builder disappears, any n8n developer can maintain it.

## Differentiation

**Key differentiators:**
- A deterministic sequence guard blocks out-of-order completion and states the reason in plain language. It blocks the manager too, and the override is recorded.
- A stage can only be completed by the vendor it was actually handed to. Work that was never released cannot be reported finished.
- Every outbound vendor message is drafted, never sent. The manager chooses Email, Message, or Both, per message.
- Ignoring an approval is a valid decision. The draft stays open and nothing goes out.
- Silence is treated as a signal. A stage that goes quiet past its expected duration raises an alert, once, during business hours.

**Why customers choose us:** They see the mechanism run against their own numbers before paying, and get told plainly if their vendor reply rate makes it a bad fit.

## Objections

| Objection | Response |
|---|---|
| "My vendors won't use an app." | They don't have to. They reply by email or the app they already use. Nothing to install, no account. |
| "Doesn't Property Meld or HappyCo already do this?" | For some operators, yes, and say so. HappyCo starts at 500 units. Property Meld needs vendors to register. If either fits, buy it. |
| "I already know what's happening with my units." | Probably for the ones thought about this morning. Ask about one specific unit's stage and how long it has been there. |
| "We tried something like this and vendors ignored it." | That is the real risk. Test with a few vendors and look at the reply rate before committing. Below roughly 30% reply rate this is a bad purchase. |
| "What happens if you disappear?" | Everything runs on infrastructure in the client's name. They keep it, and any n8n developer can maintain it. |

**Anti-persona:** An all in-house maintenance crew with no vendor handoffs; fewer than roughly 30 turns a year; a portfolio large enough that an enterprise platform fits properly; a company already using a managed make-ready service in their metro.

## Switching Dynamics

**Push:** Rent lost in invisible gaps between handoffs, and paying twice when stages run out of order.

**Pull:** A ranked morning list answering which unit is stuck and for how long, and a rule that makes the expensive mistake structurally harder.

**Habit:** Texting vendors individually and holding status in memory feels cheaper than it is.

**Anxiety:** Whether vendors will actually reply; trusting a solo builder with no track record; keeping one more thing alive.

## Customer Language

**How they describe the problem:**
- "When my painter finishes a unit, how do I find out?"
- "How many units are in turn right now, and how long has each been sitting?"

**How they describe us:** No customer language exists. No client has used this. Do not fabricate quotes.

**Words to use:** the automation, the sequence rule, the handoff, the approval, the manager, the vendor, your Airtable, your own instance.

**Words to avoid:** my platform, my tool, my product, my software, the app, the dashboard, the board, users, sign up, onboard, subscribers. There is no board in this build and no software anyone logs into.

**Glossary:**

| Term | Meaning |
|---|---|
| Turn / make-ready | Preparing a vacated unit for the next resident |
| Stage | One step of the 11-step sequence, for example Paint or Deep clean |
| Handoff | The message telling the next vendor the unit is ready for them |
| Sequence rule / guard | The deterministic check that blocks out-of-order completion |
| Awaiting approval | A drafted handoff sitting with the manager, not sent |
| Stall | A stage that has passed its expected duration with no word |
| Vendor reply rate | Share of completions reported by the vendor rather than entered by hand |

## Brand Voice

**Tone:** Understated, incident-report register. Short declaratives, real numbers, first person, US spelling. No hype, no exclamation points, at most one em dash per document and zero is better.

**Style:** Every capability claim names the specific part of the automation responsible. Limits are stated before a prospect finds them.

**Personality:** Honest, unhurried, structurally cautious, willing to disqualify itself, and willing to name the competitor a prospect should buy instead.

## Proof Points

**Metrics:** None from a real client. The mechanism has been verified live against synthetic fixtures: vendor completions over Telegram and email, ordering enforcement, ambiguity resolution when one vendor holds two units at the same stage, duplicate and double-send protection, and single-channel and dual-channel delivery. **This is testing, not a customer result, and must never be presented as one.**

**Customers:** None yet. This would be the first. Say so plainly.

**Testimonials:** None.

**Value themes:**

| Theme | Proof |
|---|---|
| Lost days are computable, not vague | Days at stage and dollars burned are derived from real timestamps |
| Out-of-order rework is a named failure with a price | The rule has a specific blocked reason, and industry reporting prices second visits at 20-25% of turnover repairs |
| Nothing reaches a vendor without a person | Every handoff waits for a channel choice, and ignoring it sends nothing |
| Silence gets noticed | A quiet stage raises one alert rather than waiting to be discovered |

## Goals

**Primary business goal:** Land a first paying pilot in the target band.

**Key conversion action:** A low-pressure invitation to walk through the mechanism using the prospect's own numbers. No fabricated links or handles.

**Current metrics:** None from real usage. Local verification is an implementation-readiness signal and must not be blended with customer outcomes.

## Changelog

*Newest first.*
- **v2 (2026-08-18)** — Rewritten for the current build. Removed the visualization board, which was deleted from the project, and the Send / Edit / Hold approval card, replaced by Email / Message / Both. Added Airtable and Telegram as the manager surfaces, email as a first-class vendor channel, the ordering rule that a stage can only be completed by the vendor it was handed to, and stall detection. Rebuilt the competitive section from live research: HappyCo's 500-unit minimum, Property Meld's vendor registration requirement, and the fact that sequencing enforcement already exists in the category and cannot be claimed as unique.
- v1 (2026-08-04) — Initial context from `03-make-ready-coordination.md` and `make-ready-demo-build-plan.md`. **Superseded.**
