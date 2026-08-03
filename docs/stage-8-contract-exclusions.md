# Pilot Contract Exclusions

Use this language as proposal/contract source text. Have counsel review before signing.

## System Scope

The automation is a coordination and visibility layer for vacant-unit make-ready work. It helps track stage status, vendor replies, manager approvals, blocked sequence conditions, and elapsed time. The client's PMS remains the system of record.

## Explicit Exclusions

- No PMS system of record. The automation does not replace Buildium, AppFolio, Rent Manager, Propertyware, or any other PMS.
- No PMS sync unless separately scoped in writing after confirming the client's PMS plan and API access.
- No deposit assessment. The automation does not classify damage as tenant-chargeable, normal wear, or owner expense.
- No security deposit correspondence or itemization.
- No tenant screening, applicant scoring, lease approval, or housing decisioning.
- No listing, ad copy, ad targeting, pricing, or fair-housing-sensitive marketing automation.
- No occupied-unit maintenance or habitability response workflow.
- No automatic vendor chasing or autonomous outbound vendor messaging. Vendor messages are drafted and require manager approval before sending.
- No photo verification. Photos are stored and displayed for human review only.
- No guarantee of vendor reply rate, turn-time reduction, vacancy reduction, or ROI.

## Client Responsibilities

- Own and pay for the VPS, domain, Twilio account, phone numbers, and messaging registration.
- Provide accurate vendor roster, phone numbers, and consent records.
- Review message templates before any production SMS.
- Confirm operating-state SMS and property-management legal requirements with qualified counsel.
- Keep PMS records current.
- Perform final QA before relisting a unit.

## Operator Responsibilities

- Build and maintain the n8n workflows on the client-owned instance.
- Keep workflow changes versioned.
- Maintain backup and restore procedures.
- Alert the client/operator on infrastructure failures.
- Provide an offboarding path so the client can retain data and revoke access.

## SMS Gate

No production SMS may be enabled until:

- A2P 10DLC brand and campaign are approved under the client's identity.
- Privacy policy and terms URLs required for campaign registration are available.
- Vendor consent is recorded.
- STOP/UNSUBSCRIBE handling is live and tested.
- State-law review is complete.
