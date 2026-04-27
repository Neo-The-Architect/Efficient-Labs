# ADR 0003 — n8n licensing posture: Standard tier only, Sovereign tier blocked

- **Status:** Accepted
- **Date:** 2026-04-27
- **Captures:** Section 9 of `docs/architecture/2026-04-27-fulfillment-architecture-report.md` (and the Section 1 / Section 6 references to tier-conditional delivery)
- **Supersedes:** —

## Context

The Efficient Labs offer was originally framed as two tiers: **Standard** (handoff — the workflow JSON gets emailed or made available as a one-time download for the client to import into their own n8n) and **Sovereign** (managed — Efficient Labs provisions and operates a per-client n8n instance on the EL VPS, bound through Tailscale Funnel, with its own Postgres database and `N8N_ENCRYPTION_KEY`).

n8n is licensed under the **Sustainable Use License**, not an OSI-approved open-source license. The SUL explicitly forbids:

1. Hosting n8n and charging users for access.
2. Letting customers connect their own credentials and build workflows on a hosted instance.

n8n staff have confirmed in community threads (see architecture report Section 9) that consulting — building a workflow and delivering the file to the client to run themselves — is fine. Managed-hosting-as-a-service is not. The Sovereign tier as scoped above clearly crosses the line.

The official remedy is an **n8n Embed license**, obtained directly from n8n GmbH sales. Community claims of approximately $50K/year exist but are unconfirmed; n8n does not publish Embed pricing. Conversation with sales is the only way to get a real number.

## Decision

**Ship Standard tier (handoff JSON file delivery) only.** This tier is unambiguously permitted under the Sustainable Use License — Efficient Labs writes the workflow, hands the JSON to the client, the client imports it into n8n that they themselves operate. No EL-hosted n8n surface. No credentials managed on EL infrastructure for n8n purposes.

**Sovereign tier is blocked** until an n8n Embed license is obtained in writing from n8n GmbH. No managed-tier marketing copy, no managed-tier provisioning automation, no managed-tier pricing in the public proposal templates until the license question is closed. The architecture report Section 6 Step 24-alt (Sovereign provisioning) is design-only and does not ship.

**The Embed conversation is owned by the operator** (NeoTheArchitect) and is gated on having three Standard-tier paying clients delivered, per architecture report Section 8. Until then, the conversation is an explicit non-task.

## Consequences

**Positive.** Zero licensing risk for week-1-through-week-3 fulfillment. The Standard tier is the simpler product to ship and the less expensive to operate (no per-client n8n process, no per-client Postgres database, no per-client systemd unit, no per-client Funnel binding). Public credibility is preserved — no story about Efficient Labs running afoul of an open-source license, which would be terminally damaging for a sovereignty-positioning brand.

**Negative.** No managed-hosting MRR until Embed lands. Sovereign was the higher-margin tier and the one most aligned with the "managed and hardened on our VPS" sovereignty narrative. The first three engagements run as time-and-materials-style fulfillment, not recurring revenue. The recurring-revenue thesis arrives later than the original plan.

**Kill switch.** If Embed pricing comes back at a number that does not pencil for the engagement scale (e.g., $50K/year against the first ten clients), the Sovereign tier is permanently abandoned. Replacement: position the Sovereign tier as "we will help you self-host n8n on your own infrastructure with our hardening playbook." That keeps EL on the right side of the SUL while still selling the operational expertise. The hardening playbook becomes another public artifact in `infra/runbooks/`.

## Concerns / Open questions

- **Verify n8n staff position in writing before public launch.** Community threads are not contracts. The Embed conversation should also confirm in writing what Standard tier *delivery* (handing over a JSON file) is allowed under the SUL — almost certainly yes, but get it on record.
- **Watch n8n license changes.** SUL terms have been amended before. Pin a Renovate-style watch on the n8n license file in their public repo and alert on any change.
- **Single-tenant managed-on-client-infra workaround.** Provisioning n8n on infrastructure the client owns (their AWS, their Hetzner, their on-prem) and operating it for them under a managed-services agreement is a different licensing question than the Sovereign tier as originally scoped. Probably permitted; worth raising during the Embed conversation.
- **The architecture report references this ADR as `0003` and elsewhere references `0005`** (Section 8 Week 2 milestone refers to "ADR 0005 documents the n8n license decision"). The numbering in the report's Section 8 was a placeholder; this repo lands the n8n license decision as ADR 0003 to put it in front of the operator early. ADR 0005 may be re-used for a different decision later.
