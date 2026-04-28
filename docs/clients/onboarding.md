# Client onboarding

**Status: stub.** Filled out post-first-paying-client. Authoring this document before the first engagement would produce a confident description of a process that has never run; the failure mode is well-understood (see the [incident-response stub](../processes/incident-response.md#why-this-is-a-stub) for the same reasoning applied to a different document).

## What this document will eventually cover

- **The signature-to-kickoff window.** Concrete actions in concrete order: client signs MSA / DPA / publish policy → per-client repo provisioned in `efficient-labs-clients/` → kickoff call scheduled → intake bundle (PRD draft, credentials inventory, access requirements) generated.
- **The intake bundle.** What information Efficient Labs needs from the client to start work, in the format the client can produce in 30 minutes rather than 3 hours.
- **The first delivery.** What "first delivered workflow" looks like as an artifact: where it lives (the per-client private repo), how the client receives it, what verification the client is expected to perform.
- **The followup loop.** What happens after delivery — monitoring (when the followup workflows ship), iteration cadence, the path from "delivered workflow" to "production-running workflow at the client's site."
- **Communication.** Cadence (weekly check-in vs. async-only), channels (email / Slack / something else), escalation path, who is on the Efficient Labs side at each step (today: operator, with Claude Code in the engineering loop; future: contractor or second operator).
- **What the client commits to.** The client's responsibilities — providing access, reviewing PRDs, approving the publish-policy boundary state, paying invoices on schedule. Honest about the asymmetry: a fulfillment engagement is two-sided.
- **What ends an engagement.** Successful delivery, scope completion, mutual termination, escalation paths if either party is unhappy. The MSA template (DRAFT in [`legal/`](../../legal/)) will name these contractually; this document is the operational guide to applying them.

## Why this is a stub

Writing client onboarding before any client has been onboarded produces fiction. The right time to write this document is during the first paying engagement, with the engagement itself as the source material. The first version is the engagement's debrief, refined into a forward-looking document for the second engagement.

## In the meantime

A prospective client who arrives at this stub before the first engagement has happened can take that as honest signal — Efficient Labs is at the pre-first-customer stage, the operator is building the system in public, and onboarding will be designed alongside the first paying client rather than imposed from a template. The architecture report at [`docs/architecture/2026-04-27-fulfillment-architecture-report.md`](../architecture/2026-04-27-fulfillment-architecture-report.md) is the canonical design and is the right document to read for the technical and operational shape of an engagement.

For commercial questions while this document is a stub: the operator's contact information is published on the marketing site (when deployed) and through the GitHub profile. The legal directory ([`legal/`](../../legal/)) is the working surface for contractual structure.
