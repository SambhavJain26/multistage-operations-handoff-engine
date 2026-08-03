# Stage 8 Production Pilot Readiness

Stage 8 prepares the make-ready sequencing automation for a first paid pilot. It does not deploy a real server, enable SMS, or create a multi-client SaaS. Production remains one client per instance, on infrastructure billed to and owned by that client.

## Readiness Assets

- `docker-compose.production.yml`: production-shaped Compose template with pinned images for Caddy, Postgres, and n8n.
- `Caddyfile.production`: TLS reverse proxy for `n8n.<client-domain>` and basic-auth static board hosting at `board.<client-domain>`.
- `.env.production.example`: placeholder production environment contract. Copy to `.env.production` only on a client-owned VPS.
- `scripts/check-stage-8-production-readiness.ps1`: validates production placeholders, pinned images, HTTPS origins, retention defaults, and safe SMS-disabled posture.
- `docs/stage-8-manager-runbook.md`: one-page client manager operating guide.
- `docs/stage-8-contract-exclusions.md`: one-page proposal/contract exclusions.
- `docs/stage-8-success-metrics.md`: pilot metric definitions.

## Client-Owned Provisioning Path

1. Client buys or owns the VPS, domain, and Twilio account. Your access is by SSH key and can be revoked by the client.
2. Point DNS:
   - `n8n.<client-domain>` -> VPS public IP.
   - `board.<client-domain>` -> VPS public IP.
3. Open only required public firewall ports:
   - `80/tcp` and `443/tcp` to Caddy.
   - SSH restricted to known admin IPs where possible.
   - Do not expose Postgres publicly.
4. Install Docker Engine and Docker Compose plugin.
5. Clone the private client repo or copy the approved release artifact to the VPS.
6. Copy `.env.production.example` to `.env.production` and replace every placeholder.
7. Run:
   ```powershell
   .\scripts\check-stage-8-production-readiness.ps1 -EnvFile .env.production
   ```
8. Start the stack:
   ```bash
   docker compose --env-file .env.production -f docker-compose.production.yml up -d
   ```
9. Import workflows using the Stage 7 import helper with production env values in place. Telegram may remain inactive unless explicitly retained for the pilot.
10. Create n8n credentials manually for Postgres, OpenAI, and any approved messaging provider.
11. Run the Stage 8 readiness check again, then run the Stage 7 static check against the production instance before onboarding vendors.

## Caddy Layout

- `n8n.<client-domain>` reverse-proxies to `n8n:5678`.
- `board.<client-domain>` serves the static board from `/srv/board` and applies Caddy basic auth.
- Caddy obtains public certificates automatically when DNS points to the VPS and ports 80/443 are reachable.
- The board still uses internal webhook tokens in n8n. Caddy basic auth is the pilot user-facing gate; custom app accounts are deferred.

## Backup And Restore

Default policy:

- Nightly Postgres dump.
- Keep backups for at least `BACKUP_RETENTION_DAYS`, default 30.
- Store a second copy outside the VPS region or provider.
- Test restore once before go-live and after any backup script change.

Manual dump command:

```bash
docker compose --env-file .env.production -f docker-compose.production.yml exec -T postgres \
  pg_dump -U "$MAKE_READY_DB_USER" -d "$MAKE_READY_DB" --format=custom \
  > "data/backups/make-ready-$(date -u +%Y%m%d-%H%M%S).dump"
```

Restore-test outline:

1. Start an isolated throwaway Postgres container or database.
2. Restore the latest dump with `pg_restore`.
3. Confirm core tables exist: `vendor`, `turn`, `turn_stage`, `outbound_queue`, `event_log`, and `media_asset`.
4. Confirm at least one known pilot row is present when testing after go-live.
5. Record the restore timestamp and dump file name in the client handoff log.

## Retention

- Keep stage timestamps and non-sensitive metrics long-term because they are the reporting value.
- Purge vendor free-text messages after `RETENTION_MESSAGE_DAYS`, default 90.
- Purge stored photos after `RETENTION_PHOTO_DAYS`, default 90, unless the client chooses a shorter window.
- Do not store SSNs, bank details, lease documents, tenant screening data, or deposit itemization artifacts.

## Monitoring And Dead Letter

Required pilot alerts:

- n8n health endpoint unavailable.
- Board URL unavailable.
- No inbound vendor message for 24 business-hours after vendor SMS is enabled.
- Any `workflow_error` event.
- Any failed messaging/OpenAI call that exhausts retries.

Dead-letter policy:

- Retry transient OpenAI or messaging failures with backoff.
- After three failed attempts, write a dead-letter event and alert the builder/operator.
- Do not auto-send recovery messages to vendors.
- The manager may resolve from the board or approval queue after review.

## SMS Readiness

SMS remains disabled in Stage 8. `SMS_ENABLED` must be `false`.

Before first production SMS:

- Client has a paid Twilio account.
- Client registers A2P 10DLC under their EIN/brand.
- Campaign is approved before any vendor traffic.
- Client has public privacy policy and terms URLs for A2P campaign registration.
- Vendor roster includes phone number, consent source, consent timestamp, and opt-out state.
- STOP/UNSUBSCRIBE/QUIT/END/CANCEL style inbound text sets `vendor.opted_out_at`.
- Every outbound Send path checks `opted_out_at IS NULL`.
- Client message templates are reviewed and approved.
- Client operating states are reviewed by qualified US counsel for TCPA and state SMS rules.

Reference sources for the current checklist:

- Twilio A2P 10DLC quickstart: https://www.twilio.com/docs/messaging/compliance/a2p-10dlc/quickstart
- Twilio June 30 2026 privacy/terms requirement: https://www.twilio.com/en-us/changelog/a2p-10dlc-campaign-registration-will-require-privacy-policy-and-
- FCC TCPA revocation rules page: https://www.fcc.gov/document/tcpa-rules-revoking-consent-unwanted-robocallsrobotexts

## Handoff

Give the client:

- VPS provider login ownership.
- Domain/DNS ownership.
- Twilio ownership.
- Repo or release artifact.
- `.env.production` location and rotation instructions, without sending secrets over chat/email.
- Backup restore procedure and latest restore-test record.
- Manager runbook.
- Contract exclusions.
- Offboarding note: stop containers, revoke your SSH key, rotate n8n/OpenAI/Twilio secrets, and keep the database/backups.
