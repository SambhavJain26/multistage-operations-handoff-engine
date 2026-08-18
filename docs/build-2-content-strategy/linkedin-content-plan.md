# LinkedIn Content Plan — Maintenance Triage

Created: 2026-08-13

Fifteen posts: one demo video, fourteen supporting. Each brief carries the elements a script needs, so turning one into a draft is a writing job, not a thinking job. Finished copy will live in `linkedin-post-scripts.md`.

This is the second of four planned builds. The first, vendor insurance paperwork, is planned in `docs/build-1-content-strategy/linkedin-content-plan.md` and has finished scripts. **Neither build has published anything yet**, so the launch order is still open and this plan is written to work either way. See "Relationship to build 1" for the two posts whose placement depends on that decision.

## What is being sold

**Custom AI automation, built and implemented inside a client's existing business.** Not software. Not a SaaS product. Nothing to log into, no seats, no subscription.

This governs every post. The triage system is a **worked example of how I approach a problem** — evidence of judgment, not a product being launched. Language never implies "my tool" or "my platform." It says: this is the kind of thing I build, inside your mailbox, your database, your process, and you own it when it's done.

**The buyer:** US residential property management companies, roughly 150–600 doors, ideally 200–600. Owner or principal signs; the ops manager or maintenance coordinator is the daily user and the internal champion.

**The competitive context.** Three funded companies sell AI maintenance triage into exactly this segment — Property Meld, Latchel, Vendoroo — and every major PMS ships a maintenance module. No post may imply nobody has noticed the problem. The differentiator is direction, not existence: the category is moving toward removing the human from dispatch, and this is built for the operator who wants the opposite. Full vocabulary, pricing and the two facts that define the position are in `customer-language.md`.

**Where each post leads:** authority first, conversation second, call third. One post carries a real CTA. The rest earn the right to one.

## Why this build is the stronger opener

Build 1 spends five posts making vendor insurance paperwork legible before it can say anything. That is a structural cost of the subject, and its own plan documents the revision it took to get there.

This build has no such cost. Everyone understands a broken toilet at 11pm. The problem is also the best-evidenced of the four researched — a 1,000+ manager survey, a separately collected owner survey, a 193,000-request operational dataset, and slow maintenance response identified as the #1 driver of non-renewal. The demo is visceral and needs no domain knowledge: six messages go in, they sort, and an emergency alert lands on the prospect's own phone.

The recommendation is to lead with this build. The decision is not mine to make, and the plan works in either order.

## Relationship to build 1

Same buyer, same voice, adjacent subjects. Three of this plan's posts were caught colliding with build 1 during review and have been rebuilt. **Do not reintroduce the original framings when writing scripts.**

| This post | Collided with | Resolution |
|---|---|---|
| 6. Every rule is a scar | Build 1 post 1, *What AI should do with your paperwork* | Build 1 owns the reading-versus-deciding principle. This post must not restate it. It teaches something different: the rules cannot be written in advance, only discovered by running the thing against reality |
| 3. The category is removing the human from dispatch | Build 1 posts 13 and 3 | Build 1 owns "what can it do without a person seeing it first" as a cross-build principle, and its refuse-list already names vendor dispatch. This post drops the permission argument entirely and becomes a competitive-direction post, which is new material |
| 13. Where your automation gives up | Build 1 post 8, *The reminder that fired twice* | Build 1 owns retry logic and the definition of "I already asked." This post is about the give-up path and who receives the escalation, which is a different mechanism and a better lesson |

Two further notes:

- **Post 4 is conditional.** "I don't sell software" is build 1's post 5. It can only be published once. If this build leads, it belongs here and this is a 15-post plan. If build 1 leads, delete post 4 and this becomes 14.
- **Post 15 shares its shape with build 1's post 15** — same offer structure, different artifact. That is correct, since only one plan runs at a time. If both eventually publish, the second must be rewritten rather than refilled, or the set reads as templated.

**Rotation rule inherited from build 1:** never two consecutive build-in-public posts about the same system. That rule does not bind while a single build runs solo at one post a week, and starts binding as soon as a second build's posts interleave.

## Accessibility

Build 1 needed a five-post gateway arc. This build needs three posts, not five, and they are load-bearing for a different reason: nothing is published yet, so the first people to see any of this are the wrong audience by default.

Posts 1, 2 and 3 answer the three questions a stranger asks in order: what world is this, is it real, and is this person going to sell me garbage. All three work on a reader with no property management knowledge. From post 5 onward the reader is assumed to know what triage and a work order are, which `customer-language.md` confirms is safe.

**No origin story.** The work explains itself. Positioning comes from what the posts demonstrate.

## Format split

| Format | Count | Posts |
|---|---|---|
| Text | 6 | 3, 4, 9, 11, 13, 15 |
| Document carousel | 4 | 1, 5, 6, 8 |
| Native video | 3 | 2 (demo), 10, 12 |
| Single image | 2 | 7, 14 |

**The carousels carry the four highest-insight posts in the set.** This was corrected during review: post 1 is the thesis of the entire product and was originally allocated to text, which is exactly the mistake build 1's own revision was written to fix. Teaching goes in carousels and video; positioning and proof go in text, where low reach costs nothing.

Ranked by the test "would a property manager learn something and keep this," the top four after the demo are posts 8, 1, 5 and 6. Those are the four carousels.

## Pillars

| Pillar | Count | Posts | Job |
|---|---|---|---|
| Triage literacy | 3 | 1, 5, 11 | What urgency actually is, why the resident can't tell you, and why alert discipline matters. Genuinely useful to someone never trained in it, which is most of them |
| What software is allowed to do | 4 | 3, 6, 8, 14 | The load-bearing pillar. Escalated from build 1's reading question to the deciding question, because here the cost of being wrong lands on a resident |
| Failure lessons anyone can apply | 4 | 7, 10, 12, 13 | Real defects from live runs, framed so the lesson is theirs and the story is mine |
| Proof and operating model | 3 | 2, 4, 9 | The work is real, this is a service rather than a product, and here is the communication boundary |
| The ask | 1 | 15 | The only real CTA |

**"What software is allowed to do" is load-bearing** because it is the honest escalation of build 1's material. Build 1 asked what a model should read. This build asks what it is allowed to decide when the answer sends a stranger to someone's home. That question is current, the category is answering it in the opposite direction, and I can write it honestly because I made the choice in code.

## Process and frameworks

Run in this order. Steps 0 and 1 are done; the rest repeat per batch.

| Step | Source | What it gives | Status |
|---|---|---|---|
| 0 | `product-marketing` | `.agents/product-marketing.md`. Over 100 skill files read it before acting | Done — refreshed to v2 for Stage 9 on 2026-08-13. v1 described the Stage 8 build and would have poisoned every draft |
| 1 | `customer-research` | Maintenance vocabulary, pain phrasing, competitive facts | Done — `customer-language.md`. Primary practitioner voice still unreached; see its sourcing caveat |
| 2 | `social` references | Structure per format — `carousel-frameworks.md`, `short-form-video.md`, `platform-limits.md` only | Per batch |
| 3 | `copywriting` | Line-level principles, plus `references/natural-transitions.md` | Per batch |
| 4 | `offers` | Post 15 only. Value framing for the free diagnostic, and its guidance on when *not* to apply offer tactics | Post 15 |
| 5 | `seo-audit/references/ai-writing-detection.md` | **Mandatory pass on every draft** | Every draft |
| 6 | `image`, plus `high-end-visual-design` | Carousel slides and the two image posts. The design skills exist to avoid the generic template look, which is its own tell | Per batch |
| 7 | `copy-editing` | Seven Sweeps, after the draft has been rewritten in my own words | Final pass |

`full-output-enforcement` applies to every batch: no partial delivery, no "the rest follows the same pattern."

**Rejected from skills otherwise in use:** `social`'s hook libraries, for both text and video. They generate "Unpopular opinion:", "I was wrong about X," "[Number] things that [outcome]" — the templated register that reads as machine-written. Structure yes, hooks no. Hooks come from the material. Same for `post-templates.md`: use the skeleton, cut the engagement-bait closer.

**Deliberately not used:** `marketing-psychology` (persuasion levers fight an understated positioning), `video` (production tooling, not scripting), `ads` and `ad-creative` (paid), `content-strategy` (this plan is the output), `marketing-council` (a simulated advisory board produces confident generic advice).

## Brief format

Every post has the same fields:

- **Hook angle** — what the opening does, not the words
- **The turn** — the pivot the whole post is built on
- **Evidence** — the specifics that must appear, with source
- **Takeaway** — what the reader leaves holding
- **Discipline** — the constraint that keeps the post honest, where one applies
- **CTA**

---

# The posts

Numbered in publishing order.

## 1. The urgency rating your resident gives you is the least reliable number in the process

**Format:** carousel, 9 slides · **Framework:** Problem-Proof · **Pillar:** triage literacy · **CTA:** none

**Hook angle:** Open on two messages that arrived in the same inbox on the same day. One said URGENT in capitals. One apologised for bothering anyone. The capitals were a squeaky hinge. The apology was a failed supply line.

**The turn:** The industry already knows residents misjudge this — every management company publishes an emergency-definition page to correct it. Nobody draws the conclusion. If the rating is unreliable in both directions, then the urgency field on your intake form is decoration, and any process that sorts on it is sorting on noise. The description is evidence. The rating is a guess by the person least equipped to make it, at the worst moment to ask them.

**Evidence:** The two-sided cost from `02-maintenance-triage.md`: a "bit of water under the sink" that was a failed supply line, $150 becoming a $12,000 claim across two units; and a Saturday 8pm running toilet dispatched at weekend rates, $340 for a $60 flapper valve, roughly twice a month. The industry's own concession, from operator-authored emergency pages, that requests "may feel urgent to tenants" while only some qualify. The built artifacts: fixtures `01-understated-gas.txt` and `03-urgent-squeaky-door.txt`, which exist because both directions had to be tested. The Buildium Emergency/Urgent/Routine taxonomy as the standard being sorted into.

**Takeaway:** Stop asking residents how urgent it is. Ask them what is happening, and classify it yourself — or have something classify it for you. The words are data. The rating is not.

**Legibility:** Zero domain knowledge required. Anyone who has ever been asked to rate their own problem on a form follows it immediately.

**Discipline:** Do not present "residents misjudge severity" as the insight. They already know, and asserting it reads as condescending. Lead with the conclusion, not the premise. See `customer-language.md`.

**Why first:** It establishes the audience and the entire reason this category exists, and it quietly indicts every portal with an urgency dropdown without naming one.

---

## 2. The demo — six messages go in, and the emergency reaches a phone

**Format:** native video, 2–3 minutes · **Framework:** scene structure from `docs/operating-guide.md` · **Pillar:** proof · **CTA:** soft — offer to walk through it

**Why not the short-form template:** at 2–3 minutes this sits outside short-form video, where the 0–3 second hook rules apply.

**Hook angle:** Open on an empty board and immediately do the thing. No preamble, no introduction.

**The turn:** Nothing here required anyone to read anything. Six messages arrived together, the gas smell and the burst pipe went to the top, the squeaky door went to the bottom, the rambling three-paragraph one came out as nine words, and the manager's phone rang for exactly one of them.

**Evidence:** The six live-demo fixtures. The Telegram emergency alert landing on a phone on screen. The manager message showing the request summary, the drafted vendor email, and the vendor buttons. One tap sending one email. Then twenty seconds, unhurried, on what it does not do: it does not create the work order in your PMS, it does not pick the vendor, and it does not tell the resident when anyone is arriving.

**Takeaway:** This is real, it works, and the person who built it volunteers its limits before being asked.

**Framing discipline:** "Here's something I built for a property management company's maintenance inbox." Never "here's my product." The video is evidence of how I work, not a launch.

**Capture note:** Synthetic fixtures only, stated on screen. Reset to clean demo state first, per the pre-call checklist.

---

## 3. The whole category is trying to take the human out of dispatch. I went the other way.

**Format:** text, 250–300 words · **Pillar:** what software is allowed to do · **CTA:** none

**Rebuilt during review.** The original version argued that it can draft but not send, which is build 1 post 13's territory and is explicitly framed there as a cross-build principle. This version drops the permission argument and reports the market instead, which is new material.

**Hook angle:** Open on what the competitors actually promise, quoted accurately and without sneering. One of them advertises that its AI de-escalates 48% of emergencies. One of them will pay for its own mistakes in writing.

**The turn:** That second one is a real answer to the liability question, and a company with insurance and a track record can make it. My answer is different, not better in every case: the decision never leaves the manager. The safety rules in my build can only ever raise a priority, never lower one, because I could not write down a defensible reason for software to decide that something a resident called an emergency is not one.

**Evidence:** Latchel's advertised "48% of emergencies de-escalated" and "23% solved at intake." Vendoroo's "If the AI makes an error, we will pay for it," from ~$3/door/month. Property Meld at ~$1.60–2.00/unit/month, marketed as agentic triage and dispatch. Against that: the escalate-only architecture rule in `AGENTS.md`, and the fact that no code path exists from an inbound message to a vendor without a manager tap.

**Takeaway:** Both designs are real products. Ask which one you want on the day it is wrong, because that is the only day the difference matters.

**Discipline:** Never disparage the autonomous products, and say plainly that some operators should buy them. The anti-persona is real and naming it is the most credible thing available. Every competitor claim must be quoted accurately from `customer-language.md` sources, never paraphrased into something worse than they said.

---

## 4. I don't sell software

**Format:** text, 200–250 words · **Pillar:** operating model · **CTA:** none

**Conditional post.** This is build 1's post 5 and can only be published once. Include here only if this build leads. If build 1 publishes first, delete this and renumber.

**Hook angle:** State the negative first. Nothing to log into, no seats, no per-door fee, no monthly charge for a dashboard nobody opens.

**The turn:** What I build runs inside the business that already exists — the mailbox you already use, a database you own, the process your team already follows. When it's finished it belongs to you, and if we stop working together it keeps running.

**Evidence:** Concretely, what "inside your business" means here: it reads the mailbox you already have, writes to a database you control, sends from your address, and can be exported and handed to anyone. Contrast with the category, where every named competitor prices per door and requires the maintenance workflow to move into their platform.

**Takeaway:** This is a different transaction from buying a tool. You are not adopting a product; you are getting a specific piece of your operation handled.

**Legibility:** This is the post that makes the whole offer make sense to anyone who assumed I was selling an app. It should come early precisely because that assumption is the default.

---

## 5. When it's ambiguous, go up

**Format:** carousel, 7 slides · **Framework:** principle, then mechanism, then application · **Pillar:** triage literacy · **CTA:** soft — invite the question about their own processes

**Hook angle:** Open on the cost of each mistake, side by side. Calling a routine issue an emergency costs you a phone call and some vendor goodwill. Calling an emergency routine costs you a claim, a habitability problem, and sometimes a resident.

**The turn:** Those two numbers are nowhere near each other, so the two errors should never be treated as equally bad. Every ambiguous case should resolve upward, by rule, before anyone has a chance to be optimistic about it. Most processes get this wrong not because anyone decided badly, but because nobody ever priced the two errors and compared them.

**Evidence:** The instruction in the classification prompt: when ambiguous between two levels, always choose the higher. The architectural version, which matters more: deterministic safety rules run *after* the model and are escalate-only, so they can raise a priority above the model's answer and have no code path to lower one (`AGENTS.md`). The contrast, stated factually: a competitor advertises that its AI de-escalates 48% of emergencies. And the honest limit — this asymmetry is why the system over-escalates sometimes, which is a cost I chose.

**Takeaway:** Find one judgment call in your business where the two errors cost wildly different amounts. Check whether your process treats them the same. It probably does.

**Legibility:** Universal. This is the post most likely to be shared by someone outside the industry, because the idea applies to hiring, credit, safety checks and anything else with asymmetric error costs.

---

## 6. Every rule in this system is a scar

**Format:** carousel, 8 slides · **Framework:** Value-Stack, three worked cases · **Pillar:** what software is allowed to do · **CTA:** soft — invite the question about their own systems

**Rebuilt during review.** The original framing restated build 1 post 1's reading-versus-deciding principle. **That principle belongs to build 1 and must not appear here.** This post is about where the rules come from, not what they are for.

**Hook angle:** Open on a specific line of logic that looks absurd out of context: a ceiling fan that has stopped working is not an electrical job.

**The turn:** Every hand-written rule sitting on top of the model exists because a real run produced an answer that was defensible and useless. You cannot write these in advance. They are not designed; they are discovered, one incident at a time, and the number of them is a better measure of whether something has actually been run than any accuracy figure.

**Evidence:** Three cases, each with the run that produced it.
1. **The fan.** A live test classified a stopped ceiling fan as ELECTRICAL. Defensible — a fan uses electricity. Also useless: the demo roster's electrical vendor covers one property only, so the request matched no vendor at all and reached the manager with nothing to approve. The rule now says a standalone ceiling or exhaust fan with no HVAC or electrical-hazard context is ROUTINE and APPLIANCE, which matches an all-property vendor. Sparking, smoke, burning smell, exposed wiring and breaker trouble remain electrical danger signals (`progress-notes.md`, 2026-08-13).
2. **The bucket.** A contained ceiling drip with a bucket under it stays URGENT rather than escalating to EMERGENCY, unless the water is spreading or there is a collapse or electrical risk (Stage 8 model-stability correction, 2026-08-01).
3. **The hinge.** A squeaky or noisy door stays ROUTINE unless it affects locking, closing, access, or creates an injury or security concern (same).

**Takeaway:** Ask anyone selling you an AI system how many of these they have and how they found them. A vendor who cannot produce the list has either not run it against reality or has not been watching.

**Discipline:** Do not explain why a rules layer exists at all — build 1 post 1 does that. Start from the assumption that rules exist and teach where they come from.

---

## 7. It asked for a phone number while it was talking to them

**Format:** single image — the actual message · **Structure:** image carries the claim, 100–150 words explain it · **Pillar:** failure lessons · **CTA:** none

**Hook angle:** The screenshot is the post. A live chat, mid-conversation, in which the system asks the resident for a contact number.

**The turn:** The clarification step was built from a list of fields a request needs before it can be classified. Contact details were on the list, so it asked. It was holding an open conversation on the channel it was asking for. It also asked which property they lived at, on a bot dedicated to a single known resident whose address it already had.

**Evidence:** The 2026-08-13 correction in `progress-notes.md`. The fix: the classifier now drops CONTACT from the missing-field list whenever a reply channel is already open, and asks one combined property-and-unit question only when location is genuinely missing, because vendor matching is property-specific.

**Takeaway:** Automation asks for what it was told to collect, not what it already has. If you have an intake form, there is a decent chance it is asking a resident for something you already know.

**Commentary length:** 100–150 words. The image carries it.

---

## 8. I ran the accuracy test properly and it failed

**Format:** carousel, 9 slides · **Framework:** Problem-Proof — the number nobody publishes on slide 1, the scorecard as the receipt on slide 9 · **Pillar:** what software is allowed to do · **CTA:** none

**The highest-value post in the set, and the one with the tightest honesty constraints.**

**Hook angle:** Open on the number. Thirty test messages, three runs each, roughly fifteen minutes of compute. 15.6% exact match. Six under-escalations. Ten missed safety signals.

**The turn:** The instinct is to tune the prompt until the number improves. I did not do that, because a number you tuned against your own test set is a number about your test set. What the failure actually said was that a language model should not be the last thing standing between a gas smell and a person's phone. So the life-safety decisions moved out of the model entirely, into fixed rules that run afterward and can only escalate.

**Evidence:** The full run from `progress-notes.md`, 2026-07-31: 30 fixtures x 3 runs, ~14m47s, 15.6% exact match, 6 under-escalations, 4 over-escalations, 10 missed safety signals. The structural response: deterministic escalate-only safety rules running after the model. The receipt: `docs/stage-3-scorecard.md`.

**Takeaway:** When a vendor quotes you an accuracy figure, ask what happened on the cases it got wrong, and what changed as a result. A number with no failures attached to it is a number from a test nobody tried hard enough to fail.

**Discipline — non-negotiable:** This post must not imply the system is now accurate. The passing gate it later cleared is six fixtures I chose for a demo, and the full 30-fixture hardening remains deferred. Say that in the post. The honest close is that I still will not quote an accuracy percentage, and the reason is that I know what mine came from. Any drafting that turns this into a redemption arc has broken it — the constraint is recorded in `.agents/product-marketing.md` under Proof Points.

**Why post 8 and not post 1:** Opening a cold audience with "my system failed its safety test" gives them no reason to read it as rigor rather than incompetence. By 8, the demo has shown the thing works and post 3 has established the safety posture, so the failure reads as the origin of the design.

---

## 9. What it will and won't say to a resident

**Format:** text, 250–300 words · **Pillar:** operating model · **CTA:** none

**Hook angle:** Open on the message it refuses to send: "someone will be out shortly."

**The turn:** That is the message everyone wants. It is also the one that generates the complaint, because nobody has actually confirmed it and the resident will remember it word for word when nobody arrives. The hardest part of automating resident communication is not writing the complicated message. It is refusing to write the reassuring one.

**Evidence:** The bounded set the system may send unsupervised: acknowledge receipt, ask deterministic questions for details it actually needs, answer a status question truthfully, and confirm that a provider has been contacted — but only after a manager-approved email has genuinely sent. Before that, a status question gets "this is with the manager." After it, "a maintenance provider has been contacted and an update will follow." It never states or implies an arrival time. Accommodation and legal-sensitive requests generate no draft at all and go to a person (`docs/build-description.md`).

**Takeaway:** Anything that talks to your residents needs a written list of what it is allowed to say. If the list does not exist, the list is "whatever the model thought of," and the reassuring message is exactly what a model thinks of.

---

## 10. The system emailed itself

**Format:** native video, 60 seconds · **Framework:** Hook / Body / Close, 0–3s hook · **Pillar:** failure lessons · **CTA:** none

**Hook angle:** Open on the ticket list with two requests on it that no resident sent. State that the system created them for itself and then asked the manager to approve them.

**The turn:** Vendor emails were going out of the same mailbox the system was reading for new requests. The IMAP trigger picked them back up, read them as fresh maintenance reports, created tickets, matched vendors, and sent the manager approval buttons for messages it had written. Nothing errored. It looked like a busy afternoon.

**Evidence:** The 2026-08-13 incident in `progress-notes.md`: vendor emails for `MR-0011` and `MR-0012` went out without the configured system subject prefix, were re-ingested as `MR-0014` and `MR-0015`, and produced repeated manager approvals. The fix: every system-generated email now carries a subject beginning `[MT-SYSTEM]`, vendor mail carries `[MT-SYSTEM][VENDOR]`, and inbound normalization treats the prefix as case-insensitive even when a mail client adds "Re:" or extra whitespace.

**Takeaway, aimed at them:** Anything that both reads and writes the same channel will eventually talk to itself. Shared inboxes, auto-responders, forwarding rules. It does not announce itself, because a loop looks exactly like real work until you count.

**Honesty note:** This happened in a controlled test mailbox with synthetic vendors. No real vendor received anything. Say so.

---

## 11. Nothing here gets an emergency alert for being old

**Format:** text, 200–250 words · **Pillar:** triage literacy · **CTA:** none

**Hook angle:** Open on the feature I was told to build and didn't. The original spec had an aging ladder: a routine request open ten days becomes urgent, fourteen days triggers emergency review.

**The turn:** A request that has been sitting for eleven days is a management problem. It is not a reason to make someone's phone ring at 2am, because nothing about it got more dangerous overnight. Age produces a status on a board and a line in the morning digest, and that is all it will ever produce. The reason is narrow: an alert channel that fires for things that can wait gets muted, and a muted channel does not deliver the gas smell either.

**Evidence:** The architecture rule in `AGENTS.md` — age creates OVERDUE board and digest status only, and must never trigger an emergency phone alert. Stage 8 validation specifically tested it: a backdated routine ticket rendered OVERDUE and produced zero Telegram sends from age alone.

**Takeaway:** Every alert you add makes every existing alert slightly less effective. Worth knowing which of yours fire for things that could have waited until Tuesday.

**Discipline:** Do not cite the original 10-day/14-day ladder as though it were built. It was deliberately not built, and `customer-language.md` flags it as a live risk of accidental miscitation.

---

## 12. "When will all this be fixed?" got a ticket number

**Format:** native video, 60 seconds · **Framework:** Hook / Body / Close, 0–3s hook · **Pillar:** failure lessons · **CTA:** none

**Hook angle:** A resident asks when their existing problems will be resolved. On screen, the system opens a new maintenance request and assigns it a reference.

**The turn:** It was reading everything as a report of a problem, because that is what arrives in a maintenance inbox. But most of what lands there is not a maintenance request, and a system that cannot tell the difference does not merely fail on those messages. It manufactures work, notifies a manager about it, and puts a number on something that does not exist.

**Evidence:** The 2026-08-13 defect: the status question missed a narrow arrival-only pattern and became `MR-0013`. The fix now recognises resolution, progress, update, ETA and completion language, returns one consolidated summary across the chat's open requests, and records the exchange without invoking triage at all. The post-fix run created no ticket, left the count unchanged, and produced no manager notification. The wider category, all present in the fixture corpus: out-of-office auto-replies, marketing newsletters, forwarded portal notifications, a vendor's own reply, and a resident venting with no request in it.

**Takeaway:** Anything reading an inbox needs an explicit answer for what is *not* a request, and that list is longer than the list of what is. Most systems only have the second list.

---

## 13. Where your automation gives up, and who it gives up to

**Format:** text, 250–300 words · **Pillar:** failure lessons · **CTA:** none

**Rebuilt during review.** The original framing was about the retry count, which is build 1 post 8's territory. This is about the escalation path.

**Hook angle:** Open on the rule as I first wrote it, which sounds entirely sensible: ask the resident for missing details twice, and if it still isn't clear, hand it to a person.

**The turn:** So it did. A vague report about a door burned both rounds without getting any clearer, and landed on the manager's desk still vague — which is precisely the message the manager did not want and could do nothing with. I had built an escalation path that delivered its least useful output to its busiest person. The count was never the right condition. The right condition is a state: keep asking while a specific named detail is still missing, and escalate for the reasons that genuinely need a human, which are sensitivity and ambiguity about the person, not impatience with the conversation.

**Evidence:** The two-round cap and its removal, `progress-notes.md` 2026-08-13. The current rule in `AGENTS.md`: do not treat the clarification-round count or a provisional review result as a reason to stop while mapped missing fields remain; reserve manager review for human-only or genuinely sensitive cases. The related guard: a new ticket with missing details does not invoke the manager desk at all.

**Takeaway:** Every automation has a give-up path. It usually points at whoever is busiest, and almost nobody checks what actually arrives there. Escalating something unactionable is worse than not escalating it, because now it is someone's problem and still cannot be solved.

---

## 14. What happens if you tap the button twice

**Format:** single image — the second-tap response · **Structure:** image carries the claim, 100–150 words explain it · **Pillar:** what software is allowed to do · **CTA:** none

**Hook angle:** The screenshot is the post. A manager taps approve twice, and the second tap says the request has already been handled.

**The turn:** The obvious way to build this is to send the email when the button is pressed. Press it twice and two plumbers get booked, and the second one bills for showing up. Instead the first tap claims the request by writing a row to a table with a unique constraint on it. The second tap cannot write that row, so it never reaches the part that sends.

**Evidence:** `triage.vendor_send_attempts`, unique per ticket. Only the first valid callback can claim a request; the double-approve guard was validated in Stage 6 and again in Stage 9. It is four lines of schema.

**Takeaway:** Ask any vendor what happens if someone taps twice, or if the network drops halfway through. It is a small question and the answer tells you whether anyone thought about the day it goes wrong. "Nobody has tried that" is a real answer you will sometimes get.

**Commentary length:** 100–150 words.

---

## 15. Send me a week of your maintenance inbox

**Format:** text, 250–300 words · **Structure:** `offers` skill — what they get, what it costs them, what makes it safe to say yes · **Pillar:** the ask · **CTA:** real

**Hook angle:** Open on what I don't need: access to your PMS, a project plan, or a budget conversation.

**The turn:** Forward me about twenty maintenance messages from a normal week with names and addresses removed. I will run them and send back what your week would have looked like sorted — what would have been flagged an emergency, what would have sat, what needed a detail nobody asked for, and what it got wrong. That last part is included on purpose.

**Evidence:** The honest boundaries, stated before anyone asks. It does not touch your PMS and does not create a single work order, so the data entry is still yours. It is a demo-depth build, not a production deployment. The passing accuracy figures I have come from six messages I selected, and the broader test is still unfinished. Data handling: what I receive, where it goes, how long it stays, and when it is deleted.

**Takeaway:** The first useful output is a picture of where things actually stand on a normal week, and getting there takes days rather than a quarter.

**Data handling:** Address it in the post, briefly and unprompted. Asking someone to forward real resident messages to a stranger is the moment the objection becomes real, and naming the retention terms before being asked turns the weakest moment into another proof point.

**Discipline:** This is the only post that asks. Nothing in posts 1–14 sells.

---

# Sequencing and cadence

**Publishing order is the numbering above.** Posts 1, 2 and 3 go up before driving anyone to the profile.

The sequence alternates weight deliberately: no two carousels adjacent, no two videos adjacent, and the two cheap image posts (7 and 14) sit after dense ones. Post 8 is placed after the demo and the safety-posture post have earned it.

**Cadence:** one a week to start, rising to two or three as the audience shifts. Fifteen posts is roughly four months at one a week.

**If build 1 runs concurrently:** interleave so no two consecutive posts come from the same system, and drop post 4.

# Voice and checks

**Register:** incident report. Investigate, report precisely, state impact without drama, don't oversell. Short declaratives, real numbers, understated conclusions, first person singular, US spelling.

**Banned:** hype vocabulary (game-changer, unlock, leverage, seamless, powerful, revolutionize, robust, streamline, effortless). LinkedIn broetry — one line per paragraph. "Let that sink in." Rhetorical questions as openers, though they're fine mid-post. Emoji. Any selling in the body of a post that isn't 15.

**No hashtags on LinkedIn posts.** Not "3–5 maximum" — zero. LinkedIn disabled hashtag pages in October 2024 and removed hashtag following, so they no longer distribute anything. What remains is a topical signal telling the algorithm which audience a post belongs to, which makes `#ai` and `#automation` actively harmful to a plan whose stated goal is fewer developer comments and more property manager ones. Build 1's finished scripts use none. YouTube hashtags are a separate mechanism and are kept, since the first three still render above the video title as working links. Full reasoning is recorded in `linkedin-post-scripts.md`.

**Checks before publishing any draft:**

| Check | Standard |
|---|---|
| Accuracy claims | Zero percentages across the full fixture set. Zero implication of production-grade reliability. Post 8's constraint is absolute |
| Overclaim vocabulary | Zero: "handles it automatically," "never misses an emergency," "replaces your answering service," "maintenance management system" |
| Request vs work order | Never blurred. The system stops before the work order and the copy says so wherever it could be misread |
| Response targets | Never called a deadline or an SLA. Never presented as a legal window |
| Competitor claims | Quoted accurately from `customer-language.md` sources, never paraphrased into something worse. No disparagement. The anti-persona is named honestly |
| Product language | Nothing implying a tool being sold. It's work done inside a client's business |
| First 210 characters | Must stand alone and earn the expand. Measure by truncating, not by eye |
| Length | Text 150–300 words · carousel slides under 25 words · video voiceover 150–200 words per 75 seconds |
| Factual trace | Every number, rule and incident resolves to a named file, commit, or cited source |
| Em dashes | At most one per post. The single most reliable AI tell and the hardest to notice while writing. Use commas, colons, or parentheses |
| AI writing tells | Run the full list in `seo-audit/references/ai-writing-detection.md`: banned openers ("in today's", "let's delve"), transitions ("that being said", "at its core"), closers ("in conclusion", "at the end of the day"), and structural patterns ("it's not just X, it's Y", "whether you're a X, Y, or Z", sentences opening with "By" plus a gerund) |
| Sentence length variance | Not every sentence the same length. Uniform rhythm reads as machine-written even when the words are clean |
| Build 1 collision | Posts 3, 6 and 13 checked against build 1's posts 1, 3, 8 and 13. The rebuilt framings must hold |
| Read aloud | Anything that can't be said out loud without embarrassment gets cut |

# Out of scope

- Scripts. This plan is briefs only; finished copy goes in `linkedin-post-scripts.md`.
- The full-length demo recording. That belongs in the profile Featured section as uploaded media, which does not create a feed post. Only the 2–3 minute cut is post 2.
- Anything requiring real client data, real resident messages, or a testimonial. None exist.
- Content for builds 3 and 4. The same structure will apply.
