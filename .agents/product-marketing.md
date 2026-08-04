# Product Marketing Context

**Document version:** v1
**Last updated:** 2026-08-04

## Product Overview
**One-liner:** Custom AI automation, built inside a property management company's existing make-ready process, that shows every vacant unit's turnover status live and drafts vendor handoffs for a manager to approve.

**What it does:** Tracks each unit through an 11-stage make-ready sequence (notice through relist), blocks stages from being marked done out of order (for example, deep clean before repairs), and drafts the next vendor's message the moment a vendor reports a stage finished — a manager presses Send, Edit, or Hold before anything goes out. A board shows every unit in turn, sorted worst-first, with live vacancy-cost math.

**Product category:** None. This is not a named software product, SaaS, or app. It is a custom automation build delivered as a service, comparable to hiring someone to build and run an internal tool — not to buying a subscription.

**Product type:** Consulting / service delivery. Each client gets their own automation built on their own infrastructure (their VPS, their n8n instance, their database). There is no multi-tenant platform and no shared account system across clients.

**Business model:** One-time setup fee plus a monthly fee for the client's own instance. Setup $1,000-1,800, monthly $350-600 (first two clients priced lower: $600 setup, $300/month while the model is unproven). Priced against recovered rent, not against hours worked.

## Target Audience
**Target companies:** US residential property management companies, 250-600 doors, 30%+ annual turnover, using outside vendors (not an all in-house maintenance team) for at least some make-ready trades.

**Decision-makers:** Owner or principal. This is a P&L conversation, not a facilities-department purchase — the buyer feels vacancy loss directly.

**Primary use case:** Knowing, without asking anyone, which vacant units are stuck in turnover, at what stage, and for how long — and stopping vendors from working stages out of order.

**Jobs to be done:**
- Recover rent currently lost to gaps between one vendor finishing and the next one being told to start.
- See every unit in turn on one screen instead of reconstructing status from texts, memory, or a whiteboard.
- Stop paying for rework caused by stages completed out of sequence (for example, cleaning before drywall repair).

**Use cases:**
- A maintenance coordinator opens one screen each morning to see which units are stalled and by how much.
- A vendor texts "done" the way they already text the company today; the next vendor's message is drafted automatically and waits for a human to send it.
- A manager gets an alert only when a stage has actually stalled past its allotted time, not a constant stream of updates.

## Personas
| Persona | Cares about | Challenge | Value we promise |
|---|---|---|---|
| Owner / principal (buyer) | Rent lost to vacancy, P&L impact | Can't see where turns are stuck without asking someone | A screen that shows dollars burning per unit, live, without asking |
| Maintenance coordinator / manager (daily user) | Not getting blindsided by a stalled vendor, not double-booking cleaning before repairs | Currently tracks turns by memory, spreadsheet, or a whiteboard | One board, worst-first, plus a guard that blocks the expensive mistake |

## Problems & Pain Points
**Core problem:** Every day a unit sits empty is rent that never comes back, and most of those days are not work — they are waiting for someone to find out the previous vendor finished.

**Why alternatives fall short:**
- Manual tracking (whiteboard, spreadsheet, memory) has no enforcement — a stage can be marked done out of order and nobody notices until it costs a second visit.
- Property Meld requires vendors to accept an email invite and set up an account before they are in the system.
- A property management system (PMS) like Buildium is not built for live per-turn sequencing and its open API sits behind a Premium-tier paywall.

**What it costs them:** Rent at roughly rent-monthly ÷ 30 per day per empty unit, plus rework cost (a second clean, a second visit) when stages get done out of order.

**Emotional tension:** The owner suspects turns are slower than they should be but cannot point to where the time goes, and doesn't fully trust that a vendor's "done" text was ever actually acted on by anyone.

## Competitive Landscape
**Direct:** Property Meld — vendors must accept an email invite and create an account before they can respond; does not block a downstream stage (like cleaning) from being marked done while an upstream stage (like repairs) is still open.

**Secondary:** Hiring a coordinator / VA — genuinely better than this automation at most day-to-day judgment calls, but has working hours and can't answer "which of my units is stuck right now" at 6pm.

**Indirect:** Managed make-ready services (for example Lula, operating in a defined set of metros) — a different approach entirely: outsourcing the make-ready work itself, not coordinating the client's own existing vendors.

## Differentiation
**Key differentiators:**
- A deterministic sequence guard blocks out-of-order stage completion (for example, deep clean while repairs are still open) with a plain-language reason, not a silent allow.
- Vendors need nothing installed — they reply to a text the way they already communicate; there is no account to create.
- Every outbound vendor message is drafted, never sent automatically. A human always presses Send, Edit, or Hold.
- The visibility board delivers value even at a 0% vendor reply rate, since a manager can advance stages manually through the same guard.
- Runs entirely beside the client's PMS with zero integration; the client owns the instance and infrastructure it runs on.

**How we do it differently:** The system is built once, for one client's actual stage sequence and vendors, on infrastructure that client owns — not a shared product with generic defaults.

**Why that's better:** No account setup for vendors, no PMS integration risk or cost, and no dependency on the builder staying available, since the client owns the running system.

**Why customers choose us:** They get proof the mechanism works (a live pilot, or a walkthrough using their own numbers) before paying anything, and an explicit offer to say "this isn't for you" if vendor reply rate turns out too low.

## Objections
| Objection | Response |
|---|---|
| "My vendors won't use an app." | Agreed — they reply to a text or send a photo, exactly what they already do. Nothing to install, no account. |
| "I already know what's happening with my units." | Probably true for the ones thought about this morning. Ask about one specific unit's stage and age instead. |
| "We tried a system like this and vendors ignored it." | That is the real risk. Offer to test with a small number of vendors first and look at the reply rate before any commitment. |
| "What happens if you disappear?" | Everything runs on infrastructure in the client's name, on their account. If the builder disappears, the client keeps the system and any n8n developer can maintain it. |

**Anti-persona:** An in-house-only maintenance team with no outside vendor handoffs to coordinate; a company doing fewer than roughly 30 turns a year; vendors who do not text; a company already using a managed make-ready service in their metro.

## Switching Dynamics
**Push:** Rent lost to invisible gaps between vendor handoffs, and rework costs from stages completed out of sequence.

**Pull:** A live board that answers "which unit is stuck and for how long" instantly, plus a guard rail that makes the expensive mistake structurally harder to make.

**Habit:** Calling or texting vendors individually and tracking status by memory or a whiteboard feels lower-effort to keep doing than it actually is.

**Anxiety:** Whether vendors will actually reply to a text (the automation is worthless if they don't, though the board still has value); trusting a solo builder with no track record; adding one more "system" to keep alive.

## Customer Language
**How they describe the problem:**
- "When my painter finishes a unit, how do I find out?" (posed as the qualifying question in `03-make-ready-coordination.md`)
- "How many units are in turn right now, and how long has each been sitting?"

**How they describe us:**
- No customer language exists yet — no client has used the system. Do not fabricate quotes; this section stays empty until real usage exists.

**Words to use:** the board, the automation, the intake workflow, the manager, the vendor, the manager's approval, your own infrastructure/instance.

**Words to avoid:** my platform, my tool, my product, the app, users, sign up, onboard onto, subscribers. This UI exists only so a human can see what the automation did; it is never described as software someone logs into.

**Glossary:**
| Term | Meaning |
|---|---|
| Turn / make-ready | The full process of preparing a vacated unit for a new tenant |
| Stage | One step in the 11-step sequence (for example Paint, Deep Clean) |
| Sequence guard | The deterministic rule set blocking out-of-order stage completion |
| Awaiting approval | A drafted vendor message sitting in the manager's queue, not yet sent |
| Vendor reply rate | The percentage of vendor completions logged automatically vs. by hand |
| Auto-handled rate | The percentage of stage advances the automation completed without a manager typing anything |

## Brand Voice
**Tone:** Understated, incident-report register. Short declaratives, real numbers, first person, US spelling. No hype vocabulary, no exclamation points, at most one em dash across a given document and zero is better.

**Style:** Direct and specific — every capability claim names the exact part of the system responsible for it rather than describing the system as a whole. Limitations are stated before a prospect finds them, not defended when asked.

**Personality:** Honest, unhurried, structurally cautious, willing to disqualify itself, allergic to guarantees it can't back up.

## Proof Points
**Metrics:** None yet from a real client. Internal fixture testing (F01-F20) has verified the mechanism works against synthetic data; this is a testing result, not a customer result, and must never be presented as one.

**Customers:** None yet. This would be the first client in property management for this builder — say so plainly rather than implying otherwise.

**Testimonials:** None yet.

**Value themes:**
| Theme | Proof |
|---|---|
| Rent recovery is computable, not vague | Live board computes days-vacant × daily rent per unit from real timestamps |
| Out-of-order rework is a real, named failure mode | Sequence guard has a specific blocked reason for the repairs-before-cleaning case |
| Nothing goes to a vendor without a human | Manager approval queue (Send/Edit/Hold) sits in front of every outbound draft |

## Goals
**Primary business goal:** Land a first paying pilot client in the target ICP (250-600 doors, 30%+ turnover, vendors who already text).

**Key conversion action:** For the recorded demo video specifically, a low-pressure invitation to reach out and walk through the mechanism with the viewer's own numbers — not a hard CTA, no link or handle fabricated where none exists yet.

**Current metrics:** None from real usage. Internal fixture-test coverage (F01-F20) and local Stage 1-8 verification are implementation-readiness signals, not customer metrics, and should not be blended with the two.

## Changelog
*Newest first. One line per revision: what changed and why.*
- v1 (2026-08-04) — Initial context, drafted from `03-make-ready-coordination.md` (ICP, positioning, objections, pricing) and `make-ready-demo-build-plan.md` §11 (honesty boundary) ahead of writing `docs/how-the-system-works.md` and `docs/demo-script.md`.
