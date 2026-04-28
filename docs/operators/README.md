# Operator documentation

This directory holds documents written for the operator's own benefit — references, checklists, onboarding material — distinct from runbooks (which describe what to do on a host) and processes (which describe how the team operates). Operator documents are durable companions to a working session: opened to remember, not to learn for the first time.

## Index

| Document | Purpose |
| --- | --- |
| [Command reference](command-reference.md) | Cold-start command reference. The first document opened when returning after a break. Covers VPS access, sandbox launch, two-user discipline, common operations, emergency recovery, auth inventory, key URLs. **Living document, draft v1 from workspace context** — will be augmented from the operator's external canonical reference in a follow-up commit. |
| [Onboarding](onboarding.md) | Onboarding document for a future operator (or future-Neo after a long break). **Stub.** Substance lands when the first second-operator joins or when the operator returns from a break long enough to test the document against their own memory. |

## What lives here vs. elsewhere

- **Command reference:** here. The day-to-day "remind me how to do X" surface.
- **Runbooks:** in [`infra/runbooks/`](../../infra/runbooks/). Runbooks change live host state and follow the [runbook execution protocol](../processes/runbook-execution-protocol.md).
- **Processes:** in [`docs/processes/`](../processes/). Processes describe how the team operates (review cycle, incident response, runbook authoring discipline).
- **ADRs:** in [`docs/adr/`](../adr/). Decisions that constrain subsequent work.
- **Architecture report:** in [`docs/architecture/`](../architecture/). The canonical design document.
- **Vendor escalation contacts:** not yet on disk; tracked as a gap in [`docs/processes/incident-response.md`](../processes/incident-response.md) under "open questions."

## How to add an operator document

A new document is appropriate when the operator finds themselves repeatedly looking up the same thing across sessions, or when an external piece of context (a vendor's quirks, a host's history, a workflow's sequence) would save the operator's future time if recorded once. Stub-then-fill is acceptable: open with structure, fill substance as the operator hits the situations that produce the substance.

When a document outgrows this directory's "operator's-own-reference" framing — for example, when it becomes useful to clients or to contributors — it migrates to the appropriate sibling directory (`clients/`, `contributors/`, `security/`).
