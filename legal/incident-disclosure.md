# Incident disclosure policy

**Status: DRAFT — pre-legal-review.** This document will be filled when Layer 7 substantive work lands. Until counsel review, no claim below should be treated as an authoritative commitment for the purposes of a signed agreement.

This document is the **client-disclosure side** of incident response. It pairs with [`docs/processes/incident-response.md`](../docs/processes/incident-response.md), which is the operational side — what the operator does during an incident. This document is what gets communicated outward, on what timeline, and with what content.

## Coverage

When filled, this document will cover at minimum:

- **Detection-to-disclosure timeline.** The commitment from incident detection to first client notification. The current working target is consistent with **GDPR Article 33's 72-hour breach notification window** for incidents that meet the breach threshold. For non-breach incidents that nonetheless affect a client, the commitment is "without undue delay" — operationalized as a target the operator will write here once the supporting alerting infrastructure exists.
- **What gets disclosed.** Specifically:
  - **Timeline** of the incident — when it started, when it was detected, when it was contained.
  - **Impact** on the client — what data, what systems, what duration.
  - **Remediation** taken and the operator's confidence that the root cause is addressed.
  - **Forward-looking commitments** — what changes (process, infrastructure, monitoring) the operator is making to reduce the chance of recurrence.
- **What does not get disclosed.** Operational details that compound risk — for example, the exact sequence of commands an attacker used, or specifics that would materially aid a copycat. The operator's [postmortem template](../docs/processes/postmortem-template.md) is the place where the full operational detail lives; the client-facing disclosure is a derivative product.
- **Channel.** Email is the default disclosure channel for incidents; a parallel posting may go on the public status page (when one exists) for incidents with broad public-system impact. The MSA will name the client's preferred contact for incident communications.
- **Coordination with other parties.** Sub-processors involved in the incident (per [`vendor-list.md`](vendor-list.md)) and the operator's coordination with their incident-response teams, when applicable.

## Why this is a DRAFT stub

Disclosure commitments are contractual the moment a paying client relies on them. The discipline is the same as the rest of `legal/`: structure now, substance when counsel has reviewed and the operational reality (alerting, containment, communication channels) is in place to back the commitment.

## Triggers for filling this stub

- The first paying client signs an MSA that names disclosure obligations — at which point this document is the operative reference.
- A real incident occurs, and the postmortem produces concrete data about what disclosure shape was actually appropriate. Even a near-miss postmortem is informative for this document.
- Counsel review of the contractual templates begins, since the MSA references this document.
