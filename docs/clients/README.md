# Client documentation

This directory holds documents written for clients — the prospective and active companies that engage Efficient Labs for fulfillment. The audience matters: client-facing documents are written in language a non-technical buyer can act on, with technical depth available behind links rather than imposed up front.

## Index

| Document | Purpose |
| --- | --- |
| [Onboarding](onboarding.md) | The client onboarding flow — what happens between contract signature and first delivered workflow. **Stub.** Filled out post-first-paying-client. |

## What lives here vs. elsewhere

- **Client onboarding flow:** here. The "what happens between signature and delivery" surface.
- **Vulnerability disclosure (for clients reporting issues):** at the repo root, [`SECURITY.md`](../../SECURITY.md). Not duplicated here.
- **Sub-processor inventory and DPA structure:** in [`legal/`](../../legal/). The [vendor list](../../legal/vendor-list.md) is the operative working draft.
- **Commercial terms (MSA template, engagement structure):** in [`legal/`](../../legal/) once those templates exist (currently DRAFT; see [`legal/README.md`](../../legal/README.md)).
- **Architecture and design:** the [architecture report](../architecture/2026-04-27-fulfillment-architecture-report.md) is public for clients who want the technical depth, but is not the document a client is expected to read first.

## What this directory is *not*

Not a marketing site. The marketing site lives at `marketing-site/` (placeholder today; deployed to Cloudflare Pages per architecture report Section 8). The marketing site is the persuasion surface; this directory is the post-engagement reference surface.

Not a sales-collateral library. Sales material that varies per opportunity (proposals, pricing tables, case-study drafts) lives outside the public mono-repo; only finalized, fully-anonymized or explicitly-consented case studies land in [`case-studies/`](../../case-studies/) per architecture report Section 7.

## How to add a client document

When the operator finds themselves answering the same client question across multiple engagements, the answer is a candidate for this directory. The first version is honest about its draft status; later versions iterate based on what clients actually use.

Confidentiality boundary: no client-specific identifiers, no real workflow internals, no real lead data in any document committed here. The [publish-policy template](../../legal/publish-policy-template.md) is the source of truth for what about a client engagement may be referenced publicly.
