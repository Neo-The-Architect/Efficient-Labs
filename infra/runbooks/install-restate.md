# Runbook: install Restate

Restate is the durable executor Weft sits on top of. Single binary, RocksDB-backed, BUSL-1.1 license. Runs as its own systemd service alongside Postgres.

## Purpose

Provide the durable-execution substrate for Weft programs. Restate persists in-flight executions to local RocksDB so Weft programs survive process restart and crash. Per architecture report Section 5, restart resumes — there is no fallback substitute when Restate is down; Weft is paused until Restate comes back.

## Prerequisites

- TODO: choose Restate release (single binary, pinned version — not `latest`).
- TODO: BUSL-1.1 license terms reviewed and explicitly accepted by the operator. For self-hosted internal use the terms are acceptable (see architecture report Section 9). Note the Apache 2.0 conversion date for the chosen release.
- TODO: data disk path confirmed; RocksDB lives on the same encrypted disk as Postgres data.
- TODO: `RESTATE_ROCKSDB_TOTAL_MEMORY_SIZE` sized for the VPS — start at 1 GB per architecture report Section 9.
- TODO: admin port chosen and bound to `127.0.0.1` only.
- TODO: `infra/systemd/restate.service.template` reviewed.
- TODO: Tailscale Serve mapping decided for operator access to the admin UI (operator-only, never Funnel).

## Steps

TODO. Sketch:

1. Download the pinned Restate binary, verify checksum, install to `/usr/local/bin/restate-server`.
2. Create dedicated `restate` Linux user (no shell, no home directory beyond the data path).
3. Create the data directory on the encrypted disk, owned by `restate`.
4. Materialize `restate.toml` from the template — set `bind-address` to `127.0.0.1`, `data-dir`, `rocksdb-total-memory-size`.
5. Materialize the systemd unit from `infra/systemd/restate.service.template`. `OnFailure` action goes to the operator alert path.
6. Enable and start the service.
7. Set up Tailscale Serve mapping for operator-only admin port (no Funnel).

## Verification

TODO:

- `systemctl status restate` shows active and not flapping.
- Healthcheck endpoint on the admin port returns 200 from `127.0.0.1`.
- The healthcheck is reachable through Tailscale Serve from the operator device.
- The healthcheck is *not* reachable from the public internet.
- A trivial Weft test program registers and runs to completion against this Restate instance.
- Kill `restate-server`; confirm systemd auto-restart triggers; confirm in-flight test execution resumes from where it stopped.

## Rollback

TODO:

- If the Restate version regresses, stop the service and downgrade the binary. RocksDB state is forward-compatible within minor versions; cross-major rollback may require state migration — read release notes before any major upgrade.
- If RocksDB corruption is suspected, stop Restate, take a filesystem snapshot of the data directory, attempt a Restate-built-in repair, and only fall back to clearing state as a last resort — clearing state loses all in-flight Weft executions.
- Backup posture for Restate state is filesystem snapshot + off-host copy of the RocksDB directory. WAL-style archive is not native to Restate; the snapshot cadence has to match the operator's tolerance for losing in-flight execution state. TODO: define cadence.
