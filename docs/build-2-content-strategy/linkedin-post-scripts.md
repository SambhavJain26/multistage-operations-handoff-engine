# LinkedIn Post Scripts — Maintenance Triage

Finished copy for the 15 posts briefed in `linkedin-content-plan.md`.

Register: incident report. Short declaratives, real numbers, understated conclusions, first person singular, US spelling.

Every post below has been checked for: zero accuracy percentages across the full fixture set, no blurring of request and work order, response targets never called deadlines or SLAs, competitor claims quoted accurately and without disparagement, at most one em dash, the AI tells in `seo-audit/references/ai-writing-detection.md`, a first 210 characters that stands alone, and varied sentence length.

**Verified against the live skills on 2026-08-13.** The five carousel frameworks exist as named in `social/references/carousel-frameworks.md` (Value-Stack, Problem-Proof, Hack List, Rant Callout, Demo Walkthrough). LinkedIn limits confirmed from `social/references/platform-limits.md`: 3,000 characters maximum, roughly 210 visible before the fold, 3–5 hashtags recommended, hashtags perform better at the end than inline. YouTube: 100-character title with roughly 70 visible, 5,000-character description with roughly 100 visible before "Show more", and the first three description hashtags render above the title.

**Document titles are capped at 50 characters** per the platform constraint you gave. Each carousel below carries its title with a character count.

**Standing note on honesty.** The $12,000 water-damage claim and the $340 weekend call-out are documented industry patterns from `02-maintenance-triage.md`, not incidents I witnessed. No post presents them as my own experience. Where a post opens on a specific message, it is a synthetic fixture I wrote, and the copy says so.

**Standing note on hashtags: there are none, and that is deliberate.**

An earlier draft of this file carried three hashtags per post. They were removed on 2026-08-13 after checking what LinkedIn hashtags actually do now. LinkedIn disabled hashtag pages in October 2024 and removed hashtag following, hashtag suggestions, and the "Talks About" section. Hashtags are no longer clickable on desktop and no longer function as a distribution channel. What survives is a topical signal to the algorithm and a search term.

That surviving function is the reason to avoid them here rather than a reason to keep them. If a hashtag now tells LinkedIn's algorithm which audience a post belongs to, then `#ai` and `#automation` instruct it to route this work toward people interested in AI. That is the opposite of what this plan needs. Build 1's plan states the constraint directly: who comments decides who sees the post next, and six comments from property managers beats sixty from developers. Nine of the fifteen posts had been tagged `#ai`, including post 8, which is the single most likely post in the set to be picked up by an engineering audience.

The reach and engagement figures circulating for LinkedIn hashtags (roughly 9% more reach, up to 30% more engagement) all trace to companies selling LinkedIn tools and appear to be recycled between them. They are not independently verified and are treated here the same way `customer-language.md` treats vendor marketing.

`#propertymanagement` alone would be defensible, since niche and specific is the only hashtag pattern with any support left. It is still omitted, for three reasons: build 1's finished scripts use none, so a mixed convention across builds reads as unconsidered; the audience here is being built by commenting and connecting rather than by discovery, so hashtags contribute nothing to the actual growth mechanism; and a row of tags under an incident-report post reads as broadcasting.

**YouTube hashtags are kept.** They are a different mechanism. The first three in a description still render above the video title as working links, so post 2's description retains its three.

**Standing note on naming competitors.** Post 3 quotes two competitor claims accurately but does not name the companies. Naming them would be more verifiable to the reader and is a defensible choice; leaving them unnamed avoids a public argument with a funded company and stays consistent with the understated register. The named variant is included in the production notes if you prefer it.

---

# Batch 1: Posts 1, 2, 3

The three posts that go up before driving anyone to the profile. They answer, in order: what world is this, is it real, and is this person going to sell me garbage.

---

## Post 1. The urgency rating your resident gives you is the least reliable number in the process

**Format:** document carousel, 9 slides. **Framework:** Problem-Proof. **Pillar:** triage literacy. **CTA:** none.

**Document title (50-char limit):** `Stop asking residents how urgent it is` (38 characters)

**On the framework.** Problem-Proof needs a specific claim with a number on slide 1 and a real artifact as the receipt on the last slide. Both are honest here: the claim is the two fixtures and what they cost when misread, and the receipt is the actual classification output for those same two messages. The mechanism slides name what gets read instead, which is the part the framework file warns goes vague.

### The post copy that sits above the document

> I wrote thirty fake maintenance messages to test a triage system. Two of them are the reason the whole thing exists.
>
> The first one has URGENT in the subject line, in capitals, with three exclamation marks after it.
>
> It's a squeaky bathroom door.
>
> The second apologizes for the bother and mentions, in passing, a smell in the hallway. That one is a gas leak.
>
> Neither resident was being unreasonable. They were both doing the same thing: guessing at the severity of something they have no way to assess, and reporting it however the fear or the politeness came out.
>
> Nearly every property management company publishes a page telling residents what does and doesn't count as an emergency. So the industry already knows the ratings can't be trusted. What I haven't seen anyone say out loud is the conclusion.
>
> If the rating is wrong in both directions, the urgency field on your intake form isn't data. It's a guess, made by the person least equipped to make it, at the worst possible moment to ask. Any process that sorts on it is sorting on noise.
>
> The description is a different thing entirely. "There's a smell in the hallway" is a report of what's actually in front of someone, in their own words. That's evidence, and none of it is in the dropdown they picked.
>
> Nine slides on why the two mistakes cost such different amounts, and what to read instead.

*Word count: 264. Characters: 1,486. Em dashes: 0. First 210 characters end inside "with three exclamation marks after it", so both reveals are withheld past the fold.*

### Slides

**Slide 1 — Hook**
> One message said URGENT, in capitals.
> One apologized for the bother.
> The apology was the gas leak.

**Slide 2 — Reframe the problem**
> Residents misjudge urgency in both directions.
> The industry already knows.
> It publishes pages to correct it.

**Slide 3 — Reframe, sharpened**
> Every "what counts as an emergency" page is an admission that the rating can't be trusted.
> The intake form still asks for it.

**Slide 4 — The mechanism**
> A rating is a guess, made by the person least equipped to make it, at the worst moment to ask them.

**Slide 5 — The mechanism**
> A description is a report of what is physically happening, in their own words.
> One of these is evidence.

**Slide 6 — The detail: under-response**
> Under-response, as the industry documents it:
> a $150 repair becomes a $12,000 claim across two units.
> Plus a resident who starts browsing listings.

**Slide 7 — The detail: over-response**
> Over-response: $340 at weekend call-out rates for a $60 part.
> Roughly twice a month.
> It appears on no report anywhere.

**Slide 8 — The detail: what to read instead**
> Read for what is happening: gas, water, heat, sewage, electrical, locks, security.
> Not for how loudly it was reported.

**Slide 9 — Proof (the receipt)**
> [Screenshot: both requests as classified, side by side]
> Same two messages, sorted on description.
> Squeaky door: routine. Smell in the hallway: emergency.

### Production notes

- **Slide 9 must be a real screenshot**, not a mockup. Both fixtures exist: `fixtures/03-urgent-squeaky-door.txt` and `fixtures/01-understated-gas.txt`. Run them through the demo-tools workflow from clean state and capture the two resulting records showing priority. The framework file is explicit that mockups read as vaporware.
- Slide 1 is the feed thumbnail. It has to stop the scroll with no carousel behind it. Test it alone.
- One visual template across slides 2 through 8. Slide 9 is the only one that breaks the pattern, which is what makes it read as evidence.
- Slides 6 and 7 carry industry figures. The phrase "as the industry documents it" on slide 6 is doing honesty work and should not be cut for space.
- Every slide is under 25 words.

---

## Post 2. The demo

**Format:** native video, roughly 2 minutes 40 seconds. **Pillar:** proof. **CTA:** soft.

**Not short-form.** At this length the 0–3 second hook rules in `short-form-video.md` do not apply, and the Demo Walkthrough carousel framework is for documents rather than video. The structure below follows the demo sequence in `docs/operating-guide.md`.

### The video script

**[0:00–0:10] Screen: Airtable Requests table, empty.**

> This is the maintenance inbox for a property management company. Right now there's nothing in it. I'm going to send it six messages at once, the way a Monday morning actually arrives.

**[0:10–0:30] Screen: the six messages going in.**

> A burst pipe, written in a panic, with no unit number. Someone who thinks they can smell gas, understated, three lines. A squeaky bathroom door marked urgent in capitals. A three-paragraph complaint with the real problem in sentence nine. One in Spanish. And a request for a disability accommodation.

**[0:30–0:55] Screen: the records appearing, sorted by priority.**

> Here's what came back. The burst pipe and the gas smell are at the top, both emergencies. The squeaky door is routine, at the bottom, where the resident's capital letters didn't move it. The rambling one has been cut down to nine words and correctly called urgent. The Spanish message was classified from the Spanish.

**[0:55–1:10] Screen: the accommodation request detail view.**

> The accommodation request has no drafted reply attached to it at all. That one is legal-sensitive, so the system writes nothing and routes it to a person. That's deliberate, and it's the only correct behavior.

**[1:10–1:35] Screen: phone, Telegram alert arriving.**

> One of those six made a phone ring. The gas smell. Not the one the resident marked urgent, and not the longest one. The manager gets the summary, the priority, the property and unit, and a drafted email to a plumber who actually covers that property.

**[1:35–2:00] Screen: the manager taps a vendor button; the email sends.**

> Three vendor buttons, because three active vendors match this trade at this property. Tapping one sends that email. Tapping Hold sends nothing. If the manager taps twice, the second tap says the request is already handled, because the first tap claimed it in the database. Two plumbers turning up is a real failure mode and it's cheap to prevent.

**[2:00–2:15] Screen: the resident's Telegram conversation.**

> The resident is told a provider has been contacted. Not when anyone is arriving, because nobody knows that yet.

**[2:15–2:40] Screen: static, plain, no UI.**

> What this doesn't do. It doesn't create the work order in your property management system, so that data entry is still yours. It doesn't pick the vendor. It doesn't dispatch anyone. It doesn't close anything, and it never gives a resident an arrival time. Everything you just watched is synthetic: test residents, a test vendor roster, a controlled mailbox. Nobody real was contacted to make this.

*Voiceover word count: 352, which lands around 2:35–2:45 at a natural pace.*

### The LinkedIn post copy

> Six maintenance messages, sent into an empty inbox at the same time.
>
> A burst pipe with no unit number. A gas smell, described in three understated lines. A squeaky door marked URGENT in capitals. A three-paragraph complaint with the real problem in sentence nine. One in Spanish. One accommodation request.
>
> Two and a half minutes of it working, including the part where the manager's phone rings for exactly one of the six, and the part at the end where I list what it refuses to do.
>
> The accommodation request is the one I'd watch. It gets no drafted reply at all, because that's a legal-sensitive matter and the correct output there is a person, not a paragraph.
>
> Everything in the video is synthetic. Test roster, controlled mailbox, invented residents. Nobody was contacted to make it.

*Word count: 143. Characters: 831. Em dashes: 0. First 210 characters end mid-list, which stands alone and earns the expand.*

### YouTube title (100-char limit, ~70 visible)

`AI maintenance triage for property managers: six messages, one alert` (68 characters)

Leads with the searchable phrase, stays inside the visible truncation point, and states the demo's structure rather than promising a transformation.

### YouTube description (5,000-char limit, ~100 visible before "Show more")

> Six maintenance requests go into an empty inbox at once. Here's how they sort, which one makes a phone ring, and what the system refuses to do.
>
> This is a demo-depth build for US residential property management companies. It reads maintenance requests from email, a web form, or a resident messaging channel, classifies urgency and trade, asks the resident for details it needs before anyone is interrupted, matches vendors on property and trade, and puts a drafted vendor email in front of the manager for approval.
>
> Chapters:
> 0:00 An empty inbox
> 0:10 Six messages sent at once
> 0:30 How they sorted
> 0:55 The accommodation request, and why it has no draft
> 1:10 The emergency alert reaching a phone
> 1:35 Manager vendor approval, and the double-tap guard
> 2:00 What the resident is told
> 2:15 What this does not do
>
> The six messages: a burst pipe written in a panic with no unit number, an understated gas smell, a squeaky door marked URGENT by the resident, a rambling complaint with the real issue in sentence nine, one message in Spanish, and a disability accommodation request.
>
> A note on what this is not. It does not create the work order in a property management system, so that data entry stays with the manager. It does not select or dispatch a vendor. It does not close a request or promise an arrival time. Every outbound vendor email requires a manager to tap a button, and the safety rules can raise a priority but have no path to lower one.
>
> Everything shown is synthetic: test residents, a test vendor roster, and a controlled mailbox. No real resident, vendor, or property management company appears in this video.
>
> Built with self-hosted n8n, Postgres and Airtable, with OpenAI handling classification and drafting.
>
> #propertymanagement #propertymaintenance #automation

*Characters: 1,847. First 100 characters stand alone before "Show more". Three hashtags, which render above the title.*

### Production notes

- Run `.\scripts\reset-demo.ps1 -Apply` and restore the clean snapshot before recording, so no historical `MR-` references appear.
- The six fixtures are the live-demo set: `01-understated-gas`, `02-panicked-burst-pipe-no-unit`, `03-urgent-squeaky-door`, `04-buried-lede`, `05-spanish-no-hot-water`, `06-accommodation-request`.
- Put "synthetic test data" on screen as a caption during the first ten seconds as well as saying it at the end. The spoken disclaimer at 2:15 is the credibility beat; the on-screen one covers anyone who watches muted.
- Do not say "my product" or "my platform" anywhere in the voiceover. The framing is "something I built for a property management company's maintenance inbox."
- Subtitles are required. Most feed video is watched without sound, and the closing limitation list is the most important part of the video.
- The full-length recording belongs in the profile Featured section, not the feed. Only this cut is post 2.

---

## Post 3. The whole category is trying to take the human out of dispatch

**Format:** text, 290 words. **Skeleton:** Contrarian Take, closer cut. **Pillar:** what software is allowed to do. **CTA:** none.

**Rebuilt from the plan's original framing.** The first version argued that the system can draft but not send, which is build 1 post 13's territory and is framed there as a principle across every build. This version reports the market instead, which is material build 1 never touches.

### The post copy

> One of the AI maintenance products in this space advertises that it de-escalates 48% of emergencies.
>
> Another one will pay for its own mistakes. That isn't my paraphrase, it's on their homepage: if the AI makes an error, they cover it.
>
> I want to be fair about both, because they're real products solving a real problem and some property management companies should buy them. That de-escalation number sits behind a staffed call center with a human reachable in about fifteen seconds. The indemnity is a serious commitment, and a company with insurance and a track record can make it where I can't.
>
> But look at the direction of travel. Every funded product in maintenance triage is working toward the same destination: fewer people standing between a resident's message and a vendor arriving. Priced per door, somewhere between $1.60 and $3 a unit a month, and the pitch is that your coordinator stops touching it.
>
> I built the opposite, and I want to be clear that it was a choice rather than a limitation.
>
> The safety rules in mine can raise a priority. They have no path to lower one. I couldn't write down a defensible reason for software to decide that something a resident called an emergency isn't one, so I didn't give it that power. No vendor is contacted without a manager tapping a button. There is no code path from an inbound message to an outgoing email.
>
> That costs something. It over-escalates sometimes, and the manager stays involved in work they might rather hand off entirely.
>
> Both designs are real. The question isn't which is smarter on a good day. It's which one you want on the day it's wrong, because that's the only day the difference shows up.

*Word count: 293. Characters: 1,714. Em dashes: 0. First 210 characters end inside "if the AI makes an error", which stands alone and withholds the turn.*

### Production notes

- **Both quoted claims are accurate.** "48% of emergencies de-escalated" and "23% solved at intake" are Latchel's own homepage figures. "If the AI makes an error, we will pay for it" is Vendoroo's. Pricing: Property Meld ~$1.60/unit Core and ~$2.00 Ops, Vendoroo from ~$3/door. All sourced in `customer-language.md`.
- **Named variant.** If you'd rather name them, replace the first two paragraphs with: *"Latchel advertises that its AI de-escalates 48% of emergencies. Vendoroo will pay for its own mistakes — that isn't my paraphrase, it's on their homepage."* Naming makes the claims checkable and reads as more confident. It also invites a response from a funded company, and the rest of the post is careful enough that the response would probably be civil. Your call; the unnamed version is the default because it keeps the register understated. If you use the named variant, note it introduces one em dash, so remove it.
- The fairness paragraph is load-bearing and must not be trimmed for length. Without it this reads as a competitor attack, and the plan's discipline is explicit that some operators should buy the autonomous products.
- The cost admission near the end ("it over-escalates sometimes") is what keeps the post from being a sales pitch. Do not cut it.

---

# Checks run on this batch

| Check | Post 1 | Post 2 | Post 3 |
|---|---|---|---|
| Accuracy percentages across full fixture set | None | None | None |
| Overclaim vocabulary | Clear | Clear | Clear |
| Request vs work order | Not applicable | Stated explicitly in VO and description | Not applicable |
| Response target language | Not used | Not used | Not used |
| Competitor claims | Not used | Not used | Quoted accurately, no disparagement, anti-persona named |
| Product language ("my tool", "my platform") | Clear | Clear, flagged in production notes | Clear |
| First 210 characters | Stands alone, both reveals withheld | Stands alone mid-list | Stands alone, turn withheld |
| Length | 264 words / 1,486 chars | 143 words / 831 chars | 293 words / 1,714 chars |
| Slide length (under 25 words) | All 9 pass | n/a | n/a |
| Em dashes | 0 | 0 | 0 (1 in the named variant, flagged) |
| Banned openers, transitions, closers | Clear | Clear | Clear |
| Structural AI patterns | Clear | Clear | Clear |
| Sentence length variance | Varied | Varied | Varied |
| Build 1 collision | No counterpart | No counterpart | Rebuilt away from build 1 posts 3 and 13 |
| Factual trace | Both fixtures named; industry figures attributed | Six fixtures named; all six behaviors verified | All four competitor facts sourced |

**Seven Sweeps pass:** run after you've read these aloud and rewritten anything that sounds like me rather than you. I've kept the register consistent with build 1's scripts, but the final voice pass is yours.

---

# Batch 2: Posts 4, 5, 6, 7, 8, 9

Three carousels, two text posts, one image post. Post 8 carries the tightest honesty constraints in the set.

---

## Post 4. I don't sell software

**Format:** text, 236 words. **Skeleton:** Contrarian Take, closer cut. **Pillar:** operating model. **CTA:** none.

**Conditional post.** This is build 1's post 5 and can only be published once. Written fresh here rather than reused, and it leans on the per-door pricing contrast, which is specific to this category and does not appear in build 1's version. If build 1 publishes first, delete this and renumber.

### The post copy

> There's nothing to log into.
>
> No seats, no per-door fee, no monthly charge for a dashboard nobody opens. I'm not going to send you an onboarding sequence or ask your team to adopt anything.
>
> What I build runs inside the business that already exists. The mailbox you already have. A database you own. The process your team already follows, roughly as they already follow it. When it's finished it belongs to you, and if we stop working together it keeps running, because there's no license phoning home.
>
> This matters more in maintenance than it first looks. Every product in this category is priced per door and needs your maintenance workflow to move onto their system. That's a migration, a data model that isn't yours, and a per-unit line item that grows with the thing you were trying to make cheaper. It also means your residents' messages now live somewhere you don't control.
>
> Concretely, what "inside your business" means: it reads the mailbox you already use, writes to a database you can query yourself, sends from your address, and can be exported and handed to any developer you like.
>
> I'm aware this makes it harder to describe. "Custom automation, built into your operation" doesn't fit on a pricing page, and there's no free trial to click.
>
> It's a different transaction. You're not adopting a tool. You're getting one specific part of your operation handled.

*Word count: 236. Characters: 1,393. Em dashes: 0. First 210 characters end inside "What I build runs in", with the full negative stated and the alternative withheld.*

### Production notes

- The word "platform" appears once, referring to competitors, which is the permitted use. It must never refer to this work.
- The self-aware paragraph near the end ("harder to describe") is what stops this reading as a humblebrag about not selling software. Keep it.
- If build 1 runs first, this post is deleted rather than rewritten. Two versions of the same argument published weeks apart is the single most templated-looking thing this plan could do.

---

## Post 5. When it's ambiguous, go up

**Format:** document carousel, 7 slides. **Framework:** adapted (principle, then mechanism, then application). **Pillar:** triage literacy. **CTA:** soft.

**Document title (50-char limit):** `The two errors don't cost the same` (34 characters)

**On the framework.** None of the five carousel frameworks fits this honestly. Value-Stack needs a count, Problem-Proof needs a personal result with a number, Hack List needs named techniques, Rant Callout is polarizing by design, and Demo Walkthrough needs a UI. The framework file says to adapt the structures rather than satisfy their labels, so this is relabelled honestly instead of having a fake number bolted onto slide 1.

### The post copy that sits above the document

> Calling a routine repair an emergency costs you a phone call and some vendor goodwill.
>
> Calling an emergency routine costs you a flooded unit, a habitability problem, and sometimes a resident who doesn't renew.
>
> Those two numbers aren't close. They aren't even the same kind of number. And almost every process I've looked at treats the two mistakes as though they were symmetrical, because nobody ever sat down and priced them against each other.
>
> Once you do price them, the design follows immediately. Every ambiguous case should resolve upward, by rule, before anyone gets the chance to be optimistic about it.
>
> In the triage system I built, that isn't guidance sitting in a prompt hoping to be followed. The model classifies, and then a separate layer of fixed rules runs afterward and checks for the things that are dangerous regardless of what the model decided. Those rules can raise a priority. There is no code path that lets them lower one. I never wrote one, so it can't start happening by accident later.
>
> There's a real cost here and I'd rather say it than have you find it. The system over-escalates. A manager occasionally gets an alert for something that could have waited until Tuesday. I decided that was the cheaper mistake and I'd make the same call again.
>
> Seven slides on pricing your own two errors. Worth finding one judgment call in your business where the mistakes cost wildly different amounts, and checking whether your process knows that.

*Word count: 259. Characters: 1,536. Em dashes: 0. First 210 characters end on "a resident who doesn't renew", so the full asymmetry lands before the fold.*

### Slides

**Slide 1 — Cover**
> Calling a routine repair an emergency costs a phone call.
> Calling an emergency routine costs a flooded unit.

**Slide 2 — The principle**
> Those two numbers aren't close.
> Most processes treat the two mistakes as if they were the same size.

**Slide 3 — Why**
> Nobody priced them.
> It isn't a judgment failure. It's an arithmetic one that never happened.

**Slide 4 — The rule that follows**
> So the rule writes itself: every ambiguous case resolves upward, before anyone has a chance to be optimistic.

**Slide 5 — The mechanism**
> In my build, fixed rules run after the model.
> They can raise a priority. There is no code path to lower one.

**Slide 6 — The cost, stated**
> This over-escalates. A manager sometimes gets an alert for something that could have waited.
> That's the cheaper mistake.

**Slide 7 — Application**
> Find one judgment call in your business where the two errors cost wildly different amounts.
> Check whether your process knows.

### Production notes

- Slide 6 is the credibility slide. A carousel about a safety rule that doesn't admit the rule's cost reads as marketing.
- Slide 1 works as a standalone thumbnail: the two clauses carry the whole idea even with no carousel behind them.
- Do not add a fourth priority level or invent a number to make slide 1 look more like Problem-Proof.

---

## Post 6. Every rule in this system is a scar

**Format:** document carousel, 8 slides. **Framework:** Value-Stack. **Pillar:** what software is allowed to do. **CTA:** soft.

**Document title (50-char limit):** `Three rules that look absurd out of context` (43 characters)

**Do not restate build 1 post 1.** That post owns the reading-versus-deciding principle: the model transcribes, fixed rules decide. This post assumes rules exist and teaches where they come from. The copy below deliberately avoids arguing for a rules layer at all.

### The post copy that sits above the document

> A ceiling fan that has stopped working is not an electrical job.
>
> That line exists in the triage system I built, and out of context it reads like somebody made a mistake. Here's how it got there.
>
> A live test came in about a fan that had stopped working. The model classified it as electrical, which is defensible. A fan runs on electricity. It was also useless, because the demo vendor roster's electrical contractor covers one property and this request came from a different one. So the request matched no vendor at all, and reached the manager with nothing to approve and no obvious reason why.
>
> The fix isn't a smarter classification. It's a narrow rule: a standalone ceiling or exhaust fan with no HVAC or electrical-hazard context is a routine appliance job, which matches the general repairs vendor who covers every property. Sparking, smoke, a burning smell, exposed wiring and breaker trouble all remain electrical danger signals. The boundary is deliberately small.
>
> I have three of these. Every one arrived the same way: something ran, produced an answer that was perfectly defensible and completely useless, and I wrote a rule.
>
> You can't write these in advance. Nobody sits down and predicts the ceiling fan. They're discovered one incident at a time, which makes the number of them a better signal that something has actually been run against reality than any accuracy figure a vendor quotes you.
>
> Eight slides on all three, with the run that produced each one.

*Word count: 272. Characters: 1,614. Em dashes: 0. First 210 characters end inside "A live test came", with the rule stated and its origin withheld.*

### Slides

**Slide 1 — Cover (exact count, exact deliverable)**
> Three rules in this system that look absurd out of context.
> And the live run that produced each one.

**Slide 2 — Rule 1**
> Rule 1: a ceiling fan that stopped working is a routine appliance job.
> Not electrical.

**Slide 3 — The run behind rule 1**
> The model said electrical. Defensible: a fan uses electricity.
> The roster's electrician covers one property. This came from another.
> Zero vendor matches.

**Slide 4 — Rule 2**
> Rule 2: a ceiling drip with a bucket under it stays urgent.
> It does not become an emergency.

**Slide 5 — The run behind rule 2**
> Repeated runs escalated contained drips to emergency.
> Spreading water, ceiling collapse and electrical risk still do.
> The bucket is the signal that it's contained.

**Slide 6 — Rule 3**
> Rule 3: a squeaky door is routine.
> Unless it won't lock, won't close, blocks access, or can injure someone.

**Slide 7 — The run behind rule 3**
> Runs drifted on noisy hinges.
> The exception list is the whole rule. A door that won't lock is a security problem, not a noise complaint.

**Slide 8 — Close**
> Ask any AI vendor how many of these they have, and how they found them.
> A list nobody can produce means nothing has run against reality.

### Production notes

- Value-Stack promises an exact count on the cover and must deliver exactly that. Three rules, three runs, no padding to reach ten slides.
- All three rules are recorded: the fan in `progress-notes.md` 2026-08-13, the drip and the hinge in the Stage 8 model-stability correction of 2026-08-01, and all three in `AGENTS.md`.
- The fan is the strongest case and belongs first, because the model's answer was reasonable and still produced a dead end. The other two are drift corrections, which are less interesting.
- Slide 7's exception list must stay complete. Trimming it to fit turns a safety boundary into a soundbite.

---

## Post 7. It asked for a phone number while it was talking to them

**Format:** single image, plus 140 words of commentary. **Pillar:** failure lessons. **CTA:** none.

### The post copy

> This is the system I built asking a resident for their phone number, in the middle of a conversation with them.
>
> It had been given a list of fields a request needs before it can be classified. Contact details were on the list, so it asked. It was holding an open chat on the exact channel it was requesting. In the same breath it asked which property they lived at, on a bot dedicated to one resident whose address it already had.
>
> The fix took ten minutes: drop contact from the missing-field list whenever a reply channel is already open, and only ask about location when it's genuinely unknown, since vendor matching is property-specific.
>
> Automation asks for what you told it to collect, not what it already has. If you run an intake form, there's a fair chance it's doing this to someone today.

*Word count: 143. Characters: 872. Em dashes: 0. First 210 characters end inside "Contact det", with the absurdity stated and the explanation withheld.*

### Production notes

- **The image is the real message.** It was sent in a live Telegram conversation on 2026-08-13 and reset does not clear external Telegram history, so the original should still be in the tenant bot chat. Capture it there. If it has genuinely gone, say in the post that the screenshot is a reconstruction rather than quietly staging one.
- Crop to the message bubbles only. No surrounding UI chrome, no bot name visible if it identifies the demo build.
- Redact nothing else, because there is nothing to redact: the resident is synthetic.
- Recorded in `progress-notes.md` 2026-08-13, with the fix described as removing CONTACT from missing fields when a reply channel is present.

---

## Post 8. I ran the accuracy test properly and it failed

**Format:** document carousel, 9 slides. **Framework:** Problem-Proof. **Pillar:** what software is allowed to do. **CTA:** none.

**Document title (50-char limit):** `15.6%: the accuracy test I failed` (33 characters)

**The tightest honesty constraints in the set.** This post must not become a redemption arc. The system is not now accurate. The gate it later passed is six messages I selected for a demo, and the full thirty-message hardening is still unfinished. Both facts appear in the copy, on a slide, and in the close.

### The post copy that sits above the document

> 15.6%.
>
> That's the exact-match rate from the first real accuracy test I ran on this triage system. Thirty test messages, three runs each, about fifteen minutes of compute. Six under-escalations, meaning six times it called something less serious than it actually was. Ten missed safety signals.
>
> The instinct at that point is to go and tune the prompt until the number comes up. I didn't, and not out of discipline. It's that a number you tuned against your own test set is a number about your test set. I could have moved it somewhere respectable in an afternoon and learned nothing.
>
> What the failure actually said was narrower and more useful than "the model isn't good enough." It said a language model shouldn't be the last thing standing between a gas smell and somebody's phone.
>
> So the life-safety decisions moved out of the model. There's now a fixed layer that runs afterward, checks for the dangerous cases regardless of what the model concluded, and can only ever raise a priority.
>
> I should be straight about where that leaves things. The system later passed a six-fixture gate with a clean sheet, and that gate is six messages I chose for a demo. The full thirty-message hardening is still unfinished. Which is why you won't find an accuracy percentage anywhere in how I describe this work, and why I'm not going to quote you one.
>
> When a vendor gives you an accuracy figure, ask what it got wrong and what changed as a result. A number with no failures attached came from a test nobody tried hard enough to fail.
>
> Nine slides, including the entry where I wrote the failure down.

*Word count: 294. Characters: 1,738. Em dashes: 0. First 210 characters end inside "Six under-escalations, meaning", with the number and the scale stated.*

### Slides

**Slide 1 — Hook**
> 15.6%.
> The exact-match rate the first time I properly tested this.
> Thirty messages, three runs each.

**Slide 2 — Reframe the problem**
> Six under-escalations. Ten missed safety signals.
> It was calling real problems smaller than they were.

**Slide 3 — Reframe, sharpened**
> The obvious move is to tune the prompt until the number improves.
> A number tuned against your own test set is a number about your test set.

**Slide 4 — The mechanism**
> What the failure actually said: a model shouldn't be the last thing standing between a gas smell and somebody's phone.

**Slide 5 — The mechanism**
> So the life-safety decisions left the model.
> A fixed layer runs afterward and checks the dangerous cases regardless of what the model concluded.

**Slide 6 — The detail**
> That layer can raise a priority. It has no path to lower one.
> Gas, flooding, sewage, fire, sparking, exposed wiring, no heat, no lock.

**Slide 7 — The detail: the honest limit**
> It later passed a six-fixture gate with a clean sheet.
> That gate is six messages I chose for a demo.
> The full thirty is still unfinished.

**Slide 8 — The detail: the consequence**
> Which is why I don't quote an accuracy percentage for this work, and won't.

**Slide 9 — Proof (the receipt)**
> [Screenshot: the progress-notes entry recording the failure, dated 2026-07-31]
> Ask a vendor what their number got wrong, and what changed because of it.

### Production notes

- **The receipt is the progress-notes entry, not the scorecard.** `docs/stage-3-scorecard.md` records the six-fixture run that *passed*, and using it here would imply the opposite of the post. The honest artifact is the line in `progress-notes.md` dated 2026-07-31: "failed the production-style gate: 15.6% exact match, 6 under-escalations, 4 over-escalations, and 10 missed safety signals." A screenshot of my own notes recording the failure at the time it happened is a stronger receipt than any scorecard, because it shows the failure was written down rather than reconstructed later.
- The failing run's raw artifacts live under ignored `tmp/stage-3/` output and may no longer exist. Do not go looking for them and do not regenerate a stand-in.
- **Every drafting pass on this post must re-check slide 7 and the corresponding paragraph.** They are the only things preventing this from reading as "I failed, then I fixed it, now it's accurate." That sentence would be false.
- The post quotes 15.6% as a failure, which is permitted and is the entire point. The standing constraint bans quoting a percentage as a *proof point*. See `.agents/product-marketing.md` under Proof Points.

---

## Post 9. What it will and won't say to a resident

**Format:** text, 285 words. **Structure:** false belief, then the fact, then what it changes. **Pillar:** operating model. **CTA:** none.

### The post copy

> The message this system refuses to send is "someone will be out shortly."
>
> That's the message everyone wants. The resident wants it, the manager would like to have sent it, and it's the natural thing for any language model to produce, because it's what a helpful person says. It's also the message that generates the complaint, because nobody has confirmed it, and the resident will remember it word for word when nobody arrives.
>
> So there's a written list of what it's allowed to say without a person checking first. Four things.
>
> It can confirm a request was received. It can ask for details it genuinely needs in order to classify the request, no more than three questions at a time. It can answer a status question truthfully, which before any vendor has been contacted means saying the request is with the manager. And once a manager has approved a vendor email and that email has actually sent, it can say a maintenance provider has been contacted and an update will follow.
>
> That's the whole list. It never gives an arrival time. It never says soon. Accommodation requests and legal-sensitive matters generate no draft at all and go straight to a person, because the correct output there is a human being, not a paragraph.
>
> The list took longer to write than the code that enforces it. It's also the first thing I'd ask to see from anyone else selling this.
>
> If something is talking to your residents, there should be a written list of what it's permitted to say. If that list doesn't exist, the list is whatever the model thought of. And the reassuring message is always what a model thinks of first.

*Word count: 285. Characters: 1,668. Em dashes: 0. First 210 characters end inside "the natural thing for any", with the refusal stated and the reasoning withheld.*

### Production notes

- The four permitted messages are exactly those in `docs/build-description.md` under Clarification and status behavior. Do not add a fifth for rhythm.
- "No more than three questions at a time" is a real implemented limit, not a rounded illustration.
- The closing line is the strongest in the batch and should survive the voice pass intact.

---

# Checks run on batch 2

| Check | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|
| Accuracy percentages as a proof point | None | None | None | None | None; 15.6% cited as failure only | None |
| Overclaim vocabulary | Clear | Clear | Clear | Clear | Clear | Clear |
| Request vs work order | Not used | Not used | Not used | Not used | Not used | Not used |
| Response target language | Not used | Not used | Not used | Not used | Not used | Not used |
| Product language | "Platform" used once, of competitors only | Clear | Clear | Clear | Clear | Clear |
| First 210 characters | Stands alone | Stands alone | Stands alone | Stands alone | Stands alone | Stands alone |
| Length | 236w / 1,393c | 259w / 1,536c | 272w / 1,614c | 143w / 872c | 294w / 1,738c | 285w / 1,668c |
| Slide length under 25 words | n/a | All 7 pass | All 8 pass | n/a | All 9 pass | n/a |
| Document title under 50 chars | n/a | 34 | 43 | n/a | 33 | n/a |
| Em dashes | 0 | 0 | 0 | 0 | 0 | 0 |
| Banned openers, transitions, closers | Clear | Clear | Clear | Clear | Clear | Clear |
| Structural AI patterns | Clear | Clear | Clear | Clear | Clear | Clear |
| Sentence length variance | Varied | Varied | Varied | Varied | Varied | Varied |
| Build 1 collision | Same post; conditional, delete if build 1 leads | No counterpart | Rebuilt away from build 1 post 1 | No counterpart | No counterpart | No counterpart |
| Factual trace | Competitor pricing sourced | Escalate-only rule in `AGENTS.md` | Three rules dated in `progress-notes.md` | Incident dated 2026-08-13 | Failure dated 2026-07-31 | Four messages per `build-description.md` |

---

# Batch 3: Posts 10, 11, 12, 13, 14, 15

Two 60-second videos, two text posts, one image post, and the only post that asks for anything.

**On the video framework.** Both videos use the Story Arc structure from `social/references/short-form-video.md`: hook at 0–3s, setup to 15s, the journey to 45s, resolution to 55s, lesson to 60s. Its hook library is rejected per the plan, and reading it confirmed why: "The secret to...", "I made a huge mistake with...", "Unpopular opinion:". Both hooks below come from the incident instead.

**Voiceover length.** The plan budgets 150–200 words per 75 seconds, so a 60-second video is 120–160 words. Both scripts land at roughly 155, which the reference notes should be delivered slightly faster than normal conversation.

---

## Post 10. The system emailed itself

**Format:** native video, 60 seconds. **Framework:** Story Arc. **Pillar:** failure lessons. **CTA:** none.

### The video script

**Hook — 0:00–0:03**
- Visual: the request list, two records highlighted
- Audio: "Two of these maintenance requests weren't sent by anyone."
- Text overlay: `Nobody sent these`

**Setup — 0:03–0:15**
- Visual: a vendor email going out, then the same mailbox being watched
- Audio: "When a manager approves a vendor, the system emails that vendor. It was sending from the same mailbox it was also watching for new maintenance requests."
- Text overlay: `Same mailbox. In and out.`

**Journey — 0:15–0:45**
- Visual: the ingest picking the email back up, new records appearing, a manager approval arriving
- Audio: "So it read its own outgoing email as a new maintenance request. Created a ticket. Classified it. Matched a vendor. Then sent the manager an approval button for a message it had written itself. Nothing errored. It just looked like a busy afternoon."
- Text overlay: `It approved its own email`

**Resolution — 0:45–0:55**
- Visual: the subject prefix on an outgoing email, then the ingest rule discarding it
- Audio: "The fix is a subject prefix on every system-generated email and an ingest rule that discards anything wearing it. Case-insensitive, so a Re: or a stray space doesn't defeat it."
- Text overlay: `[MT-SYSTEM]`

**Lesson — 0:55–1:00**
- Audio: "Anything that reads and writes the same channel will eventually talk to itself. It doesn't announce itself, because a loop looks exactly like real work."

*Voiceover word count: 154.*

### The LinkedIn post copy

> Two maintenance requests appeared in the system I built. Neither was sent by a resident.
>
> When a manager approves a vendor, the system emails that vendor. It was sending from the same mailbox it was also watching for new maintenance requests. So it read its own outgoing email, decided somebody was reporting a new problem, opened a ticket, classified it, matched a vendor to it, and sent the manager an approval button for a message it had written itself.
>
> Nothing errored. Nothing turned red. It looked like a busy afternoon.
>
> The fix is unglamorous. Every system-generated email now carries a subject prefix, and the ingest rule discards anything wearing it. Case-insensitive, because a mail client adding "Re:" or a stray space shouldn't be enough to defeat it.
>
> The general version is worth checking on your own setup. Anything that both reads and writes the same channel will eventually talk to itself. Shared inboxes, auto-responders, two systems forwarding to each other where each one thinks it's the source of truth.
>
> It doesn't announce itself, which is the actual problem. A loop looks exactly like real work until you count.
>
> This was a controlled test mailbox with synthetic vendors. Nobody real was emailed.

*Word count: 205. Characters: 1,232. Em dashes: 0. First 210 characters end inside "the same mailbox it was also", with the setup stated and the consequence withheld.*

### Production notes

- Recorded in `progress-notes.md` 2026-08-13: vendor emails for `MR-0011` and `MR-0012` went out without the configured prefix and were re-ingested as `MR-0014` and `MR-0015`.
- The two real reference numbers can appear on screen. They are synthetic demo tickets.
- The closing honesty line about the controlled mailbox belongs in both the video and the post copy. It is the difference between a war story and a claim that real vendors were spammed.
- Subtitles required. The line that carries the post is the last one, and most feed video is watched muted.

---

## Post 11. Nothing here gets an emergency alert for being old

**Format:** text, 236 words. **Structure:** false belief, then the fact, then what it changes. **Pillar:** triage literacy. **CTA:** none.

### The post copy

> The spec I was working from had an aging rule in it. A routine request open ten days becomes urgent. Fourteen days triggers an emergency review.
>
> I didn't build it, and it's worth explaining why, because it looks like the obviously responsible feature.
>
> A request that has been sitting for eleven days is a management problem. It is not a reason to make somebody's phone ring at eleven at night. Nothing about it got more dangerous overnight. The pipe didn't start leaking faster because a counter rolled over.
>
> So age produces a status on the board and a line in the morning digest. That's all it produces. There is no path from an aging counter to an emergency alert, and I tested for exactly that: a backdated routine request renders as overdue and sends zero alerts.
>
> The reasoning is narrow. An alert channel that fires for things that could have waited gets muted. Not formally, nobody announces it, but the manager stops reading it with the same attention. And a muted channel doesn't deliver the gas smell either.
>
> Every alert you add makes every existing alert slightly less effective. That isn't an argument for having no alerts. It's an argument for being able to say, about each one, what actually happens if nobody looks at it for four hours.
>
> Worth knowing which of yours fire for things that could have waited until Tuesday.

*Word count: 236. Characters: 1,403. Em dashes: 0. First 210 characters end inside "it's worth explaining why, because it", with the unbuilt feature stated and the reasoning withheld.*

### Production notes

- The 10-day and 14-day ladder comes from `02-maintenance-triage.md` and was deliberately not built. The plan flags accidental miscitation as a live risk; this post cites it correctly, as the thing that was rejected.
- The architecture rule is in `AGENTS.md`: age creates OVERDUE board and digest status only, never an emergency phone alert. The zero-alert test is in the Stage 8 validation log.
- "Response target" language is deliberately absent here. This post is about alerting, not about targets, and mixing them would invite the deadline reading.

---

## Post 12. "When will all this be fixed?" got a ticket number

**Format:** native video, 60 seconds. **Framework:** Story Arc. **Pillar:** failure lessons. **CTA:** none.

### The video script

**Hook — 0:00–0:03**
- Visual: the resident's message on screen, then a reference number appearing beside it
- Audio: "A resident asked when their problems would be fixed. Watch what the system does with that."
- Text overlay: `This is a question, not a request`

**Setup — 0:03–0:15**
- Visual: the newly created request record
- Audio: "It opened a new maintenance request and gave it a reference number. There's no problem here. Nobody reported anything broken. It's a question about the three things they already reported."
- Text overlay: `MR-0013`

**Journey — 0:15–0:45**
- Visual: the fixture list scrolling past
- Audio: "It was reading everything as a report of a problem, because that's what usually arrives here. But most of what lands in a maintenance inbox isn't a request. Out-of-office replies. Newsletters. Forwarded portal notifications. A vendor's own reply. Someone venting with no ask in it. A system that can't tell the difference doesn't just fail on those. It manufactures work and puts a number on something that doesn't exist."
- Text overlay: `Most of the inbox isn't a request`

**Resolution — 0:45–0:55**
- Visual: the post-fix run, one consolidated reply, ticket count unchanged
- Audio: "Now it recognizes status, progress, update and completion language, answers once across every open request in that conversation, and never touches triage."
- Text overlay: `0 tickets created`

**Lesson — 0:55–1:00**
- Audio: "Anything reading an inbox needs an explicit answer for what isn't a request. That list is longer than the list of what is."

*Voiceover word count: 158.*

### The LinkedIn post copy

> A resident asked when all their issues would be resolved. The system opened a new maintenance request and gave it a reference number.
>
> There was no problem. Nobody reported anything broken. It was a question about the three things they'd already reported, and it came back as a fourth ticket with its own number, its own vendor match, and its own notification to the manager.
>
> The cause is that it was reading everything as a report of a problem, which is a reasonable default for a maintenance inbox and wrong more often than you'd think. Out-of-office replies. Marketing newsletters. Forwarded portal notifications. A vendor's own reply arriving back. Somebody venting with no actual request in it.
>
> A system that can't tell those apart doesn't just fail on them quietly. It manufactures work, notifies someone about the work it manufactured, and puts a reference number on something that doesn't exist.
>
> It now recognizes status, progress, update and completion language, answers once across every open request in that conversation, and doesn't touch triage at all. The verification run created no ticket and sent the manager nothing.
>
> Anything reading an inbox needs an explicit answer for what is not a request. That list is longer than the list of what is.

*Word count: 213. Characters: 1,289. Em dashes: 0. First 210 characters end inside "It was a ques", with the absurdity stated and the explanation withheld.*

### Production notes

- Recorded in `progress-notes.md` 2026-08-13. The status question missed a narrow arrival-only pattern and became `MR-0013`. The post-fix verification (execution `1315`) created no ticket, held the count at 15, and held manager executions at 21.
- The five non-request categories are all real fixtures: `10-pure-venting-no-request`, `13-vendor-email`, `14-out-of-office-auto-reply`, `15-newsletter-marketing-spam`, `16-forwarded-portal-notification`. The scrolling shot should show those actual files.
- Do not reshoot the defect live. The fix is published, so the hook footage has to come from the recorded incident or a clearly labelled reconstruction. If reconstructing, say so on screen.

---

## Post 13. Where your automation gives up, and who it gives up to

**Format:** text, 271 words. **Skeleton:** Story Post, closer cut. **Pillar:** failure lessons. **CTA:** none.

**Rebuilt from the plan's original framing.** Build 1 post 8 owns retry logic and the definition of "I already asked about this." This post deliberately spends one sentence on the count being wrong and the rest on the escalation path.

### The post copy

> The rule I wrote sounded entirely sensible. Ask the resident for missing details twice. If it still isn't clear, hand it to a person.
>
> So that's what it did. A vague report about a door came in. Two rounds of questions went out, neither of them got the detail that was actually missing, and the request landed on the manager's desk exactly as unclear as when it arrived.
>
> Which is the one thing the manager didn't want. They now owned a request they couldn't classify, couldn't route to a trade, and couldn't do anything with except start the same conversation over from the beginning. I had built an escalation path that reliably delivered its least useful output to its busiest person.
>
> The count was never the right condition. Two isn't a number that means anything about a conversation. The right condition is a state: keep asking while a specific named detail is still missing, and escalate for the reasons that genuinely need a person, which are sensitivity and legal exposure, not impatience with the resident.
>
> Small change, and it moved something real. A vague request now stays in the conversation until it's actionable, and the manager gets interrupted once, with something they can act on.
>
> Every automation you own has a give-up path. It fires when the retries run out, or the confidence drops, or the timeout hits, and it hands the problem to somebody. That somebody is usually whoever is busiest, and almost nobody checks what arrives in their lap.
>
> Escalating something unactionable is worse than not escalating it. Now it's a person's problem and it still can't be solved.

*Word count: 271. Characters: 1,606. Em dashes: 0. First 210 characters end inside "Two roun", with the sensible rule stated and its failure withheld.*

### Production notes

- Recorded in `progress-notes.md` 2026-08-13, with the current rule in `AGENTS.md`: do not treat the clarification-round count or a provisional review result as a reason to stop while mapped missing fields remain.
- The closing two lines are the whole point. If the voice pass shortens this post, cut from the middle.
- Watch for drift toward build 1 post 8 during editing. If a draft starts explaining what counts as "the same problem" across repeat contacts, it has crossed into that post.

---

## Post 14. What happens if you tap the button twice

**Format:** single image, plus 148 words of commentary. **Pillar:** what software is allowed to do. **CTA:** none.

### The post copy

> This is what happens when the manager taps the approve button twice.
>
> The obvious way to build this is to send the email when the button is pressed. Press it twice, two plumbers get booked, and the second one bills for turning up.
>
> Instead, the first tap claims the request by writing a row to a table with a unique constraint on it. The second tap can't write that row, so it never reaches the part that sends. It gets told the request is already handled.
>
> That's four lines of schema, and it's the difference between one plumber and two.
>
> Ask any vendor what happens if someone taps twice, or if the network drops halfway through a send. It's a small question and the answer tells you whether anybody thought about the day it goes wrong. "Nobody's tried that" is a real answer you'll sometimes get.

*Word count: 148. Characters: 891. Em dashes: 0. First 210 characters end inside "and the secon", with the failure mode stated and the mechanism withheld.*

### Production notes

- The image is the second-tap response in the manager Telegram chat. Real, and reproducible: approve a demo request, then tap the same button again.
- `triage.vendor_send_attempts` is unique per ticket. The double-approve guard was validated in Stage 6 and again in Stage 9.
- Crop to the two message bubbles. The point is legible at thumbnail size, which the carousel checklist requires of any image doing the work.
- Do not show the schema. A screenshot of SQL turns a buyer question into a developer post, and the audience for this is the person who would ask the vendor, not the person who would write the constraint.

---

## Post 15. Send me a week of your maintenance inbox

**Format:** text, 291 words. **Pillar:** the ask. **CTA:** real.

**On the offers skill.** Applied mostly to decide what not to do. Its "When NOT to Use Offer-Design Tactics" section rules out three things this post could easily have done: manufactured scarcity (there is no real limit on how many inboxes I can look at, so any "only taking three" line would be a lie), a bonus stack (inflating a free diagnostic with extras is the pattern sophisticated buyers see through), and a named, trademarked-sounding offer. The value equation is used honestly: the effort lever is the one doing the work, since the ask is twenty forwarded emails and no system access.

### The post copy

> I don't need access to your property management system, a project plan, or a conversation about budget.
>
> Here's what I'd like instead. Forward me about twenty maintenance messages from a normal week, with names and addresses taken out. Whatever mix you actually get: email, portal forwards, texts someone pasted in, the ones written at midnight.
>
> I'll run them and send back what that week looks like sorted. What would have been flagged an emergency and reached somebody's phone. What would have sat. Which ones were missing a detail nobody thought to ask for. And which ones it got wrong, because across twenty real messages there will be some, and those are the useful part.
>
> No cost, and no call required unless you want one. It takes a couple of days, not a quarter.
>
> Two things I'd rather say up front than have you find out later.
>
> This doesn't touch your PMS and doesn't create a single work order, so that data entry stays exactly where it is now. And it's a demo-depth build rather than a production deployment: the accuracy figures I have come from six messages I picked myself, and the wider testing is unfinished.
>
> On the data. I'd receive the messages you send, they'd sit on a machine I control for as long as it takes to run them and write the reply, and then they're deleted. Nothing goes into a training set. Happy to put that in writing before you send anything.
>
> Asking someone to forward real resident messages to a stranger on the internet is the part of this that deserves an answer before it's asked.

*Word count: 291. Characters: 1,714. Em dashes: 0. First 210 characters end inside "with names and addresses taken", with the ask fully stated.*

### Production notes

- The honest-limits paragraph is the offer's real risk reversal. It replaces a guarantee, which would be the wrong instrument for something free.
- Do not add scarcity, a deadline, a named package, or a "normally $X" line. All four are ruled out by the offers skill's own guidance and all four would contradict the register of the previous fourteen posts.
- "Which ones it got wrong" must survive editing. It is the single most credible sentence in the post and the natural instinct is to soften it.
- The data-handling paragraph goes in the post, not in the comments or a DM. Naming the retention terms unprompted turns the weakest moment into a proof point.
- This is the only post in the set that asks for anything. If it is publishing near another CTA, move one.

---

# Checks run on batch 3

| Check | 10 | 11 | 12 | 13 | 14 | 15 |
|---|---|---|---|---|---|---|
| Accuracy percentages as a proof point | None | None | None | None | None | None; limits stated instead |
| Overclaim vocabulary | Clear | Clear | Clear | Clear | Clear | Clear |
| Request vs work order | Not used | Not used | Not used | Not used | Not used | Stated explicitly |
| Response target language | Not used | Deliberately absent | Not used | Not used | Not used | Not used |
| Product language | Clear | Clear | Clear | Clear | Clear | Clear |
| First 210 characters | Stands alone | Stands alone | Stands alone | Stands alone | Stands alone | Stands alone |
| Length | 205w / 1,232c | 236w / 1,403c | 213w / 1,289c | 271w / 1,606c | 148w / 891c | 291w / 1,714c |
| Voiceover length | 154 words / 60s | n/a | 158 words / 60s | n/a | n/a | n/a |
| Em dashes | 0 | 0 | 0 | 0 | 0 | 0 |
| Banned openers, transitions, closers | Clear | Clear | Clear | Clear | Clear | Clear |
| Structural AI patterns | Clear | Clear | Clear | Clear | Clear | Clear |
| Sentence length variance | Varied | Varied | Varied | Varied | Varied | Varied |
| Offer tactics ruled out | n/a | n/a | n/a | n/a | n/a | No scarcity, no bonus stack, no guarantee, no naming |
| Build 1 collision | No counterpart | No counterpart | No counterpart | Rebuilt away from build 1 post 8 | No counterpart | Same shape as build 1 post 15; only one runs |
| Factual trace | Incident dated 2026-08-13 | `AGENTS.md` rule + Stage 8 test | Incident + execution 1315 | Incident dated 2026-08-13 | Stage 6 and 9 validation | Boundaries from `build-description.md` |

---

# The set is complete

All fifteen posts are drafted. What remains is production, not writing.

## Assets to capture

| Post | Asset | Notes |
|---|---|---|
| 1 | Slide 9 screenshot: both fixtures classified side by side | Run `03-urgent-squeaky-door` and `01-understated-gas` from clean state |
| 2 | Full demo recording, 2:40 | Reset and restore clean snapshot first; on-screen synthetic-data caption |
| 5, 6, 8 | Carousel slide design | One visual template per carousel; legible at thumbnail |
| 7 | Screenshot of the phone-number clarification message | Should still exist in tenant bot Telegram history; reset does not clear it |
| 8 | Slide 9 screenshot: the `progress-notes.md` failure entry, dated 2026-07-31 | Not the scorecard. See that post's production notes |
| 10 | 60s video | Reference numbers `MR-0014`, `MR-0015` may appear; synthetic |
| 12 | 60s video | Fix is published, so hook footage is recorded or a labelled reconstruction |
| 14 | Screenshot of the second-tap response | Reproducible: approve, then tap again |

Slide design uses `image` and `high-end-visual-design`, which were deliberately deferred from scripting. Six carousels' worth of slides plus two image posts is the next unit of work.

## Before publishing anything

1. Read every post aloud and rewrite whatever sounds like me rather than you. The register is consistent with build 1's scripts, but the final voice pass is yours to make.
2. Run the `copy-editing` Seven Sweeps across the whole set in one pass, after that rewrite.
3. Decide post 3's named-versus-unnamed competitor variant.
4. Decide the launch order, which determines whether post 4 ships or is deleted.
5. Truncate the first 210 characters of each post in a real LinkedIn draft and confirm the fold lands where this file says it does. The counts here are computed, not observed.
