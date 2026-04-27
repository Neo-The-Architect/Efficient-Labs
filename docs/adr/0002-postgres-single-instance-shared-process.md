# ADR 0002 — Postgres: single instance, shared process, role-separated databases

- **Status:** Accepted
- **Date:** 2026-04-27
- **Captures:** Section 2 of `docs/architecture/2026-04-27-fulfillment-architecture-report.md`
- **Supersedes:** —

## Context

Two systems on the VPS need a relational store: Weft (metadata about programs, executions, secret types) and Paperclip (companies, agents, issues, approvals, costs, secrets). Paperclip ships with an embedded-postgres driver that listens on `127.0.0.1:54329` by default and bakes its own credentials. Weft has no embedded driver and expects an external Postgres URL.

Three plausible postures: (a) let Paperclip keep its embedded Postgres on 54329 and stand up a separate external Postgres for Weft, (b) point both at the same external Postgres process with database-level isolation, (c) point both at the same external Postgres with schema-level isolation inside one database.

Paperclip's schema is owned by 38+ Drizzle migrations that change with every calver release. Sharing schema-level state between Paperclip and Weft inside one database (option c) couples Weft's reliability to Paperclip's migration cadence. Running two Postgres processes (option a) means two backup targets, two tuning surfaces, two failure modes, and the embedded-postgres driver's credentials baked into Paperclip. Paperclip officially supports `DATABASE_URL` override via Docker environment, which makes option b operationally trivial.

Restate, the durable executor Weft sits on top of, brings its own RocksDB and does not need Postgres. It is not in scope for this decision.

## Decision

**One external PostgreSQL process on the VPS, two databases, two roles.**

- One Postgres cluster, systemd-managed, version pinned in the install runbook.
- Database `paperclip` owned by role `paperclip`.
- Database `weft` owned by role `weft`.
- Each role has full ownership of its own database and zero privilege on the other.
- Paperclip is configured via `DATABASE_URL=postgres://paperclip:...@127.0.0.1:5432/paperclip` so it does not start its embedded driver.
- Weft connects to `postgres://weft:...@127.0.0.1:5432/weft` via its standard config.
- Connections bind to `127.0.0.1` only — Postgres is not on the tailnet and not on the public internet.
- Single backup target: nightly `pg_dump` of both databases, plus WAL archiving for the cluster, both shipped off-host (Backblaze B2 per architecture report Section 5).

Restate keeps its own RocksDB on the data disk, separate from Postgres. No change to that.

## Consequences

**Positive.** One backup tooling surface. One tuning surface. One process to monitor for OOM, replication lag, disk pressure. Database-level isolation prevents Paperclip migrations from touching Weft schema. Paperclip's embedded-postgres driver is eliminated entirely, removing one set of baked credentials and one undocumented startup path.

**Negative.** Database-level isolation is weaker than separate-process isolation: a Postgres-level outage takes both systems down simultaneously. Per architecture report Section 5 the right response is pause-and-retry plus operator alert (Restate persists in-flight Weft executions, Paperclip retries on its side). RTO is 4h via restore from off-host backup. This is acceptable for the current single-VPS posture; it would not be acceptable for a multi-region production deployment, which is not on the near-term roadmap.

**Kill switch.** If a Paperclip calver release ships a migration that violates this isolation (e.g., assumes ownership of the cluster, attempts cross-database joins), pin Paperclip to the previous SHA and open an upstream issue. As a last resort, fall back to option (a) — separate Postgres processes — which Paperclip natively supports because it can re-enable its embedded driver. This is operationally noisier but reversible.

## Concerns / Open questions

- **Postgres version pin.** Choose a version supported by both Paperclip's embedded-postgres bundling and any Restate-related tooling. Document in the install runbook (`infra/runbooks/install-postgres.md`).
- **Connection pooling.** Paperclip and Weft will each manage their own pool. PgBouncer is unnecessary at the expected fulfillment volume; revisit if the lead intake graph crosses 10 leads/minute sustained.
- **`pg_dump` format.** Use `--format=custom` per database for individual restore. Verify restore once before claiming the backup works.
- **Encryption at rest.** The host disk encryption (LUKS or equivalent) is responsible for at-rest. Postgres does not need column-level encryption for this workload — credentials live in Paperclip's encrypted `secrets` table, not in shared columns.
