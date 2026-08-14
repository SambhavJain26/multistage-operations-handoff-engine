# Stage 8 Production Pilot Readiness

This pack prepares one client-owned pilot instance. It doesn't deploy a VPS, enable SMS, or create a multi-client product.

## Production Shape

- The client owns the VPS, domain, Airtable workspace, mailbox, Telegram groups, OpenAI account, and future Twilio account.
- Caddy exposes only `n8n.<client-domain>` over HTTPS.
- Postgres isn't public. Airtable is the manager workspace, not the database of record.
- n8n, Postgres, and Caddy use explicit image versions in the production Compose template.
- n8n editor access uses reverse-proxy/basic authentication for the first pilot.

## Provision From An Empty VPS

1. Record the client's VPS and domain ownership. Add operator SSH keys individually so the client can revoke them.
2. Point `n8n.<client-domain>` to the VPS public IP.
3. Open public ports 80 and 443. Restrict SSH by source IP where possible. Don't expose port 5432.
4. Install Docker Engine and the Docker Compose plugin.
5. Place the approved repository release on the VPS.
6. Create `.env.production` from `.env.production.example` and replace every placeholder with a client value.
7. Generate the Caddy bcrypt password hash with `docker run --rm -it caddy:2.8.4-alpine caddy hash-password`. Put the result in `CADDY_BASIC_AUTH_HASH` inside single quotes so its dollar signs remain literal. Keep the plaintext password in the client's password manager, not `.env.production`.
8. Validate `docker-compose.production.yml` and `Caddyfile.production` with the Stage 8 readiness check.
9. Start Caddy, Postgres, and n8n.
10. In n8n, create credentials named `Make-Ready Postgres`, `Make-Ready OpenAI`, `Make-Ready Airtable`, `Make-Ready Manager Telegram Bot`, `Make-Ready Vendor Telegram Bot`, `Make-Ready Vendor Email IMAP`, and `Make-Ready Vendor Email SMTP`.
11. Provision the client Airtable base and create the Interface and intake form from `docs/airtable-workspace-setup.md`.
12. Import the 19 operational workflows with `scripts/import-make-ready-workflows.ps1` and only the connector activation switches approved for that client.
13. Test intake, one inbound Telegram message, one inbound email reply, one dual delivery, one partial delivery retry, one OpenAI fallback, and one Airtable reconciliation.
14. Run a database restore test before adding the real vendor roster.
15. Record handoff, credential ownership, backup location, and operator access removal.

Caddy can obtain a public certificate only after DNS points to the VPS and ports 80/443 are reachable.

## Backup And Restore

Run a nightly custom-format `pg_dump`. Keep 30 days by default and store a second copy outside the VPS provider or region.

```bash
docker compose --env-file .env.production -f docker-compose.production.yml exec -T postgres \
  pg_dump -U "$MAKE_READY_DB_USER" -d "$MAKE_READY_DB" --format=custom \
  > "data/backups/make-ready-$(date -u +%Y%m%d-%H%M%S).dump"
```

A backup isn't accepted until restore passes:

1. Start an isolated throwaway Postgres database.
2. Restore the latest dump with `pg_restore`.
3. Confirm `vendor`, `turn`, `turn_stage`, `communication_message`, `outbound_queue`, `outbound_delivery`, `airtable_record_map`, and `event_log` exist.
4. Compare row counts and one known turn against the source.
5. Record the dump name, restore time, result, and tester.
6. Delete the throwaway database and any unencrypted temporary copy.

## Retention

- Keep stage timestamps and aggregate operating measures long term.
- Delete vendor message bodies after `RETENTION_MESSAGE_DAYS`, default 90.
- Delete photos and email attachments after `RETENTION_PHOTO_DAYS`, default 90.
- Keep backup files for `BACKUP_RETENTION_DAYS`, default 30.
- Don't collect SSNs, bank details, lease files, screening data, or deposit evidence in this automation.

## Monitoring And Failed Work

Alert the builder when:

- n8n webhook health fails;
- no inbound vendor message is processed for 24 business-hours during an active turn;
- `workflow_error` appears;
- Airtable reconciliation fails;
- approved email or Telegram delivery exhausts its retries; or
- an OpenAI call fails and uses the safe fallback.

Failed provider calls remain in durable delivery or communication records. Retry transient failures with backoff, then stop and alert the builder. Don't send an automatic apology, chase, or recovery message to a vendor.

## SMS Readiness Only

SMS stays disabled. Before any future SMS activation, the client needs a paid Twilio account, an approved A2P 10DLC brand and campaign, consent records, reviewed templates, and legal review for every operating state.

Consent records must include source, timestamp, person who captured it, phone number, and approved purpose. STOP, UNSUBSCRIBE, QUIT, END, and CANCEL style requests set `vendor.opted_out_at`; every future SMS send path must block opted-out contacts.

New campaign registration also needs public privacy-policy and terms URLs under Twilio's June 30, 2026 requirement. A qualified US lawyer must review TCPA and state rules before the first production text.

## Handoff

Give the client control of the VPS, DNS, Airtable, mailbox, Telegram groups, OpenAI account, backup target, and any future Twilio account. Provide the release, manager runbook, restore-test record, credential rotation steps, and an offboarding record.

Then revoke operator SSH and workspace access that the client no longer needs.
