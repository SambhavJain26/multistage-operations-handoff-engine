# Production Make Ready Sequencing Automation Blueprint

## Purpose and scope

This blueprint describes how a production make-ready sequencing automation would operate inside an established residential property management company. It is written for owners, executives, operations leaders, and turnover managers. It explains the business outcome first, then the operating model, systems, controls, exception handling, and the exact elements needed to draw a complete workflow map.

The system coordinates vacant-unit turnover from notice through rent-ready handoff. It does not replace the property management system, decide security-deposit liability, inspect workmanship, publish listings, or manage occupied-unit maintenance. The property management system remains the official record for residents, leases, properties, accounting, and compliance. The automation closes the operational gaps between make-ready stages and maintains a durable coordination record around those handoffs.

The figures in the opening example are illustrative operating assumptions, not promised results. A production pilot must establish the client's actual baseline and measure its own outcomes.

# 1 Business impact at scale

## An illustrative operating day in a 5000 unit company

At 7:00 on a Monday morning, a regional property management company has 126 units somewhere between notice received and rent ready. Those turns are spread across 24 properties and involve five regional managers, 18 site teams, an internal maintenance group, and more than 40 outside vendors. No single employee has to reconstruct the portfolio from email, text threads, vendor calls, and property management system notes.

The automation has already assembled the current operating picture. It identifies 17 stages beyond their agreed service window, 11 next-vendor messages waiting for manager approval, four approved deliveries blocked by missing contact information, six turns approaching their target-ready dates, and two completion reports that cannot be matched safely to a unit. Each item has an owner, a status, an age, and a recorded next action.

During the day, vendors send ordinary replies such as “12B done,” “materials delayed until Thursday,” and “which lockbox?” by email, text-enabled channel, or another approved messaging channel. The automation records every message, identifies the sender, interprets the wording, and compares it with the vendor's assigned work. A clear completion can close the current stage, but only after fixed rules confirm the unit, vendor assignment, duplicate status, and work sequence. The next vendor is never contacted automatically. The system prepares the message and puts an approval card in the turnover manager's normal manager channel. The manager chooses Email, Message, or Both.

By 4:00, the company has processed dozens of small turnover events without asking coordinators to remember which vendor to call next. The employees still handle decisions, exceptions, vendor relationships, owner approvals, and quality control. The automation handles the repeated administrative work around those decisions: collecting signals, maintaining status, applying ordering rules, drafting routine handoffs, watching elapsed time, and making exceptions visible.

## How small savings become operating capacity

The value appears in small increments. One vendor completion may save only a few minutes of checking, recording, and preparing the next message. One stall alert may prevent only one forgotten follow-up. One sequence block may prevent only one return visit. At portfolio scale, those events repeat thousands of times.

Consider an illustrative 5000-unit portfolio with 35 percent annual turnover:

| Operating assumption | Illustrative volume | Business meaning |
|---|---:|---|
| Annual turns | 1750 | Units moving through the process each year |
| Coordinated handoffs per turn | 8 | Vendor-sensitive transitions between inspection, trash-out, repairs, paint, flooring, cleaning, and QA |
| Annual handoffs | 14000 | Repeated opportunities for delay, status checking, and missed follow-up |
| Administrative time avoided per handoff | 4 minutes | Status lookup, update, next-message preparation, and logging |
| Annual administrative capacity released | About 933 hours | Roughly half of one full-time working year before any vacancy benefit |
| Daily rent exposure per vacant unit | $60 | Illustrative value for portfolio arithmetic |
| One avoidable idle day removed per turn | $105000 annual rent exposure | A scenario for planning, not a promised recovery |

These figures show why the system is more than a convenience. The operating gain does not depend on one dramatic event. It comes from making thousands of ordinary handoffs faster and harder to lose.

## What changes for the business

The production outcome is a more controlled turnover operation:

- Coordinators spend less time asking for status and copying updates between systems.
- A silent vendor, missing destination, ambiguous reply, failed delivery, and overdue stage become visible work instead of hidden risk.
- Every property follows an agreed sequence while still allowing an authorized manager to skip or override when the unit genuinely requires it.
- Managers see current workload and exceptions across properties without reading every communication thread.
- Vendor messages remain in the company's normal channels, so adoption does not depend on contractors learning a portal.
- The business can add properties and turns without increasing administrative headcount in direct proportion to event volume.
- Executives gain measurable operating data, including vendor reply rate, safely auto-handled messages, stage duration, move-out-to-ready duration, and blocked sequence violations.

The automation does not eliminate the need for property managers. It protects their attention. Employees spend more time resolving real issues and less time discovering that an issue exists.

# 2 Real world production example

## Unit 12B from notice to rent ready

A resident at Unit 12B submits notice through the company's resident portal. The property management system records the notice date, lease end, property, resident, and expected move-out. That event is the business trigger.

If the property management system supports webhooks or an approved API, it sends the notice event to the automation. If it does not, the automation can receive the same information from an approved report, a monitored mailbox, or a short intake form used by the turnover coordinator. The production goal is to reuse information the company already captures, not to make the site team recreate the lease record.

The automation creates the coordination record for 12B and applies the correct stage template for that property type. The notice and pre-inspection stages begin before vacancy. The vacancy clock does not begin until keys are returned or move-out is confirmed.

After move-out, the inspector completes the punch list in the company's existing inspection or maintenance tool. The automation receives the work-ready signal and activates Trash-out. It does not decide whether any item is tenant damage, normal wear, or deposit deductible. Those decisions remain in the company's compliance process.

The trash-out vendor receives work only after a manager approves the outbound channel and message. When the vendor replies “12B cleared, photo attached,” the system stores the communication, preserves the photo for human review, and checks four facts: the sender is known, 12B is a safe match, Trash-out is the vendor's active assignment, and the sequence permits completion. If all four checks pass, Trash-out closes and Repairs becomes ready for approval.

The same pattern continues through Repairs, Paint, Flooring, Deep Clean, and QA. When Paint finishes, the automation will not let Deep Clean close if Flooring is still required and open. If Flooring is not needed for this unit, a manager records a skip. A skipped stage counts as satisfied and remains visible in the audit history.

Suppose the flooring vendor says, “done at Maple.” The company has three active Maple units. The system does not guess. It shows the original message and candidate units to the manager. If the vendor used the email Reply action on the original 12B assignment, the stored thread reference can safely narrow the context, but it never overrides the assigned-vendor check.

When QA is complete, the automation records the completion and returns a rent-ready status to the appropriate operating surface. Depending on the client's approved integration, that may update a PMS task, close a maintenance work order, add a note, create a leasing-team task, or place a rent-ready item in an integration queue for an employee to confirm. It never publishes a listing or changes rent without a separately authorized workflow.

## The human experience

The turnover coordinator does not supervise a hidden robot. They receive a concise queue of decisions in the company's approved manager channel. A normal day includes approval cards, exception notices, and a digest of the most overdue work. Each card shows the unit, property, current stage, source of the update, draft message, and the action that will occur.

The coordinator can ignore a draft. It remains open and visible. They can choose Email, Message, or Both. If a vendor has no destination for the selected channel, the system records a configuration block and alerts the manager. It does not silently switch channels or pretend the message was sent.

# 3 What the production system does

## Core operating responsibilities

The production system performs nine business functions.

### Creates a coordination record

It opens a turn from an existing business event and attaches the correct property, unit, dates, rent context, stage template, service windows, and vendor assignments.

### Maintains current stage state

It records each stage as pending, active, awaiting approval, complete, skipped, blocked, cancelled, or otherwise configured for the client. Only one stage is active for a normal turn unless the client approves a different parallel-work rule.

### Receives vendor communications

It accepts messages from approved channels such as email, Telegram during pilot use, a generic inbound interface for text messaging, or a client-specific connector. Every channel is normalized into the same business envelope so downstream decisions do not depend on how the message arrived.

### Interprets free form messages

AI identifies likely intent and extracts only the wording needed for routing, such as a unit hint, work type, or stated timing. The original message remains attached to the record.

### Applies fixed safety rules

Deterministic controls verify sender identity, unit match, vendor assignment, duplicate status, stage status, confidence, and sequence. AI output alone cannot update a stage or contact a vendor.

### Prepares and gates outbound work

The system builds the next assignment or chase message and waits for the manager. The manager authorizes Email, Message, or Both. Each authorized channel receives its own delivery record.

### Watches for absence

Scheduled monitoring compares active-stage age with the client's service windows, quiet hours, snoozes, and previous alerts. It makes silence visible without automatically nagging the vendor.

### Mirrors status into business tools

The system updates the manager workspace and, where approved, returns a status, task, note, or completion signal to the PMS or related tool. Synchronization failure does not change the authoritative sequencing state.

### Preserves an audit trail

Every meaningful branch is recorded, including rejected duplicates, uncertain messages, sequence blocks, manual actions, approvals, delivery attempts, failures, retries, and completions.

## What the system does not do

The production design has clear boundaries:

- It does not replace the PMS, accounting system, lease record, inspection tool, or document system.
- It does not determine security-deposit deductions or tenant liability.
- It does not inspect photo quality or certify that work was performed correctly.
- It does not select vendors, accept bids, approve invoices, or commit spend unless separately designed and authorized.
- It does not send an autonomous vendor message.
- It does not handle tenant screening, pricing, advertising, or fair-housing-sensitive decisions.
- It does not manage occupied-unit maintenance or emergency response.

# 4 How the system integrates with the existing PM business

## Integration principle

The automation is installed around the company's current operating stack. It listens for events, reads the minimum information needed, coordinates the make-ready process, and writes useful status back. The company does not migrate its portfolio, accounting, leases, or resident records into a new product.

## Where information can enter

The preferred input is the company's existing property management or maintenance system. Production connection options are selected in this order:

1. Approved webhook or API events for notice, move-out, work-order, inspection, and unit-ready changes.
2. Scheduled API reads for systems that expose data but do not emit events.
3. Approved report exports or secure file drops for systems with limited APIs.
4. Monitored operational email for notifications already sent by the PMS or inspection platform.
5. A short manager intake form for the few fields the source system cannot provide.

This tiered approach lets the company begin without waiting for a perfect integration. A later API connection can replace a report or form without changing the sequence guard, communication logic, manager approvals, or database model.

## Where employees work

Most employees continue in their existing tools:

- Site teams create notices, inspections, and maintenance records in the PMS or inspection system.
- Vendors reply through email or the approved messaging channel they already use.
- Turnover managers receive approvals and exceptions in the approved manager messaging channel. The current reference implementation uses Telegram; a client deployment can retain it for a pilot or replace the transport with an approved equivalent while preserving the same controls.
- Executives and coordinators see portfolio status in an Airtable Interface or an approved existing reporting surface. They do not edit the automation's synced operating tables directly.
- Leasing and accounting teams receive only the handoff relevant to their existing work, such as a rent-ready task, PMS note, or exception.

Airtable is a practical manager-facing mirror when the PMS cannot show sequence age and exception queues. It is not the database of record. If the client already has a suitable operations dashboard, the same status can be surfaced there instead.

## Read and write boundaries

Production integrations should be explicit about authority.

| Information | Primary owner | Automation use | Write back |
|---|---|---|---|
| Resident, lease, property, unit | PMS | Identify the turn and dates | Normally read only |
| Inspection and punch list | Inspection or maintenance tool | Activate work stages and link evidence | Status or reference only |
| Turn sequence and coordination state | Automation database | Enforce order and maintain current state | Mirrored summary to PMS or workspace |
| Vendor contact and consent | Approved vendor master | Match sender and authorize channels | Corrected contact data through controlled process |
| Vendor messages | Communication systems and automation log | Interpret and route | Summary or link where useful |
| Accounting, invoices, owner approvals | Accounting or PMS | Exception context only | No financial action in core scope |
| Rent-ready or relist handoff | PMS or leasing system | End state of make-ready coordination | Create or update approved task or status |

## Practical adoption sequence

The company can start with a sidecar deployment that reads a daily turn feed and uses manager-approved messaging. Once the operating rules are proven, higher-value write-backs can be enabled one at a time. This reduces implementation risk and avoids forcing a broad process redesign before the company has evidence that the workflow fits its teams and vendors.

# 5 Major components and why they exist

## Business actors

| Actor | Role in the system | Decisions retained by the actor |
|---|---|---|
| Resident | Creates notice and completes move-out process | Notice, access, keys, resident obligations in existing systems |
| Site team or property manager | Starts and oversees the turn | Correct unit, dates, exceptions, manual completion, skip, override, cancellation |
| Turnover coordinator | Manages portfolio handoffs | Outbound channel approval, ambiguous matches, vendor escalation |
| Inspector or maintenance lead | Produces punch list and final QA | Scope accuracy and workmanship acceptance |
| Vendor | Performs assigned stage and reports status | Completion, delay, question, evidence |
| Leasing team | Receives rent-ready handoff | Listing, pricing, showing, and applicant process outside this automation |
| Operations leader | Reviews performance and exceptions | SLA policy, staffing, vendor process, expansion decisions |
| System operator | Maintains the client-owned automation | Reliability, credential rotation, restores, controlled releases |

## Existing business systems

### Property management system

Purpose: official record for properties, units, residents, leases, dates, work orders, and often accounting.

Receives: approved status summaries or tasks when write-back is enabled.

Sends: notice, move-out, unit, property, rent context, inspection, work-order, and rent-ready events or reports.

Communicates with: integration gateway and, where permitted, the reporting workspace.

Why needed: the automation must fit the company's official process and avoid creating a competing portfolio record.

### Maintenance and inspection tools

Purpose: capture work scope, punch lists, technician activity, and QA evidence.

Receives: task references or stage status where the client wants them.

Sends: inspection complete, punch list ready, work-order status, and QA complete signals.

Communicates with: PMS, integration gateway, and document or photo storage.

Why needed: make-ready sequencing depends on verified business events, while scope and quality remain with the teams that perform the work.

### Email and messaging providers

Purpose: carry vendor replies and approved outbound assignments through channels vendors already monitor.

Receives: manager-approved message and destination.

Sends: inbound message, thread identifiers, provider delivery result, bounce or failure status, and attachments.

Communicates with: n8n orchestration, vendor master, durable communication records, and manager channel.

Why needed: the automation succeeds only if it can observe the same communication signals the company already relies on.

### Manager workspace

Purpose: show turns, stages, vendors, communications, approvals, delivery states, overdue work, and exceptions in a business-friendly view.

Receives: a synchronized mirror from the authoritative database.

Sends: new-turn intake or approved configuration changes through controlled forms.

Communicates with: n8n synchronization and the company's reporting process.

Why needed: the PMS may not expose stage age, cross-property bottlenecks, or message-level delivery states in one view.

## Automation platform components

### n8n orchestration

Purpose: run the continuous workflows that connect systems and coordinate each event.

Receives: PMS events, forms, schedules, vendor messages, manager actions, delivery results, and system errors.

Sends: database updates, AI requests, approval cards, provider sends, workspace synchronization, alerts, and write-backs.

Communicates with: every integration through client-owned credentials.

Why needed: it makes the process visible, configurable, and transferable to another qualified operator without creating a custom SaaS application.

### PostgreSQL authoritative coordination database

Purpose: store durable make-ready state and guarantee consistent transitions.

Receives: turns, stage changes, messages, approvals, delivery attempts, mappings, evidence references, and audit events.

Sends: current state and history to workflows, monitoring, manager views, and reports.

Communicates with: n8n only on the private network; it is not exposed publicly.

Why needed: sequence enforcement, duplicate protection, retries, and auditability require transactional state that a spreadsheet mirror cannot provide.

### OpenAI message interpretation and drafting

Purpose: interpret varied contractor language and improve the wording of short drafts.

Receives: the minimum message text and limited work context required for the task. Production configuration should omit names, full addresses, photos, resident data, and unrelated history whenever possible.

Sends: a structured interpretation or a revised draft. It does not send messages or update records.

Communicates with: n8n through a controlled request and response path.

Why needed: vendors use typos, shorthand, and inconsistent wording that rigid keyword rules cannot handle well.

### Deterministic matcher and sequence guard

Purpose: make the decisions that must be predictable.

Receives: known sender, extracted hints, assigned stages, stage history, and requested transition.

Sends: allowed, blocked, duplicate, ambiguous, or review-required outcomes with a plain reason.

Communicates with: vendor inbound, manual manager actions, stage completion, and exception handling.

Why needed: a wrong-unit update or out-of-order completion has a higher cost than asking a manager.

### Delivery ledger

Purpose: keep one durable record per authorized outbound channel.

Receives: queue item, authorized channels, current destination, provider result, retry count, and timestamps.

Sends: sent, partially sent, failed, configuration blocked, or retry-required status.

Communicates with: email, messaging provider, manager alerts, stage activation, and workspace sync.

Why needed: dual delivery must never infer that both channels succeeded from one provider response, and retries must not duplicate a channel that already succeeded.

### Integration mapping and synchronization

Purpose: connect the authoritative record with external record identifiers and prevent unnecessary rewrites.

Receives: source identifiers, external identifiers, and payload hashes.

Sends: creates, updates, links, and reconciliation exceptions.

Communicates with: PMS connector, Airtable, and the authoritative database.

Why needed: external tools have their own identifiers and may be temporarily unavailable. The sequence must continue safely while a mirror catches up.

### Monitoring backup and recovery services

Purpose: detect silent failures, protect data, and provide recovery evidence.

Receives: health checks, workflow errors, expected workflow inventory, provider failures, backup results, and inactivity signals.

Sends: builder alerts, retry work, dead-letter records, restore-test records, and incident status.

Communicates with: n8n, Postgres, public webhook endpoints, and the system operator.

Why needed: the dangerous failure is often silence, such as an inactive workflow or expired webhook, rather than a visible crash.

### Client owned hosting and security boundary

Purpose: keep the runtime, data, credentials, and access under the client's control.

Receives: approved software releases and operator access.

Sends: secure HTTPS endpoints and private service connectivity.

Communicates with: DNS, reverse proxy, n8n, Postgres, backup storage, and monitoring.

Why needed: the client can revoke access, retain its data, and transfer maintenance without depending on a multi-client vendor platform.

# 6 How the components communicate

## Standard business event envelope

Every inbound source is converted into a common event record. At business level, the record contains:

- event source and channel;
- source-system identifier and timestamp;
- property, unit, turn, and stage hints where present;
- known sender or unresolved sender reference;
- original text and permitted attachment references;
- thread or reply context;
- processing status and correlation identifier.

The common envelope lets email, messaging, PMS, form, and future text-message inputs share the same matcher, AI interpreter, safety rules, and audit history.

## Communication pattern

The main communication pattern is:

1. A source system emits or exposes a business event.
2. n8n validates and normalizes the event.
3. Postgres records the event before any material action.
4. AI may propose an interpretation or wording.
5. Deterministic controls decide whether the event is safe to apply.
6. Postgres commits the state change and creates any approval or exception.
7. The manager channel receives a decision card when required.
8. An approved outbound action creates one delivery record per channel.
9. Provider results update delivery state.
10. The manager workspace and approved source-system surfaces receive the new status.

## Authority and failure isolation

Postgres is authoritative for coordination state. Airtable and other business views are mirrors. If a mirror is unavailable, the automation records the sync failure and continues to protect the turn sequence. If the PMS write-back fails, the system keeps the pending write-back visible for retry and alerts the appropriate operator. A failed display update must never roll back a valid sequence decision.

External actions use an outbox pattern. The business decision and the intended message are saved before a provider call. The provider response then updates the individual delivery record. This makes retries controlled and auditable.

# 7 Human involvement and AI boundaries

## What AI is responsible for

AI performs two narrow tasks:

1. It classifies short vendor messages into operational intents such as completed, started, delayed, question, wrong unit, or unclear, and extracts wording that may identify a unit, stage, or timing.
2. It rewrites a deterministic outbound template into the client's approved communication style while preserving the facts.

AI is useful here because the input is informal and variable, while the output is easy for a human or deterministic rule to check.

## What AI cannot decide

AI cannot decide:

- which unit is safe to update;
- whether the sender is authorized for the active stage;
- whether the work sequence allows completion;
- whether a message is a duplicate;
- whether a vendor should be contacted;
- which channel should be used;
- whether a stage should be skipped, overridden, or cancelled;
- whether a photo proves workmanship;
- whether damage is chargeable to a resident;
- whether a unit should be listed or a price changed.

These decisions remain with fixed rules or an authorized employee.

## Human review points

| Review point | Why a human is required | Available outcome |
|---|---|---|
| New turn exception | Source data is incomplete or contradictory | Correct data, hold intake, or close duplicate |
| Ambiguous unit or stage | More than one safe candidate exists | Select candidate or contact vendor |
| Unknown or mismatched sender | Identity or assignment is not trusted | Map sender, reject, or investigate |
| Low confidence or risky language | Message may concern deposits, costs, residents, safety, or another process | Route to correct team with no stage change |
| Sequence violation | Business may have a valid exception, but rework risk exists | Keep blocked or override with reason |
| Outbound message | Vendor relationship and timing remain the manager's responsibility | Email, Message, Both, or no action |
| Missing destination | Selected channel cannot be used | Correct contact, select another channel, or leave blocked |
| Final QA | Workmanship must be inspected by a person | Accept, reopen a stage, or create follow-up work |

## Safe failure behavior

When AI is unavailable or returns an invalid result, the system does not infer completion. It preserves the original message and sends it to the manager for review. Drafting falls back to the approved deterministic template. An AI outage may reduce convenience or tone quality, but it must not bypass the sequence guard or create an autonomous send.

# 8 End to end production workflow

## Phase 1 Notice and turn creation

1. The resident notice is entered in the PMS.
2. The PMS connector, report, mailbox, or intake form produces a Notice Received event.
3. The automation validates the property, unit, dates, and duplicate status.
4. If required data is missing, it creates an intake exception assigned to the site team.
5. If valid, it creates the turn and selects the stage template by property or portfolio policy.
6. Pre-inspection and move-out preparation tasks appear in the manager workspace and, where enabled, in the PMS.

## Phase 2 Move out inspection and work release

7. Keys returned or move-out confirmation starts the vacancy clock.
8. The inspector records the punch list in the existing inspection or maintenance tool.
9. The completion signal activates the first required work stage.
10. If owner approval, insurance, utilities, or scope clarification blocks work, the turn moves to a visible business hold with an owner and review date.
11. The system prepares the first vendor assignment and sends an approval card to the manager.
12. The manager chooses Email, Message, Both, or no action.
13. The system verifies the selected destination and consent status for each authorized channel.
14. Each provider receives only its authorized delivery. A successful first delivery activates the stage. A failed second delivery creates Partially Sent without repeating the successful channel.

## Phase 3 Vendor work and inbound interpretation

15. The vendor performs the work and replies in an approved channel.
16. The channel connector records the original message and thread context.
17. The system resolves the sender against the vendor master.
18. Unknown senders are logged and disclosed only to the manager. They receive no data-bearing response.
19. AI classifies the message and extracts verbatim hints.
20. The deterministic matcher combines those hints with sender assignments and thread context.
21. A low-confidence, ambiguous, risky, or unsupported message becomes a manager review item with no stage change.
22. A clear completion enters the sequence guard.
23. The sequence guard checks prerequisites and current status.
24. If blocked, the manager sees the reason and may keep it blocked or override with a recorded reason.
25. If allowed, the current stage completes, evidence is linked for human review, stale chase drafts are cancelled, and the next required stage is identified.

## Phase 4 Next stage approval and delivery

26. The system builds a fact-locked message for the next assigned vendor.
27. AI may adjust tone within the approved character and content limits.
28. The message enters Awaiting Approval. Nothing is sent.
29. The manager approves one or both channels.
30. Delivery results are recorded independently.
31. After at least one authorized channel succeeds, the next stage becomes active. Queue finalization compares successful deliveries with the channels actually authorized, not with a hardcoded two-channel assumption.
32. If no selected channel succeeds, the stage remains inactive and the manager receives a visible failure.

## Phase 5 Stall monitoring and daily control

33. On a schedule, the watchdog reads active stages and compares age with the client's service window.
34. Snoozed stages and acknowledged alerts remain suppressed until their next eligible time.
35. Outside quiet hours, the alert is held for the next approved window.
36. A new breach creates one manager alert with unit, stage, vendor, age, and relevant cost context.
37. The manager can mark verified work Done or request a Chase draft. Chase never sends automatically.
38. Daily and weekly summaries show overdue work, approvals, partial sends, reply rate, safely auto-handled rate, stage duration, and sequence blocks.

## Phase 6 QA and rent ready handoff

39. Deep Clean cannot complete until required upstream work is complete or explicitly skipped.
40. QA receives stored photos and work history for human inspection.
41. If QA fails, the manager reopens the appropriate work stage or creates a controlled follow-up stage. The history remains intact.
42. When QA passes, the turn reaches the configured manager-ready or rent-ready state.
43. The automation updates the manager workspace and sends the approved status or task back to the PMS or leasing workflow.
44. Leasing staff decide listing readiness, pricing, publication, and applicant actions outside this automation.

## Phase 7 Reporting and continuous improvement

45. Completed turns feed operating measures without exposing unnecessary message content.
46. Leaders review median stage hours, move-out-to-ready days, reply rate, safely auto-handled rate, and sequence violations.
47. The team adjusts stage templates, service windows, vendor assignments, and intake quality through an approved change process.
48. No performance claim is made until the client has a defined baseline, sufficient volume, and an agreed comparison period.

# 9 Exceptions and edge cases

| Exception | System response | Human owner | Final state |
|---|---|---|---|
| Duplicate notice or turn | Compare source identifiers and open turn | Site team if unresolved | Existing turn retained or duplicate closed |
| Missing unit or move-out date | Create intake exception | Property manager | Turn held until corrected |
| Vendor sends bare “done” for multiple assigned units | Present candidates and original message | Turnover coordinator | No stage change until selected |
| Reply to a known assignment thread | Use thread as context after sender check | None if unambiguous | Correct stage may proceed |
| Unknown sender | Log, alert manager, disclose no candidate data | Turnover coordinator | No mutation |
| Assigned vendor mismatch | Block and show assignment conflict | Property manager | No mutation or approved reassignment |
| Repeated completion | Detect completed stage or duplicate window | None unless suspicious | Record rejection, no second advance |
| Out of order completion | Sequence guard blocks with prerequisites | Authorized manager | Keep blocked or override with reason |
| Stage legitimately unnecessary | Manager uses Skip | Authorized manager | Stage skipped and prerequisites satisfied |
| Tenant renews after notice | Manager cancels turn | Property manager | Open work and drafts cancelled |
| Owner or insurance hold | Pause with reason and review date | Property manager or owner liaison | Visible hold, watchdog policy adjusted |
| Vendor delay notice | Preserve exact words and notify manager | Turnover coordinator | Stage stays active |
| Vendor question | Route verbatim to manager | Appropriate employee | No stage change |
| Deposit or tenant-liability language | Route outside automation | Property manager or compliance team | No AI opinion or financial action |
| Photo without usable caption | Store securely and request match | Turnover coordinator | Evidence unassigned until reviewed |
| Voice note or unsupported file | Preserve provider reference and alert manager | Turnover coordinator | No automated interpretation or mutation |
| AI timeout or invalid schema | Use unclear path or approved draft template | Manager if interpretation required | Safe degradation |
| Email bounce or messaging failure | Update that channel's delivery row | Turnover coordinator or operator | Failed, Partially Sent, or retry required |
| Missing vendor destination | Record configuration blocked | Turnover coordinator | No silent fallback |
| Manager presses an old approval twice | Reject already-decided queue | None | No duplicate send |
| Airtable or dashboard unavailable | Continue in Postgres and queue sync retry | System operator | Authoritative state preserved |
| PMS write-back unavailable | Queue retry and show stale external status | System operator and manager | Coordination continues with visible mismatch |
| Workflow inactive or webhook expired | Expected-inventory and provider health checks alert operator | System operator | Restore workflow before clearing incident |
| Database or host failure | Stop external processing, restore from tested backup | System operator | Resume from durable records after verification |
| Unit operates across a different timezone | Apply property or portfolio timezone policy | Operations leader | Correct quiet hours and due times |
| Vendor reports multiple units in one message | Split only when each unit is explicit and safe; otherwise review | Turnover coordinator | Independent events or no mutation |
| QA fails after completion | Reopen controlled stage without deleting history | Inspector or manager | Follow-up work visible |

## Preventing silent loss

Every item that requires action must have a durable status. Open approvals remain Awaiting Approval. Missing destinations remain Configuration Blocked. One-channel success remains Partially Sent until the authorized set is resolved. Failed write-backs remain Pending Sync. Unclear inputs remain Needs Review. Overdue stages retain the original alert timestamp and any snooze. Workflow errors create operator incidents.

The manager view should include queues for Stalled, Due Soon, Awaiting Approval, Partially Sent, Configuration Blocked, Needs Review, and Pending Sync. A queue is not considered resolved because a notification was delivered. It is resolved only when the underlying durable record reaches a terminal or explicitly deferred state.

## Operational controls

Production readiness includes nightly backups, off-host retention, periodic restore tests, credential rotation, expected-workflow inventory checks, webhook health probes, provider delivery monitoring, dead-letter handling, and a documented offboarding process. The client owns the infrastructure and accounts and can revoke operator access.

# 10 Complete production workflow map reference

## Recommended diagram structure

Draw the workflow left to right with ten horizontal swimlanes:

1. Residents and source events
2. Property management maintenance and inspection systems
3. Vendors and communication providers
4. Integration and orchestration
5. AI interpretation and drafting
6. Deterministic controls
7. Authoritative coordination database
8. Manager decision channel
9. Manager workspace reporting and PMS write back
10. Monitoring security backup and operator response

Use solid arrows for synchronous business flow, dashed arrows for scheduled monitoring or reconciliation, red arrows for blocked or failed paths, and a distinct human icon for every approval or exception decision. Show Postgres as the central state store. Show Airtable or another operations view as a mirror, never as the source of sequence truth.

## Map nodes

| ID | Node label | Type | Primary input | Primary output |
|---|---|---|---|---|
| A1 | Resident Notice | Business event | Resident action | Notice record |
| A2 | Property Manager | Human actor | Exceptions and decisions | Intake corrections and approvals |
| A3 | Turnover Coordinator | Human actor | Approval and review queues | Channel choice and match decisions |
| A4 | Inspector | Human actor | Unit condition and QA | Punch list and QA result |
| A5 | Vendor | External actor | Approved assignment | Status reply and evidence |
| A6 | Leasing Team | Human actor | Rent-ready handoff | Listing process outside scope |
| S1 | Property Management System | Existing system | Portfolio lease and work data | Notice move-out and status events |
| S2 | Maintenance Inspection System | Existing system | Work and inspection activity | Punch list and QA events |
| S3 | Email Provider | Communication system | Approved email and vendor replies | Delivery and thread results |
| S4 | Messaging Provider | Communication system | Approved message and vendor replies | Delivery and sender results |
| S5 | Manager Channel | Human decision surface | Approval cards alerts and digests | Email Message Both Done Chase Skip Override Cancel |
| S6 | Manager Workspace | Visibility mirror | Synced operating records | Intake and portfolio visibility |
| P1 | Source Event Connector | Process | API webhook report email or form | Standard event envelope |
| P2 | Validate and Deduplicate Intake | Process | Standard event envelope | Valid turn or intake exception |
| P3 | Create Turn and Stage Plan | Process | Valid turn and client template | Durable turn and stages |
| P4 | Normalize Vendor Message | Process | Email message or generic inbound | Standard communication envelope |
| P5 | Resolve Sender | Process | Sender reference and vendor master | Known unknown or mismatched sender |
| AI1 | Interpret Vendor Message | AI process | Minimal text and open work context | Structured intent and verbatim hints |
| D1 | Unit and Stage Match | Deterministic decision | Hints assignments and thread context | Safe match ambiguous or reject |
| D2 | Completion Safety Checks | Deterministic decision | Match status duplicate and assignment | Allowed or review required |
| D3 | Sequence Guard | Deterministic decision | Requested stage and prerequisite state | Allowed blocked or override requested |
| P6 | Commit Stage Completion | Transactional process | Allowed completion | Completed stage audit and next stage |
| P7 | Build Fact Locked Draft | Process | Next stage vendor unit and approved facts | Deterministic draft |
| AI2 | Rewrite Draft Tone | AI process | Deterministic draft and tone sample | Bounded draft or fallback |
| P8 | Create Approval Queue | Process | Draft and next stage | Awaiting Approval record and card |
| D4 | Manager Channel Choice | Human decision | Approval card | Email Message Both or no action |
| D5 | Destination and Consent Check | Deterministic decision | Authorized channels and vendor master | Sendable or Configuration Blocked |
| P9 | Create Channel Delivery Records | Transactional process | Authorized sendable channels | One durable row per channel |
| P10 | Dispatch Approved Delivery | External action | Pending channel delivery | Provider response |
| D6 | Delivery Finalization | Deterministic decision | Authorized count and successful count | Sent Partially Sent Failed or retry |
| P11 | Activate Next Stage | Transactional process | At least one authorized success | Active stage and timestamp |
| P12 | Stall Watchdog | Scheduled process | Active stages SLAs snoozes and time | Held or new stall alert |
| P13 | Manager Action Processor | Process | Done Chase Skip Override Cancel | Guarded state action or draft |
| P14 | Workspace Synchronization | Scheduled process | Authoritative state and mappings | Mirror updates or sync exceptions |
| P15 | PMS Write Back | Integration process | Approved status or task | PMS update or Pending Sync |
| DB1 | Coordination Database | Data store | Turns stages messages queues deliveries events mappings | Current truth and history |
| M1 | Operating Measures | Reporting process | Completed stages and events | Reply rate auto-handled rate duration and blocks |
| O1 | Health and Workflow Inventory | Monitoring process | Endpoints workflow set and activity | Operator incident |
| O2 | Retry and Dead Letter | Reliability process | Failed external work | Retried result or durable failure |
| O3 | Backup and Restore | Recovery process | Coordination database | Off-host backup and restore evidence |
| O4 | System Operator | Human actor | Incidents and change requests | Recovery credential rotation and release |

## Primary arrows

Use these labelled connections as the main happy path:

1. A1 to S1 Notice submitted
2. S1 to P1 Notice or move-out event
3. P1 to P2 Normalized source event
4. P2 to P3 Valid intake
5. P3 to DB1 Turn and stages created
6. S2 to P1 Punch list or QA event
7. DB1 to P8 First vendor assignment draft
8. P8 to S5 Approval card
9. S5 to D4 Manager selection
10. D4 to D5 Authorized channels
11. D5 to P9 Valid destinations
12. P9 to P10 Pending delivery per channel
13. P10 to S3 or S4 Approved message
14. S3 or S4 to A5 Assignment delivered
15. A5 to S3 or S4 Vendor reply
16. S3 or S4 to P4 Inbound communication
17. P4 to DB1 Original message recorded
18. P4 to P5 Sender reference
19. P5 to AI1 Known vendor message
20. AI1 to D1 Structured interpretation
21. D1 to D2 Safe unit and stage match
22. D2 to D3 Completion candidate
23. D3 to P6 Allowed transition
24. P6 to DB1 Stage completion and audit
25. P6 to P7 Next required stage
26. P7 to AI2 Fact locked draft
27. AI2 to P8 Draft or deterministic fallback
28. P10 to D6 Provider result
29. D6 to P11 Required delivery success
30. P11 to DB1 Active stage
31. DB1 to P14 Changed authoritative record
32. P14 to S6 Mirrored operating status
33. DB1 to P15 Approved write back
34. P15 to S1 Status task or note
35. DB1 to M1 Operating history
36. M1 to S6 Executive measures
37. P6 to A6 Rent-ready handoff after QA

## Decision diamonds

| Decision ID | Question | Yes path | No path |
|---|---|---|---|
| Q1 | Is intake complete and unique | Create turn | Intake exception to A2 |
| Q2 | Is sender known and assigned | Interpret | Unknown or mismatch review |
| Q3 | Is AI result valid and above policy threshold | Match | Needs Review with original text |
| Q4 | Is unit and stage unambiguous | Safety checks | Candidate choice to A3 |
| Q5 | Is message a permitted completion | Sequence guard | Delay question risky or unclear review |
| Q6 | Are prerequisites satisfied | Commit completion | Block and offer authorized override |
| Q7 | Does next stage require an external vendor | Draft assignment | Activate internal step or close turn |
| Q8 | Did manager authorize a channel | Validate destination | Remain Awaiting Approval |
| Q9 | Is selected destination configured and permitted | Create delivery row | Configuration Blocked |
| Q10 | Did at least one authorized delivery succeed | Activate stage | Keep inactive and alert manager |
| Q11 | Did every authorized delivery succeed | Sent | Partially Sent and retry failed channel only |
| Q12 | Is active stage beyond SLA and eligible for alert | Alert manager | No action or hold until business hours |
| Q13 | Did QA pass | Rent-ready handoff | Reopen controlled work stage |

## Exception arrows

Draw each exception to a durable record and a named human owner:

- P2 to S5 and DB1 for Intake Exception.
- P5 to S5 and DB1 for Unknown Sender or Assignment Mismatch.
- AI1 to S5 and DB1 for AI Failure or Risky Language.
- D1 to S5 and DB1 for Needs Review.
- D3 to S5 and DB1 for Sequence Block and optional Override.
- D5 to S5 and DB1 for Configuration Blocked.
- P10 to O2 and DB1 for Provider Failure.
- D6 to S5 and DB1 for Partially Sent or Failed.
- P12 to S5 and DB1 for Stall Alert.
- P14 to O2 and DB1 for Mirror Sync Failure.
- P15 to O2 and DB1 for PMS Write Back Failure.
- O1 to O4 and DB1 for Workflow or Webhook Incident.
- O3 to O4 for Restore Failure.

## Status legend

Use the following status vocabulary on the map and in prospect discussions:

| Object | Main statuses |
|---|---|
| Turn | Planned Active On Hold Rent Ready Cancelled Closed |
| Stage | Pending Awaiting Approval Active Complete Skipped Blocked On Hold Cancelled |
| Message | Received Interpreted Needs Review Rejected Resolved |
| Approval | Awaiting Approval Decided Expired Cancelled |
| Delivery | Pending Sent Partially Sent Failed Configuration Blocked Retry Required |
| Synchronization | Current Pending Sync Failed Reconciled |
| Incident | Open Acknowledged Monitoring Recovered Closed |

## Prospect meeting walkthrough

When presenting the map, begin at the business result rather than at n8n or AI. Show the active portfolio, the size of the event volume, and the reduction in hidden work. Then follow one unit through Notice, work release, vendor completion, manager-approved handoff, stall detection, QA, and PMS return. End by tracing the red exception paths. Those paths demonstrate that the production design remains useful when messages are unclear, integrations are unavailable, or people do not act immediately.

The central message for a decision-maker is simple: the company keeps its current systems and its decision rights. The automation supplies the missing coordination memory between them.
