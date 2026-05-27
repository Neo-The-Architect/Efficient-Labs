# ADR 0007 — AI Sovereignty Audit fulfillment pipeline runs end-to-end without operator intervention

- **Status:** Accepted
- **Date:** 2026-05-26
- **Captures:** The booking-to-delivery flow built during the launch sprint (Tasks 6A/6B, 88–94 in the workspace task tracker). Pipeline went green E2E on 2026-05-26; this ADR formalizes the architecture before it accretes complexity from real customer traffic.
- **Supersedes:** —

## Context

The AI Sovereignty Audit is Efficient Labs' launch product (Standard $797 / Sovereign $1,497 / Bespoke). The operator's stated launch principle is **AI-native operation with operator intervention reserved for sales calls and consultations** — every other step from intake to delivery must run without human action. The product economics depend on this; manual fulfillment at $797 doesn't scale past a handful of audits per month.

The decision space was shaped by:

- **n8n already self-hosted** on the production VPS (ADR 0003) with durable execution, retries, and observability. Self-hosted, no per-execution license burden.
- **MemCompute as the IO substrate** (ADR 0018 in sovereign-core, separate repo) provides a typed document store for intake records, delivery tickets, archived deliverables.
- **sovereign-core's CLI LLM backend** uses the operator's Claude Code subscription rather than per-call Anthropic API spend (sovereign-core commit `48524f2`). This makes per-audit LLM cost zero at the margin.
- **Tally** was already chosen as the intake form vendor for its hosted webhook delivery and managed compliance (no PII liability for the form layer itself).
- **Stripe** has KYC complete and live-mode charges enabled.
- **The Temporal question.** A pre-launch evaluation considered Temporal for durable workflow execution, but the conclusion was: n8n provides sufficient durable execution for the $797–$1,497 product. Temporal becomes the right tool for multi-week Bespoke-tier sagas post-launch. Three orchestration substrates (n8n + sovereign-core + Temporal) is wrong; two is enough.

## Decision

The fulfillment pipeline is a **seven-stage, vendor-and-substrate-explicit pipeline** with one operator override point. Each stage owns one contract; no stage reaches across boundaries.

1. **Intake (Tally).** Form `81R2zr` collects 26 questions covering company, workflow, sovereignty, regulation, tier, budget, timeline, success criteria. Tally delivers a webhook on submit.
2. **Normalization (n8n workflow `44rID3Fapv84vALY`).** Webhook → JS Code node maps Tally fields (label-first lookup, key-fallback for synthetic tests) into the canonical `IntakeSubmission` schema → MemCompute PUT under `intake-gate/`.
3. **Conversion (Stripe Checkout, created from the same n8n workflow).** A POST to `/v1/checkout/sessions` mints a tier-aware Checkout link ($797 for Standard, $1,497 for Sovereign or Bespoke fallback). Metadata carries the `intake_id`, `tier`, `client_email`, `company`. Confirmation email to the client includes the link; operator gets BCC.
4. **Payment confirmation (Stripe webhook → n8n workflow `DTyLwBqgxbASClyr`).** Stripe POSTs `checkout.session.completed` with HMAC-SHA256 signature. n8n Code node verifies the signature (raw body via binary attachment, `crypto` module via `NODE_FUNCTION_ALLOW_BUILTIN` allowlist drop-in). On match: MemCompute PUT to `delivery-queue/<intake_id>.md` creates a delivery ticket with `delivery_status: pending_generation` and a 72-hour SLA deadline.
5. **Generation (cron-driven worker, `sovereign-core/scripts/audit_delivery_worker.js`).** Every 10 minutes the worker drains `delivery-queue/`. For each pending ticket: read the intake record, call `dispatchSection` for all 9 canonical sections via the sovereign-core CLI LLM backend (Claude Code subscription, ~45s/section, ~7 minutes total), assemble into final markdown, archive to MemCompute under `audit-deliverables/`.
6. **Rendering (`sovereign-core/scripts/render_audit_pdf.sh`).** pandoc + wkhtmltopdf, branded CSS in `scripts/audit_pdf_style.css`. Falls back to markdown-in-email if PDF rendering fails — the deliverable still reaches the customer, just less polished.
7. **Delivery (Resend).** PDF attached to email, sent to client with operator BCC. Ticket frontmatter updated to `delivery_status: delivered` with `delivered_at`, `resend_message_id`, `sections_generated`.

**Operator override point: the dispatch board (MemCompute `agent-handoffs/`).** If anything goes wrong (alert from supervisor, failed delivery, customer complaint), the operator posts a handoff. Claude Code cron-wakes process the inbox.

**Self-healing.** Systemd `Restart=always` (n8n, docker) or `Restart=on-failure` (MemCompute, cloudflared). `/home/neo/bin/launch-supervisor` cron-runs every 5 minutes, probes 9 endpoints + workflow-active states, emails the operator on 3 consecutive failures (~15 minute outage threshold).

## Consequences

### Positive

- **Audit fulfillment scales with no per-audit operator time.** A paying customer's audit lands in their inbox autonomously within ~10 minutes of payment (worst case: until next cron tick).
- **Substrate honesty preserved.** Every stage writes to MemCompute, every email gets a Resend message ID, every n8n execution is inspectable. There's a complete audit chain from form submission to PDF delivery.
- **Zero per-audit LLM API spend.** The Claude CLI backend uses the operator's existing Claude Code subscription. The marginal cost of the LLM passes inside an audit is operator subscription overhead, not per-call API.
- **Single source of truth for tier pricing.** Stripe live products `prod_UaQt8HHhDKUE71` (Standard) and `prod_UaQtNqVcGWwSYB` (Sovereign) — the workflow maps tier to price ID via expression; no duplication.
- **Build-in-public credibility.** Every component is in a public repo (Efficient-Labs, sovereign-core) except the vault. Customers can read the dispatcher, the worker, the n8n workflow JSON, the PDF style.

### Negative

- **Stripe webhook signing secret is currently inlined** in workflow `DTyLwBqgxbASClyr`'s verify-sig Code node (rather than read from a credential or env var). n8n encrypts workflow JSON at rest, so the exposure is equivalent to a credential; but rotating the signing secret requires editing the workflow Code node, not just updating an env var. Upgrade path: when the next material change to the workflow lands, refactor to read from `$env.STRIPE_WEBHOOK_SIGNING_SECRET` (the n8n container already has the `NODE_FUNCTION_ALLOW_BUILTIN` env passthrough machinery installed).
- **Tally → n8n webhook is not HMAC-verified.** The webhook URL is a hard-to-guess path on a Cloudflare Tunnel, but anyone who learns it could submit synthetic intakes. Mitigation pending operator enabling webhook signing in the Tally UI (`TALLY_WEBHOOK_SIGNING_SECRET` will then be added to vault and consumed by a sibling verify-sig node in the audit-intake workflow).
- **Per-audit wall time is ~7 minutes** (9 sections × ~45s/section). Acceptable for a 72-hour SLA, but the audit can't be marketed as "instant." Customers wait the full 10-minute cron cycle worst-case before the worker picks up their paid ticket.
- **wkhtmltopdf's unpatched Qt on Debian** means `--footer-*` options are silently dropped. PDFs have no page numbers in the footer. Acceptable for v1; revisit if customers comment.
- **Bespoke tier currently falls through to Sovereign pricing** in the Checkout creation expression. A customer who selects Bespoke gets a $1,497 link with an email noting that a custom quote will follow. Operator needs to manually adjust if the bespoke scope materially exceeds Sovereign. v1.1 should add a `bespoke` branch that emails the operator and skips Checkout entirely.
- **Prompt quality is uneven across the 9 sections.** Executive Summary template is the most-refined; sections 2–9 are noted in code as "scaffold-quality, will be iterated on after first 2–3 real client engagements." First 2–3 paying customers will get audits whose tier-2 sections lag the Executive Summary in tightness.

### Kill switch

This pipeline reverses to **operator-driven fulfillment** if any of the following land:

- **More than 2 consecutive customer complaints about deliverable quality** before sections 2–9 templates are iterated. The operator should pause the cron worker (`crontab -e`), generate audits manually via `sovereign run`, and refine prompts before re-enabling automation.
- **Sustained LLM CLI backend outage** (the Claude CLI unavailable for >2 hours during business hours). The worker would error every audit; operator can switch the dispatcher to fall through to a `pending_operator_generation` status and email each as it arrives.
- **A delivery-quality incident where a customer receives an audit referencing wrong data** (e.g., field mapping bug). Workers stops on the failing ticket and emails the operator instead of continuing.

## Alternatives Considered

- **Temporal as primary orchestrator.** Rejected for v1: adds a third orchestration substrate alongside n8n + sovereign-core for marginal gain on a 72-hour SLA product. Will be revisited for Bespoke-tier multi-week engagements post-launch.
- **All workflows in sovereign-core (no n8n).** Rejected because n8n's webhook + visual debugging dramatically reduce iteration cost during a launch sprint. sovereign-core handles the LLM-bearing logic (section generation) where it owns the audit chain; n8n handles the I/O glue where execution traces + retry semantics are the value.
- **Pre-rendered HTML email instead of PDF attachment.** Rejected because customers consistently expect a PDF they can save, share, and reference. HTML-in-email is a strictly weaker artifact for audit-engagement context.
- **Anthropic HTTP API for section generation.** Rejected for per-audit cost reasons. Roughly 5,000–6,000 output tokens × 9 sections × $0.015/1k = ~$0.80/audit on Sonnet. Marginal but real; CLI backend is $0 marginal.
- **Self-hosted Gemma 3 27B as LLM backend.** Local model would eliminate the Claude CLI subscription dependency entirely. Deferred to post-launch: model selection + prompt tuning + infrastructure load all need separate validation; not worth the v1 risk.

## Concerns / Open Questions

- **Tally HMAC verification.** Blocked on operator UI step (toggle webhook signing in Tally dashboard, paste signing secret into vault as `TALLY_WEBHOOK_SIGNING_SECRET`). Tracked as workspace task #93.
- **Prompt quality iteration.** First real customer audits should be reviewed by the operator before delivery; the cron worker could be paused for the first 2–3 customers if the operator wants to inspect each PDF before send. Open question: do we want a "draft mode" that emails the operator first and only sends to the customer on approval? Trade-off: defeats the autonomy claim.
- **Customer reply handling.** Right now, customer replies to the deliverable email land in the operator's inbox via the reply-to header. No mechanism to thread them back to the intake record. v1.1 should add a reply-watching layer (Resend inbound webhook?) that updates the intake record with conversation history.
- **Substrate corruption.** If MemCompute is somehow corrupted between intake write and delivery, the worker reads stale data. Detection mechanism: the worker should checksum the intake record on payment confirmation and re-checksum at delivery start; a mismatch should alert the operator. Not built; tracked as a v1.1 hardening item.
- **9-section prompts as "scaffold-quality."** sovereign-core's `audit_section_prompts.js` explicitly calls out that sections 2–9 will be iterated after 2–3 real engagements. The first real audit landing in this pipeline will produce evidence; the iteration loop is not yet automated (would require capturing customer reply quality signals and feeding them into prompt refinements). Tracked as the "self-improvement loop" v1.1 item.
