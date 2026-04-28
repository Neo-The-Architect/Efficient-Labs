# Security documentation

This directory holds the internal security-posture documents for Efficient Labs — the design-side companions to the public-facing artifacts at the repo root.

## Index

| Document | Status | Purpose |
| --- | --- | --- |
| [`threat-model.md`](threat-model.md) | Stub | STRIDE-based threat model for the Efficient Labs fulfillment surface. Will be filled when Layer 7 substantive work lands; pre-legal-review. |

## Pointers to related security artifacts

The security posture is distributed across several surfaces. This index names where each piece lives.

- [`SECURITY.md`](../../SECURITY.md) at the repo root — the **public vulnerability disclosure policy**. The two private channels (GitHub Security Advisories and TBD email) are documented there. Read first for any disclosure question.
- [`legal/security-policy.md`](../../legal/security-policy.md) — **DRAFT public-facing security posture statement**. The controls Efficient Labs commits to. Pairs with the disclosure policy above; pre-legal-review.
- [`legal/data-handling.md`](../../legal/data-handling.md) — **DRAFT data flow inventory and handling policy**. What is collected, where it lives, retention, deletion. Source material for the eventual DPA.
- [`legal/incident-disclosure.md`](../../legal/incident-disclosure.md) — **DRAFT client-disclosure side of incident response**. Pairs with [`docs/processes/incident-response.md`](../processes/incident-response.md) (the operational side).
- [`legal/audit-log-retention.md`](../../legal/audit-log-retention.md) — **DRAFT audit log policy**. What is logged, retention windows, access conditions.
- The [architecture report](../architecture/2026-04-27-fulfillment-architecture-report.md) — security-relevant sections include Section 6 (host hardening) and Section 7 (sub-processor and data-flow boundaries).
- [ADR 0005](../adr/0005-tailscale-ssh-as-primary-access-path.md) — the **host-access posture** (Tailscale SSH primary, OpenSSH masked). The single most consequential security decision currently in force.

## What lives here vs. elsewhere

This directory is for **design-side** security documents — threat models, architectural risk analysis, security-relevant design decisions that are not yet weighty enough for an ADR. The **disclosure policy** is at the repo root (`SECURITY.md`) for discoverability. The **public-facing posture statement and policies** live in `legal/` because they are the surface a prospective client reads.

## When to add a document here

A new document is appropriate when an internal security concern is substantial enough to deserve its own artifact and is not better captured by an ADR or a process document. The threat model is the canonical example; future candidates include service-specific security notes (Restate sandboxing, Paperclip skill isolation) when the corresponding services land.
