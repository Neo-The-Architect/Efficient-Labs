# Audit log retention policy

**Status: DRAFT — pre-legal-review.** This document will be filled when Layer 7 substantive work lands. Until counsel review, no claim below should be treated as an authoritative commitment for the purposes of a signed agreement.

This document is the **audit log policy** — what events are recorded as audit-grade evidence, how long the records are retained, who can request them, and the integrity guarantees on the records themselves. Pairs with [`data-handling.md`](data-handling.md) (which covers data flows generally) and [`docs/observability/`](../docs/observability/) (which covers observability logging more broadly).

## Coverage

When filled, this document will cover at minimum:

- **Event classes that get logged.** The working list, subject to revision when the production surface is observable:
  - **Access events** — authentication attempts (Tailscale, where applicable), SSH session starts, sudo invocations on the EL VPS.
  - **Configuration changes** — file changes under version control are captured by git; configuration changes outside version control (e.g. host-level edits performed under a runbook) are recorded here.
  - **Data-access events** — reads and writes to client data classes, where instrumentation exists. Sources from [`data-handling.md`](data-handling.md) for the data classes.
  - **Privilege-elevation events** — sudo, role grants in Postgres, any change to Tailscale ACLs.
  - **Incident-related actions** — actions taken during an incident response, captured in the incident log (whose location is named in [`docs/processes/incident-response.md`](../docs/processes/incident-response.md)).
- **Retention windows by event class.** The default working target is one year for access and configuration events, longer where regulatory frameworks require it. Per-engagement retention may extend beyond the default; the MSA will name client-specific retention requirements where applicable.
- **Who can request audit logs.** The operator (always); clients (subject to the conditions in their MSA, typically scoped to events that involve their own data); regulators (subject to legal compulsion). Each request is itself an audit event.
- **Conditions for client-facing audit-log access.** Which subset of audit logs is exposable to a client without compounding risk to other clients or to operational integrity. The default is "events where the client's own data is the subject"; the operator-side events (sudo, privilege elevation) are not exposed unless contractually required.
- **Log integrity.** The working target is **append-only** storage with **signed records** — once written, an audit-log entry cannot be silently modified or deleted. The implementation choice (append-only file with chained hashes, an external service like Vector + S3 with object lock, or a managed solution) is open and lands when the supporting infrastructure is decided.

## Why this is a DRAFT stub

Audit logs are evidence. Publishing a policy that the system cannot back up is worse than publishing a stub. The structure is here so that the supporting infrastructure can be built against the named commitments; the substance lands when both the infrastructure and counsel review are in place.

## Triggers for filling this stub

- The first audit-log producer (likely Postgres, then Restate) deploys with logging configured.
- A prospective client requests this document as part of vendor security or audit review.
- Counsel review begins on the contractual templates that reference this document.
