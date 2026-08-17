# Airtable Table Setup

This proof-of-concept uses six normal Airtable tables. It does not create an Airtable Interface, dashboard, custom view, or Airtable form.

The setup script reads the scoped Airtable token from the existing n8n credential named `Airtable Make Ready Demo`. It keeps the token in memory and writes only base, table, and field IDs to the ignored local manifest at `data/airtable/airtable-manifest.json`.

## Provision The Supplied Base

Run `scripts/setup-airtable.ps1 -BaseId <base-id>`.

The six typed operational tables are already provisioned in the current demo base, so this step does not need to be repeated. Do not delete Airtable's default `Table 1` from a script; on this base the owner removed it by hand, and any remaining default table should be left alone.

The tables are:

- Turn Intake
- Turns
- Stages
- Vendors
- Communications
- Approvals & Deliveries

The schema intentionally uses Airtable field types such as currency, date/time, email, select, linked record, attachment, checkbox, percentage, and duration. It does not use plain text where a typed field conveys the data better.

Run `scripts/check-airtable-schema.ps1 -Live` after setup. It runs under Windows PowerShell 5.1.

## Using The Tables In The Demo

Managers add a new row only in `Turn Intake`. Set `Intake Status` to `New`, then wait for Airtable Workspace to process it. The workflow creates the turn in Postgres and updates the row to `Created` or `Error`.

`Turns`, `Stages`, `Vendors`, `Communications`, and `Approvals & Deliveries` are synced operating records. Do not manually edit them during a demonstration; Postgres is authoritative and the five-minute reconciliation restores the Airtable mirror after a service interruption.
