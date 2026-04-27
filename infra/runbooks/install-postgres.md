# Runbook: install Postgres

Single PostgreSQL instance on the EL VPS, two databases (`paperclip` and `weft`), two roles, systemd-managed. Implements the decision in [ADR 0002](../../docs/adr/0002-postgres-single-instance-shared-process.md).

## Purpose

Provision the shared relational store for Weft metadata and Paperclip state, with database-level isolation and a single backup target. Bind to `127.0.0.1` only — Postgres is not on the tailnet and not on the public internet.

## Prerequisites

- TODO: confirm Ubuntu 24.04 base, snap-free or apt-only posture.
- TODO: data disk path and mount confirmed (separate from root disk for IO isolation and easier backup snapshots).
- TODO: Postgres major version pinned (decision pending; document choice and rationale here).
- TODO: `infra/systemd/postgres.service.template` reviewed.
- TODO: Backblaze B2 bucket and access key provisioned for off-host backup.
- TODO: LUKS or equivalent at-rest encryption confirmed on the data disk.

## Steps

TODO. Sketch:

1. Install Postgres from the official apt repository (not the distro version, for upgrade flexibility).
2. Stop the service before any configuration change.
3. Move the data directory to the encrypted data disk.
4. Configure `postgresql.conf` for the workload — TODO confirm `shared_buffers`, `work_mem`, `effective_cache_size` for the VPS RAM.
5. Configure `pg_hba.conf` for `127.0.0.1`-only connections, scram-sha-256 auth.
6. Enable WAL archiving to off-host (Backblaze B2 via `wal-g` or `pgbackrest` — TODO pick one, pgbackrest preferred for parallel restore).
7. Create role `paperclip` with login, no superuser; create database `paperclip` owned by `paperclip`.
8. Create role `weft` with login, no superuser; create database `weft` owned by `weft`.
9. Verify each role cannot connect to the other database.
10. Install nightly `pg_dump --format=custom` cron for both databases, shipping to the off-host bucket.
11. Materialize the systemd unit from `infra/systemd/postgres.service.template`. Enable and start.

## Verification

TODO:

- `psql` as `paperclip` against `paperclip` succeeds; against `weft` fails.
- `psql` as `weft` against `weft` succeeds; against `paperclip` fails.
- `nc -z 127.0.0.1 5432` succeeds; `nc -z <tailnet-ip> 5432` fails.
- WAL archive shows recent segments in B2.
- A test restore from the latest `pg_dump` succeeds against a throwaway database. Run this *before* claiming the backup works. Verify before trust.

## Rollback

TODO:

- If the cluster fails to start after a config change, revert `postgresql.conf` from the previous-config snapshot.
- If a migration corrupts state, restore from the latest `pg_dump` to a parallel cluster on a non-default port, validate, then promote.
- If the encryption layer fails, the cluster is unrecoverable from disk — the off-host B2 backup is the only recovery path. RTO 4h per ADR 0002.
