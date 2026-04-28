# Security policy

**Status: DRAFT — pre-legal-review.** This document will be filled when Layer 7 substantive work lands. Until counsel review, no claim below should be treated as an authoritative commitment for the purposes of a signed agreement.

This document is the **public-facing security posture statement** — the controls Efficient Labs commits to operating, expressed in language that a prospective client's security questionnaire can match against. The internal threat model lives at [`docs/security/threat-model.md`](../docs/security/threat-model.md). Vulnerability disclosure procedure lives at [`SECURITY.md`](../SECURITY.md) at the repo root.

## Coverage

When filled, this document will cover at minimum:

- **Encryption at rest and in transit.** What is encrypted, with what algorithms, where keys are held, who can rotate them. The current default at this stage is "Tailscale-mediated transport in transit; disk-level encryption on the EL VPS at rest" — both pending deploy verification.
- **Access control.** Who can access production systems, what authentication factors are required, how access is granted and revoked. The current posture is named in [ADR 0005](../docs/adr/0005-tailscale-ssh-as-primary-access-path.md): Tailscale identity is the primary access path, OpenSSH is masked, two-factor identity is required at the Tailscale layer.
- **Sub-processor security expectations.** What Efficient Labs requires of sub-processors and how those requirements are verified. Sources from [`vendor-list.md`](vendor-list.md).
- **Incident response commitments.** Detection-to-response, response-to-mitigation, and mitigation-to-disclosure timelines. The disclosure side lives at [`incident-disclosure.md`](incident-disclosure.md); the operational side is at [`docs/processes/incident-response.md`](../docs/processes/incident-response.md).
- **Audit log retention.** What is logged, retention windows, integrity guarantees. The full policy lives at [`audit-log-retention.md`](audit-log-retention.md); this document references it.
- **Compliance posture.** SOC 2 readiness roadmap (Type I as the realistic first target; Type II later), GDPR processor obligations, any sector-specific frameworks that apply per engagement.

## Why this is a DRAFT stub

Security policy statements are contractual instruments in effect once a paying client relies on them. Publishing fictional commitments would be worse than publishing none. The DRAFT structure is published so that prospective clients can see the topics that are being thought about, while the substance lands once (a) the corresponding controls are actually operating and (b) counsel has reviewed.

## Triggers for filling this stub

- The first production service deploys to the EL VPS and the actual encryption, access, and logging postures are observable rather than designed.
- Counsel review begins on the contractual templates (MSA, DPA, public-build playbook) — this document is one of the policy artifacts those templates reference.
- A prospective client requests this document as part of vendor security review.
