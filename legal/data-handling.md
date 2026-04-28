# Data handling policy

**Status: DRAFT — pre-legal-review.** This document will be filled when Layer 7 substantive work lands. Until counsel review, no claim below should be treated as an authoritative commitment for the purposes of a signed agreement.

This document is the **data flow inventory and handling policy** — the working description of how data moves through Efficient Labs. It is the source material for the eventual DPA (Data Processing Agreement), which will be a separate signed instrument per client. The vendor-side inventory lives at [`vendor-list.md`](vendor-list.md); this document is the data-side inventory.

## Coverage

When filled, this document will cover at minimum:

- **Data classification.** The categories of data Efficient Labs handles, and the handling rule for each. The current working categories are:
  - **PII** — personally identifiable information about end users of client systems. Treated as the most sensitive class.
  - **Client confidential** — non-PII information that is sensitive to the client's business (revenue figures, strategic plans, internal processes).
  - **Operational** — system telemetry, logs, configuration that is not client-sensitive.
- **Where each class lives.** Storage locations for each class — Postgres tables on the EL VPS, vendor systems (Anthropic, Stripe, etc.), backups in Backblaze B2 (when that lands), the operator's local devices when applicable. Each location includes encryption posture and access list.
- **Retention windows.** How long each class is held before deletion, the trigger conditions for early deletion (client request, contract termination, incident-driven), and the verification that deletion actually occurred.
- **Deletion procedures.** The runbook (yet to be written) for client-requested deletion, including the Backblaze B2 backup-purge step and the audit-log entry that records the deletion event.
- **Access logs.** Which accesses are logged, the retention of the access logs themselves, and the conditions under which clients may request their own access logs. Pairs with [`audit-log-retention.md`](audit-log-retention.md).
- **Sub-processor data flows.** A flow diagram (or its textual equivalent) showing which classes of data flow to which sub-processors, under what circumstances. The vendor-list.md captures the vendors; this document captures the flows.

## Why this is a DRAFT stub

The right time to write this document substantively is when (a) the production system handles real data and the flows are observable rather than designed, and (b) counsel has reviewed. Both gates are open today. The structure is published so that prospective clients can read the working categories and surface concerns before signing.

## Triggers for filling this stub

- The first production service deploys to the EL VPS and the data flows are observable.
- The first paying client signs an engagement, at which point the DPA (which references this document) becomes a signed instrument.
- A prospective client requests this document as part of vendor security or DPO review.
