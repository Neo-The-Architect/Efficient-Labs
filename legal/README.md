# legal/

**Status: DRAFT — pre-legal-review.** Every document in this directory is a working draft. Counsel review is non-optional before any of these documents are treated as authoritative or used as the basis for a signed agreement with a paying client. Architecture report Section 7 is the source of the discipline: this is the one place the build-in-public stack does not move-fast-and-break-things.

The directory is published in advance of legal review for two reasons. First, prospective clients can read the operator's working drafts and surface concerns before a sales conversation rather than after. Second, the public-build credibility pattern (architecture report Section 7) requires that the legal posture be visible from the start — having no legal directory at all signals worse than having a clearly-DRAFT legal directory.

## Contractual templates

Three documents that must exist *before* the first paying client signs. None of them are written yet. Counsel review is required before they are usable.

1. **MSA** — Master Services Agreement template covering scope, deliverables, payment, IP assignment, and a build-in-public clause. The build-in-public clause is **opt-out by default**, **opt-in for name attribution**. Per architecture report Section 7.
2. **DPA** — Data Processing Agreement template (Efficient Labs as processor, client as controller) listing sub-processors. The current sub-processor inventory lives at [`vendor-list.md`](vendor-list.md) (also DRAFT). GDPR Article 28 compliant.
3. **Public-build playbook** — operator-and-client-facing document describing what gets published, when, and under what consent state. References the per-client publish-policy boundary file at [`publish-policy-template.md`](publish-policy-template.md).

These three are not yet on disk; they land as separate PRs as the legal-review cycle produces them.

## Policy and inventory documents

The documents below are the policy / inventory layer that the contractual templates above will reference. They are all DRAFT pending legal review; the structure is in place so that counsel review can produce the operative versions without re-architecting the directory.

| File | Purpose |
| --- | --- |
| [`security-policy.md`](security-policy.md) | Public-facing security posture statement. Names the controls Efficient Labs commits to. References [`SECURITY.md`](../SECURITY.md) (the disclosure policy at the repo root) for vulnerability handling. |
| [`data-handling.md`](data-handling.md) | Working description of how data flows through Efficient Labs — what is collected, where it is stored, who has access, retention, deletion. Source material for the eventual DPA. |
| [`vendor-list.md`](vendor-list.md) | Active and conditional sub-processor inventory. Sources from architecture report Section 7. Updated as the vendor stack evolves. |
| [`incident-disclosure.md`](incident-disclosure.md) | The client-disclosure side of incident response. Pairs with [`docs/processes/incident-response.md`](../docs/processes/incident-response.md), which is the operational side. Includes the 72-hour breach-notification commitment that GDPR-bound clients will require. |
| [`audit-log-retention.md`](audit-log-retention.md) | What is logged, how long it is retained, who can request it, and the conditions for client-facing audit-log access. |
| [`publish-policy-template.md`](publish-policy-template.md) | Per-engagement template form of the publish-policy boundary file. Three-checkbox structure (case-study, archetype-derivative, name-attribution) with all defaults `no`. Per architecture report Section 7. |

## Why this directory is public

The templates and policies are public so prospective clients can read them before a sales conversation. The signed instances (per-client MSAs, per-client DPAs, per-engagement publish policies) are private and held in the relevant per-client repository or in document storage outside this monorepo. Architecture report Section 7 specifies the topology: `efficient-labs-public/` (everything ships), `efficient-labs-templates/` (curated archetypes, sanitized), `efficient-labs-clients/` (private, per-client repos, never public).

## DRAFT discipline

While documents in this directory are DRAFT, every file in the directory carries a `Status: DRAFT — pre-legal-review` line at the top. The DRAFT line is removed only when counsel review has produced the operative version. Removing the line without legal review is a discipline failure that the [code review checklist](../docs/processes/code-review-checklist.md) catches.

If a client asks whether they can rely on a DRAFT document, the honest answer is: not as a contract, yes as a statement of operator intent that will be ratified by counsel before signature.
