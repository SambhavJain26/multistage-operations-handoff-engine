# Build Technical Notes

**Audience:** a builder, or an operator who codes.

This is the companion to `how-the-system-works.md`. That document explains the behaviour without naming a single piece of technology. This one explains how it is put together, and assumes you would rather read a node count than a claim.

**Everything here is measured from the committed build**, not recalled. Node counts come from parsing the seven JSON exports in `n8n-workflows/`. Thresholds, limits and timeouts are read out of the code that uses them. Where a number could not be measured, it is absent and said to be absent.

**There is no client.** Every run referenced below was against fixtures. Verification means the code did the right thing on invented data, which is the only kind of data that exists here.

---

## The stack

| Layer | Choice | Why not the obvious alternative |
|---|---|---|
| Orchestration | Self-hosted n8n 2.29.10 | Managed automation platforms (Zapier, Make) put the client's coordination logic on a vendor account the client cannot export or self-host. Self-hosted means the client owns the instance, the export, and the ability to hire anyone to maintain it. A build the client cannot keep is a dependency dressed as a deliverable. |
| State | Postgres 16 | Google Sheets and n8n's own Data Tables were both explicitly rejected. Sequencing needs transactional writes, partial unique indexes, and one snapshot per decision. `uniq_one_active_stage_per_turn` is a partial unique index; a spreadsheet cannot express it, so the invariant would have to live in application code where a race can beat it. |
| Manager surface | Airtable, mirrored from Postgres | A custom board was built during development and deleted. It was a screen that existed only because the builder existed, and it made the client dependent on the person who wrote it. Airtable is a tool the company already pays for, and every row is exportable without anyone's help. The tradeoff is honest: Airtable cannot be authoritative, so it is a mirror and sync failure cannot alter sequencing state. |
| Model calls | Raw HTTP to the OpenAI Responses API | n8n's built-in OpenAI and LangChain nodes obscure the request body, which makes `json_schema` with `strict: true` awkward and raw error handling worse. Direct HTTP gives an exact model id, an exact schema, the raw error, and `continueOnFail` for a deterministic fallback. |
| Vendor inbound | Telegram, IMAP, and a generic webhook, all three routed by the same logic | A single-channel build reads as a Telegram build. Three inbound channels sharing one router is what proves channel independence, and the webhook is what a real SMS provider would post to. |
| Vendor outbound | SMTP and Telegram, one durable row per channel | Inferring both channels succeeded from one provider response is how retries duplicate messages. Each channel gets its own `outbound_delivery` row, unique on `(outbound_queue_id, channel)`. |
| Manager surface for decisions | Telegram inline keyboards | Approval belongs on the phone the manager already answers. Email approval links need a hosted endpoint, which means a screen, which is what this build spent effort removing. |
| Local exposure | Temporary Cloudflare quick tunnel | Only because Telegram requires public HTTPS. It is deliberately not a VPS, domain or reverse proxy. `docker-compose.production.yml` carries the pinned Caddy/Postgres/n8n stack for a real deployment and is inert. |

**Not in the stack, deliberately:** no community n8n nodes, no PMS connector, no SMS provider, no queue, no vector store, no custom application code outside the workflows themselves.

---

## The workflows

Seven workflows, **201 nodes**. Node counts are exact, parsed from the exports.

| Workflow | Nodes | Triggers | Owns |
|---|---|---|---|
| Vendor Communications | 97 | Telegram trigger, IMAP, `POST /vendor-in` | Reading inbound vendor messages on any channel, identifying sender and unit, and deciding whether anything may act |
| Airtable Workspace | 24 | 1-minute intake poll, 5-minute reconciliation, called | Turn intake, and keeping the Airtable mirror equal to Postgres |
| Manager Operations | 24 | Telegram trigger, 7am schedule, manual | Everything the manager touches: callbacks, digest, `/health` |
| Stage Update | 20 | Called only | The order rules, closing a stage, drafting the next handoff |
| Monitoring | 15 | 15-minute schedule, Monday 8am, webhook | Noticing that nothing happened |
| Vendor Delivery | 15 | Called only | Sending, and recording each channel independently |
| Builder Error Handler | 6 | Error trigger | Logging failures and alerting the builder, never the manager |

Node types across all seven: 66 Code, 40 Postgres, 35 IF, 21 Telegram, 11 Execute Sub-workflow, 10 HTTP Request, 5 Schedule, 3 Execute Sub-workflow Trigger, 2 Telegram Trigger, 2 Webhook, 2 Respond to Webhook, 1 Error Trigger, 1 Manual Trigger, 1 IMAP, 1 Send Email.

### Why Vendor Communications is 97 nodes

It contains **47 distinct logical nodes**. Twenty-five of them are the shared router, and the router exists three times, once per inbound channel, prefixed `Telegram `, `Email ` and `API `. Twenty-five times three, plus twenty-two channel-specific nodes, is ninety-seven.

**This is a platform constraint, not a design preference.** An Execute Sub-workflow node emits no downstream items when the called workflow exits through a routed branch, and the router exits through routed branches by design: completion, manager review, unknown sender, and duplicate all leave by different paths. Calling it as a sub-workflow meant the caller silently received nothing on most branches. The options were to make every branch converge on a single return node, which flattens the routing that is the point of the workflow, or to inline the router per channel. Inlining won.

The consequence to be aware of: **the router is written once in the generator and emitted three times.** A fix applied by hand in the n8n editor to one copy leaves two copies wrong. Every change goes through the generator.

### Why the other six are small

Because the router is where the ambiguity lives. Stage Update at 20 nodes owns the entire ordering system. Vendor Delivery at 15 owns the entire outbound surface. Both are small because they are deterministic: given the same inputs they do the same thing, and there is nothing to branch on except success and failure.

### The call graph

Two workflows take input from the outside world: Vendor Communications (Telegram trigger, IMAP, `POST /vendor-in`) and Manager Operations (Telegram trigger). Airtable Workspace and Monitoring wake on schedules, Monitoring also carries a `stall-watchdog` webhook, and Builder Error Handler fires on an error trigger. Stage Update and Vendor Delivery have no trigger of their own at all. The calls between them:

- Manager Operations → Stage Update, Vendor Delivery, Airtable Workspace
- Vendor Communications → Stage Update, Airtable Workspace
- Stage Update → Airtable Workspace
- Vendor Delivery → Airtable Workspace

**Nothing calls Vendor Delivery except Manager Operations,** which is the subject of the next section.

---

## The single path to the irreversible action

The irreversible action in this build is contacting a vendor. A message sent to a subcontractor cannot be recalled, and a wrong one costs a relationship rather than a record.

**Of 201 nodes, exactly two can contact a vendor.**

| Node | Type | Workflow |
|---|---|---|
| `Delivery Send Vendor Email` | `emailSend` | Vendor Delivery |
| `Delivery Send Vendor Telegram` | `telegram` | Vendor Delivery |

`Delivery Send Vendor Email` is **the only `emailSend` node in the entire build**. There is not a second one anywhere.

Of the 21 Telegram nodes, eighteen target `manager_chat_id` (seventeen sends and one `answerQuery`), one targets `builder_chat_id`, one is an inbound photo `get`, and one, `Delivery Send Vendor Telegram`, resolves a `telegram_destination` from the delivery plan. `Delivery Send Failed Channel Retry` reads like an exception and is not one: its `chatId` is `manager_chat_id` and it carries a Retry inline button. It is an alert about a vendor, not a message to one.

**Both send nodes live in a workflow with no trigger of its own.** Vendor Delivery's only entry point is `Delivery Receive Approved Delivery`, an Execute Sub-workflow Trigger. Exactly one node in the build calls it: `Manager Call Vendor Delivery Dispatcher` in Manager Operations. Its inbound edge comes from `Manager Dispatch Approved Message?`, and tracing back from there gives one unbroken chain:

```
manager-managertelegramtrigger
  → Manager Parse Manager Update
  → Manager Determine Manager Route
  → Manager Manager Action?
  → Manager Resolve Edit Queue
  → Manager Dispatch Approved Message?
  → Manager Call Vendor Delivery Dispatcher
  → [Vendor Delivery] Delivery Receive Approved Delivery
```

Every node on that path is upstream of a Telegram callback from the manager's own chat. There is no schedule on it, no webhook, no retry timer, and no second entry.

**So "nothing reaches a vendor without a person" is not a policy. It is a property of the graph, and you can verify it in about two minutes** by opening `n8n-workflows/demo-vendor-delivery.json`, confirming its only trigger is an Execute Sub-workflow Trigger, and grepping the other six exports for `demo-vendor-delivery`. One hit.

Two related audits, since they are cheap:

**Nothing writes to a PMS.** Zero nodes of any type target a property management system. All ten HTTP Request nodes resolve to exactly two hosts: `api.openai.com` (four calls) and Airtable's `api.airtable.com` / `content.airtable.com` (six). There is no PMS credential, no PMS node, and no third host.

**Nothing sends SMS.** There is no Twilio node and no SMS node of any kind. SMS is documented in the production readiness pack and does not exist in the build.

---

## How the guardrails actually work

There are three, they are all deterministic JavaScript or SQL, and **none of them is prompting**. The model has no tools, no write path, and no way to reach any of them.

### 1. The unit matcher, `Score Unit Match`

Runs once per inbound message, immediately after interpretation. Fixed scoring, no model input except a `unit_hint` string that is treated as text to tokenise:

| Evidence | Score |
|---|---|
| Reply resolves to a known stage (`thread_stage_id`) | 100 |
| Exact unit label appears in the message tokens | 100 |
| Unit number token appears | 90 |
| Street name appears, with street-type words stripped | 70 |

Selection requires `score >= 70` **and exactly one candidate at the top score**. A tie sets `needs_manager` and the message escalates. It does not pick the first one.

The stronger property is upstream. `Prepare Unit Match Candidates` restricts the candidate set to stages where `ts.vendor_id = input.vendor_id` (or the exact `thread_stage_id`), with `ts.status IN ('active','awaiting_approval','awaiting_delivery')` and `t.status = 'active'`. **A vendor cannot claim another vendor's stage because that stage was never a candidate.** The later `assigned_vendor_id` check in the policy is a second belt, not the mechanism.

### 2. The safety policy, `Apply Safe Message Policy`

Runs immediately after matching. A first-match-wins ladder; only the last branch permits action:

```
duplicate_like                       → duplicate_inbound,        manager
media type voice/unsupported         → unsupported_media,        manager
interpretation.status !== 'openai'   → classification_fallback,  manager
confidence < 0.8 or intent unclear   → manager_match_needed,     manager
match.needs_manager                  → manager_match_needed,     manager
assigned_vendor_id !== vendor_id     → stage_vendor_mismatch,    manager
safety_flags non-empty               → safety_review,            manager
intent === 'stage_complete'          → completion_requested,     ACT
else                                 → notify manager
```

A completion therefore requires all of: not a duplicate, supported media, the model call succeeded and validated, confidence at or above 0.8, an unambiguous unit match, the sender is the assigned vendor, no safety flags, and an explicit `stage_complete` intent. Everything else lands with a person.

### 3. The sequence guard, `Evaluate Sequence Guard`

Runs inside Stage Update, and **this is the run that matters**, for two reasons.

**It is the only guard on the manual path.** A vendor message passes through the matcher and the policy first; a manager pressing `Done` in Telegram passes through neither. `Manager Call Stage Complete Core` calls the same Stage Update workflow, entering at the same `Stage Receive Completion Request` trigger. The guard is the single check both paths share, so it is the only place an invariant can be enforced for both. Putting ordering logic in the router would have left the manager path unguarded.

**It re-reads state rather than trusting what it was handed.** `Load Stage State For Guard` reselects the stage and its siblings immediately before evaluation. The policy's decision was made against state read earlier in the run; the guard's is made against state read now.

The rules, in full:

```js
if (targetSeq > 2) required.push('MOVEOUT');
const ruleMap = {
  PAINT:      ['REPAIRS'],
  FLOORING:   ['PAINT'],
  DEEP_CLEAN: ['REPAIRS', 'PAINT', 'FLOORING'],
  QA_PHOTOS:  ['DEEP_CLEAN'],
  RELIST:     ['QA_PHOTOS']
};
const satisfied = stage => stage && ['complete', 'skipped'].includes(stage.status);
```

One gate plus five prerequisite rules. `skipped` satisfies a dependency, so skipping is a decision rather than a violation. An already `complete` or `skipped` stage is refused before the rules run, which is what makes a double `Done` press safe.

Refusals return `blocked_by` plus a plain-language `reason`, and mint an `override_token` of the form `OVR:<stage_id>:<timestamp>`. An override is accepted only if the presented token starts with `OVR:<stage_id>:`, and sets `completed_via: 'override'` so the override survives into the record and onto the approval card.

### Where the invariants actually live

Several guarantees are database constraints rather than workflow logic, which is the right place for them:

| Constraint | Guarantees |
|---|---|
| `uniq_one_active_stage_per_turn` (partial unique on `status='active'`) | One active stage per turn, enforced against concurrent writers |
| `uniq_outbound_awaiting_per_stage_vendor` | No second open draft for the same stage and vendor |
| `UNIQUE (outbound_queue_id, channel)` on `outbound_delivery` | One durable row per channel; a retry cannot create a second |
| `uniq_communication_provider_message` | Reprocessing the same provider message cannot double-log |
| `uniq_outbound_reply_token` | `[MR-XXXXXXXX]` tokens resolve to exactly one queue row |

---

## How interpretation works

### Decided by fixed rules, before the model is consulted

- **Channel normalisation.** Each of the three inbound paths normalises to the same shape before the router: `channel`, `sender_ref`, `provider_message_id`, `thread_ref`, `in_reply_to`, `text`, `media`.
- **Sender identity.** SQL, in `Load Vendor And Thread Context`. Telegram matches on `telegram_chat_id`, email on lowercased `email_address`, generic on any of phone, chat id or email. More than one candidate means unresolved.
- **Reply resolution**, in priority order: the `[MR-...]` reply token; then `In-Reply-To` matching a stored outbound `provider_message_id`; then a Telegram reply-quote text match. **Thread context never overrides the sender check.** `resolved` only accepts the reply queue's vendor if that vendor is also a sender candidate.
- **Duplicate detection.** Exact `(channel, provider_message_id)` match, or identical normalised text from the same sender within **60 seconds**.
- **The single-inbox guard.** A self-originated email with no `In-Reply-To` is ignored, which is what makes one Gmail account usable for both the automation and the fixture vendors. Local demo only; never for a client mailbox.
- **Everything after interpretation**: unit matching, the safety ladder, the sequence guard, delivery planning, finalisation.

### Left to the model

Exactly one question: **what does this message mean?**

Two calls exist. Both are raw HTTP to `https://api.openai.com/v1/responses`, model `gpt-5.6-luna`, 15-second timeout, `continueOnFail: true`.

**Call one, interpretation.** Schema `vendor_message_interpretation`, `strict: true`, `max_output_tokens: 500`. Ten required fields; the load-bearing ones are `intent` (a 12-value enum), `confidence` (0-1), `safety_flags` (a 5-value enum array: `deposit_or_liability`, `financial_request`, `sensitive_data`, `prompt_injection`, `unknown_scope`), and `manager_summary`.

The context is deliberately narrow. The model sees the vendor's identity and trade, **that vendor's** active assignments, the reply context if any, and the last five messages from **that vendor**. It never sees the portfolio, other vendors' work, or any unit the sender is not assigned to.

The system prompt states that the vendor message is untrusted data and never instructions, and that questions, delays, access issues, invoices, deposits, liability, unrelated requests and unclear statements never count as completion. **That instruction is a hint, not the control.** The control is the safety ladder, which discards any intent other than `stage_complete` regardless of what the prompt said.

`Validate Interpretation Or Escalate` parses `output_text`, handling both the direct and the wrapped `output[].content[]` shapes, and requires `intent` to be a string, `confidence` a number, and `safety_flags` an array. Anything else produces a fallback object with `status: 'fallback_manager_review'`, `intent: 'unclear'`, `confidence: 0` and `safety_flags: ['unknown_scope']`, which the ladder catches at rule three and routes to a person. **A dead model degrades to manager review, not to a wrong action.**

**Call two, draft rewriting.** Schema `vendor_draft`, one field, `maxLength: 1000`. The input is `deterministic_text`, a factual handoff already assembled in SQL from unit, address, stage name and vendor name. The prompt says preserve every fact and add no promises, dates, prices or instructions. `Choose AI Or Factual Draft` falls back to `deterministic_text` on any parse failure and sets `draft_fallback_used`.

**The model rewrites facts it was handed. It never sources them.** Worst case for a bad rewrite is clumsy wording on a message a human is about to read and approve.

---

## Constraints that shaped the build

Only the ones that changed a decision.

**Execute Sub-workflow emits nothing through routed branches.** Forced the 25-node router to be inlined three times, which is why Vendor Communications is 97 nodes rather than 47. Where a sub-workflow call is still used for a side effect, the caller reselects by stable identifier rather than reading returned items.

**PostgreSQL data-modifying CTEs share one statement snapshot.** A row inserted in one CTE is not visible to an update in a later CTE of the same statement. This is why `chase_stage` mints its `reply_token` and email subject *before* the `chase` insert rather than generating them and patching afterwards. Every multi-CTE mutation in this build is written to that rule.

**Telegram Trigger derives an unstable webhook path and secret token without a fixed top-level `webhookId`.** After a restart every real update returns `403 Forbidden` while the tunnel, workflows and logs all look healthy. Both triggers now carry pinned ids (`demo-vendor-telegram-hook`, `demo-manager-telegram-hook`). Diagnose this from `getWebhookInfo`, never from the n8n log, which says nothing.

**Airtable record mutations cap at 10 records per request.** Batching is `chunk(rows, 10)` with `performUpsert` merging on `External ID`. A payload hash short-circuits unchanged rows.

**Airtable `performUpsert` does not preserve request order and there is no API to set a view's sort.** Grid order after a rebuild is arbitrary. Sorting the Stages view is a manual configuration step, permanently.

**Linked records need two reconciliation passes after a full rebuild.** Stages sync before Turn and Vendor mappings exist, so link fields are stripped on pass one; the payload hash then differs and the links populate on pass two.

**n8n Code nodes default to run-once-for-all-items.** A node reading `$json` or `$('Node').item` sees only the first input item. Where an upstream HTTP node emits one response per batch, the consumer must walk `$input.all()` and pair against `$('Node').all()` by index. This caused a real defect, below.

**`n8n import:workflow --activeState=fromJson` is rejected in 2.29 local regular deployment mode.** Import is inactive, then `n8n publish:workflow --id=<id>` per workflow, then restart.

**Imported Execute Sub-workflow nodes are only reliable at type version 1 with a plain `workflowId` string.** Newer workflow-selector JSON imports cleanly and then fails at runtime with "No information about the workflow to execute found."

**`$env` is blocked inside Code nodes and expressions.** Configuration is substituted into temporary JSON copies at import time instead.

**n8n `emailReadImap` in `simple` format exposes raw headers under `metadata`.** Not `headers`, not `headerLines`. Caused a real defect, below.

**Strict IF nodes require actual booleans.** Truthy strings and draft bodies are normalised in Code nodes before routing.

**`trycloudflare` quick tunnels collapse silently.** `cloudflared` keeps running, the hostname stops resolving, n8n keeps serving the stale `WEBHOOK_URL`, and Telegram callbacks vanish with no error anywhere. Probe `WEBHOOK_URL/healthz` before any live Telegram step and treat a failed probe, not the user, as the first suspect.

**Windows PowerShell 5.1.** No `ConvertFrom-Json -Depth`, no `&&`, no ternary. `docker compose restart` writes progress to stderr, which PowerShell wraps as `NativeCommandError`, so `scripts/import-make-ready-workflows.ps1` exits 1 even on success. Verify activation from the n8n database, never from the exit code.

---

## The defects that shipped

Ordered by how long they went unnoticed, which is roughly the order of how much they teach.

### 1. Only the first Airtable batch was ever mapped

**Symptom:** none, for weeks. Airtable looked correct. Every record was present with the right values.

**Cause:** `Capture Airtable Record IDs` was written per item, reading `$json` and `$('Build Airtable Batches').item`, but ran in n8n's default run-once-for-all-items mode. It therefore captured record ids from the first batch only. Vendors and Turns sort first and are small enough to fit one batch, so they mapped. Stages, Communications and Approvals never recorded a mapping at all.

**Why nothing looked wrong:** `performUpsert` merges on `External ID`, so Airtable itself stayed correct without any help from the local map. Only `airtable_record_map` was incomplete. The two visible consequences were subtle: linked-record fields never resolved, and every row re-upserted on every five-minute cycle because the payload-hash short-circuit could never find a prior hash to compare against.

**Fix:** walk `$input.all()` and pair each response against `$('Build Airtable Batches').all()` at the same index.

**Generalisation:** *a caching or mapping layer that fails silently is worse than one that crashes, because the system keeps producing correct output by a slower path and nobody investigates.* If you have a short-circuit that is supposed to skip work, instrument the hit rate. A cache with a permanent 0% hit rate looks exactly like a working system with a higher bill.

### 2. Genuine vendor email replies were ignored

**Symptom:** a real Gmail reply, sent with the client's Reply button, did nothing at all. No error, no log line suggesting a problem, no manager notice. The message was classified as self-originated and correctly discarded, by a guard doing exactly what it was told, on a false premise.

**Cause:** the single-inbox demo mode ignores self-originated email with no `In-Reply-To`, so one Gmail address can serve as both the automation's mailbox and the fixture vendors'. The `header()` helper read `headers` and `headerLines`. n8n's `emailReadImap` in `simple` format exposes raw headers under **`metadata`**. `In-Reply-To` therefore always read as empty, so every genuine reply satisfied the discard condition.

**Fix:** `header()` now also reads `metadata`. Re-verified that outbound copies, bounces and auto-replies are still ignored.

**Generalisation:** *a safety guard fed a wrong input is more dangerous than no guard, because it produces confident silence.* When a guard's decision depends on a field from a third-party library, assert the field exists rather than assuming absence means false. `In-Reply-To` being empty and `In-Reply-To` being unreadable are different states and this code could not tell them apart.

### 3. The approval card credited a vendor who had said nothing

**Symptom:** a message went out saying a painter had reported his work finished. He had not. The stage was marked complete by the manager, from the manager's phone. The painter sent nothing and had no idea any of it had happened.

**Cause:** `Format Manager Approval Card` had a default. When writing the summary line it reached for the vendor assigned to the stage, because on most days that is who finished the work. The record had been right the whole time: `completed_via` stored `manual` with the manager's actor id against it. The sentence just never asked.

**Fix:** the credit line now branches on `completed_via`: `manual` reads "Marked complete by the manager", `override` reads "as an override", `skip` reads "This stage was skipped", and only the vendor path credits the vendor.

**Generalisation:** *a default is a guess that runs every time and never announces that it is guessing.* If your system writes a sentence about what another person did, check what it actually knows before it says it. This one was a wording bug on test data; on a live account it is a message telling a contractor they said something they did not say, on the client's letterhead.

### 4. Telegram returned 403 on every update after a restart

**Symptom:** vendor messages and button presses did nothing. The tunnel was healthy, all workflows were active, the n8n log was clean, and there was no error anywhere in the demo.

**Cause:** both Telegram Trigger nodes had `webhookId: null`. Without a fixed top-level `webhookId`, n8n derives an unstable path and secret token, so after a restart Telegram's registered URL and the expected secret no longer matched. Telegram was rejecting every delivery and reporting it only in `getWebhookInfo`, which nothing in the local stack surfaces.

**Fix:** pinned `demo-vendor-telegram-hook` and `demo-manager-telegram-hook`.

**Generalisation:** *when a webhook stops working, the provider's own record of the subscription is the first thing to read, not your logs.* Your logs can only tell you about requests that arrived.

### 5. A workflow sat inactive and nothing said so

**Symptom:** silence again. Vendor messages on every channel did nothing. The n8n startup log listed six activations and looked entirely healthy.

**Cause:** `demo-vendor-communications` was `active = false` in `workflow_entity`. **n8n only logs workflows it attempts to activate**, so the one that mattered produced no log line at all. The absence was the signal, and absence does not appear in a log.

**Fix:** `n8n publish:workflow --id=demo-vendor-communications` and restart. `scripts/prepare-demo-recording.ps1` now names the inactive workflow ids on failure and prints the fix, rather than reporting a count.

**Generalisation:** *health checks must assert the expected set, not count the observed one.* "Six workflows activated" and "seven workflows should be active" are different statements, and only the second one can fail usefully.

### 6. The approval card was never delivered during a live rehearsal

**Symptom:** during a live run, the stage completed and the next stage moved to `awaiting_approval` correctly, but no card arrived. State was right; the human never found out.

**Cause:** the completion handler compared the import-substituted manager chat id against the literal it had just been substituted with. Once a real chat id was configured, the gate evaluated false. Substitution had made the "is this configured?" check impossible to pass.

**Fix:** the gate now tests for a non-blank value that is not a placeholder sentinel, matching `stage7-%-missing` rather than comparing against the substituted literal. The same bug in mirror image suppressed builder alerts when a real `BUILDER_TELEGRAM_CHAT_ID` was configured.

**Generalisation:** *never write a configuration check that compares against a value your build step rewrites.* Test the shape of the unconfigured state, not equality with the configured one.

### 7. A callback acknowledgement failed after the action had already succeeded

**Symptom:** a manager pressed a button, the state change worked, and Telegram then returned `Bad Request: query is too old or query ID is invalid`. Worse, this fired the error workflow, so a successful action produced a builder alert.

**Cause:** `telegram_callback_query_id` was dropped crossing an Execute Sub-workflow boundary and a SQL result, so `answerQuery` ran with an empty id.

**Fix:** the callback id is carried explicitly through the sub-workflow call and preserved in the SQL projection.

**Generalisation:** *when a call boundary drops fields, the symptom appears at the last step and blames the wrong thing.* Postgres nodes that update and reselect must return every field a later expression uses; sub-workflow calls must carry caller metadata explicitly. Both are the same failure with different surfaces.

### 8. Airtable drifted to twice the real record count

**Symptom:** Airtable held 12 turns, 100 stages and 12 vendors against a Postgres truth of 6, 66 and 6.

**Cause:** `scripts/reset-demo.ps1` resets Postgres only. A reset assigns new Postgres ids, so previously synced Airtable rows survive as orphans with External IDs that will never be written again. Each reset roughly doubled the mirror.

**Fix:** documented ordering rather than code. Reset Postgres, reapply vendor contacts, delete every record in the six operating tables, clear `airtable_record_map`, then let reconciliation rebuild over two passes. `scripts/prepare-demo-recording.ps1` performs all of it and refuses to report ready until both passes have settled.

**Generalisation:** *a reset that clears one side of a mirror is not a reset.* If you have a sync with durable external ids, the teardown path needs the same care as the sync path, and it is usually written months later by someone who has forgotten the ids are durable.

---

## Reproducibility

**The workflows are generated, not hand-edited.** `scripts/generate-demo-workflows.js` is the entry point and each generator invokes its predecessor:

```
generate-demo-workflows.js
  → generate-airtable-email-workflows.js
      → generate-stage-7-workflows.js
          → …stage 6 → 5 → 4 → 3
```

The stage-era generators emit nineteen small workflows. `generate-demo-workflows.js` then inlines them into the seven consolidated exports according to a declarative `specifications` array. For example, Vendor Communications is three roots (`wf9-vendor-email-ingest`, `wf4-vendor-telegram-ingest`, `wf4-vendor-in-api`) each inlining `wf4-vendor-router`, `wf9-ai-interpreter` and `wf4-unit-matcher` under a channel prefix. Node names are rewritten and every `$('Node')` reference is rewritten with them. A layout pass then assigns positions by longest-path depth and lane, because consolidation preserves each source's original coordinates and would otherwise stack three copies of the same router on identical positions.

**The guard and the matcher are reused, not reimplemented.** `wf3-sequence-guard` and `wf4-unit-matcher` are inlined from the stage-3 and stage-4 generators that were verified in their own stage gates. There is exactly one sequence guard and exactly one unit matcher in the build, and the manual and vendor paths share both. Reimplementing either for the manager path is the specific mistake this structure exists to prevent.

**One caveat that follows from generation.** Node names in emitted Code nodes must appear as literal `$('...')` strings so the consolidator's rewrite can find them. A name assembled dynamically in the generator will not be rewritten and will fail at runtime. Emitted regex and newline escapes need doubled backslashes; compile every generated Code node before accepting the export.

### Secrets and identifiers

Nothing sensitive is committed. Verified by grep over all seven exports:

- **Credentials are referenced by name and id only**: `Make-Ready Postgres`, `Make-Ready OpenAI`, `Make-Ready Airtable`, `Make-Ready Vendor Email IMAP`, `Make-Ready Vendor Email SMTP`, and the two Telegram bots. No token, key or password appears in any workflow file.
- **Identifiers are placeholder sentinels.** The exports contain `AIRTABLE_BASE_ID_PLACEHOLDER` (8), `stage5-manager-chat-id-missing` (24), `stage3-manager-chat-id-missing` (4), `stage7-builder-chat-id-missing` (1), and the two vendor email placeholders.
- **Substitution happens at import into temporary copies.** `scripts/import-make-ready-workflows.ps1` reads `.env`, writes rewritten JSON into an ignored temp directory, and imports from there. The committed files are never modified.
- **Real chat ids are gated behind `-ActivateLive`.** Without it, manager, builder and vendor placeholders are left intact, so a local fixture import cannot accidentally message a live chat even when `.env` holds real ids.
- **`.gitignore` covers** `.env` and `.env.*` (except the two examples), `data/`, `tmp/`, `*.dump`, `*.sql.gz`, `*.backup`, `*.log`, and any `n8n-credentials*.json` / `credential-export*.json`.

### Environment

Local: `postgres:16` and `n8nio/n8n:latest`, two containers, timezone `America/Phoenix`. **`n8nio/n8n:latest` is a reproducibility hole and is deliberately not fixed for the demo.** The running instance is 2.29.10. `docker-compose.production.yml` pins `caddy:2.8.4-alpine`, `postgres:16.4-alpine` and `n8nio/n8n:2.29.10`, and `scripts/check-stage-8-production-readiness.ps1` fails the readiness check if any production image is unpinned.

Schema: 9 tables across 6 migrations, 507 lines total, applied in lexical order. Migrations must not narrow an enum or check constraint that a later stage has already written rows against, because reset reapplies all of them before fixture cleanup.

Fixtures: 6 turns, 66 stages, 6 vendors (5 outside trades and 1 in-house), plus 20 scripted scenarios in `fixtures/stage-7-fixtures.json` and 16 in `fixtures/email-ai-fixtures.json`. Airtable's contract is 6 tables in `fixtures/airtable-schema.json`: Vendors (8 fields), Turn Intake (15), Turns (19), Stages (16), Communications (16), Approvals & Deliveries (13).

---

## What was verified, and what that means

Verified in live runs against fixtures, over real Telegram traffic and a real mailbox:

- Vendor completion end to end on Telegram, on email by threaded reply, and through the generic webhook.
- Ambiguity resolution under the hard case: one flooring vendor holding two units at the same stage, a reply of "done", correct resolution to the replied-to unit, the other unit untouched, no duplicate advance.
- Messy wording handled correctly ("don3e", "yeah thi si sdone", "task complete"), and a non-completion ("on it") logged without advancing anything.
- The sequence guard refusing out-of-order completions with a plain reason, and refusing the manager identically.
- Double completion refused, recorded as `guard_blocked` with a reason naming the stage as already complete, mutating nothing.
- A delivery button pressed on an already-sent queue rejected as `msg_rejected`, three times, with no second send.
- All three delivery choices, with a single-channel choice creating exactly one `outbound_delivery` row and activating the next stage.
- `configuration_blocked` recorded and the manager alerted when a chosen channel has no destination.
- Stale chase drafts cancelled when their stage completes.
- Digest `Done` and `Chase` working on units other than the top row.
- Manual completion attributed to the manager rather than the vendor.
- Stall alerts held outside business hours and released inside them, one per stage.
- Airtable mirroring Postgres exactly at 6 turns and 66 stages with linked records populated after the second pass.
- The error workflow firing and writing `workflow_error`, verified from `event_log` rather than HTTP status, because a Webhook workflow that throws before its Respond node can still return HTTP 200 with an empty body.
- All 20 stage-7 fixtures and 16 email/AI fixtures passing.

**This is testing. It is not a customer result.** There is no client and no pilot. Every turn, unit, vendor and message above is invented. Nothing here demonstrates that the automation reduced anyone's turn time, because it has never run against a real turn.

**Not measured, and therefore not stated anywhere in either document:**

- **Latency.** No end-to-end timing was recorded for any path.
- **Token usage and model cost.** The stage-7 report records `$0.00` because the exercised branches used the deterministic fallback or did not surface usage in the captured output. That is an absence of measurement, not a measurement of zero.
- **Model accuracy as a rate.** Individual interpretations were observed correct. No confusion matrix was built and no per-intent accuracy exists.
- **Behaviour at volume.** Six turns. Nothing here says anything about six hundred.

---

## Known limits of the current build

- **Delivery retry after a genuine channel failure is untested.** The code path exists and refreshes the failed channel's destination from the current vendor record before retrying. Exercising it requires deliberately breaking a vendor destination, and that has not been done. It is the only remaining untested branch.
- **The router exists in triplicate.** Any change must go through the generator. A hand-edit in the n8n editor fixes one channel and leaves two broken.
- **Airtable view order cannot be set by API,** permanently. Sorting the Stages view is manual after every rebuild, and the Airtable Interface layout is a documented manual step.
- **A full Airtable rebuild needs two reconciliation passes** and roughly five minutes before linked records read correctly.
- **`reset-demo.ps1` does not touch Airtable** and will orphan the mirror if used alone. Use `prepare-demo-recording.ps1`.
- **Telegram is a demo stand-in.** US trade vendors text. SMS is designed, disabled, and gated behind registration under a real client's identity.
- **The single-inbox email mode is local-only.** It depends on ignoring self-originated mail without `In-Reply-To`, which means test replies must use the client's Reply action. Never use this shortcut for a client mailbox.
- **The local stack runs `n8nio/n8n:latest`.** The demo is not pinned and could change under a pull.
- **No PMS integration exists,** by decision, and the client's PMS remains the system of record.
- **The confidence threshold of 0.8 is asserted, not tuned.** No calibration data exists to justify that number over 0.7 or 0.9.
- **The 60-second duplicate window is a guess.** A vendor who sends the identical message twice, ninety seconds apart, produces two inbound rows.
- **Business hours are hardcoded** to 08:00-18:00 `America/Phoenix` in the watchdog SQL. Not configurable per client today.
- **The stall watchdog excludes in-house stages entirely** (`v.trade <> 'inspect'`). If a client runs trades in-house and wants them watched, that is a change.
