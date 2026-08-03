# Pilot Success Metrics

Agree these metrics with the client before go-live. Report from week one, even if the numbers are weak.

## Vendor Reply Rate

Percentage of vendor-assigned completed or skipped stages completed through vendor reply.

Purpose: proves whether the vendor automation is viable for this client.

Decision use: if reply rate stays under roughly 30 percent, reframe the pilot around board visibility and manager control rather than vendor automation.

## Auto-Handled Rate

Percentage of vendor inbound messages that reached a safe workflow outcome without a manager matching the unit or intent.

Purpose: shows whether the parser and matcher are reducing coordination work.

Decision use: low auto-handled rate means the client has ambiguous unit labels, inconsistent vendor texting, or too many shared vendor numbers.

## Median Hours Per Stage

Median elapsed hours from stage activation to completion, grouped by stage code and vendor where data volume is sufficient.

Purpose: exposes bottlenecks such as paint, flooring, or deep clean.

Decision use: use for manager conversations, not punitive vendor scorecards during the first pilot.

## Median Move-Out To Relist Days

Median days from `moveout_date` to Relist/manager-ready state.

Purpose: ties the workflow to the vacancy outcome the client cares about.

Decision use: compare before/after only when the client has enough baseline data or a clearly agreed pilot window.

## Sequence Violations Blocked

Count of attempted stage completions blocked by the deterministic sequence guard.

Purpose: proves the system prevents rework, such as cleaning before repairs.

Decision use: review blocked events weekly to distinguish real saves from bad stage setup.

## Reporting Rules

- Do not promise a percentage improvement before the client has data.
- Separate manual completions from vendor replies.
- Keep cancelled/off-market turns out of turn-time metrics unless the client asks for a separate exception report.
- Keep raw event logs available for audit, but report plain-language summaries to managers.
