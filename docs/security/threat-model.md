# Threat model

**Status: STUB — pre-legal-review.** This document will be filled when Layer 7 substantive work lands. It is published as a stub because the structure is load-bearing for the security-doc directory and because a prospective client reading the security index should see what is planned, not just what is missing.

## Approach

The threat model will be **STRIDE-based** (Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege), applied to the Efficient Labs production fulfillment surface as it exists at the time of authoring. STRIDE is the chosen framework because it is well-understood, it produces a finite enumeration, and it maps cleanly onto the architectural boundaries already named in the [architecture report](../architecture/2026-04-27-fulfillment-architecture-report.md) and the [ADRs](../adr/README.md).

## Coverage

When filled, this document will cover at minimum:

- **Client data flows.** What client data enters Efficient Labs systems, where it transits, where it rests, who can read it, and the integrity guarantees on each segment of the path.
- **Agent autonomy boundaries.** Which agents (Claude in the sandbox, n8n CTO, Paperclip skill executions, Weft program runs) can take which actions, where the human-in-the-loop checkpoints sit, and what an agent escaping its intended scope would look like.
- **Sandbox escape risks.** The Hostinger VPS isolation model, the n8n execution boundary, the Restate worker boundary, and the failure modes if any of those are breached.
- **Sub-processor trust boundaries.** What each vendor sees, what each vendor could do with what it sees, and the operator's mitigations against each. Sources from [`legal/vendor-list.md`](../../legal/vendor-list.md) and architecture report Section 7.
- **Supply-chain risks.** npm, apt, GitHub Actions (when Layer 3 lands), Claude Skill imports, Restate version pinning. The supply-chain surface grows substantially when CI lands; the threat model grows with it.
- **Incident detection capabilities.** What the operator can see (logs, alerts, Lynis scores), what the operator cannot see (silent failures, slow data exfiltration), and the gaps that need to close before the first paying client.

## Why this is a stub

A threat model written before the system is built is fiction, and a threat model written without legal review is preliminary. Both constraints apply today. The right time to write the substantive version is when (a) at least one production service is deployed and observable, and (b) counsel has reviewed the surrounding policy documents in `legal/`. Until then, the stub names the structure and the coverage so the gap is visible.

## Triggers for filling this stub

- The first production service (Postgres, Restate, Weft, or Paperclip) deploys to the EL VPS and accepts non-test traffic.
- A prospective client requests the threat model as part of a vendor security questionnaire.
- A serious security event reveals a class of risk this stub did not anticipate. The postmortem of that event is the source material for the substantive revision.
