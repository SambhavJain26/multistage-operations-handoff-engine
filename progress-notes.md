# Make-Ready Sequencing Progress Notes

This file is the running handoff record for future sessions. Read it before starting any stage.

## Current Status

- Planning phase complete.
- No implementation code has been written.
- `build-plan.md` created with eight staged sessions.
- Git repository initialized on `main`; remote target is private GitHub repo `make-ready-sequencing`.
- Framing corrected: this is an AI automation demo, not a named software/SaaS product. Any UI is only for demo visualization.

## Source Documents Read

- `03-make-ready-coordination.md`
- `foundation-3-turnover-makeready.md`
- `make-ready-demo-build-plan.md`

## Stage Progress

| Stage | Name | Status | Notes |
|---|---|---|---|
| 1 | Local Environment And Tooling Setup | Not started | Needs local Docker/n8n/Postgres/board, Telegram tunnel, and OpenAI verification. |
| 2 | Data Model, Stage Template, And Fixtures | Not started | No schema or seed data created yet. |
| 3 | Visibility Board And Manual Control | Not started | Core 0% vendor-reply path. |
| 4 | Intake, Channel Normalization, And Matching | Not started | Inbound paths should log only until completion loop is built. |
| 5 | Vendor Completion Loop With Human Approval | Not started | Must preserve manager approval for all outbound vendor messages. |
| 6 | Stall Detection, Digest, Simulator, And Photos | Not started | Absence detector and demo companion surfaces. |
| 7 | Full Fixture Testing And Demo Hardening | Not started | F01-F20, fallback behavior, rehearsal, recording, export/rebuild. |
| 8 | Production Pilot Readiness | Not started | Client-owned VPS, Twilio/10DLC, consent, STOP handling, backups, contract exclusions. |

## Decisions Locked For Now

- Use Postgres for demo state, not Google Sheets.
- Do not assign a product name. Refer to the work as the make-ready sequencing AI automation demo.
- Build and test the demo locally by default.
- Keep VPS, domain, and Caddy for production/pilot deployment only.
- Use a temporary HTTPS tunnel, such as Cloudflare Tunnel or ngrok, only when testing Telegram triggers against local n8n.
- Use two Telegram bots for demo: vendor-facing and manager-facing.
- Build a generic inbound webhook so the Telegram demo can prove channel independence.
- No PMS integration in the demo.
- No production SMS until a client exists and 10DLC can be registered under the client's identity.
- No autonomous outbound vendor messages. Draft only; manager releases.
- Manager approval must include Send, Edit, and Hold for draft vendor messages.
- Manager-only controls must include Cancel as well as Override, Skip, Snooze, and Done.
- Manual manager stage advance is required before vendor automation.
- The sequence guard must be deterministic and reused by manual and vendor paths.
- The unit matcher must be deterministic and reused by all inbound paths.
- Use direct HTTP Request nodes for OpenAI Responses API calls, not n8n's built-in OpenAI/LangChain nodes, when strict schema control or raw error handling matters.
- Default to `gpt-5.6-luna` for both classification and short draft rewriting unless live testing shows draft quality is insufficient.
- Keep `gpt-5.6-terra` or `gpt-5.4-mini` as draft-quality fallbacks, not defaults.
- Use only core n8n nodes; no community nodes in the demo.
- Surface vendor reply rate and auto-handled rate in the board header, weekly digest, and manager `/health` command.
- After every completed task, commit and push changes to `main` unless blocked; report the commit hash or push failure.

## Open Questions / Validation Items

- Confirm actual OpenAI model IDs available with the user's API key during Stage 1.
- Confirm the local tunnel provider before Telegram testing.
- Confirm the domain/VPS provider only before Stage 8 production/pilot readiness.
- Verify Property Meld sequencing behavior before making competitive claims in sales.
- Check whether the prospect is in a metro where managed make-ready providers like Lula materially change the objection.
- Verify state-specific SMS laws before production SMS for any real client.
- Get legal advice before signing any data processing agreement involving India-US processing.

## Deviations From Original Documents

- The original source spec allowed automatic next-vendor notification; this plan follows the later demo build correction and requires manager approval.
- The original source spec suggested Google Sheets for demos; this plan follows the later demo build correction and uses Postgres.
- The original source spec framed vendor reply behavior as a product gate; this plan treats it as an automation gate while preserving a board/manual-control automation path at 0% vendor reply.

## Outstanding Risks

- Vendor reply rate may be too low for automation value.
- Telegram is only a demo stand-in; US vendors should not be expected to adopt it in production.
- The sequence-enforcement differentiator against competitors is not yet verified.
- OpenAI model availability/pricing may differ from the researched defaults and must be checked live.
- Telegram reliability during local testing depends on the tunnel and `WEBHOOK_URL`; a bad value can silently break Telegram triggers.
