# How The Make-Ready Coordination Automation Works

**Audience:** a property manager, operations manager, or owner.

Nothing in this document requires you to know what software the automation is built on. There are no technical terms here that you would need looked up. If you want the engineering detail, it is in `build-technical-notes.md`, and this document is written so that you never have to open it.

**One thing stated up front, because it changes how you should read everything else.** There is no client. This is a working proof of concept running against invented test data: invented buildings, invented vendors, invented units. Every behaviour described here has been watched working, and none of it has been watched working for a real portfolio. Where this document says something was verified, it means it was tested. It does not mean it produced a result for anybody.

---

## The problem

**A unit turn is a chain of handoffs between people who do not talk to each other, and nobody is paid to notice when a link goes quiet.**

Here is what that looks like on a Tuesday.

The painter finishes 12B at two in the afternoon. He packs up and drives to his next job. He does not call, because from where he is standing the work is done and the job is over. Nothing has failed. He was never asked to call, and there is no form for him to fill in.

The flooring crew could start Wednesday morning. They do not, because nobody has told them the unit is theirs. They find out Thursday afternoon, when the coordinator gets through the list and rings the painter to check. The flooring crew has other work booked by then, so they come Monday.

The unit sat empty from Tuesday afternoon to Monday morning. Roughly two days of that was work. The rest was nobody knowing.

Now consider what the coordinator's morning actually looks like. They open the inbox and there is nothing from the painter. That silence has two possible meanings and they look identical:

- The painter finished on Tuesday and said nothing.
- The painter has not started, because his materials are late.

One of those costs a day of rent. The other costs four. There is nothing in the inbox that distinguishes them, so the only way to find out is to ring somebody, and the only way to be sure is to ring everybody. That is the work. Not deciding, not scheduling. Ringing people to find out whether something that already happened has happened.

**The reason this persists at companies that measure everything else is that the lost days are never recorded as lost.** They are absorbed into the total. No property manager has a field called "days spent not knowing the painter was finished." It goes in the file as "turnover took eleven days," and eleven days looks like a slow turn rather than a coordination failure. You cannot fix what your reporting has no name for.

There is a second cost, and it is the one owners tend to miss. Getting the order wrong is expensive in a way that shows up as an invoice rather than as vacancy. Clean before repairs and you clean twice. Lay flooring before paint and you either mask everything or you replace flooring. Nobody logs those as sequencing failures either. They go in as a second visit, or as a slightly higher invoice than expected.

---

## Is this a real industry problem

Yes, and it is measured. The figures below are all published, all sourced, and all linked. They are reused verbatim from this project's research file rather than restated from memory.

| Fact | Figure | Source |
|---|---|---|
| Turns taking nine days or longer | 49% of companies studied; 45% under nine days, with the largest cluster at 5-7 days | [State of the Property Management Industry 2026](https://www.tricapnc.com/pdf/state-of-the-pm-industry-report.pdf) |
| Best-practice benchmark | 3-7 days | PropertyMeld data, via this project's research |
| Cost of one extra vacant day | $50-100 in lost rent | [US Tech Automations, 2026](https://ustechautomations.com/resources/blog/property-management-unit-turnover-pain-solution-2026) |
| Turnover repairs needing a second visit | 20-25% | [US Tech Automations, 2026](https://ustechautomations.com/resources/blog/property-management-unit-turnover-pain-solution-2026) |
| Expedited work premium | 30-50% above scheduled rates | [US Tech Automations, 2026](https://ustechautomations.com/resources/blog/property-management-unit-turnover-pain-solution-2026) |
| Turnover costs year over year | +17.5%, with vacancy and rent loss at $1,323 per unit, a fourth consecutive annual rise | NAA 2024 Income/Expense IQ, cited via [Lula](https://lula.life/articles/what-is-a-make-ready) |
| Repairs and maintenance since 2021 | +28.2% cumulative | NAA 2024 Income/Expense IQ |
| Total make-ready cost | $1,000-5,000 per unit over 5-10 days | [Dropcurb](https://dropcurb.com/blog/apartment-make-ready-checklist) |
| Recovered rent from compressing turns | A 200-unit operator running 100 turns a year at $1,500 rent: $20,000-50,000 a year, moving from 7-14 days to 3-5 | [Lula](https://lula.life/articles/how-to-reduce-days-vacant-on-rental-properties) |
| Sequencing improvement at a single operator | 14 days down to 5 in Phoenix, by removing sequencing bottlenecks | GPS Renting, via [Breasy](https://joinbreasy.com/knowledge/rental-turnover-checklist-for-landlords/) |
| Phone tag | A mid-sized Texas operator losing 2-3 days waiting for vendors to confirm, with 10-15 hours a week per portfolio spent chasing status | This project's research |

The most useful single sentence in the research: **a standard apartment make-ready takes 5-10 days from move-out to rent-ready, and most of the calendar beyond the hands-on work is coordination lag between trades.**

### The arithmetic you can run yourself

A 300-unit company at 40% annual turnover runs about 120 turns a year. If four days of each turn are lost to communication gaps rather than to work, at roughly $50 a day in lost rent, that is about **$24,000 a year**.

**This is arithmetic, not a benchmark and not a result.** It is offered so you can redo it with your own door count, your own turnover rate, your own rent, and your own honest guess at how many days go missing. If your number comes out small, that is a real answer and it means this is not your problem. Nobody has measured $24,000 anywhere. It is four multiplications.

---

## What the research does and does not prove

**What it proves:** turns are slow, the slowness is expensive, a large share of the calendar is coordination rather than work, sequencing errors are common enough to be priced at 20-25% of turnover repairs, and the costs are rising year over year. The problem is real, it is measured by people with no stake in this build, and it is not going away.

**What it does not prove:** that this automation fixes any of it.

None of the sources above tested this system. None of them tested anything like it. They establish that the disease exists and what it costs. They say nothing about this particular treatment, because this particular treatment has never been given to a patient.

Two further limits worth being explicit about:

**The category is not empty.** Make Ready Manager, TurnTrack, AppWorks, SuiteSpot, HappyCo, Property Meld, and Rent Manager's own Make Ready module all sell into this problem. Several of them already enforce stage ordering; automated turnover systems advertise preventing progression until previous stages are complete and verified. **Ordering enforcement is table stakes in this category, and nothing in this document should be read as claiming it is novel.** If you run more than 500 doors, the enterprise tools are built for you and you should look at them first. If you already pay for Rent Manager, try the module you are already buying before you buy anything else.

**The one figure that is a real difference is not a feature.** It is that the vendor does nothing new. Property Meld's own documentation describes vendors receiving an emailed invite, clicking through, entering details, creating a password, and completing registration before they can manage work orders. Every portal-based product needs the vendor to become a user first, and vendor adoption is where these deployments actually die. That is a genuine distinction, but it is a distinction about adoption, not about capability.

---

## The solution

**A vendor replies however they already reply, the automation works out what they meant and whether the order allows it, and then it drafts the next vendor's message and stops, because a person, not the automation, decides whether anything leaves the building.**

The whole design follows from one observation: the expensive part of a turn is not doing the work and it is not deciding what to do. It is finding out that something finished. So the automation is pointed entirely at that gap. It watches for vendors saying they are done, in whatever words they use, on whatever channel they already use. It confirms which unit and which stage, checks that the order permits it, closes the stage, writes the handoff to the next trade, and then holds it in front of a person.

It also watches the silence. Every stage carries an expected duration. A stage that passes it with nothing heard raises exactly one alert, in business hours. That is the part with no equivalent in an inbox: nothing arriving is the event.

Two things it deliberately is not. It is not a system of record: your property management system stays the system of record and this never writes to it. And it is not a screen you log into. Everything it produces lands in tables your company already owns.

---

## The stages, and where it stays quiet

A turn is expanded into eleven stages. Each one carries an expected duration, which is what the automation uses to decide when something has gone quiet. **This is an expected duration, not a deadline and not a service level agreement.** Nobody has committed to it and nothing is breached when it passes. It is the point at which silence becomes worth mentioning.

| # | Stage | Expected duration | Cannot start until |
|---|---|---|---|
| 0 | Notice received | none | n/a |
| 1 | Pre-move-out inspection | 48 hours | n/a |
| 2 | Move-out / keys returned | none | n/a |
| 3 | Inspection + punch list | 24 hours | Move-out |
| 4 | Trash-out | 24 hours | Move-out |
| 5 | Repairs / trades | 72 hours | Move-out |
| 6 | Paint | 48 hours | Move-out, Repairs |
| 7 | Flooring | 48 hours | Move-out, Paint |
| 8 | Deep clean | 24 hours | Move-out, Repairs, Paint, Flooring |
| 9 | QA walkthrough + photos | 12 hours | Move-out, Deep clean |
| 10 | Relist | none | Move-out, QA walkthrough |

A stage you deliberately skip counts as satisfied. Skipping is a decision, not a violation, and the automation treats it as one.

**Paint before flooring is this operation's order, not a law of building.** A painter may argue the reverse and in some renovation and new-construction contexts they are not simply wrong. The order above is written down once so that nobody has to re-argue it at four o'clock on a Friday, and it can be changed if an operator wants it changed.

### Where it deliberately does nothing

Three of the eleven stages, Notice received, Move-out and Relist, carry no expected duration at all. **They can never raise an alert, no matter how long they sit.** That is not an omission. A unit under notice that has not been vacated has burned nothing, so counting its days would be wrong. A move-out happens when a resident hands back keys, which is not a vendor's fault and not something chasing improves. And Relist is your decision about a unit that is already rent-ready, which is exactly the point at which the automation's job has finished and its opinion stops being useful.

The same restraint applies to your own people. Stages assigned in-house are excluded from the watchdog entirely. The automation will not tell you that your own coordinator is slow. You can see your own team; you cannot see a subcontractor's van.

The result is that the watchdog only ever speaks about outside-vendor work with an expected duration attached, which is to say, only about the places where you genuinely cannot see. **A system that alerts on everything trains people to ignore it, and an alert people have learned to ignore is worse than no alert.** Most of the design effort here went into deciding what not to say.

---

## The complete flow, in the order it happens

1. **A turn is created.** A manager fills in a short intake form with business facts only: unit, address, rent, move-out date. Submitting the same turn twice does not create two turns.

2. **The turn is expanded into its eleven stages,** each with its expected duration and its prerequisites, and each assigned to a trade.

3. **Only the stage that is allowed to start becomes active.** Everything downstream waits. Nothing is chased, drafted, or alerted on for a stage that cannot legally begin.

4. **A vendor sends an ordinary message.** A text in their messaging app, or a reply to an email. No form, no portal, no account, no app to install. They write "12b is done" or "wrapped up, second coat finished today" or "all good except the closet" in whatever words they normally use.

5. **The automation works out who sent it** and what that person is currently assigned to. If the sender is not recognised, nothing moves and the manager is told. **An unrecognised sender is never told anything about a unit.**

6. **The message is read and turned into a structured reading:** what the vendor appears to mean, which unit they seem to be referring to, how confident that reading is, and whether anything in the message is sensitive: money, deposits, liability, or an attempt to instruct the automation rather than inform it.

7. **Which unit it actually is gets decided separately, on evidence, not on the reading.** A reply to a specific message resolves to that message's unit. A unit number written in the text resolves to that unit. A street name alone is weaker and may not be enough. **If two candidates are equally good, it asks the manager rather than choosing.** This matters most when one vendor holds two of your units at the same stage, which is the situation where a bare "done" means nothing at all.

8. **A fixed policy check decides whether the automation may act.** It may not, and instead tells the manager, if: the message repeats one just received, the reading is not confident enough, the unit is ambiguous, the sender is not the vendor assigned to that stage, the message is a question or a delay notice rather than a completion, anything sensitive was flagged, or the interpretation step was unavailable. **Only a confident, unambiguous completion from the assigned vendor gets any further.**

9. **The order is checked, separately again.** If the stage cannot close yet, nothing moves and the refusal comes with a plain-language reason, such as repairs still being open on that unit. **The manager gets the same refusal that a vendor gets.** The same check runs for a button press as for a vendor message, so there is no path that quietly bypasses it.

10. **The stage closes.** Any stale draft still sitting against that stage is cancelled at the same time, so nobody chases work that has just been reported finished.

11. **The next vendor's message is drafted from the facts of the record**: unit, address, stage, vendor name. The wording is tidied up automatically, but the facts are not invented and cannot be. If the tidying step is unavailable, the plain factual version is used instead and the message still goes out correctly.

12. **The draft reaches the manager, and nothing has been sent.** The card says what completed, who reported it, what happens next, and shows the exact text that would go out. **If a manager marked the stage complete themselves, the card says so rather than crediting the vendor.**

13. **The manager chooses Email, Message, or Both.** Ignoring the card is a valid decision: the draft stays open and nothing goes out. Choosing a channel the vendor has no address or number for does not fail silently. It is recorded as blocked and the manager is told.

14. **Delivery is recorded separately for each channel chosen.** If Both is chosen and one channel fails, the successful one is never repeated, the failed one can be retried on its own, and the record reads as partially sent rather than as sent.

15. **The next stage becomes active as soon as one channel has succeeded,** because the vendor has been reached even if the second route did not work.

16. **If nothing is ever heard, the silence itself raises one alert,** once, in business hours, for that stage. It can be snoozed for a day. The manager can then either mark the work done or send a chase, and a chase is a draft too, which the manager still has to release.

---

## What each tool does

| Tool | What it does, in one line |
|---|---|
| Airtable | The manager's workspace: turns, stages, vendors, messages, approvals and delivery results, plus the form used to add a new turn. |
| Telegram | Carries vendor messages inbound, and carries every manager alert, approval and control outbound. |
| Company mailbox | Receives vendor replies and sends approved vendor messages. |
| A private database | Holds the authoritative history of every turn, stage, message, approval and delivery attempt. |
| OpenAI | Reads free-form vendor wording and proposes what it means. It decides nothing. |
| The orchestration layer | Runs the automations and moves information between the tools above. You never open it, and you do not need to know what it is. |

**Airtable is a mirror, not the truth.** The private database is authoritative. If Airtable is unavailable, sequencing carries on and the mirror catches up afterwards. Nothing about a vendor message or an approval depends on Airtable working.

**Telegram is a stand-in for the demonstration.** It proves that a vendor can reply from a messaging app they already have, without installing anything. For a real deployment in the US, text messaging is the channel vendors would actually use, and enabling it requires registration under the client's own identity. That has not been done and is described below under production.

---

## The human boundaries

These are enforced in code, not by asking the model nicely. They are conditions in the workflow logic, and the automation cannot talk its way past them.

- **No vendor is contacted without a person choosing a channel.** Across the entire build, exactly two steps can contact a vendor, and neither runs until a manager presses a button.
- **Ignoring an approval is a valid decision.** There is no timeout that sends it anyway.
- **The order rules apply to the manager too.** A manager pressing Done goes through the same check as a vendor message. Overriding is possible, and the override is recorded as an override.
- **An unrecognised sender is told nothing.** No unit, no address, no status.
- **A vendor can only ever complete their own work.** The candidate units considered for a message are restricted to stages assigned to that vendor before any matching happens, so a vendor claiming another vendor's stage is not a check that could fail. It is a state that cannot be reached.
- **Ambiguity is escalated, never guessed.** Two equally good matches produce a question, not a choice.
- **Money and liability are flagged, not handled.** Deposits, invoices, damage charges and tenant liability route to a person with no drafted answer attached.
- **A successful delivery is never repeated.** Retry acts only on the channel that failed.

---

## What the system will not do

These are design decisions, not gaps waiting to be filled. Several of them would be straightforward to build and are deliberately absent.

- **It does not write into your property management system.** Your PMS stays the system of record. That data entry remains yours.
- **It does not choose which vendor gets the job.** Assignment is a human decision about relationships and price.
- **It does not communicate with residents.** Nothing here ever contacts a tenant.
- **It does not chase a vendor on its own.** There is no automatic follow-up, no escalation ladder, no nudge after a timeout.
- **It does not judge workmanship.** Photos are stored for a person to look at. Nothing scores them.
- **It does not decide deposits, damage, wear and tear, liability, invoices or payments.**
- **It does not screen residents, publish listings, write ad copy, or price units.**
- **It does not handle maintenance in occupied units.** Different problem, different build.
- **It does not send text messages.** The design exists; the capability is switched off and stays off until it can be registered under a real client's identity.
- **It has no dashboard.** There is nothing to log into that you do not already own. A visualisation screen was built during development and deleted, because it was a screen that existed only because the builder existed.

---

## What the proof of concept proves today

Each of these has been observed working in a real run against test data, over real messaging and a real mailbox.

- A vendor completion sent as an ordinary message closes the right stage and drafts the next handoff, on messaging, on email, and through a generic inbound route.
- Messy human wording is read correctly. Live runs included "don3e", "yeah thi si sdone" and "task complete", all handled; and "on it", correctly logged as an update that advances nothing.
- **Ambiguity resolves correctly under the hardest realistic condition.** With one flooring vendor holding two units at the same stage, a reply of "done" to a specific message advanced only that unit. The other stayed exactly where it was.
- The order guard refuses out-of-order completions with a plain reason, and refuses a manager exactly as it refuses a vendor.
- Marking an already-complete stage complete again is refused and recorded, and changes nothing.
- Pressing a delivery button on a queue already sent is rejected and does not send again.
- All three delivery choices work. A single-channel choice creates exactly one delivery record, not two.
- Choosing a channel the vendor has no destination for is recorded as blocked and alerts the manager, rather than failing quietly.
- Completing a stage cancels any stale chase draft still open against it.
- The daily digest offers Done and Chase on the three most overdue units, and both work on units other than the top one.
- A manager's own completion is attributed to the manager on the card, not to the vendor.
- Silence raises one alert per stage, held outside business hours and released inside them.
- The manager workspace mirrors the database exactly: six turns and sixty-six stages, with linked records populated.
- When a workflow throws, a separate handler records it and alerts the builder rather than the manager.
- Twenty scripted scenarios and sixteen message-interpretation scenarios pass.

**This is testing. It is not a customer result.** There is no client, no pilot, and no portfolio behind any of it. The buildings are invented, the vendors are invented, the units are invented. Nothing above says the automation made anybody's turns faster, because nobody has used it on real turns. It says the automation behaves correctly, including when it should refuse.

One path remains untested: retrying a delivery after a genuine channel failure. Producing one requires deliberately breaking a vendor's contact details, and it has not been done.

---

## What a client pilot must measure

A pilot exists to answer one question that testing cannot: **do your vendors actually reply?**

Everything else in this build works whether they do or not. The order rules, the refusals, the workspace, the manager controls, the silence alerts, all of that functions at a zero percent vendor reply rate, because a manager can drive the whole thing by hand. **The vendor reply rate is the only variable the pilot really turns on**, and it decides which product you actually bought.

- **Below roughly 30%**, the automated half is fiction and the honest answer is to say so. What you have is a coordination workspace with good ordering discipline and manual control. That is worth something, but it is not what this document has been describing.
- **Above roughly 60%**, it works as designed and the coordination time genuinely moves.
- **In between**, it depends on which vendors reply. One responsive painter and four silent trades is not the same as five vendors who each reply half the time.

Alongside that, agree these before go-live and report them from week one even when they look bad:

| Measure | What it tells you |
|---|---|
| Vendor reply rate | Whether vendor automation is viable at this company at all |
| Auto-handled rate | Share of vendor messages reaching a safe outcome without a manager identifying the unit or intent |
| Median hours per stage | Where the real bottleneck is, by stage and by vendor |
| Median move-out to relist days | The vacancy outcome, and the only number an owner cares about |
| Sequence violations blocked | How often the order rules actually caught something |
| Delivery failures | Whether the contact details you hold for vendors are correct |

Two reporting rules that matter more than the list. **Do not promise a percentage improvement before there is data.** Compare before and after only when there is a real baseline or an agreed pilot window. And **separate manual completions from vendor replies in every report**, because mixing them makes a manually-driven pilot look like an automated one.

The one thing not to measure: leasing speed. This affects **days vacant**, the time to get a unit rent-ready. It does not affect **days on market**. It does not lease anything. Anyone reporting these as one number is measuring the wrong thing.

---

## What production would add

Nothing below exists today. This is the gap between a working proof of concept and something a company runs on.

**Text messaging as the vendor channel.** Messaging apps prove the principle, but US trade vendors text. Enabling that requires business messaging registration under the client's own identity, recorded vendor consent, working opt-out handling, and a state-law review. It is designed and switched off.

**A client-owned server.** Today this runs on a laptop behind a temporary tunnel. Production is a server the client owns and pays for, with a proper domain and certificate, so the client owns the instance and can keep it if the relationship ends.

**Backup, restore, and monitoring.** Templates and procedures exist. They have not been operated.

**Real vendor and property data,** replacing the invented roster, with contact details verified before anyone relies on them.

**The manager's workspace laid out properly.** The tables and the intake form are provisioned automatically; the presentation layer over them is a manual configuration step. Managers get a view and the intake form as their only writing surface.

**Optional, and only if separately agreed:** a connection to the client's property management system. It is deliberately out of scope now. It requires knowing which system, whether its interface permits it, and who owns the resulting data, and it is the fastest way to turn a narrow, honest automation into a project.

**What production would not add:** autonomous vendor messaging. That is not a roadmap item that has not been reached. It is a decision. A person releases every message, in the pilot and afterwards.
