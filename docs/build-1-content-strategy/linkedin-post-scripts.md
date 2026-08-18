# LinkedIn Post Scripts

Finished copy for the 15 posts briefed in `docs/linkedin-content-plan.md`.

**Revised 2026-08-17.** Seven posts were rebuilt after an audit against the question "would a property manager learn something and keep this." Posts 1, 4 and 9 were replaced outright, because they taught the reader nothing they did not already know. Posts 8, 12, 13 and 14 kept their evidence and changed their subject, from what my build does to what the reader can check in their own business. Post 2 was later replaced to show the actual Stage 9 maintenance-triage demo, rather than the retired vendor-certificate workflow. The plan's pillar and format allocation was rewritten at the same time, and the reasoning is recorded at the top of `linkedin-content-plan.md`.

The batch headings below record the order things were written, not the publishing order. Publish in numerical order.

Register: incident report. Short declaratives, real numbers, understated conclusions, first person singular, US spelling.

Every post below has been checked for: zero banned words (compliant, verified, covered, approved in a claiming sense), at most one em dash, the AI tells in `seo-audit/references/ai-writing-detection.md`, a first 210 characters that stands alone, and varied sentence length.

**Standing note on COI and lapse.** `docs/customer-language.md` says use COI unexpanded and lapse for expiry. Both apply from post 6 onward. Posts 1 to 5 are the gateway posts, which the plan requires a non-industry reader to follow without jargon, so those spell the document out and use plain expiry language. Posts 6, 7, 8 and 10 were corrected to COI and lapse after the first pass missed it.

**One standing note on "approve."** The word appears in two posts as the verb for a person authorizing an email to be sent. It never appears as a claim about a vendor or a certificate. Post 2 makes the distinction out loud: the manager approves one drafted email, not the vendor or a dispatch decision. If you would rather it never appear at all, the substitutions are marked in each post's notes.

---

# Batch 1: Posts 1, 2, 3

---

## Post 1. What AI should do with your paperwork, and what it must never touch

**Format:** document carousel, 8 slides. **Framework:** principle, then mechanism, then application. **Pillar:** AI buying literacy. **CTA:** soft.

**Document title (58-char limit):** `What AI should read, and what it should never decide` (52 chars)

**Rebuilt 2026-08-02.** Replaces "What a property manager actually does all day," which taught a property manager nothing they don't already live.

**On the framework.** The plan originally labelled this Problem-Proof. It isn't. Problem-Proof needs a numbered claim on slide 1 and a real artifact as the receipt on the last slide, and this post has neither. Relabelled honestly rather than bolting on a fake number and a screenshot that would have to be invented. The framework files say to adapt the structures, not to satisfy their labels.

### The post copy that sits above the document

> Every AI pitch you sit through this year will blur two different jobs: reading a document, and deciding what to do about it.
>
> Only one of those should ever go to a model.
>
> A model that reads wrong is checkable. The document is right there and you can look at it. A model that decides wrong is invisible, because there is nothing to hold the decision against. It produces an answer, and the answer looks exactly like every other answer.
>
> So in the vendor paperwork system I built, the model has one job. It transcribes what the certificate says and rates its own confidence high, medium or low. Every decision after that is fixed logic that runs identically every time. Is the expiration after the effective date. Is there a general liability line. Does the holder match one of your legal names. The model is never asked whether a certificate is acceptable, because that is a decision.
>
> Eight slides on where that line sits in the thing I built.
>
> If someone is selling you AI right now: what does the model decide? If the answer is anything other than nothing, ask how you would ever find out it was wrong.

*Word count: 216. Em dashes: 0. First 210 characters end on "A model that reads wrong is che", with the two-jobs distinction fully made and the reason withheld.*

### Slides

**Slide 1 (cover)**

> Reading a document and deciding what to do about it are two different jobs.
>
> Only one of them should go to AI.

**Slide 2**

> A model that reads wrong is checkable. The document is right there.
>
> A model that decides wrong is invisible.

**Slide 3**

> So the model gets one job: transcribe what the page says. Vendor, carrier, policy number, limits, dates. And rate its own confidence.

**Slide 4**

> Every decision after that is fixed logic. Same inputs, same answer, every single time.
>
> No judgment. No drift. No bad day.

**Slide 5**

> What the rules decide: is the expiration after the effective date. Is there a general liability line. Does the holder match your legal name.

**Slide 6**

> What the model decides: nothing.
>
> It is never asked whether a certificate is acceptable. That question never reaches it.

**Slide 7**

> When the model says it isn't sure, the row goes to a person.
>
> "Unsure" is an answer. Guessing is not.

**Slide 8 (close)**

> Ask any AI vendor what the model decides.
>
> If the answer isn't "nothing," ask how you'd ever find out it was wrong.

*Longest slide: 24 words. Slide 1 states the split, slide 6 delivers the payoff, slide 8 converts it into something the reader can use on somebody else.*

### Alternative cover lines

- "There are two jobs inside every AI document pitch, and they get deliberately blurred."
- "AI should read your paperwork. It should never decide anything about it. Here's the difference."
- "The question that cuts through any AI demo: what does the model actually decide?"

### Production note

Slides 5 and 6 are the pair the whole carousel turns on, and slide 6 is the shortest by design. Give it the most white space in the deck. Same template as the other three carousels, no icons, no accent color doing emotional work.

### Facts traced

- **The split is real and is the system's central design decision.** `docs/how-the-system-works.md`, "Why The Reading And The Checking Are Separate": the AI reads, the rules decide, and the model is never asked whether a certificate is good enough.
- **What the rules check**, verbatim in behavior from `scripts/lib/coi-stage-4-validator.js`: date order, expiry plausibility, presence of a general liability line, holder match against accepted legal names, limits against the per-trade minimum.
- **The confidence route.** `LOW_CONFIDENCE` is a hard flag, so a model that says it is unsure sends the row to review rather than producing a number.

### Notes

- This post now carries the gateway job that the old post 1 carried, and it does it better, because it establishes the audience and demonstrates judgment in the same breath rather than just describing their week back to them.
- Publish first, as before. Posts 2 and 3 assume the reader has met this argument.

---

## Post 2. The demo: three ways in, one manager decision

**Format:** native video, 2 minutes 35 seconds. **Pillar:** proof. **CTA:** soft.

Scene structure follows `docs/operating-guide.md`, cut down from the live Stage 9 walkthrough. Screen recording throughout. No face, no intro card, no music.

### The post copy

> Three maintenance requests enter this demo in three different ways: an email, a form, and a Telegram conversation. Each reaches the same manager decision point, not three places to sort.
>
> The Telegram part is the useful test. "There is a problem in my bathroom" is not enough to send someone out. The bot asks for the symptom. It does not create a request, alert the manager, or pretend it knows what the problem is. When the resident says the faucet is dripping, it creates one request using the conversation so far.
>
> Then the workflow classifies the request, keeps the manager workspace up to date, finds vendors who cover that property and trade, and drafts the email. A manager chooses whether to send it. One tap releases one email.
>
> It stops before the work order. It does not select a vendor by itself, promise an arrival time, or close a request. That is the point.
>
> Here is the live walkthrough, using synthetic data.

*Word count: 162. Em dashes: 0. First 210 characters establish the three intake routes and the manager outcome without relying on the video.*

### Shot list and voiceover

Timings are cumulative. Read at an unhurried pace, roughly 130 words per minute. Total 314 words across 2:35, which sits inside the 150 to 200 words per 75 seconds range.

**Shot 1. Start clean. 0:00 to 0:12**

*Screen: Airtable `Requests` view, empty after the demo reset. Hold for two seconds, then switch to the shared Gmail mailbox.*

> "Three requests are about to arrive through three different channels. Email, a web form, and Telegram. This is the manager's workspace. It starts empty, with no old requests left over from an earlier test."

**Shot 2. Email intake. 0:12 to 0:34**

*Screen: Send a synthetic email describing water leaking from the pipe under a kitchen sink. Cut to Airtable only after the request row appears. Briefly show the `[MT-SYSTEM]` onboarding email arriving in the controlled mailbox.*

> "First, an email. It describes water leaking from a pipe under the kitchen sink. The workflow reads the request, assigns a reference, classifies the trade and priority, and writes the result here. It also sends one Telegram pairing link. That system email is marked so the shared mailbox cannot read its own message as a new request."

**Shot 3. Form intake. 0:34 to 0:54**

*Screen: Submit the synthetic web form for a failed ceiling fan. Cut to Airtable showing the second request and source field. Do not wait long enough to show an unrelated email notification.*

> "Second, the same process through a form. A stopped ceiling fan becomes another request, with the intake source shown alongside it. The manager does not need to remember which inbox it came from. It records the channel, not a separate process."

**Shot 4. Telegram clarification. 0:54 to 1:29**

*Screen: Tenant Telegram chat. Send "There is a problem in my bathroom." Show the focused symptom prompt. Send "It started yesterday and is getting worse." Show that it asks again. Send "The bathroom sink faucet is dripping constantly." Then cut to the single new Airtable request.*

> "The third route is the one I wanted to test properly. The resident starts vaguely: there is a problem in my bathroom. Then says it started yesterday and is getting worse. Neither message creates a ticket, because neither names a maintenance symptom. When they say the sink faucet is dripping, it creates one request from the conversation so far. No duplicate requests. No premature manager alert."

**Shot 5. Manager decision. 1:29 to 2:03**

*Screen: Manager Telegram alert for the plumbing request. Show request reference, summary, matched vendor button, Hold, and the drafted email preview. Keep the Airtable request visible in a second window only if legible.*

> "Once the request is complete, the manager gets the decision point. The alert shows the issue, the matching vendor, and the exact email it would send. The manager can choose that vendor or hold it. The workflow does not dispatch anyone. It does not decide that the vendor is right."

**Shot 6. One approved email. 2:03 to 2:21**

*Screen: Tap the actual vendor button once. Cut to the controlled Gmail sent message, then the tenant Telegram update and Airtable send state.*

> "One tap releases one email. After the SMTP send succeeds, the resident gets a factual update: a maintenance provider has been contacted. The database prevents the second tap from sending that email twice."

**Shot 7. The boundary. 2:21 to 2:35**

*Screen: Tenant Telegram chat. Send "When will all this be resolved?" Show the single consolidated status reply. Keep the reply and open Airtable records on screen.*

> "Last check. A status question gets a status answer, not another request or an invented arrival time. This is where the automation stops: it sorts, asks, drafts, and records. The manager still decides."

### Burned-in caption notes

- **Captions on every second of it.** LinkedIn autoplays muted, and shots 4 and 7 carry the argument.
- Burn them in rather than relying on the platform's auto-captions. Bottom third, high contrast, two lines maximum, no animation.
- Terms that need to be right in the captions: **Airtable**, **Telegram**, **SMTP**, **work order**.
- **Add one persistent corner label** for the first ten seconds only: "Synthetic maintenance data." Every name, request, and vendor email on screen is controlled demo data.
- Show the `Requests` and `Conversations` tables only at a readable scale. Do not show raw Postgres or n8n execution data in the finished cut.
- Blur the controlled mailbox address and Telegram chat IDs when visible.

### Alternative opening lines for the post copy

- "The same maintenance request can arrive in an inbox, a form, or a chat. The manager should not have to triage it three times."
- "A vague resident message is not a work order. It is the start of a conversation."
- "I tested the part most maintenance automation skips: what happens before a request is clear enough to send on."

### Notes

- If you would rather the word "approve" never appear: shot 6 becomes "One tap releases one email." The line as written is stronger because it makes the limited decision explicit.
- Reset local demo state immediately before recording: `./scripts/reset-demo.ps1 -Apply`. Use only the controlled mailbox and synthetic Airtable roster.
- Facts traced: three intake routes, Telegram clarification, Airtable manager workspace, vendor selection, one-send-only, and status boundaries from `docs/operating-guide.md` and `docs/build-description.md`. The six-fixture rehearsal is not shown and no broad accuracy claim is made.

---

## Post 3. Five things I would refuse to automate

**Format:** text. **Skeleton:** List Post, closer cut. **Pillar:** honest limitation. **CTA:** none.

### The post

> There is work in property management I would turn down, and the money spends the same as any other work.
>
> Five of them.
>
> Anything that decides which vendor gets dispatched. Software can sort by rating, price, and who picked up last time. It should not choose who goes to a property, because whoever chooses is whoever answers for it afterwards.
>
> Anything that sends a legal notice on a timer. A notice that goes out on day four because a rule said day four is a notice nobody read first. These carry legal weight in every state and they should cost somebody thirty seconds of attention.
>
> Anything that judges a tenant. Scoring an application, ranking a person, flagging a resident as a problem. I do not want a model near that decision, and you should not want one either.
>
> Anything that tells an owner the money is fine. An automated reassurance is the most expensive sentence in this business to get wrong, and it gets sent monthly.
>
> Anything that decides a vendor is insured. This one is closest to home. I built a system that tracks vendor certificates, and it will not say a vendor is insured. It reports what the document says and the date printed on it, and then it stops. A certificate describes the day it was issued. Nothing about it survives contact with what happened next.
>
> Every one of these is buildable. That is the whole point. The limit was never technical.
>
> The person you want building this is the one who tells you what not to build.

*Word count: 262. Em dashes: 0. First 210 characters cover the opening line and "Five of them," which is enough of a promise to earn the expand.*

### Alternative opening lines

- "I have turned down automation work in this industry, and I would do it again for the same five reasons."
- "Five things in a property management business that I will not automate. Not because they are hard. Because being wrong costs the wrong person."
- "Everything below is buildable in a week. That is exactly why I won't build it."

### Notes

- The fifth item is the one that does the work. It applies the standard to my own build rather than to a hypothetical vendor, which is the only version of this post that isn't cheap.
- No CTA, deliberately. The post's job is to be trusted, not to convert.
- Facts traced: the refusal list and the certificate boundary come from `docs/how-the-system-works.md`, sections "What It Deliberately Refuses To Do" and "What It Genuinely Cannot Do."

### Flagged as my invention

- **"These carry legal weight in every state."** Directionally correct and deliberately unquantified, but it is my assertion rather than a cited one. If you want it airtight, narrow it to "These have legal consequences" and lose nothing.
- **"day four"** is illustrative, not a real notice period from any statute. It reads as an example, but if it reads to a property manager as a specific rule I got wrong, change it to "on a schedule."

---

# Batch 2: Posts 4, 7, 13 (the carousels)

---

## Post 4. What it actually costs to have AI read a document

**Format:** document carousel, 7 slides. **Framework:** Problem-Proof through slide 3, then a reframe close. **Pillar:** AI buying literacy. **CTA:** none.

**Document title (58-char limit):** `What it actually costs to have AI read a document` (49 chars)

**Rebuilt 2026-08-02.** Replaces "The four-minute problem," which did arithmetic on something the reader already knows better than I do, and was a business case for hiring me wearing a teardown costume.

### The post copy that sits above the document

> Having AI read a vendor insurance certificate, and pull out every date, limit, carrier and policy number, costs about two tenths of a cent.
>
> Not two dollars. Not twenty cents. About $0.002.
>
> A certificate is one page of mostly tabular text. A forty-page lease is twenty times the material. At thirty certificates a month, the model cost is under a dime.
>
> That is not an accusation aimed at anyone. Hosting is real, support is real, product work is real, and any one of those can justify a monthly fee on its own.
>
> It is a question worth asking, though. If the reading is the cheap part, what is the rest of the price buying? Because that is the part you are actually being sold, and it is the part nobody puts on a pricing page.
>
> Seven slides on where the money in an automation really goes.

*Word count: 163. Em dashes: 0. First 210 characters end on "Not two dollars. Not twenty cents. About $0.002," which is the whole hook and a number nobody expects.*

### Slides

**Slide 1 (cover)**

> Having AI read a vendor insurance certificate costs about two tenths of a cent.
>
> Not two dollars. $0.002.

**Slide 2**

> A certificate is one page of mostly tabular text.
>
> A forty-page lease is twenty times the reading.

**Slide 3**

> Thirty certificates a month.
>
> The model cost is under a dime.

**Slide 4**

> That isn't an accusation. Hosting is real. Support is real. Product work is real. Any of them can justify a fee.

**Slide 5**

> But if the reading is the cheap part, what is the rest of the price buying?

**Slide 6**

> You're paying for what happens after the reading. Which decisions are automatic, which stop for a person, and what the thing refuses to do.

**Slide 7 (close)**

> Price the judgment, not the reading.
>
> The reading was never the expensive part.

*Longest slide: 23 words. Slide 1 opens the loop with the number, slide 3 lands the total, slide 5 turns it into the reader's question.*

### Alternative cover lines

- "Two tenths of a cent. That's what it costs to have AI read a vendor certificate."
- "The AI is almost never the expensive part of an AI product. Here's the arithmetic."
- "Before you accept a quote for AI document processing, here's what the AI part costs."

### Production note

Slides 1 and 3 are pure numerals and should be set as such: the figure at display size, the sentence beneath it small. Slide 5 is a question on an otherwise empty slide. That pacing, three number slides then a question, is what makes the swipe work.

### Facts traced

- **$0.002 per certificate** for LLM extraction, and **under $0.10 a month at 30 certificates**. `01-vendor-coi-chase.md`, "Cost to run."
- **800 to 1,200 tokens per certificate against a 40-page lease at 20,000+.** `01-vendor-coi-chase.md`, "Why the document is easy," which explains it: the form is one page of mostly tabular text with the same boxes in the same places.

### Discipline, and this one is important

**Never put my own pricing or margin in this post**, and do not answer comments that fish for it. `01-vendor-coi-chase.md` contains both a price range and a margin figure. The moment this post becomes a comparison to what I charge, it stops being a buyer tool and becomes an undercut, and competing on price contradicts the entire positioning.

The honest, defensible position if someone pushes in the comments: the model cost is a rounding error, which is exactly why the price of any automation reflects the decisions built into it rather than the compute. That answer is true, it is on-message, and it does not disclose anything.

### Flagged as my invention

- **"nobody puts on a pricing page"** in the post copy is my characterization, not something sourced. It is fair and easily defended, but it is an assertion about other vendors, so be ready to stand behind it.

---

## Post 7. Twelve things that can be wrong when a COI arrives

**Format:** document carousel, 11 slides. **Framework:** Value-Stack. **Pillar:** honest limitation. **CTA:** none.

**Document title (58-char limit):** `Twelve things that can be wrong when a COI arrives` (50 chars). Reused from the cover slide rather than written separately, so the title and the first thing the reader sees say the same thing.

**Revised 2026-08-03.** Two changes, both found while building the carousel.

The old slide 4 claimed "All seven go to a person." Two of the seven never reach one: `NOT_A_COI` and `OLDER_THAN_ON_FILE` short-circuit to their own ignore dispositions in `buildResult` before the hard-flag branch that sets `NEEDS_REVIEW`. The line is now accurate, and the correction is more interesting than the error, because "stop everything" turning out not to mean "fetch a human" is the sort working.

A new slide 2 states the principle behind the split. It was only ever in the post copy, and the post copy does not travel with the document — the PDF is what gets shared, and inside it the reader met seven stop-cold items that look milder than the five filed ones with no explanation offered. Slide 9 asserts the sorting is the work; now something earns it.

**Cover widened 2026-08-03.** Was "Twelve things that can be wrong with a COI," which promised narrower than the list delivers. Three of the twelve are not defects in a certificate at all: a document that is not a certificate, one already superseded by a newer certificate on file, and a vendor name a keystroke off an existing vendor, where the ambiguity is on your side rather than the document's. Two more, an unreadable scan and a password-protected file, are properties of the copy you received rather than of the certificate. "When a COI arrives" frames the moment rather than the document, and every one of the twelve fits it. The alternative cover lines were rewritten for the same reason, and the third also carried the "seven need a person" error.

**Slide 10 given a subject, 2026-08-03.** Was "Anything can flag everything." In the post copy that line lands, because the sentence before it supplies the referent. On a slide it opens cold, and "anything" leaves the reader working out whether it means any tool, any person or any process before the point arrives. Naming the subject fixes it in one word and keeps the short opener the slide's rhythm depends on. The post copy keeps "Anything," which is correct there and needs no help.

### The post copy that sits above the document

> A COI is one page. That's the trap. It looks like a document you can check by looking at it.
>
> There are twelve specific things I check for, and they're sorted by what should happen next rather than by how alarming they sound. Seven stop the process, and most of them get a person involved. Five get filed with a note attached that stays visible on the row.
>
> The split is the part that matters. A process that treats a password-protected file the same as a limit slightly under your minimum is a process people learn to ignore inside a month. Anything can flag everything. Sorting by severity is the actual work, and it's the part that gets skipped.
>
> All twelve are in the slides. None of them tell you whether the vendor is actually insured. That's a different question and a certificate cannot answer it.

*Word count: 152. Em dashes: 0. The fold lands after "check by looking at it," so the trap is stated and the count is still ahead of the reader.*

### Slides

**Slide 1 (cover)**

> Twelve things that can be wrong when a COI arrives.
>
> Seven should stop you. Five should just get written down.

**Slide 2**

> Seven mean you don't have a certificate you can use.
>
> Five mean you do, and it falls short.

**Slide 3**

> Seven that stop everything.
>
> 1. Expiration date falls before the effective date.
> 2. A date nowhere near believable.
> 3. Too unclear to read confidently.

**Slide 4**

> 4. Not a certificate at all.
> 5. Older than the one already on file.
> 6. Vendor name one keystroke off an existing vendor.

**Slide 5**

> 7. The file is password protected and cannot be opened.
>
> Five go to a person. Two need no one. None of them get a guess.

**Slide 6**

> Five that get filed, with a note.
>
> 8. The certificate holder isn't one of your legal names.
> 9. A limit under your minimum for that trade.

**Slide 7**

> 10. No general liability line on the document.
> 11. No workers' comp line, unless that vendor is marked exempt.

**Slide 8**

> 12. A renewal that starts after the old policy lapsed, leaving a gap between two certificates that both look fine.

**Slide 9**

> Seven stop the process. Five get written down and stay visible.
>
> The sorting is the actual work.

**Slide 10**

> Any tool can flag everything.
>
> A process that treats all twelve the same is a process everyone learns to ignore.

**Slide 11 (close)**

> None of the twelve tells you whether the vendor is actually insured.
>
> That's a different question, and the certificate can't answer it.

*Longest slide: 24 words, now slide 5. Cover promises twelve, slides deliver exactly twelve numbered items, split exactly seven and five. Slide 2 states the principle before the reader meets a single item, because the objection forms while reading the lists, not after.*

### Alternative cover lines

- "Twelve ways a COI can arrive unusable. Only seven of them should stop anything."
- "A one-page document with twelve possible problems, and the hard part isn't finding them."
- "Seven problems that stop a COI cold. Five that just need writing down. Here are all twelve."

### Production note

Slides 2 to 4 and slides 5 to 7 need to read as two distinct groups at a glance, without color doing the work on its own. A thin rule above the group label and consistent left alignment of the numbers will carry it. If you use color, keep it to one muted accent on the stop-cold group and nothing on the other, matching the amber note treatment on the dashboard.

Slide 10 wants more white space than any other slide. It is the one people screenshot.

### Facts traced

Every one of the twelve is a real flag with the severity shown, from `scripts/lib/coi-stage-4-validator.js`:

- **Stop-cold (hard, 7):** `DATE_INVERTED`, `DATE_IMPLAUSIBLE`, `LOW_CONFIDENCE`, `NOT_A_COI`, `OLDER_THAN_ON_FILE`, `POSSIBLE_DUPLICATE_VENDOR`, `PDF_PASSWORD_PROTECTED`
- **Filed with a note (soft, 5):** `HOLDER_MISMATCH`, `LIMIT_BELOW_MINIMUM`, `NO_GL_LINE`, `NO_WC_LINE`, `COVERAGE_GAP`

Per the brief, `MODEL_REFUSED` and `MODEL_OUTPUT_INVALID` are excluded. They are real hard flags, but they describe the model misbehaving rather than the document being wrong, and including them turns a list a person can hand-check into a spec sheet. The third severity, `NO_CANCELLATION_NOTICE_WORDING`, is a neutral note rather than a problem, so it is also out. The count of twelve is exact and holds.

The workers' comp exemption on slide 7 is real: the flag is suppressed for vendors marked exempt (`docs/how-the-system-works.md`).

**Hard does not mean dangerous, and slides 2 and 5 depend on this.** In `buildResult`, a hard flag routes to `store_needs_review` / `NEEDS_REVIEW` — except `NOT_A_COI` and `OLDER_THAN_ON_FILE`, which are tested first and get `ignore_not_certificate` and `ignore_older_than_on_file` with a null status. So five of the seven reach a person and two are closed without one. The unifying property of all seven is that no usable certificate comes out of them, not that they are the worst outcomes. The five soft flags are the opposite case: the document read cleanly and what it says falls short of your requirement. Anyone challenging the sort in the comments is challenging that distinction, and it is the defensible one.

### Production note on the severity split

Do not restore severity language to the group labels without restoring slide 2 with it. "Stop everything" and "filed with a note" describe consequences, and a reader maps consequence onto danger — at which point the deck appears to halt on a password-protected file while merely noting that a vendor has no general liability line. That objection is correct on its face and is only answered by the principle slide.

### Flagged as my invention

- **"people learn to ignore inside a month"** in the post copy. Alert fatigue is well established generally, but the one-month figure is mine and unsourced. Change to "learn to ignore" and lose nothing if you would rather not carry it.

---

## Post 13. The questions to ask anyone selling you automation

**Format:** document carousel, 8 slides. **Framework:** Problem-Proof, with a question hook in place of the numbered claim. **Pillar:** AI buying literacy. **CTA:** soft.

**Document title (58-char limit):** `The questions to ask anyone selling you automation` (50 chars)

**Reframed 2026-08-02.** The material was right and the subject was wrong. Written as my operating model it made the reader a spectator. It is now a purchasing tool, and my build is the worked answer rather than the topic.

### The post copy that sits above the document

> Most people ask an automation vendor how accurate it is. It's the wrong question, or at least the second one.
>
> Accuracy is a spectrum and every honest answer is a number below 100. It tells you how often the thing will be wrong. It tells you nothing at all about what happens when it is.
>
> The question that decides your exposure is what it can do without a person seeing it first. That isn't a spectrum. It's a line somebody drew on purpose, and you can ask to see exactly where it sits.
>
> Eight slides of questions to take into your next demo, with the answers from my own build so you can hear what a specific answer sounds like. A vague one is the finding.
>
> The one that matters most: what can it send, change, or decide without you? If nobody can answer that in a sentence, the line hasn't been drawn.

*Word count: 178. Em dashes: 0. First 210 characters end on "It tells you how often", holding back the half of the sentence that carries the argument.*

### Slides

**Slide 1 (cover)**

> "How accurate is it" is the wrong question to ask an automation vendor.
>
> Here's the one that decides your exposure.

**Slide 2**

> Accuracy tells you how often it will be wrong.
>
> It tells you nothing about what happens when it is.

**Slide 3**

> Ask instead: what can it send, change, or decide without a person seeing it first?
>
> That's not a spectrum. It's a line somebody drew.

**Slide 4**

> My answer, so you know what specific sounds like.
>
> On its own it reads, extracts, sorts, flags, drafts, and tells a person.

**Slide 5**

> On its own it cannot contact anyone outside the company, set a status that implies judgment, or decide anything a person answers for.

**Slide 6**

> Every outbound email waits for a person to click approve.
>
> No click within 24 hours and it expires unsent.

**Slide 7**

> While it's being built, outbound redirects to a test address.
>
> A real vendor cannot be emailed by accident.

**Slide 8 (close)**

> Vendor. Reason. Recipient. The exact message. Two buttons.
>
> This is what a drawn line looks like.

*Longest slide: 24 words. Slides 4 and 5 are a matched pair and must use identical layout, so the only difference between them is the words.*

### Alternative cover lines

- "There's a better question than 'how accurate is it,' and almost nobody asks it."
- "What can it do without you seeing it first? Take that into your next demo."
- "Accuracy is a spectrum. Permission is a decision. Only one of them is written down anywhere."

### Production note

**Superseded 2026-08-04. Owner's call: no screenshot, and no image anywhere in the deck.** Slide 8 is typed copy, set on the deck's one inverted slide so the close carries the weight the artifact would have. The five things the email contains are stated rather than shown, in prose rather than in pills or a framed panel, because a mocked-up interface on a post about not faking your evidence is worse than no artifact at all. Read the paragraph below for what the screenshot was doing, because the cost of dropping it is real and is now carried by the copy alone.

The original note, kept because the reasoning still stands and may be worth revisiting:

> **Slide 8 is a real screenshot, not typed copy.** It is the receipt the carousel is built toward, and a mocked-up version undoes the post. Capture the actual approval email: vendor name, reason, intended recipient, drafted message, both buttons, all in one frame. Redact the mailbox address. Crop tight enough to read at thumbnail size and set the caption beneath the image rather than over it.
>
> I removed this slide in the 2026-08-02 reframe and put it back after a voice sweep. Two reasons. It is the element that makes the framework work, and without it slide 8 closed on "ask where the line is drawn, if nobody can say it in one sentence it hasn't been," which is the same construction as post 1's closing slide. Two carousels ending on an identical shape is what makes a set read as templated. The artifact also serves the buyer-tool framing perfectly well: this is what a specific answer looks like when someone actually has one.

**What the deck gives up.** Problem-Proof wants a real artifact as its receipt, and this deck no longer has one, so "This is what a drawn line looks like" now points at the list above it rather than at evidence. The framework label is still fair, because slides 4 to 7 are specific and checkable claims about a real build, but the proof is testimony rather than exhibit. If a real capture ever becomes available, slide 8 is where it goes.

### Facts traced

All from `docs/how-the-system-works.md` and `progress-notes.md`:

- **Approval gate and 24-hour expiry.** The request waits up to 24 hours and expires rather than sending. Default behavior, not a setting someone has to remember.
- **Outbound redirected during setup.** `stage_6_outbound_test_mode` defaults to true, so sends are redirected to a test recipient (`progress-notes.md`, Open Behaviour Findings). Slide 7 says "while it's being built" deliberately, because the same note flags that it must be switched off before real use. Do not let the slide imply it stays on forever.
- **What it does unattended.** Read, extract, sort, flag, draft, notify. All confined to transcription and deterministic rules.

### Notes

- If you want "approve" gone entirely, slide 6 becomes "waits for a person to release it." The word does real work here and is never used about a vendor.
- The closing question in the post copy is the soft CTA. Post 15 carries the only real ask.

---

# Batch 3: Posts 5, 6, 8, 10 (the text posts)

**A naming rule applied across this batch.** `coi-demo-build-plan.md` section 1.5 says to write "standard certificate of liability insurance forms" rather than "ACORD 25" in written marketing, and never to imply affiliation. Posts 6 and 10 are the two that would naturally reach for the name. Neither uses it. They cite the form's own printed text and the Texas Department of Insurance instead, which is stronger evidence anyway and carries no trademark question.

---

## Post 5. I don't sell software

**Format:** text. **Skeleton:** Contrarian Take, closer cut. **Pillar:** operating model. **CTA:** none.

### The post

> There is nothing to log into.
>
> No seats, no per-user pricing, no monthly fee for a dashboard somebody opens twice and then stops opening. I don't sell software, and the distinction matters more than it sounds like it should.
>
> What I build runs inside the business that already exists. It reads the mailbox you already have. It writes to a database you own. It sends from your address, not mine. Your vendors keep emailing the same person they have always emailed, and nobody has to be told to start using anything.
>
> That last part is the whole argument. Every product in this category is a portal, and the category's own marketing will tell you what goes wrong with portals: vendors find them cumbersome, get discouraged, and stop cooperating. You end up chasing vendors about the system you bought to stop chasing vendors.
>
> When the work is finished it belongs to you. The database, the workflows, the documents, all of it. Export it, hand it to another developer, carry on. If we stop working together it keeps running, because there is no service of mine sitting in the middle of it waiting to be switched off.
>
> This is a different transaction from buying a tool. You are not adopting a product. You are getting one specific part of your operation handled.

*Word count: 231. Em dashes: 0. First 210 characters end mid-sentence on "matters more than it sounds like it s", with the negative fully stated and the reason withheld.*

### Alternative opening lines

- "I have nothing for you to log into, and that is the product."
- "No seats. No subscription. No portal for your vendors to forget the password to."
- "The thing I sell has no login screen, which makes it hard to explain and easy to keep."

### Notes

- The portal failure claim traces to `docs/customer-language.md`: the category's own documented failure mode is that vendors get "discouraged by a cumbersome compliance process" and it "sours the working relationship." That is drawn from competitor marketing, which is what makes it usable. They said it, not me.
- No CTA. This post's job is to correct an assumption, and an ask at the end would confirm the assumption it just corrected.

### Flagged as my invention

- **"You end up chasing vendors about the system you bought to stop chasing vendors."** This is a logical consequence of the sourced complaint rather than something a property manager said. It is the most quotable line in the post, so it is the one most worth testing on a real reader.
- **"a dashboard somebody opens twice and then stops opening"** is mine. Universally recognized, never sourced.

---

## Post 6. Nobody has to tell you when a policy is cancelled

**Format:** text. **Structure:** false belief, then the fact, then what it changes. **Pillar:** industry literacy. **CTA:** soft.

**Read the notes on this one before publishing.** I dropped a date the brief asked for, and the closing line promises a document that does not exist yet.

### The post

> A certificate sitting in your file says the policy runs to next March. It is signed, it is on the right form, and it names your company as the certificate holder. Most people read that as twelve months of protection.
>
> It is a photograph of one day.
>
> A policy can be cancelled mid-term, and if it is, nobody is required to tell you. Whether you get notice at all depends on what is written into the policy or added by endorsement. It does not depend on anything printed on the certificate. The Texas Department of Insurance states this directly in its guidance on certificates.
>
> The form says so itself. It is issued as a matter of information only, and it confers no rights on the holder. Read that with a certificate in your hand. The document you are relying on states, on its face, that it does not do the thing you are relying on it for.
>
> Which means the certificate in your file might describe a policy that ended in March, and no letter is coming.
>
> This is not an argument for panic and it is not fixable with better software. It changes two small things. Ask your broker what your vendor contracts actually require by endorsement, rather than assuming the certificate carries it. And treat the certificate as what it is: a record of what was true the day it was issued, and nothing after that.
>
> I have a longer version of this written up with the sources. Happy to send it to anyone who wants it.

*Word count: 259. Em dashes: 0. First 210 characters cut just before "protection," which is the exact word the post spends the rest of its length taking apart.*

### Alternative opening lines

- "The certificate in your file proves one thing, and it is not the thing you think."
- "Your vendor's policy could have been cancelled in March and you would have no way of knowing. Nobody is required to tell you."
- "There is a sentence printed on every COI that undoes most of what people assume it means."

### What I dropped, and why

The brief specifies the 2010 revision to the standard certificate form, which moved cancellation notice to the policy terms and away from any obligation to the certificate holder. **I left it out.**

It appears in this repo at `coi-demo-build-plan.md:575`, but it appears there as an assertion with no external citation behind it. Everything else in this post carries a real source. This is the post the whole plan calls the most useful thing you can tell a property manager who has never been told it, which makes it the worst possible place to run an uncited date.

The post is complete without it. If you can source the revision properly, this paragraph slots in after "no letter is coming," and it does make the post stronger:

> This is not how the form always worked. A revision to the standard certificate in 2010 moved cancellation notice squarely onto the policy terms, which is why older certificates carry endorsement language that newer ones do not. Anyone who learned this job before 2010 learned a different rule.

Do not run that paragraph until you have a source you would be comfortable posting in the comments, because somebody will ask.

### The CTA needs an asset that does not exist yet

"I have a longer version of this written up with the sources" is currently untrue. `foundation-1-vendor-insurance.md` is the raw material and it has real footnotes, but it is internal background, not something to send a prospect.

Two options. Cut the last line and the post still works as pure industry literacy with no ask. Or spend an hour turning the relevant section of `foundation-1-vendor-insurance.md` into a two-page write-up before this publishes. I would do the second. It is the only soft CTA in posts 1 through 14 that produces a named person in your inbox rather than a comment.

### Facts traced

- **Texas Department of Insurance certificate FAQ**, which explains that additional insured and cancellation notice wording depend on policy or endorsement language. Cited at the foot of `docs/demo-script.md`.
- **"Issued as a matter of information only" and "confers no rights on the certificate holder"** is the form's own printed text, confirmed in `coi-demo-build-plan.md:21`, and the NY DFS certificate filing cited in `docs/demo-script.md` states the certificate is informational and does not amend the policy.
- **"Policies get cancelled mid-term. The certificate doesn't update itself"** is in `foundation-1-vendor-insurance.md:319`.
- **Twelve months** is the standard annual policy period used throughout `01-vendor-coi-chase.md`, not an invented figure.

---

## Post 8. What your reminders think "I already asked" means

**Format:** text. **Skeleton:** Story Post, closer cut. **Pillar:** failure lessons anyone can apply. **CTA:** none.

**Reframed 2026-08-02.** The old version opened on my software double-firing, which is a bug report. The finding is unchanged. The lesson now leads and my defect is the worked example.

### The post

> Anything in your business that chases people has a definition of "I already asked about this."
>
> It is almost never written down, nobody has read it, and it is usually wrong. Mine was.
>
> My reminder logic waits seven days before following up on the same problem, and stops after two ignored requests. Both rules worked exactly as written. What was broken was the definition underneath them.
>
> I had built the identifier for a problem out of four things: the vendor, the certificate, the expiration date, and the bucket it fell into. Buckets are how the daily check sorts work. Sixty days out, thirty days out, fourteen days out, lapsed.
>
> A certificate fourteen days from lapsing sits in the thirty-day bucket one morning and the fourteen-day bucket the next. Different bucket, different identifier, brand new problem. The seven-day wait had nothing to apply itself to. Two near-identical emails, a day apart, to the same vendor.
>
> The quieter half is worse. The two-strike stop rule counted per problem as well, so every bucket crossing reset the count. A vendor could be chased request after request without ever tripping the rule that exists to stop it.
>
> The fix was deleting one field from the identifier.
>
> Go and look at whatever chases people for you. Renewal reminders, late rent notices, document requests, anything on a timer. Ask what it treats as the same request, and what quietly turns one into a new one. If nobody can answer, nobody has checked.

*Word count: 262. Em dashes: 0. First 210 characters end on "It is almost never written down, nobody has read it, and it is usually wrong. Mine was," which states the lesson and promises the story.*

### Alternative opening lines

- "Every automated reminder in your business has an opinion about what counts as the same request. Yours is probably wrong."
- "There's a definition buried in anything that chases people, and almost nobody has read theirs."
- "Both my rules fired correctly and the vendor would still have been emailed twice in two days."

### Notes

- **The conditional framing is preserved.** No vendor received these emails. This was found by reading code during a cadence review, not observed in the wild. "Two near-identical emails, a day apart, to the same vendor" describes what the logic would produce, and the surrounding sentences keep it in that frame. Do not let an edit turn it into an incident that happened.
- The closing paragraph is the reframe. It hands the reader something to check in their own systems, which the old ending did not.
- No CTA.

### Facts traced

All from `db/postgres/004-stage-6-watch-chase.sql` and `progress-notes.md`, Open Behaviour Findings item 1:

- `stage_6_follow_up_days` is `'7'` (line 26).
- The escalation threshold is `HAVING count(*) >= 2` in `stage_6_escalate_overdue` (line 403).
- `stage_6_vendor_issue_key` previously composed vendor, certificate, bucket, and expiration date. The bucket is now excluded, with the reason recorded in the file at lines 75 to 80.
- Buckets are 60d, 30d, 14d, expired, plus never-received and re-attestation (`docs/how-the-system-works.md`).
- Fixed in commit `0fcd62d`. All 16 `verify-stage-6-watch.ps1` checks still pass.
- The fourteen-day worked example is the finding's own illustration, not mine.

---

## Post 10. The checkbox that proves someone ticked a checkbox

**Format:** text, 200 words. **Structure:** false belief, then the fact, then what it changes. **Pillar:** industry literacy. **CTA:** none.

### The post

> There is a narrow column of checkboxes next to each coverage line on a certificate. One of them is additional insured. When it is ticked, most people treat the question as settled.
>
> A tick tells you a tick was made.
>
> Whether your company actually holds additional insured status depends on endorsement language inside the policy, which the certificate does not contain and was never built to carry. The Texas Department of Insurance says it plainly: additional insured and cancellation notice wording depend on the policy or endorsement terms.
>
> I had to make a small decision about this while building. There is a field in my database for that box. I named it `addl_insd_asserted` rather than `additional_insured`.
>
> It is an ugly name and I kept it deliberately. A column called `additional_insured` invites everyone who ever reads it, me included, eighteen months from now when I have forgotten why I cared, to treat it as a fact. Naming it asserted keeps the honest sentence stapled to the data. Somebody claimed this, on a form, on one particular day.
>
> If your process treats that box as proof, it is carrying weight the form was never built to hold.

*Word count: 203. Em dashes: 0. First 210 characters end just after "most people treat the question as settled," so the false belief is fully stated at the fold and the correction sits behind it.*

### Alternative opening lines

- "The additional insured box on a certificate proves exactly one thing: that somebody ticked a box."
- "I named a database column something ugly on purpose, and the reason is worth two minutes."
- "There is a checkbox on every certificate that most people read as an answer. It is a claim."

### Notes

- Backticks render as plain text on LinkedIn. Set the two field names in straight quotes instead, or leave them bare. They read fine bare and the underscores make them obviously code.
- No CTA, per the brief. This one is short enough that an ask would take up a noticeable share of the post.

### Facts traced

- **The field name.** `addl_insd_asserted`, never `additional_insured`, in the extraction schema at `coi-demo-build-plan.md:378` with the reasoning at `:423`, and restated as a durable rule in `build-plan.md:157`. The "eighteen months from now when you've forgotten why you cared" phrasing is lifted from my own design note in that file, which is why it sounds like something someone actually decided.
- **Texas Department of Insurance certificate FAQ**, cited at the foot of `docs/demo-script.md`.
- **Additional insured status requires a carrier endorsement** (CG 20 10 / CG 20 37), and listing in the description box does not extend it. Sourced in `foundation-1-vendor-insurance.md` footnote 6. I deliberately kept the endorsement form numbers out of the post. They are correct, and they would make a 200-word post read like a broker wrote it.

### Flagged as my invention

- **"a narrow column of checkboxes next to each coverage line."** This describes the standard form's layout from the schema and fixture work rather than from a form in front of me. A property manager looks at these weekly and will know instantly whether the description rings true. Worth a ten-second check against a real certificate before publishing.

---

# Batch 4: Posts 9, 12 (the short videos)

Both are screen recordings, no face, no music, no intro card. Both use Hook / Body / Close with the hook landing inside three seconds, and neither takes an opening line from a hook library. The hook is the thing on screen.

**Record both in the same session as the post 2 demo.** The board has to be staged either way, and three videos out of one setup is the difference between this plan happening and not happening.

---

## Post 9. The boxes on a certificate that matter, and the one that misleads everyone

**Format:** native video, 75 seconds. **Pillar:** insurance domain literacy. **CTA:** none.

**Rebuilt 2026-08-02.** Replaces "The locked PDF that disappears," which showed my system's behavior with an unopenable file and taught a property manager nothing they could use elsewhere.

### The post copy

> Most of a COI does not matter. Four parts do, and one of them gets misread constantly.
>
> Seventy-five seconds walking an actual certificate, pointing at the boxes.
>
> The short version. The coverages table carries facts: effective date, expiration date, limits, one row per line of insurance. Printed, structured, safe to act on.
>
> The Description of Operations box is free text. Somebody typed it. Wording in there saying your company is an additional insured does not make your company an additional insured. That takes an endorsement issued by the carrier, which is a separate document, and it is not the one you were sent.
>
> I am not an insurance professional. This is what I had to learn in order to build something that reads these correctly, and it is the part I wish somebody had told me first.
>
> Synthetic certificate. Fictional carrier, fictional vendor.

*Word count: 155. Em dashes: 0. First 210 characters end just inside "The short version," with the promise made and the misread box still unnamed.*

### Shot list and voiceover

Total 156 words across 75 seconds, inside the 150 to 200 range.

**Shot 1. The hook. 0:00 to 0:06**

*Screen: a fixture certificate, full page, cursor already moving toward the coverages table before the first word.*

> "Most of this page doesn't matter. Four parts do. And one of them gets misread constantly."

**Shot 2. Where the facts are. 0:06 to 0:24**

*Screen: zoom into the coverages table. Move down the rows as they are named.*

> "This block is where the facts are. One row per line of insurance. General liability, auto, umbrella, workers' comp. Each row carries a policy number, an effective date, an expiration date, and limits. Printed, structured, and safe to act on."

**Shot 3. The checkboxes. 0:24 to 0:38**

*Screen: zoom to the two narrow checkbox columns beside the coverage rows.*

> "These two columns are checkboxes. They record that somebody made a mark. That is all a checkbox can tell you."

**Shot 4. The one that misleads. 0:38 to 1:02**

*Screen: zoom to the Description of Operations box. Hold here longer than any other shot.*

> "And this is the one. Description of Operations. Free text, typed by whoever issued the certificate. Wording in here saying your company is an additional insured does not make it so. That takes an endorsement issued by the carrier, which is a separate document, and it is not the one you were sent."

**Shot 5. Close. 1:02 to 1:15**

*Screen: pan to the certificate holder box, then pull back to the full page and hold still.*

> "Last one. Certificate holder should be your exact legal name, not a close approximation. The dates are facts. The description box is a claim. Treat them differently."

### Burned-in caption notes

- Captions throughout. This video is dense with terms auto-transcription mangles: **COI**, **additional insured**, **endorsement**, **workers' comp**, **umbrella**.
- **Every zoom needs a label burned in**, naming the box being shown. A muted viewer watching a document zoom without labels learns nothing.
- Corner label for the whole video, not just ten seconds: **"Synthetic certificate."** This is the one video where a viewer might otherwise think they are looking at a real vendor's paperwork.
- End card, held two seconds: **"The dates are facts. The description box is a claim."**

### Alternative opening lines for the post copy

- "Four parts of a COI matter. One of them is where nearly everyone gets it wrong."
- "The box people trust most on a certificate is the only one that is just free text."
- "Somebody typing 'additional insured' into a certificate does not make anyone an additional insured."

### Accuracy discipline, higher here than anywhere else in the set

This is the only piece that teaches insurance rather than automation, so it carries the highest risk of being wrong in public.

- **Do not use the ACORD name** in the video, the captions, or the post copy. `coi-demo-build-plan.md` section 1.5 says to write "standard certificate of liability insurance forms" in written marketing and never to imply affiliation.
- **Keep the "I am not an insurance professional" line.** It is not hedging. It sets the frame that makes the whole video defensible: this is what I had to learn to build correctly, not advice.
- **Do not name the endorsement form numbers on camera.** CG 20 10 and CG 20 37 are correct and sourced, but saying them makes a 75-second video sound like a broker wrote it, and invites a technical argument in the comments you are not positioned to win.
- Before publishing, confirm the box names against a real certificate. The layout is documented in `01-vendor-coi-chase.md` but I have not had one in front of me.

### Facts traced

- **The form's fixed structure**, box by box: producer, insured, insurers, coverages table with policy number and effective/expiration dates and limits, the assertion checkbox columns, Description of Operations as free text, certificate holder, authorized representative. `01-vendor-coi-chase.md`, "Why the document is easy."
- **The four coverage lines**: commercial general liability, automobile liability, umbrella/excess, workers' compensation and employers' liability. `foundation-1-vendor-insurance.md`, "The four coverage types you'll see."
- **A certificate describes, an endorsement grants**, and description-box wording does not create additional insured status. `foundation-1-vendor-insurance.md`, "The three documents people confuse constantly" and "The four tools of risk transfer."
- **Additional insured and cancellation notice wording depend on policy or endorsement terms.** Texas Department of Insurance certificate FAQ, cited at the foot of `docs/demo-script.md`.
- **Certificate holder should be the management company's exact legal name.** `01-vendor-coi-chase.md`, same section, and it is why `HOLDER_MISMATCH` exists as a flag.

### Capture note

Record in the same session as the demo. Use a fixture PDF from `fixtures/pdfs/`, never a real certificate. The fixtures carry a visible synthetic-document watermark, which works in your favor on camera.

---

## Post 12. The failure that doesn't throw an error

**Format:** native video, 60 seconds. **Pillar:** failure lessons anyone can apply. **CTA:** none.

**Reframed 2026-08-02.** The old version was an engineering war story about a dashboard column. The finding is unchanged. It now opens on the general rule and closes on something the viewer can check in their own business.

### The post copy

> The failures that cost you money don't throw errors. They stop, and the screen keeps looking healthy.
>
> Sixty seconds on one I found in my own build. Seventeen of eighteen vendors had quietly stopped being chased. Nothing errored, no run failed, every number on the dashboard was accurate. The system was doing exactly what I built it to do, which is stop chasing a vendor who has ignored enough requests and hand them back to a person. It had done that seventeen times and had nowhere to say so.
>
> Here is the part worth taking away. Pick anything running unattended in your business. Automated rent reminders, payment retries, screening, document requests. Ask one question: what does it look like on screen when it stops?
>
> If the answer is "the same as when it's working," that is the problem, and it is not a software problem.
>
> Synthetic vendors. The paused state came from my own testing, not from anybody's real paperwork.

*Word count: 168. Em dashes: 0. First 210 characters end inside "Seventeen of eighteen vendors had quietly stopped", which states the rule and opens the example.*

### Shot list and voiceover

Total 122 words across 60 seconds, inside the 120 to 160 range for this length.

**Shot 1. The hook. 0:00 to 0:06**

*Screen: the dashboard as it was before the chase column existed. Static. See the capture note.*

> "There's nothing wrong with this screen. No error, no alert, nothing red. That's exactly what makes it the dangerous kind of failure."

**Shot 2. The board that looked fine. 0:06 to 0:18**

*Screen: slow scroll down the rows. Do not rush. The viewer needs to believe the screen is healthy.*

> "Vendor, trade, carrier, expiration date, status. Every fact on it accurate. Nothing errored. Nothing failed."

**Shot 3. The column. 0:18 to 0:30**

*Screen: cut to the current dashboard, chase column present. Land the cut on the column itself.*

> "Same screen with one column added. Has anyone asked this vendor for their paperwork, when, and how many times."

**Shot 4. Seventeen. 0:30 to 0:46**

*Screen: scroll the chase column with "Chasing paused" repeating. Let it run long enough to feel repetitive.*

> "Seventeen of eighteen had quietly stopped being chased. They tripped a stop rule during my own testing and stayed there. The system was behaving correctly. It just had nowhere to say so."

**Shot 5. Close, aimed at them. 0:46 to 1:00**

*Screen: static on the paused column.*

> "So go and pick something running unattended in your business. Rent reminders, payment retries, document requests. Ask what it looks like on screen when it stops. If that looks the same as working, that's the problem."

### Burned-in caption notes

- Captions throughout.
- **Shot 4 wants a running count** burned in as the scroll passes each paused row, incrementing to 17. It turns a repetitive scroll into something that builds, and it is the only way a muted viewer feels the number rather than hearing it.
- Corner label for the first ten seconds: "Synthetic vendors, local test data."
- End card, held two seconds: **"What does it look like when it stops?"** The question is the takeaway, and it works better as text than spoken.

### Capture note, and it needs doing before you record

Shot 1 requires the dashboard **as it was before the chase column existed**. You cannot fake it by cropping, and you should not, because the honest claim is that a column was absent rather than hidden.

The previous version is one commit back. The chase column was added in `0fcd62d`; the version before it is `efad6d0`.

```bash
git show efad6d0:db/postgres/005-stage-7-dashboard.sql > tmp/dashboard-before.sql
```

Apply that to the running Postgres, load the dashboard, record shots 1 and 2, then restore with `.\scripts\apply-stage-7.ps1` and confirm the Chase column is back before recording shots 3 to 5. Run `.\scripts\verify-stage-7-dashboard.ps1` afterwards, since it checks for the Chase column header and will catch a restore that did not take.

If that is more surgery than you want on a recording day, record shots 3 to 5 only and open on the current board with the voiceover changed to "I added one column to this screen and it told me something I didn't want to know." Weaker hook, zero risk.

### Alternative opening lines for the post copy

- "Software that breaks tells you. Software that quietly stops doesn't, and that's the expensive one."
- "Seventeen of my eighteen vendors had stopped being chased and every number on the screen was correct."
- "The worst automation failures look exactly like everything working."

### Facts traced

- **17 of 18 vendors carrying `chase_paused = true`** from earlier escalation testing. `progress-notes.md`, 2026-07-31: "This was invisible before the dashboard chase column existed." `reset-demo.ps1` clears it.
- **The stop rule** is `HAVING count(*) >= 2` in `stage_6_escalate_overdue`, `db/postgres/004-stage-6-watch-chase.sql:403`.
- **The chase column** carries `last_chased_at`, `chase_follow_up_due`, `chase_count`, `chase_paused`, and a rendered `display_chase` string, added in commit `0fcd62d`.

### Honesty notes, because this one could drift

- **It had not "been sending reminders for weeks."** This is a local build with outbound test mode on, and the paused state came from my own escalation testing rather than real vendors ignoring real emails. Shot 4 says so and the post copy repeats it. Neither can be cut for pace.
- **No duration claims.** Git history for this build runs 2026-07-31 to 2026-08-01, so nothing longer is supportable.

---

# Batch 5: Posts 11, 14 (the image posts)

Both images carry the claim and the words explain it. Shoot both in the same session. Neither is a designed graphic in the marketing sense, and that is the point: a decorative concept image here would read as collateral and undo the register of everything else in the set.

---

## Post 11. The gap between two valid certificates

**Format:** single image, one timeline. **Pillar:** industry literacy. **CTA:** none.

### The commentary

> Two certificates. Both look completely fine.
>
> The first policy lapsed on a date. The replacement started fourteen days later. Nothing is wrong with either document, and no amount of care spent reading them one at a time will find it. The gap exists only in the space between them, and nobody puts two certificates side by side.
>
> So the check that catches it doesn't read the renewal on its own. It compares the new effective date against the expiration date of the policy being replaced, and reports the difference. Fourteen days here.
>
> This is a comparison problem, not a document problem. The check you would naturally write, the careful one that reads each certificate properly as it arrives, is exactly the check that cannot see this.

*Word count: 137, inside the 100 to 150 the brief asks for. Em dashes: 0. First 210 characters end on "no amount of care spent reading th", so the fold sits mid-argument with the setup complete.*

### What to capture, and how

**A plain timeline. Nothing else on the image.**

Two horizontal bars on one axis, left to right:

- **Bar 1**, labeled `Policy A`, ending at a date. Under it, small: `Certificate on file. Looks fine.`
- **A visible empty span** between the two bars, labeled `14 days`. This is the only element with any emphasis, and emphasis means a slightly heavier rule or a fill, not a color that reads as an alert.
- **Bar 2**, labeled `Policy B`, starting fourteen days after bar 1 ends. Under it, small: `Certificate on file. Looks fine.`

Rules for it:

- **No red.** The moment the gap is red, the image is telling the reader what to think and the post loses the thing it is arguing, which is that both documents look fine. Keep everything one weight of gray, and let the empty span be empty.
- **No icons, no shield, no warning triangle, no vendor logo.** Nothing that signals "insurance graphic."
- Same typeface as the carousels. This should look like it came out of the same hand.
- Real dates on the axis, taken from the fixture rather than invented. See below.

**Optional second frame, if you would rather use a real artifact than a diagram.** Upload `fixtures/pdfs/f13-renewal-coverage-gap.pdf` and screenshot the resulting dashboard row, which renders the note as `14-day paperwork gap` under the vendor name. It is more honest evidence and less legible at thumbnail size. The timeline is the better feed image. If you post the screenshot instead, the commentary needs no changes.

Note that `f13` supersedes the expired Circuit Square Electric row, so uploading it will change the board. Do this after any demo recording, not before.

### Facts traced

- **The check is real and named.** `COVERAGE_GAP` in `scripts/lib/coi-stage-4-validator.js:540`. It fires when `daysBetween(previousGl.expiration_date, glCoverage.effective_date)` is greater than zero, and records `gap_days`, `previous_expiration_date`, and `new_effective_date`. The message on the flag is "The replacement general liability policy starts after the prior policy ended."
- **It compares rather than reads.** The flag depends on `getPreviousGlCoverage(matchedVendor)`, so it needs the record of what came before. A renewal read in isolation cannot produce it. That is the whole post.
- **Fourteen days is the real fixture value**, not a chosen round number. `scripts/verify-stage-7-dashboard.ps1` requires the string `14-day paperwork gap` in the rendered dashboard HTML, so the number is asserted by a test.
- **Severity is soft**, meaning the certificate is still filed and the note stays visible on the row. Worth knowing if anyone asks in the comments: this does not stop the paperwork being recorded, it annotates it.

### Notes

- The commentary never says the vendor was uninsured during those fourteen days, and it must not. The documents show a gap between two policy periods. What was actually true in that window is a question for the carrier.
- No CTA, per the brief.

---

## Post 14. Four words that should make you suspicious of any vendor

**Format:** single image, screenshot. **Pillar:** failure lessons anyone can apply. **CTA:** none.

**Reframed 2026-08-02.** The old version was about my own discipline, which is a virtue post. It is now a detector the reader can use on any demo they sit through this year, and my build check is the evidence that I hold myself to it.

**This is the one post where the four banned words appear on purpose.** They appear as a list of things that are forbidden, which is the opposite of a claiming sense. Every other post in the set has zero.

### The commentary

> Compliant. Verified. Covered. Approved.
>
> If a piece of software puts any of those words next to a contractor's name, ask what it actually checked. It read a PDF. It cannot tell you whether the policy is still in force, whether the endorsement exists, or whether the document is genuine. The word is doing work the software cannot back.
>
> Those four are banned from anything my own system renders. This screenshot is the check that enforces it. If one appears in the page, the build fails and it does not ship. There is a second guard inside the workflow that throws rather than render one.
>
> The replacement is always a date fact. Current until a date. Expires in a number of days. Lapsed a number of days ago. No certificate on file. Needs review.
>
> It was easier to make the claim impossible to ship than to keep remembering not to make it.

*Word count: 158. Em dashes: 0. First 210 characters carry all four words and the instruction, which is the entire hook.*

### What to capture, and how

**Primary image: the check itself.** Two lines of real source from `scripts/verify-stage-7-dashboard.ps1:240`:

```powershell
foreach ($blocked in @("compliant", "verified", "covered", "approved")) {
  Assert-Stage7Condition (-not $lowerHtml.Contains($blocked)) "Dashboard HTML contained forbidden word '$blocked'."
}
```

Capture from the editor, dark theme, syntax highlighting on, cropped tight with a little air above and below. No terminal chrome, no file tree, no tab bar. The four words and their consequence sit in one frame, which is why it reads at thumbnail size.

**Stronger option, if you want a genuinely failing check.** Add the word `compliant` to a string the dashboard renders, then run:

```bash
.\scripts\verify-stage-7-dashboard.ps1
```

Two cautions. The runtime guard in `n8n-workflows/stage-7-dashboard-demo-view.json` throws `"Dashboard HTML contained a blocked term."` during rendering, so depending on where the word goes you may capture the workflow error rather than the verifier assertion. Both are true images, but the verifier line is the one the commentary describes. And revert to a clean verifier pass before touching the demo again.

I would ship the code screenshot. Zero risk, it is the actual artifact, and it puts all four words in the reader's eye at once.

### Alternative opening lines

- "Four words that tell you more about the vendor than about the contractor they're describing."
- "If their dashboard says a vendor is compliant, ask what it checked. It read a PDF."
- "I banned four words from my own software and wrote a test that fails if I forget."

### Facts traced

- **The build check.** `scripts/verify-stage-7-dashboard.ps1:240`, exactly as quoted, including the assertion message.
- **The runtime guard.** `n8n-workflows/stage-7-dashboard-demo-view.json` throws `new Error("Dashboard HTML contained a blocked term.")` rather than render one.
- **The replacement vocabulary.** Current until a date, expires in n days, lapsed n days ago, no certificate on file, needs review. `docs/how-the-system-works.md`, which records that this is enforced rather than merely intended.
- **The same four words** are blocked in fixture generation, alongside ACORD. `docs/stage-3-fixtures-runbook.md:45`.

### Notes

- The reframe is one sentence: the old opening was "four words are banned from anything this system puts on screen," which is about me. The new opening is the four words themselves, followed by an instruction to the reader. Same evidence, different subject.
- The last line is the post. Nothing goes after it.
- If a comment asks the obvious follow-up, the full answer is in `docs/how-the-system-works.md`: the system cannot confirm a policy is active with the carrier, cannot detect mid-term cancellation, cannot interpret endorsements, and cannot spot a forged certificate. Give it in full rather than deflecting.

---

# Batch 6: Post 15 (the ask)

---

## Post 15. What I need from you before I build anything

**Format:** text. **Pillar:** operating model. **CTA:** real, and the only one in the set.

### The post

> I don't need access to your property management software. I don't need a project plan, a discovery call, or a conversation about budget.
>
> Here is the entire input list for work like this. The vendors you actually use, with the trade each one does. The legal names that should appear as certificate holder, including any owner LLCs. The mailbox where this paperwork already arrives. And one person who can say yes to an email.
>
> That's it. Nothing to integrate, nothing to migrate, nothing switched off while something new gets switched on.
>
> Before any of that there's a smaller thing worth doing, and it's the actual ask here.
>
> Send me ten vendor COIs. Any ten. I'll run them and send back one page showing what's current, what's lapsed, what's missing, and what needs a person to look at it. Days, not a quarter. It costs nothing, and if the answer is that your paperwork is in decent shape, that is what the page will say.
>
> On the obvious objection, because it's a fair one. You would be emailing vendor documents to someone you have never met, in another country. So, plainly: vendor paperwork only, nothing carrying resident or tenant information. I delete the files when I send the page back. If you would rather black out the policy numbers first, go ahead. The dates and the holder names are the part that matters.
>
> Ten PDFs. Message me and I'll tell you where to send them.

*Word count: 269. Em dashes: 0. First 210 characters are three things I don't need, ending inside "The vendors you a", which sets up the list without giving it away.*

### Alternative opening lines

- "The shortest version of what I need from a property management company before building anything: four things, and none of them is access to your software."
- "No discovery call. No project plan. No budget conversation. Four inputs and a mailbox."
- "Most of what people expect to hand over at the start of a project, I don't want."

### How the offer is built, and what I deliberately left out

Run through the value equation, the binding constraint is obvious and it is not price. Price is already zero.

| Lever | State | What the post does |
|---|---|---|
| Dream outcome | Modest and specific. Knowing where the paperwork stands today | Names the four states rather than promising transformation |
| **Perceived likelihood** | **The broken lever.** No clients, no case studies, an unfamiliar name in another country | The diagnostic itself is the fix. It substitutes proof of work for proof of clients, on their own documents |
| Time delay | Days | Stated once, unquantified beyond "days, not a quarter" |
| Effort and sacrifice | Ten PDFs, plus the anxiety of sending them | Both addressed. The second one gets its own paragraph |

**Three standard offer tactics are deliberately absent**, and the `offers` skill's own guidance on when not to apply them is the reason.

- **No bonus stack.** Adding "and I'll also send you a checklist and a template" to a free diagnostic devalues the diagnostic and signals that the core is thin. The core is not thin.
- **No scarcity or urgency.** No spots, no deadline, no "taking three of these this month." Any of it would be invented, and manufactured scarcity from someone with no clients is the single fastest way to undo fourteen posts of understatement.
- **No name for the offer.** Calling it the "COI Health Check" or similar puts a product label on a thing whose whole appeal is that it isn't a product.

**The guarantee is one clause** and it is the strongest line in the post: if the answer is that your paperwork is in decent shape, that is what the page will say. It costs nothing to honor, it is the opposite of what a vendor is expected to say, and it quietly tells the reader the page is not a sales document with a conclusion written in advance.

### Facts traced

- **The four inputs** come from `docs/stage-9-client-onboarding-checklist.md`: vendor CSV with legal names and a trade assigned to each, accepted certificate holder names plus owner LLC or property-specific holder entities, the client mailbox, and the approval recipient. Those are four of the checklist's own sections, compressed.
- **"Nothing to integrate"** is real and load-bearing. `01-vendor-coi-chase.md` records that this needs zero property management system integration: PDFs arrive by email, state lives in a database you own, reminders go out by email. It is also why the Buildium Premium API tier, at roughly $375 to $400 a month, never enters the conversation.
- **"Nothing carrying resident or tenant information"** matches `docs/stage-9-data-processing-retention.md`, which states the system is not intended to process tenant data, consumer personal information, W-9s, bank details, claim files, medical information, or employment records.
- **The four output states** are the dashboard's own vocabulary: current until a date, lapsed, no certificate on file, needs review.

### Flagged: this post makes one commitment the repo does not currently cover

**"I delete the files when I send the page back."**

`docs/stage-9-data-processing-retention.md` sets a 24 month default for source certificate PDFs, but that is the production retention default for a paying client with a signed arrangement. It says nothing about a free diagnostic on ten documents from someone who has not engaged you.

Delete-on-delivery is the right commitment for the diagnostic, and it is the sentence that makes the ask answerable. It is also a promise you have to actually keep, including in your mailbox, your downloads folder, and anywhere the files got copied while you ran them. Decide you are willing to operate that way before this post goes up, because it is the one line in the whole set that someone could hold you to.

Worth adding a short "diagnostic handling" note to the retention document so the commitment lives somewhere other than a LinkedIn post.

### Flagged as my invention

- **"Days, not a quarter"** is my characterization of turnaround. Ten certificates through an already-built pipeline genuinely is days, so it is defensible, but no measured figure sits behind it.
- **"If you would rather black out the policy numbers first"** is mine. It is a real concession that costs nothing, since the validator's checks turn on dates, holder names, limits and coverage lines rather than policy numbers. Confirm you are comfortable with a redacted run before offering it, because someone will take you up on it.

### Notes

- **Publish this last, and only once posts 1 through 14 have done their work.** The plan is explicit that authority comes first and the ask comes third. This post is weak in isolation and strong after fourteen posts of evidence.
- The CTA routes to a message rather than an email address in the body. It keeps the post clean and means you can decide where the documents go on a case by case basis.
- No hashtags needed. If you use them anywhere in this set, three to five at the foot of the post is the platform ceiling worth respecting.
