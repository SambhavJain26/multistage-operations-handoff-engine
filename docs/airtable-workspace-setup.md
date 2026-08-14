# Airtable Workspace Setup

The provisioning script creates the six typed tables and writes the base/table IDs to the ignored local manifest at `data/airtable/airtable-manifest.json`. Keep the Airtable PAT in the n8n credential named `Make-Ready Airtable`; don't put it in `.env` or the manifest.

## Required Access

Create a scoped Airtable personal access token with schema and record read/write access for the selected workspace. The client should own the workspace and revoke operator access at handoff if required.

## Provision The Base

Run `scripts/setup-airtable.ps1` with the client workspace ID. The script reads `fixtures/airtable-schema.json`, creates the base, adds linked-record fields after their destination tables exist, validates every field type, and stores only non-secret IDs locally.

The exact tables are:

- Turn Intake
- Turns
- Stages
- Vendors
- Communications
- Approvals & Deliveries

Use `scripts/check-airtable-schema.ps1 -Live` after provisioning.

## Create The Interface

Create one Airtable Interface named `Make-Ready Operations`. The Airtable Web API provisions the data schema; Interface layout remains a deliberate Airtable setup step.

Add these pages:

1. **Active Turns**: headline counts for active turns, stalled turns, due-soon turns, awaiting approvals, and partially sent deliveries. Add a Kanban grouped by Current Stage.
2. **Attention Required**: Stalled first, then Due Soon. Sort by SLA Progress descending and Stage Activated ascending.
3. **Approvals**: separate grids for Awaiting Approval, Partially Sent, and Failed. Show the draft plus Email Status, Telegram Status, Last Error, Decision At, and Sent At.
4. **Turn Detail**: one Turn record with linked Stages, Communications, and Approvals & Deliveries. Include evidence attachments.
5. **Vendors**: contact readiness, trade, email, Telegram contact, and active status.

Use the existing select colors from the schema. Don't convert typed fields to text for presentation.

## Create The Intake Form

Create a form from Turn Intake and expose only:

- Unit
- Property Address
- Monthly Rent
- Notice Date
- Move-out Date
- Target Ready Date
- Trash-out Vendor
- Repairs Vendor
- Paint Vendor
- Flooring Vendor
- Deep Clean Vendor

Hide External ID, Intake Status, Error Details, and Submitted At. Set Intake Status to `New` by default.

## Permissions

Managers use Interface-only access. Operational tables are read-only to them. The Turn Intake form is their only Airtable write surface.

Builders may edit schema and records during setup. n8n uses a scoped PAT and performs all operating writes.

## Sync Rules

Postgres is authoritative. Airtable Sync runs after state changes and every five minutes. It upserts by External ID, stores Airtable record mappings and payload hashes in Postgres, and sends no vendor message.

If sync fails, don't repair the record in Airtable. Fix the credential, permission, field, or API problem, then let reconciliation write the correct Postgres state.
