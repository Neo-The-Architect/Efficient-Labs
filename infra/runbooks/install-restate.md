# Runbook: install Restate

**Status:** DRAFT — pending operator deploy verification.

Restate is the durable executor Weft sits on top of. Single binary, RocksDB-backed, BUSL-1.1 license. Runs as its own systemd service alongside Postgres on the EL VPS.

This runbook is intentionally portable — no VPS-specific identifiers, no real secrets. Another operator should be able to fork this repo and follow this runbook on their own Ubuntu 24.04 host.

## License acceptance

Restate is distributed under the **Business Source License 1.1**. The BUSL-1.1 permits self-hosted internal use, **forbids offering Restate as a hosted service to third parties**, and converts to Apache 2.0 a fixed number of years after each file's commit date (Restate's "Change Date" — currently four years; verify against the LICENSE file in the pinned release).

For Efficient Labs' use case (self-hosted internal durable-execution substrate, not resold to clients) the BUSL-1.1 terms are acceptable per [architecture report Section 9](../../docs/architecture/2026-04-27-fulfillment-architecture-report.md#section-9--open-risks-and-unknowns).

| Field              | Value                                              |
|--------------------|----------------------------------------------------|
| License            | BUSL-1.1                                           |
| Pinned version     | `<RESTATE_VERSION>` (set at deploy)                |
| Operator           | NeoTheArchitect (Efficient Labs)                   |
| Accepted on        | 2026-04-28                                         |
| Reversion to Apache 2.0 | Four years after each file's commit date     |

If you fork this repo to run Restate on your own infrastructure, replace the operator and acceptance-date entries above with your own and confirm BUSL-1.1 fits your use case.

## Purpose

Provide the durable-execution substrate for Weft programs. Restate persists in-flight executions to local RocksDB so Weft programs survive process restart, host reboot, and crash. Per [architecture report Section 5](../../docs/architecture/2026-04-27-fulfillment-architecture-report.md#section-5--multi-component-fallback-architecture):

- When Restate is down, **all Weft durable executions stall**. There is no fallback substitute. The right response is systemd auto-restart plus an operator alert.
- Restate brings its own RocksDB; it has **no Postgres dependency** (per ADR 0002). The Postgres install runbook must be complete before this one only because both compete for memory budget on the same VPS — there is no functional dependency.

Awakeables — the durable suspend mechanism Weft uses for human-in-the-loop pauses ("operator approves proposal," "client submits intake form," "Stripe webhook lands") — are implemented inside Restate. The credibility of every long-pause fulfillment step in the runbook depends on Restate being healthy.

## Prerequisites

- Ubuntu 24.04 LTS host with `sudo` access.
- Hardened baseline already in place (Lynis ≥ 85, Tailscale-only ingress, no public TCP except those exposed deliberately via Tailscale Funnel).
- Postgres install runbook completed and verified (`install-postgres.md`). Restate runs alongside but does not depend on it.
- ≥ 2 GB RAM available beyond Postgres' allocation. With Postgres' `shared_buffers = 512MB` and Restate's `rocksdb-total-memory-size = 1 GiB`, the VPS needs at least 4 GB total to leave headroom for Weft, Paperclip, the OS, and burst load.
- ≥ 20 GB free at `/var/lib/restate/`. RocksDB data grows over time even at low workflow volume.
- At-rest disk encryption (LUKS or equivalent) on the data path — same posture as Postgres.
- The host clock is sane and NTP-synced.
- A pinned Restate release version chosen. Check [github.com/restatedev/restate/releases](https://github.com/restatedev/restate/releases) for the latest stable; **never use `latest`**. Substitute `<RESTATE_VERSION>` throughout this runbook with the chosen tag (e.g. `v1.4.2`).

## Steps

### 1. Download and install the Restate binary

Restate ships single-binary tarballs for Linux x86_64 and aarch64 on GitHub Releases. Download, verify the checksum against the release page, and install to `/usr/local/bin/`.

```bash
RESTATE_VERSION='<RESTATE_VERSION>'           # e.g. v1.4.2 — pin to a real release
ARCH='x86_64-unknown-linux-musl'              # or aarch64-unknown-linux-musl on ARM
TARBALL="restate-server-${ARCH}.tar.xz"

cd /tmp
curl -fsSL -O "https://github.com/restatedev/restate/releases/download/${RESTATE_VERSION}/${TARBALL}"
curl -fsSL -O "https://github.com/restatedev/restate/releases/download/${RESTATE_VERSION}/${TARBALL}.sha256"

# Verify checksum BEFORE extracting. If this fails, do not proceed.
sha256sum -c "${TARBALL}.sha256"

tar -xJf "${TARBALL}"
sudo install -m 0755 -o root -g root restate-server /usr/local/bin/restate-server
/usr/local/bin/restate-server --version       # expect: restate-server <RESTATE_VERSION>
```

The `musl` build is statically linked and avoids glibc-version mismatches across distributions.

### 2. Create the dedicated `restate` Linux user

Restate runs as a system user with no shell and no login surface. The user owns the data directory and the running process; nothing else touches that scope.

```bash
sudo useradd --system --shell /usr/sbin/nologin --no-create-home \
    --home-dir /var/lib/restate restate
```

### 3. Create data, config, and log directories

```bash
sudo install -d -m 0750 -o restate -g restate /var/lib/restate
sudo install -d -m 0750 -o restate -g restate /var/lib/restate/data
sudo install -d -m 0750 -o restate -g restate /var/log/restate
sudo install -d -m 0755 -o root    -g root    /etc/restate
```

Filesystem layout, end state:

| Path                    | Owner            | Mode | Contents                                  |
|-------------------------|------------------|------|-------------------------------------------|
| `/usr/local/bin/restate-server` | `root:root` | 0755 | The binary                            |
| `/etc/restate/restate.toml`     | `root:root` | 0644 | Configuration (no secrets)            |
| `/var/lib/restate/data/`        | `restate:restate` | 0750 | RocksDB column families             |
| `/var/log/restate/`             | `restate:restate` | 0750 | Service logs                        |
| `/etc/systemd/system/restate.service` | `root:root` | 0644 | Service unit                  |

### 4. Materialize `/etc/restate/restate.toml`

Minimal single-node configuration. Bind addresses are loopback-only — Restate is reachable only from processes on the VPS. Operator access to the admin API is via Tailscale Serve (step 7), not a public port.

```toml
# /etc/restate/restate.toml
# Single-node Restate for the EL VPS. See architecture report Sections 2 and 5.

cluster-name = "efficient-labs"
node-name    = "el-restate-1"

# Persistent state — RocksDB column families live here.
[worker.storage-rocksdb]
path = "/var/lib/restate/data"

# Memory budget for ALL RocksDB column families across all components.
# Sized per architecture report Section 9 starting recommendation.
[rocksdb]
total-memory-size = "1 GiB"

# Ingress HTTP — where Weft sends service invocations.
[ingress]
bind-address = "127.0.0.1:8080"

# Admin API — service registration, deployment management, health checks.
[admin]
bind-address = "127.0.0.1:9070"
```

Equivalent environment variables (`RESTATE_<UPPER_SNAKE>` overrides config-file values) exist for every key — the architecture report explicitly references `RESTATE_ROCKSDB_TOTAL_MEMORY_SIZE`. The config file is preferred here so the deployed state is auditable as a single artifact.

Schema drift across Restate versions is a real risk (see `## Concerns`). Validate this config against the pinned binary's schema before starting:

```bash
# The exact subcommand name varies between Restate releases — check
#   restate-server --help
# for the version-correct invocation. Common forms include:
#   restate-server config-schema
#   restate-server schema --output-format=json
# Use whatever your pinned version exposes to confirm the keys above are accepted.
```

If a key in the config file is unknown to the binary, Restate either logs a warning and ignores it (older versions) or refuses to start (newer versions). Either way, you find out at step 6.

### 5. Materialize the systemd unit

Write `/etc/systemd/system/restate.service`:

```ini
[Unit]
Description=Restate durable executor (Weft substrate)
Documentation=https://docs.restate.dev/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=restate
Group=restate
ExecStart=/usr/local/bin/restate-server --config-file /etc/restate/restate.toml

# Logs to journald — accessible via `journalctl -u restate`.
StandardOutput=journal
StandardError=journal

# Restart-on-failure with bounded backoff. The architecture demands restart
# behavior — Restate down means Weft executions stall.
Restart=always
RestartSec=5
StartLimitIntervalSec=60
StartLimitBurst=10

# OnFailure hook fires after the StartLimit window is exhausted. Wire this
# to whatever the operator alert path is (Discord webhook unit, email, etc.).
# OnFailure=restate-failure-alert.service

# Sandboxing: read-only system, write-only into the data and log dirs.
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
ReadWritePaths=/var/lib/restate /var/log/restate
LockPersonality=true

# Environment overrides go here if needed (env file lives outside repo).
# EnvironmentFile=-/etc/restate/restate.env

[Install]
WantedBy=multi-user.target
```

Mirror this unit into `infra/systemd/restate.service.template` so the artifact lives in the repo:

```bash
sudo cp /etc/systemd/system/restate.service \
    /home/<OPERATOR>/workspace/efficient-labs/infra/systemd/restate.service.template
# Then commit the template (no secrets in it).
```

### 6. Enable and start Restate

```bash
sudo systemctl daemon-reload
sudo systemctl enable restate.service
sudo systemctl start restate.service
sudo systemctl status restate.service          # expect: active (running)

# First-boot logs — read these. RocksDB initialization, port binding,
# any deprecated-config warnings all surface here.
sudo journalctl -u restate -n 200 --no-pager
```

If status shows anything other than `active (running)` and the journal does not show `Listening on 127.0.0.1:8080` and `Listening on 127.0.0.1:9070` (or version-equivalent log lines), stop here and resolve before continuing. The most common failures are: config-file schema mismatch (step 4), data directory permissions (step 3), port already in use.

### 7. Tailscale Serve mapping for operator-only admin access

The admin API is loopback-only. Operator access is via Tailscale Serve, **never Tailscale Funnel** — Funnel exposes to the public internet, which is not what we want for the admin surface.

```bash
# Run as the user/scope that owns the Tailscale node.
sudo tailscale serve --bg --https=9070 http://127.0.0.1:9070

# Verify the operator device can reach the admin API over the tailnet.
# From the operator laptop (not the VPS):
#   curl https://<vps-tailscale-name>.tailnet.ts.net:9070/...
# (Substitute the tailnet hostname for your tailnet.)
```

Document the exact Tailscale Serve mapping in your operator's tailnet notes — Tailscale's ACL state is not version-controlled here on purpose.

### 8. Local snapshot backup (skeletal)

Restate has no native WAL-archive equivalent to Postgres. The recovery posture is **filesystem snapshot of the data directory**. This is the local skeleton; off-host shipping (Backblaze B2) is a separate runbook (Tuesday work).

`/usr/local/bin/restate-snapshot.sh`:

```bash
#!/usr/bin/env bash
# Filesystem snapshot of Restate data directory. Stops the service briefly to
# guarantee a consistent on-disk view; alternative is rsync-with-tolerated-races
# or LVM/ZFS snapshot. Trade-off: ~2-5s of suspended Weft executions vs.
# possible RocksDB inconsistency on a hot copy. The pause is the safer default.
set -euo pipefail

SNAP_DIR=/var/backups/restate
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
RETENTION_DAYS=14
SRC=/var/lib/restate/data
DST="${SNAP_DIR}/restate-${TIMESTAMP}.tar.zst"

mkdir -p "${SNAP_DIR}"

systemctl stop restate
trap 'systemctl start restate' EXIT
tar --use-compress-program=zstd -cf "${DST}" -C "$(dirname "${SRC}")" "$(basename "${SRC}")"

find "${SNAP_DIR}" -type f -name 'restate-*.tar.zst' -mtime +${RETENTION_DAYS} -delete
```

Install:

```bash
sudo install -d -m 0750 -o root -g root /var/backups/restate
sudo install -m 0750 -o root -g root /tmp/restate-snapshot.sh /usr/local/bin/restate-snapshot.sh
```

systemd timer at `/etc/systemd/system/restate-snapshot.timer`:

```ini
[Unit]
Description=Restate filesystem snapshot (nightly)

[Timer]
OnCalendar=*-*-* 03:30:00 UTC
Persistent=true
RandomizedDelaySec=15min

[Install]
WantedBy=timers.target
```

And `/etc/systemd/system/restate-snapshot.service`:

```ini
[Unit]
Description=Restate filesystem snapshot oneshot

[Service]
Type=oneshot
ExecStart=/usr/local/bin/restate-snapshot.sh
```

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now restate-snapshot.timer
sudo systemctl list-timers restate-snapshot.timer
```

03:30 UTC is chosen to land 30 minutes after Postgres backup (03:00 UTC) so the IO bursts do not collide. Re-tune if either runs long.

## Verification

```bash
# Service health.
sudo systemctl status restate                  # active (running)
sudo systemctl is-enabled restate              # enabled
ss -tlnp | grep -E '127\.0\.0\.1:8080|127\.0\.0\.1:9070'   # both ports loopback only
ss -tlnp | grep -E ':(8080|9070)' | grep -v 127.0.0.1 \
    && echo "BAD: Restate listening beyond loopback" || echo "OK: loopback only"

# Admin API responds. The exact health-endpoint path varies by Restate version
# — `restate-server --help` and the upstream docs at docs.restate.dev list the
# version-correct path. Common forms: /health, /restate/health, /admin/health.
# Substitute the right path here.
curl -fsS http://127.0.0.1:9070/<HEALTH_PATH>

# Crash-resume test. This is the load-bearing assertion — it proves Restate
# does what its license cost is buying.
sudo systemctl kill --signal=SIGKILL restate
sudo systemctl status restate                  # expect: activating, then active again within ~5s
sudo journalctl -u restate -n 100 --no-pager   # expect: clean RocksDB recovery, no corruption warnings

# Snapshot backup runs cleanly.
sudo systemctl start restate-snapshot.service
ls -lh /var/backups/restate/                   # one *.tar.zst, > 0 bytes
sudo systemctl is-active restate               # service back up after snapshot pause
```

A trivial Weft test program registered against this Restate instance and observed to run to completion is a stronger end-to-end signal — defer until after the Weft+Paperclip runbook lands.

## Rollback

Three flavors, in increasing destructiveness.

### Version downgrade (non-destructive within a major)

If a freshly pinned version misbehaves and the previous version was working:

```bash
sudo systemctl stop restate
# Re-run step 1 with the previous RESTATE_VERSION.
sudo systemctl start restate
```

RocksDB state is forward-compatible within a major and most minor versions. **Cross-major rollbacks may require state migration** — read upstream release notes before any major upgrade, and snapshot before upgrading either direction.

### RocksDB suspected-corruption recovery

```bash
sudo systemctl stop restate
sudo cp -a /var/lib/restate/data /var/lib/restate/data.suspect-$(date -u +%Y%m%dT%H%M%SZ)
# Try Restate's built-in repair if the pinned version exposes one
# (consult `restate-server --help` for the exact subcommand). If no repair
# subcommand exists, restore the most recent snapshot from /var/backups/restate
# into the data directory.
sudo systemctl start restate
```

Clearing the data directory entirely is a last resort — it loses every in-flight Weft execution. Do not do this without a captured snapshot.

### Full uninstall (destructive — wipes Restate state)

Only if Restate has no real data and the install needs to be redone clean.

```bash
sudo systemctl disable --now restate-snapshot.timer restate-snapshot.service
sudo systemctl disable --now restate.service
sudo rm -f /etc/systemd/system/restate.service
sudo rm -f /etc/systemd/system/restate-snapshot.{service,timer}
sudo rm -f /usr/local/bin/restate-server /usr/local/bin/restate-snapshot.sh
sudo rm -rf /var/lib/restate /var/log/restate /etc/restate /var/backups/restate
sudo userdel restate 2>/dev/null || true
sudo systemctl daemon-reload
```

## Secrets

**None for this runbook.** Restate, as deployed here, has no built-in credential surface — no admin API auth, no operator login. The security posture is "the admin API is on localhost, and the only path to it is through the operator's Tailscale device."

This is acceptable because:

- Tailscale tailnet membership is the access boundary. Adding a separate auth layer to a localhost-only service that's already gated by Tailscale would be defense-in-depth that doesn't increase the work-factor of an attacker who has already compromised a tailnet device.
- Weft talks to Restate over loopback inside the same VPS. There is no inter-host RPC to authenticate.

If a future architecture demands non-loopback access (e.g. a second Restate node for HA), revisit this — at that point the admin API needs auth and the inter-node port needs mTLS. Open question; not week-1 scope.

## Concerns / Open questions

- **Config schema drift across Restate versions.** Restate is young and active (current major: 1.x as of April 2026). Specific config keys (`worker.storage-rocksdb.path`, `rocksdb.total-memory-size`, `[admin]` and `[ingress]` section names, the `cluster-name`/`node-name` top-level keys) are written from the most-likely-correct schema for late-1.x. The deploy step should validate this config against the pinned binary's actual schema before first start. If keys have moved, edit the runbook and the systemd unit and commit the corrections.
- **Healthcheck endpoint path.** Marked `<HEALTH_PATH>` in the verification block because the exact path has shifted between 1.0 and 1.x. The pinned version's `--help` and upstream docs at [docs.restate.dev](https://docs.restate.dev/) are authoritative; `journalctl -u restate` after first start typically logs the bound paths.
- **Snapshot pause vs. hot copy.** `restate-snapshot.sh` stops the service for ~2–5 seconds to guarantee a consistent on-disk view. This briefly suspends Weft executions. Alternative: an LVM or ZFS snapshot avoids the pause but requires the data directory to live on a snapshot-capable filesystem, which the current root-disk install does not provide. If the pause becomes operationally costly, migrate to a dedicated snapshot-capable mount and document.
- **No off-host backup yet.** Local snapshots survive Restate failures and OS-level mistakes. They do not survive disk loss or VPS loss. The Backblaze B2 shipping runbook is the next item; do not consider Restate "backed up" until that pipeline is also test-restored end to end (verify a snapshot can be re-extracted onto a fresh data directory and Restate boots clean).
- **Memory budget interaction with Postgres.** `shared_buffers = 512MB` (Postgres) plus `total-memory-size = 1 GiB` (Restate's RocksDB) plus the JVM-equivalents of Weft and Paperclip plus OS reservation needs ≥ 4 GB total RAM to leave any headroom. The 2 GB minimum stated in the Postgres runbook is the floor for *that runbook alone*; the full stack needs more. Re-confirm VPS RAM before launching all four runtimes simultaneously.
- **BUSL Change Date is per-file, not per-release.** Each source file has its own commit date, so portions of the codebase convert to Apache 2.0 at different times. Verify against the LICENSE file in the pinned release tarball; do not assume "the whole binary" reverts on one date.
- **No built-in admin auth.** Documented above under `## Secrets`. Acceptable now; revisit if Restate ever needs non-loopback access.

## References

- [Restate documentation](https://docs.restate.dev/) — operations, configuration, version-specific schema.
- [restatedev/restate releases](https://github.com/restatedev/restate/releases) — pinned-version source, checksums, release notes.
- [Restate license (BUSL-1.1) — github.com/restatedev/restate/blob/main/LICENSE](https://github.com/restatedev/restate/blob/main/LICENSE) — authoritative license text and Change Date for the current release.
- [Architecture report Section 5](../../docs/architecture/2026-04-27-fulfillment-architecture-report.md#section-5--multi-component-fallback-architecture) — Restate as single-point-of-failure, pause-and-retry posture.
- [Architecture report Section 9](../../docs/architecture/2026-04-27-fulfillment-architecture-report.md#section-9--open-risks-and-unknowns) — BUSL-1.1 acceptance rationale, memory sizing, Restate dependency footprint.
- [ADR 0002](../../docs/adr/0002-postgres-single-instance-shared-process.md) — Restate has its own RocksDB and is independent of Postgres.
- [`install-postgres.md`](install-postgres.md) — sibling runbook; complete and verify before this one for memory-budget reasons.
