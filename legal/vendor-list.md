# Vendor and sub-processor list

**Status: DRAFT — pre-legal-review.** This document is the working inventory of third-party vendors and sub-processors involved in operating Efficient Labs. It is published for transparency in advance of legal review; counsel review is required before this document is treated as the authoritative sub-processor disclosure for a paying-client DPA. Until then, any factual claim below should be verified against the vendor's own current published terms before relying on it for a contractual decision.

**As of: 2026-04-28.** The vendor stack is expected to evolve as the company ships through weeks 1–4 of the architecture report's implementation sequence (Section 8). This document is updated through PRs as additions, removals, or material changes occur.

The list is sourced from the architecture report, especially Section 7 (public-build credibility pattern), Section 9 (open risks and unknowns), and the implementation sequence in Section 8.

---

## Active vendors

These are vendors used today, or planned for use within week 4 of the implementation sequence and already procured / signed up for.

### Anthropic

| Field | Value |
| --- | --- |
| **What they are** | LLM provider. Source of Claude (the model line that does the engineering work in the sandbox; the model that powers the n8n CTO and other agents in production). |
| **Data flowing to them** | Prompts and responses for engineering work performed in the sandbox; production prompts and responses when client-facing agents are deployed. May include intermediate state from agent runs. |
| **Data residency / jurisdiction** | United States (Anthropic, PBC; San Francisco, California). |
| **DPA / sub-processor terms** | Anthropic publishes a Data Processing Addendum and a list of sub-processors at https://www.anthropic.com/legal — verify the current version when relying on this row. |
| **Security posture link** | https://trust.anthropic.com (security page, current as of authoring; verify URL) |
| **Notes** | Privacy commitments specific to API customers (vs. consumer claude.ai users) are documented separately by Anthropic. The architecture treats Anthropic as a critical-path vendor — a sustained outage materially affects fulfillment. |

### Stripe

| Field | Value |
| --- | --- |
| **What they are** | Payment processor. Stripe Standard plus Stripe Billing plus Stripe Tax (per architecture report Section 9 — Stripe Connect is not used). |
| **Data flowing to them** | Customer billing details, payment instruments, subscription state, transaction records, invoice metadata. EU VAT determination via VIES through Stripe Tax. |
| **Data residency / jurisdiction** | Stripe Payments Europe Ltd. (Ireland) for EU customers; Stripe, Inc. (United States) for US customers; varies by customer location and product. Verify against the Stripe entity selected at signup. |
| **DPA / sub-processor terms** | Stripe publishes a DPA and a sub-processor list at https://stripe.com/legal — verify current version. |
| **Security posture link** | https://stripe.com/security |
| **Notes** | Stripe is PCI-DSS Level 1 certified. Card data does not transit Efficient Labs' infrastructure when using hosted Checkout. Not yet active — comes online when the proposal-to-payment loop ships. |

### Hostinger

| Field | Value |
| --- | --- |
| **What they are** | VPS provider. Hosts the production fulfillment surface (Postgres, Restate, Weft, Paperclip when deployed). |
| **Data flowing to them** | Everything that lives on the VPS at rest: encrypted-at-rest databases, application state, logs, backups stored on-host. (Off-host backups go to Backblaze B2, not Hostinger.) |
| **Data residency / jurisdiction** | Hostinger International Ltd. (Lithuania); the VPS itself is provisioned in a region the operator selects at signup. Verify the VPS region against the residency commitments made to clients. |
| **DPA / sub-processor terms** | Hostinger publishes terms at https://www.hostinger.com/legal — verify current version. **HIPAA BAA availability is not assumed** — architecture report Section 9 flags this for verification before any PHI client engagement. |
| **Security posture link** | https://www.hostinger.com/trust |
| **Notes** | Production access is via Tailscale SSH only ([ADR 0005](../docs/adr/0005-tailscale-ssh-as-primary-access-path.md)); the Hostinger hPanel web terminal is the documented emergency fallback (issue #3). |

### Tailscale

| Field | Value |
| --- | --- |
| **What they are** | Mesh-VPN / identity-based-network provider. Sole authorized SSH access path to the production VPS ([ADR 0005](../docs/adr/0005-tailscale-ssh-as-primary-access-path.md)); ACL-controlled access surface for operator devices. |
| **Data flowing to them** | Tailnet membership metadata (devices, users, tags, ACL configuration). Tailscale's control plane does not see traffic content (the data plane is end-to-end encrypted between peers). |
| **Data residency / jurisdiction** | Tailscale Inc. (Canada / United States; verify entity at signup). |
| **DPA / sub-processor terms** | Tailscale publishes terms at https://tailscale.com/legal — verify current version. |
| **Security posture link** | https://tailscale.com/security |
| **Notes** | Currently on the personal/free tier (architecture report Section 9: 6 users, unlimited devices, 3 ACL groups, 50 tagged resources). Move to a paid tier when the team grows to a 7th user or when commercial use exceeds the free tier's terms. |

### GitHub

| Field | Value |
| --- | --- |
| **What they are** | Source-code hosting and collaboration platform. Hosts the public Efficient Labs repository, the issue tracker, the PR workflow, and (when configured) GitHub Actions CI. |
| **Data flowing to them** | All committed source code (public on this repo); issue and PR metadata; Actions execution logs (when CI runs); repository security advisories filed through the private channel. |
| **Data residency / jurisdiction** | GitHub, Inc. (United States; subsidiary of Microsoft Corporation). |
| **DPA / sub-processor terms** | GitHub publishes a DPA and sub-processor terms at https://github.com/customer-terms — verify current version. Microsoft's cloud sub-processor list applies to GitHub Actions execution. |
| **Security posture link** | https://github.com/security |
| **Notes** | Per-client repos (`efficient-labs-clients/`) are private GitHub repositories; the public repo and the templates org are explicitly public per architecture report Section 7. |

---

## Conditional vendors

These are vendors planned for use under specific conditions — used if and only if the corresponding feature ships or the corresponding fallback triggers.

### Apollo

| Field | Value |
| --- | --- |
| **What they are** | B2B contact and company enrichment provider. |
| **Data flowing to them** | Lead identifiers (company name, email domain) for enrichment lookups; receives back contact details, firmographic data, qualification signals. |
| **Trigger** | Active when the lead-intake workflow runs enrichment (architecture report Section 6, runbook step ~3). |
| **DPA / sub-processor terms** | Apollo publishes terms at https://www.apollo.io/legal — verify current version. |
| **Notes** | Real lead data flowing to Apollo is private by definition (architecture report Section 7, "what's private"). |

### Tavily

| Field | Value |
| --- | --- |
| **What they are** | Web search / research API for agent workflows. |
| **Data flowing to them** | Search queries generated by agents during qualification, research, or workflow-design steps. |
| **Trigger** | Active when an agent in the fulfillment loop performs research as part of qualification or PRD generation. |
| **DPA / sub-processor terms** | Tavily publishes terms at https://tavily.com/terms — verify current version. |
| **Notes** | Queries derived from real lead data are themselves treated as private; queries derived from synthetic / public material are not. |

### OpenRouter

| Field | Value |
| --- | --- |
| **What they are** | LLM aggregator / router. Used as the fallback path for the multi-component LLM architecture (architecture report Section 5). |
| **Data flowing to them** | Prompts and responses routed through OpenRouter to the underlying model provider when the primary path (Anthropic direct) is unavailable or when a non-Anthropic model is intentionally selected. |
| **Trigger** | Conditional on the fallback chain firing or on a deliberate non-Anthropic model selection. Not active in the day-1 design. |
| **DPA / sub-processor terms** | OpenRouter publishes terms at https://openrouter.ai/terms — verify current version. |
| **Notes** | When OpenRouter is in the path, the underlying model provider (e.g. Google, OpenAI) is itself a sub-processor. The list will grow when fallback is enabled. |

### ElevenLabs

| Field | Value |
| --- | --- |
| **What they are** | Text-to-speech / voice synthesis provider. |
| **Data flowing to them** | Text generated by agents that is rendered to audio (e.g. for client-facing voice content if voice features ship). |
| **Trigger** | Conditional on voice features being included in a client engagement. Not active in the day-1 design. |
| **DPA / sub-processor terms** | ElevenLabs publishes terms at https://elevenlabs.io/terms — verify current version. |
| **Notes** | When voice ships, the surface and the data shape are documented in this row before going live. |

### Backblaze B2

| Field | Value |
| --- | --- |
| **What they are** | Off-host object storage. Used as the destination for encrypted nightly database backups (architecture report Section 8, pre-week zero). |
| **Data flowing to them** | Encrypted backups of `paperclip` and `weft` databases; potentially other application state. Encryption is performed before upload — Backblaze sees ciphertext. |
| **Trigger** | Active once the backup automation is configured. Not yet wired (the runbook for `paperclip db:backup` referenced in the architecture report has not yet been executed). |
| **DPA / sub-processor terms** | Backblaze publishes terms at https://www.backblaze.com/legal — verify current version. |
| **Notes** | Backup encryption keys are held by Efficient Labs; Backblaze cannot read backup contents without the operator's keys. |

### Cloudflare

| Field | Value |
| --- | --- |
| **What they are** | CDN, DNS, and edge-platform provider. Hosts the marketing site (Cloudflare Pages, per architecture report Section 8 week 1) and provides DNS for the company's domains. |
| **Data flowing to them** | Marketing site visitor traffic (IP addresses, request metadata); DNS query traffic; static site content. |
| **Trigger** | Active once the marketing site is deployed. Not yet live. |
| **DPA / sub-processor terms** | Cloudflare publishes a DPA and sub-processor list at https://www.cloudflare.com/trust-hub/ — verify current version. |
| **Notes** | The marketing site does not collect PII through forms by design (lead intake goes through Weft / Paperclip on the VPS, not through Cloudflare-stored forms). |

---

## Vendors explicitly not used

For transparency: this section lists vendors that might reasonably be expected in this kind of stack but are deliberately not used.

- **Tangle / WeaveMind** — not used for any client-touching work. Architecture report Section 3 documents the rationale: no published DPA, no sub-processor list, no SOC 2, no on-prem SKU. Revisit only if WeaveMind ships an on-prem option.
- **Stripe Connect** — Connect is for marketplaces; Efficient Labs is a normal B2B SaaS subscription business. Stripe Standard plus Billing plus Tax is the right surface (architecture report Section 9).
- **AWS / Azure / GCP** — not used as the primary host (Hostinger is). Architecture report Section 9 notes that PHI workloads, if they ever materialize, would require migration to a hyperscaler with a HIPAA BAA — that decision is deferred until a PHI client is on the table.

---

## How to update this document

When a vendor is added, removed, or the data flow / posture changes, update this document in the same PR that introduces the change. The PR description names the vendor, the trigger, and the data shape. Counsel review is non-optional once this document graduates from DRAFT — until then, it is operator best-effort and is annotated as such at the top of the file.

If the operator notices a vendor in the system that is not documented here, that is a bug. The fix is to add the row, not to silently keep operating.

---

## Open questions

- **DPA versions and effective dates.** Each vendor row above points to the vendor's terms page for the authoritative DPA. A future revision pins the DPA version (or at least the effective date) at the time of signature, so that when the vendor updates their terms, the historical reference is preserved.
- **Sub-sub-processors.** Several vendors (Anthropic, Stripe, GitHub, Cloudflare) themselves use sub-processors. The full transitive list is what a careful client will eventually ask for. This document captures the direct sub-processors today; the transitive list lands in a follow-up revision when the legal-review pass produces the formal version.
- **Region pinning.** GDPR and similar frameworks may require pinning of certain processing to specific regions (e.g. Postgres data residency in the EU for EU-controller clients). The architecture report Section 9 flags this as an open question; this document records that the question is open.
