# n8n archetypes — Standard tier deliverable templates

This directory holds the ready-to-import JSON archetypes that ship as part of the AI Sovereignty Audit Standard tier ($797) deliverable. Each archetype is operator-customized per client engagement (credentials, channel names, field mappings) and handed off as an importable n8n workflow file.

## Archetype index

| # | File | Trigger | Action | Tier |
|---|---|---|---|---|
| 01 | `01-slack-notification-on-webhook.json` | Generic webhook | Slack message via incoming-webhook | Standard |
| 02 | `02-airtable-on-stripe-checkout.json` | Stripe `checkout.session.completed` | Signature-verified Airtable record insert | Standard (Sovereign tier swaps Airtable for hosted Postgres) |
| 03 | `03-slack-thread-reply-on-linear-ticket-update.json` | Linear `Issue update` webhook | Signature-verified Slack thread reply (with thread-lookup cache) | Standard (Sovereign tier moves thread-lookup to hosted Postgres) |
| 04 | `04-calendly-operator-notification-and-resend-confirmation.json` | Calendly `invitee.created` webhook | Signature-verified fan-out to (a) Slack operator alert + (b) Resend confirmation email | Standard (Sovereign tier swaps Resend for hosted SMTP) |
| 05 | `05-postgres-poll-to-notion-sync.json` | Cron schedule (every 5 min) | Postgres cursor-poll for new rows → Notion page append | Standard (Sovereign tier swaps Notion for hosted wiki / second Postgres) |

## How archetypes are used in a client engagement

1. **Intake** — client fills the Tally audit-intake form. Submission lands in sovereign-core via the `efficient_labs.audit_deliverable` tool (PR #2 on sovereign-core).
2. **Audit deliverable scaffold** — sovereign-core writes a 9-section audit deliverable markdown to MemCompute under `clients/<client-id>/audit-deliverable-<UTC>.md`.
3. **Archetype selection** — operator (or automation) picks one or more archetypes from this directory that match the client's automation needs.
4. **Customization** — replace the `<PLACEHOLDER>` values in the JSON with client-specific credentials. The `_archetype_metadata.operator_action_required` field lists every placeholder.
5. **Delivery** — Standard tier ships the JSON file as a hand-off; client imports into their own n8n instance. Sovereign tier ($1,497) ships the customized JSON + provisions a managed n8n instance on the operator's VPS.

## Adding a new archetype

1. Create `NN-<category>-<description>.json` (numbered prefix for sort order).
2. Include the `_archetype_metadata` block at the top of the workflow JSON (see existing archetypes for shape — tier, category, version, operator_action_required, deliverable_tier).
3. Use SET_DEFAULTS as the first non-trigger node so all customizable values are in one place.
4. Add a row to the archetype index above.

## Conventions

- **Placeholders use `<UPPER_SNAKE_CASE>`** so they're trivially `grep`able.
- **Every credential is replaced**, never hardcoded. The deliverable is import-and-configure, not import-and-run.
- **Signature verification is mandatory** for any webhook that handles payment or PII. See archetype 02 for the Stripe HMAC pattern.
- **Failures fail-closed**, not silent. Webhooks return non-200 on auth/signature/schema failure.

## Roadmap (post-launch)

- 06 — Stripe subscription lifecycle hooks (created / updated / canceled)
- 07 — Inbound email parsing → CRM record
- 08 — GitHub PR opened → Linear ticket create
- 09 — Plausible spike → operator alert + auto-traffic-correlation lookup
