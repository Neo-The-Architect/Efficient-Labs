# Publish policy — per-engagement template

**Status: DRAFT — pre-legal-review.** This file is the template form of the per-engagement publish policy described in architecture report Section 7. It is not signed by anyone in this form; the signed instance is created per-engagement, lives in the relevant per-client repo (private), and is referenced by the boundary-enforcement automation described below. Counsel review is required before this template is used as the basis for a signed agreement with a paying client.

---

## What this document is

The publish policy is the bright-line, mechanical boundary that determines what about a client engagement may be published in any public Efficient Labs surface — the public mono-repo, the marketing site, social posts, case studies, conference talks, and any derivative artifacts (workflow archetypes, SKILL.md examples, prompt patterns).

The policy is mechanical so that compliance does not depend on operator judgment in the moment. The Paperclip "Content Publishing" agent will not promote a case study to public-draft until the corresponding box below is checked. The Weft archetype-extraction routine will not derive a public template until the corresponding box is checked. The names in any public artifact are governed by the third box. **Defaults are all "no";** the client must affirmatively flip a box to authorize the corresponding publication path.

---

## Per-engagement policy

**Client name (internal):** _________________________
**Client name (public-facing, if different):** _________________________
**Engagement start date:** _________________________
**Policy version:** 1.0 (this template's version at the time of authoring)
**Policy last updated:** _________________________
**Operator signature:** _________________________
**Client signature:** _________________________

### Authorization checkboxes

Each checkbox is independent. Checking one does not imply the others. Unchecked is the default; checking requires the client's explicit affirmative action — "I do not object" is not the same as authorization.

- [ ] **Case-study allowed.** Efficient Labs may publish a case study describing this engagement. The case study may include: the problem statement (in client-approved language), the workflow architecture, the outcome metric, and a generalized description of the business impact. The case study draft is reviewed and approved by the client before publication. Default: **no.**
- [ ] **Workflow archetype derivative allowed.** Efficient Labs may extract a generalized "archetype" of the workflow built for this engagement (with all client-specific identifiers, business logic, and data references removed) and publish it as a reusable template in the public mono-repo or to the relevant ecosystem (Paperclip skills, n8n templates, Weft programs). The archetype is reviewed by the client before publication if the client requests review; otherwise, the operator's sanitization is the binding step. Default: **no.**
- [ ] **Name attribution allowed.** Efficient Labs may name the client by company name (and, if separately authorized, by individual contributor name) in any of the publication paths above. Without this checkbox, the case study and any derivative artifact are anonymous or pseudonymous. Default: **no.**

If the client wants to authorize a more granular shape of attribution (e.g. company name yes, individual names no; archetype yes, but only after a 90-day delay), that nuance is captured in the **Notes / overrides** section below. The checkboxes above are the *default* boundary; overrides are explicit and dated.

---

## What is published if no box is checked

If the client signs the engagement and never checks a box, the following remains permitted by default — these are publication paths that do not depend on this policy because they do not reference the client at all:

- **Generic engineering artifacts** the operator builds during the engagement (a Postgres tuning note, a Restate operations runbook, a Tailscale ACL pattern) that are not specific to the client and would be valid Efficient Labs IP regardless of the engagement.
- **Public-mono-repo improvements** (process docs, ADRs, runbook revisions) made during the engagement window that are not derived from the client's data, business logic, or workflow.
- **Aggregate counters** (e.g. "5 engagements completed this quarter") that do not identify any specific client.

If any of the above strays into the engagement's specifics — even a sanitized version — it falls under the archetype-derivative checkbox and is not permitted without authorization.

## What is never published, regardless of any checkbox

The following remain confidential under all conditions, including positive checkboxes above:

- **The actual client workflow JSON** (the n8n `workflows/main.json` file or its Weft equivalent). Even sanitized, n8n workflow files often embed business logic that is itself the client's IP. The architecture report Section 7 explicit rule: "Never publish a client's actual workflow JSON, even sanitized, without explicit consent — n8n workflow files often embed business logic that is itself the client's IP."
- **The client's PRD.** PRDs name internal goals, constraints, and tradeoffs that are confidential to the client.
- **Real client credentials** (API keys, OAuth tokens, database passwords). These live in Paperclip's encrypted-at-rest secrets table and never leave the VPS.
- **Real lead data** (names, emails, firmographic data acquired from Apollo or similar enrichment vendors). Real lead data tied to a real engagement is private regardless of any other checkbox.
- **Internal communications** between the client and Efficient Labs (Slack messages, email threads, call recordings, meeting notes).

These exclusions are part of the boundary as a class. They are not negotiable per-engagement; if a client requests publication of any of these, the request is escalated to legal review before any action.

---

## Mechanical enforcement

The architecture report Section 7 specifies that compliance is mechanical, not discretionary. The current and aspired enforcement points:

- **Repository topology.** Three GitHub orgs (or three top-level paths in one mono-repo): `efficient-labs-public/` (everything ships), `efficient-labs-templates/` (curated archetypes, sanitized), `efficient-labs-clients/` (private, per-client repos, never public). The client repo for this engagement is at: _________________________.
- **Paperclip "Content Publishing" agent gate.** When deployed, the Content Publishing agent's Routine reads this file as JSON-extractable state and refuses to promote a draft past the checkbox state recorded here.
- **Weft archetype-extraction routine gate.** When deployed, the Weft routine that derives public archetypes from completed engagements reads this file and refuses to act unless the archetype-derivative checkbox is checked.
- **Operator manual gate.** Until the agent gates are deployed, the operator's manual review is the only enforcement layer. The operator's checklist before publishing anything that touches a real engagement: open this file, verify the box, proceed only if checked.

---

## Revocation

A client may revoke any previously-checked authorization at any time, in writing, to the operator. Revocation is forward-looking — material already published before revocation may continue to exist; material not yet published is blocked from publication going forward.

If the client requests retroactive removal of already-published material, the operator's commitment is to remove the material from Efficient Labs-controlled surfaces (public mono-repo, marketing site, social posts originated by Efficient Labs) within a best-effort window of 7 calendar days. Material that has been mirrored, archived, or republished by third parties is outside Efficient Labs' control; the operator's responsibility ends at Efficient Labs-controlled surfaces.

The revocation request and its handling are logged in the per-engagement file alongside this policy.

---

## Notes / overrides

(Use this section to record any nuance not captured by the checkboxes above. Examples: a 90-day delay before any public mention; archetype permitted but limited to a specific subset of nodes; case-study permitted but anonymized to industry-only; name attribution permitted at the company level but not the individual level.)

---

## Why this template is DRAFT

This template captures the structure described in architecture report Section 7 and the operator's intent for the boundary discipline. It has not been reviewed by counsel. Before this template is used as the basis for a signed agreement, counsel review is required. The operator is responsible for that review and for the version that becomes the actual signed instance.

A future revision of this file (post-legal-review) will:

- Pin the legal-form language (witnessing, governing law, severability, notice provisions).
- Replace the operator's prose with the contractual prose counsel produces.
- Add an "exhibit" structure linking this policy into the MSA / DPA stack referenced in the [legal directory README](README.md).
- Drop the DRAFT marker once the legal-form version is the operative one.
