# Build retrospective: turnover make-ready coordination

Revised: 2026-10-20. Status: rendered draft for review; not published or queued.

Review PDF: `carousel-kit/out/technical-retrospective-make-ready.pdf`.
Editable HTML: `carousel-kit/technical-retrospective-make-ready.html`.
Build: `node carousel-kit/scripts/build-technical-retrospective.cjs`.
Verify: `python carousel-kit/scripts/verify-technical-retrospective.py`.

## Editorial direction

- Problem-first retrospective for property-management decision makers and buyers, with enough concrete decisions and debugging to show hiring readers how I work.
- No prominent stack list, code, schema, node counts or database status labels. Explain decisions through their operational consequences. Keep the two real defects and specific checks; avoid vague AI claims.
- Eleven short slides: problem, workflow, responsibilities, sequence guard, two bugs, fallback, lesson, verification and next steps. Use varied plain-language diagrams and comparisons.
- Preserve cream ruled paper, Switzer, restrained Zodiak and meaning-led blue/yellow annotations. Either color works for every annotation shape.
- Public wording omits demo/synthetic-data and no-client/no-deployment labels. Internal evidence remains below. No invented business results, classifier benchmarks or completed future safeguards.

## LinkedIn caption

> Turning over an apartment between residents takes five or more separate trades. Every day the unit sits idle is lost rental income, but rushing trades out of order is worse: clean before drywall or painting, and you pay to clean twice.
>
> I built an automation to keep turnovers moving in sequence: receive informal contractor updates by text or email, enforce physical trade dependencies, draft the next contractor's dispatch, and bring it to a property manager for review.
>
> AI helps interpret informal contractor messages and prepare draft notices. The manager stays in full control: resolving ambiguous unit matches, selecting the outbound delivery channel, and approving every contractor dispatch before it leaves. The system never contacts an external contractor on its own.
>
> Two bugs taught me more than the happy path did.
>
> An email reader stored incoming message headers under a metadata property instead of the main header object. Without thread headers, real contractor replies were misclassified as outgoing system copies and silently ignored. I updated header normalization to inspect metadata so threaded replies route properly to active turnovers.
>
> Workspace synchronization ran once across all items, but only captured record IDs from the very first batch. Subsequent batches updated without identifiers, breaking links between turnovers, stages, and contractors until I paired each batch response by index.
>
> Those fixes shaped how I approach automation architecture. The hardest part is not connecting APIs; it is building safe boundaries for the messy ways people communicate and the unexpected ways systems fail.
>
> I verified the build against informal slang, ambiguous property names, out-of-order trade reports, and duplicate button presses. Next, I plan to add structured photo checklists for trade sign-offs and two-way contractor arrival tracking.
>
> The goal is simple: keep turnover trades moving in physical order without letting units sit idle between handoffs.

## Carousel copy

### Slide 1

**Title:** Turnover coordination that protects the sequence

**Body:** What I built to keep turnover trades moving in order, what broke, and what I changed.

**Footer:** Build retrospective · Turnover make-ready coordination

### Slide 2

**Title:** Out of order means paying twice

**Body:** Turning over an apartment takes five or more separate trades. If one contractor works out of order, fresh work gets ruined and costs double.

**Footer:** The problem · Physical order matters more than speed

### Slide 3

**Title:** From contractor text to reviewed handoff

**Body:** I built a workflow that catches informal trade completions, checks physical sequence rules, drafts the next handoff, and brings it to a manager.

**Footer:** The workflow · Connect trades without losing control

### Slide 4

**Title:** AI interprets. The manager dispatches.

**Body:** AI handles messy contractor texts and prepares draft notices. The property manager verifies the work, picks the channel, and approves every outward message.

**Footer:** The boundary · No contractor is contacted without approval

### Slide 5

**Title:** Physical order belongs in code

**Body:** Software should not let a language model guess whether floors can be installed before paint is dry. Hard dependency rules reject out-of-order completions automatically.

**Footer:** Architectural decision · Protect physical sequence deterministically

### Slide 6

**Title:** An email reply was silently ignored

**Body:** An email reader placed header lines inside metadata rather than the main header object. Without thread headers, real contractor replies were treated as outgoing copies and ignored.

**Footer:** Bug 1 · Threaded email replies lost their headers

### Slide 7

**Title:** Sync lost links after batch one

**Body:** The workspace sync ran once for all items, but only saved identifiers from the first batch. Later turnover stages updated without links until I paired each batch by index.

**Footer:** Bug 2 · Multi-item responses broke linked records

### Slide 8

**Title:** Uncertainty needs a person

**Body:** When a contractor text is vague or multiple units match, the system stops. It never guesses an apartment unit or sends on an unconfigured channel.

**Footer:** The fallback · Ambiguity stops automation before mistakes happen

### Slide 9

**Title:** Coordination breaks at the seams

**Body:** Building this changed how I view turnover automation. The challenge is rarely connecting an API; it is handling messy texts, missing headers, and out-of-order reports safely.

**Footer:** What I learned · Design for the edges of trade communication

### Slide 10

**Title:** I checked the awkward cases

**Body:** I checked messy wording, ambiguous addresses, out-of-order completions, and duplicate button presses to confirm the workflow behaves predictably under real operating conditions.

**Footer:** Verification · Specific checks of workflow behavior

### Slide 11

**Title:** What I'd improve next

**Body:** Next, I would add structured photo inspection checklists before sign-off and two-way arrival confirmations, reducing turnover delays even further.

**Footer:** Next steps · Proposed improvements

## Internal evidence mapping

| Slides | Evidence | Boundary |
|---|---|---|
| 1-3 | Current turn intake, stage template, and make-ready coordination blueprint | Built to sequence trades; vacancy reduction is the goal, no unverified revenue claim |
| 4 | WF5 Manager Action Core, Vendor Communications, and Telegram approval card | Every outbound message individually approved; manager chooses Email, Message, or Both |
| 5 | Deterministic sequence guard (`wf-3-sequence-guard.json`) | Hard dependency checks (repairs before paint, paint before flooring, clean last); never delegated to an LLM |
| 6 | August 17 IMAP metadata normalizer fix (`progress-notes.md` line 22) | `In-Reply-To` read from `metadata`; prevents self-originated misclassification |
| 7 | August 17 Airtable batch mapping fix (`progress-notes.md` line 21) | Capture node pairs responses by index across multiple batches; avoids orphan records |
| 8 | Unit matcher ambiguity score and fallback routing (`wf-4-unit-matcher.json`) | Tied candidates or confidence below threshold route to manager; unconfigured channel blocks |
| 9 | August 18 live verification and architecture lessons | Design protects against double taps, vague messages, and out-of-order advances |
| 10 | Preserved integration runs, F01-F20 checks, and August 18 duplicate protection | Messy texts ("done with 12b", "yeah thi si sdone"), 14A repair block, double-send prevention verified |
| 11 | Production business blueprint and pilot improvement backlog | Photo checklist, vendor ETA arrival tracking, and PMS accounting sync proposed as future work |

Keep this appendix, evidence provenance and local paths outside the PDF.
