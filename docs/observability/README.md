# Observability documentation

This directory holds the observability conventions and reference material for the Efficient Labs production fulfillment surface — what gets measured, how it is measured, and how the operator (and eventually clients) read the signals.

## Index

| Document | Status | Purpose |
| --- | --- | --- |
| [`healthcheck-conventions.md`](healthcheck-conventions.md) | Stub | URL pattern, response shape, and latency targets for service healthcheck endpoints. Lists the four services that will need healthchecks (Postgres, Restate, Weft, Paperclip). |

## Pointers to related observability material

- The [architecture report](../architecture/2026-04-27-fulfillment-architecture-report.md), particularly the operability sections, describes the working theory of how the system is observed: log-forward to journald, healthchecks per service, periodic Lynis runs for posture, Tailscale admin console for access. The substantive observability documents in this directory inherit that working theory.
- [`docs/processes/incident-response.md`](../processes/incident-response.md) names the triage commands (`journalctl`, `dmesg`, vendor status pages) that are the operator's working observability surface today. As the surface grows, more of those commands move into purpose-built dashboards or alerts; the runbooks reference both.
- [ADR 0002](../adr/0002-postgres-single-instance-shared-process.md) is observability-relevant because the single-instance Postgres choice means one set of database-level metrics serves both `paperclip` and `weft` databases.

## What lives here vs. elsewhere

This directory is for **observability conventions and reference material** — how healthchecks are shaped, what an SLO looks like when one is defined, how dashboards are organized when they exist. **Per-service runbooks** that include observability steps live in `infra/runbooks/`. **Incident-response procedures** live in `docs/processes/`. **Audit-log policy** (which is observability-adjacent but legally inflected) lives in `legal/audit-log-retention.md`.

## What is not yet here

The following documents will land as the corresponding services deploy:

- **SLO definitions.** Service-level objectives only become real once a service is in production with measurable behavior. The first SLO will likely be Postgres availability on the EL VPS.
- **Dashboard inventory.** The dashboards that exist, what each is for, and where to find them. There are no dashboards today; there is the operator running `journalctl` by hand.
- **Alert routing.** Which alerts fire to where, and the on-call ladder. Today the operator is the only responder; a formal alert-routing document is a Phase D-or-later artifact.

The observability surface grows when services deploy. The stub structure exists so the documents have a home.
