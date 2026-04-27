# Runbook: install Postgres

**Status:** DRAFT — pending operator deploy verification.

Single PostgreSQL 16 instance on the EL VPS, two databases (`paperclip` and `weft`), two roles, systemd-managed. Implements the decision in [ADR 0002](../../docs/adr/0002-postgres-single-instance-shared-process.md).

This runbook is intentionally portable — no VPS-specific identifiers, no real passwords. Another operator should be able to fork this repo and follow this runbook on their own Ubuntu 24.04 host.

## Purpose

Provision the shared relational store for Weft metadata and Paperclip application state, with **database-level isolation** between the two systems and a **single backup target**. Postgres binds to localhost only — it is reachable only from processes on the VPS itself, never from the tailnet, never from the public internet.

Two key decisions inherited from [ADR 0002](../../docs/adr/0002-postgres-single-instance-shared-process.md):

- Paperclip is configured via `DATABASE_URL` to use this external Postgres, which **eliminates Paperclip's embedded-postgres driver** on port 54329 entirely.
- Weft uses the `weft` database for its own metadata. Restate (the durable executor Weft sits on top of) brings its own RocksDB and is **not** a Postgres dependency.

## Prerequisites

- Ubuntu 24.04 LTS host with `sudo` access.
- Hardened baseline already in place (Lynis ≥ 85, Tailscale-only ingress, no public TCP except those exposed deliberately via Tailscale Funnel).
- ≥ 2 GB RAM available; ≥ 20 GB free at `/var/lib/postgresql/`.
- At-rest disk encryption (LUKS or equivalent) on the data path. Postgres does not encrypt data files itself; full-disk encryption is the layer responsible.
- The host clock is sane and NTP-synced. Backup timestamps and WAL ordering both depend on this.

If any of the above is not yet true, fix it before proceeding — none of these are things this runbook installs.

## Steps

### 1. Add the official PGDG apt repository and install Postgres 16

The distribution-shipped Postgres lags the upstream release train by ~12 months. The official PostgreSQL Global Development Group (PGDG) repository ships current minor versions for every supported major. Pin to **PostgreSQL 16** — the current production-supported major as of April 2026, EOL November 2028 ([postgresql.org versioning policy](https://www.postgresql.org/support/versioning/)).

```bash
sudo apt install -y curl ca-certificates gnupg lsb-release
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] \
    https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
    | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt install -y postgresql-16 postgresql-client-16 postgresql-contrib-16
```

Reference: [Linux downloads (Ubuntu) — postgresql.org](https://www.postgresql.org/download/linux/ubuntu/).

### 2. Verify the install and the default cluster

```bash
psql --version                           # expect: psql (PostgreSQL) 16.x
sudo systemctl status postgresql          # expect: active (exited) — wrapper unit
sudo systemctl status postgresql@16-main  # expect: active (running) — actual cluster
sudo -u postgres psql -c 'SELECT version();'
```

`postgresql.service` is a wrapper that starts all clusters; `postgresql@16-main.service` is the per-cluster unit. Both are managed by the package and need no template work from `infra/systemd/`.

### 3. Back up the default config files before editing

Editing in place without a backup is the single most common way to brick a cluster. Snapshot first.

```bash
sudo cp /etc/postgresql/16/main/postgresql.conf /etc/postgresql/16/main/postgresql.conf.orig
sudo cp /etc/postgresql/16/main/pg_hba.conf     /etc/postgresql/16/main/pg_hba.conf.orig
```

If a later step breaks the cluster, `cp <file>.orig <file>` and `systemctl restart postgresql@16-main` is the recovery path.

### 4. Edit `postgresql.conf`

Open `/etc/postgresql/16/main/postgresql.conf` and set the following. Lines marked with `# TUNE` are starting points sized for a 2 GB-RAM VPS with no other heavy memory pressure; revisit after the system is under real load.

```ini
# --- Connections and binding ---
listen_addresses = 'localhost'        # binds to 127.0.0.1 and ::1 only — never on the tailnet, never public
port = 5432
max_connections = 200                 # Weft + Paperclip + headroom for pg_dump and ad-hoc psql

# --- Memory (TUNE for 2 GB RAM VPS) ---
shared_buffers = 512MB                # ~25% of RAM, the canonical starting point
work_mem = 16MB                       # per-sort/hash; 200 conns × 16MB worst case = 3.2 GB — keep an eye on it
maintenance_work_mem = 128MB          # used by VACUUM, CREATE INDEX, ALTER TABLE ADD FK
effective_cache_size = 1GB            # planner hint: how much filesystem cache the OS gives Postgres

# --- Write-ahead log and archiving ---
wal_level = replica                   # required for archiving and physical replication; default in PG16
archive_mode = on                     # enabled now so the future archive_command swap is reload-only, not a restart
archive_command = '/bin/true'         # placeholder no-op until WAL archiving to Backblaze B2 lands (Tuesday)
                                      # /bin/true is the canonical placeholder per Postgres docs

# --- Logging ---
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'                 # relative to data dir: /var/lib/postgresql/16/main/log/
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_line_prefix = '%m [%p] %q%u@%d '  # timestamp, pid, optional user@db — useful in audit
log_min_duration_statement = 1000     # log any statement >= 1s for tuning
```

`/bin/true` as a placeholder `archive_command` is explicitly noted as legitimate in the [Postgres continuous archiving docs](https://www.postgresql.org/docs/16/continuous-archiving.html) — it tells Postgres "archiving succeeded" without writing anything. WAL files cycle as if archiving were happening; once the real archive script lands Tuesday, change the command and `pg_reload_conf()` (no restart). See `## Concerns` below for the implication.

### 5. Edit `pg_hba.conf`

Replace the contents of `/etc/postgresql/16/main/pg_hba.conf` with the following. **Order matters** — Postgres matches the first applicable line.

```text
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local Unix-socket connections only — never accept TCP from anywhere
# beyond what's already restricted by listen_addresses = 'localhost'.

local   all             postgres                                peer
local   paperclip       paperclip                               peer
local   weft            weft                                    peer

# Loopback TCP for clients that can't use Unix sockets (notably anything
# running inside a container that doesn't share the host's UID namespace —
# see ## Concerns about Paperclip-in-Docker). Password auth required.
host    paperclip       paperclip       127.0.0.1/32            scram-sha-256
host    paperclip       paperclip       ::1/128                 scram-sha-256
host    weft            weft            127.0.0.1/32            scram-sha-256
host    weft            weft            ::1/128                 scram-sha-256

# Reject everything else explicitly.
host    all             all             0.0.0.0/0               reject
host    all             all             ::/0                    reject
```

Peer authentication is the cleanest match for daemons that run as a dedicated Linux user (Weft as systemd, Postgres maintenance as `postgres`); password authentication on loopback covers the Docker case and any one-off `psql -h localhost` from a different OS user.

### 6. Restart Postgres and verify the new config is live

```bash
sudo systemctl restart postgresql@16-main
sudo systemctl status postgresql@16-main           # expect: active (running), no errors
sudo -u postgres psql -c 'SHOW listen_addresses;'  # expect: localhost
sudo -u postgres psql -c 'SHOW shared_buffers;'    # expect: 512MB
ss -tlnp | grep -E '127\.0\.0\.1:5432|::1\]:5432'  # expect: listening only on loopback
ss -tlnp | grep ':5432' | grep -v -E '127\.0\.0\.1|::1' \
    && echo "BAD: Postgres is listening beyond loopback" || echo "OK: loopback only"
```

If the cluster fails to start after a config change, `journalctl -u postgresql@16-main --since '5 minutes ago'` is your first stop. Most config syntax errors are immediately obvious there.

### 7. Create roles and databases

Run as the `postgres` superuser. The script is idempotent — re-running it on a fresh install or after partial failure is safe.

```bash
sudo -u postgres psql <<'SQL'
-- Roles. LOGIN, no SUPERUSER, no CREATEDB, no CREATEROLE, no REPLICATION.
-- Passwords are set at deploy time, not here. See ## Secrets below.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'paperclip') THEN
        CREATE ROLE paperclip WITH LOGIN PASSWORD '<GENERATED_AT_DEPLOY>';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'weft') THEN
        CREATE ROLE weft WITH LOGIN PASSWORD '<GENERATED_AT_DEPLOY>';
    END IF;
END$$;

-- Databases owned by the matching role. UTF8 / en_US.UTF-8.
SELECT 'CREATE DATABASE paperclip OWNER paperclip ENCODING ''UTF8'' LC_COLLATE ''en_US.UTF-8'' LC_CTYPE ''en_US.UTF-8'' TEMPLATE template0'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'paperclip')\gexec

SELECT 'CREATE DATABASE weft OWNER weft ENCODING ''UTF8'' LC_COLLATE ''en_US.UTF-8'' LC_CTYPE ''en_US.UTF-8'' TEMPLATE template0'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'weft')\gexec

-- Belt-and-braces: explicitly revoke cross-database access. Postgres already
-- enforces this through ownership, but an explicit REVOKE is auditable.
REVOKE ALL ON DATABASE paperclip FROM weft;
REVOKE ALL ON DATABASE weft      FROM paperclip;

\du
\l
SQL
```

The `<GENERATED_AT_DEPLOY>` placeholder is replaced with a freshly-generated password during deploy — see `## Secrets`.

### 8. Add Linux users for peer authentication

Peer auth checks that the connecting OS user's name matches the requested Postgres role. Create system users that do exactly that — no shell, no home, no password.

```bash
sudo useradd --system --shell /usr/sbin/nologin --no-create-home paperclip
sudo useradd --system --shell /usr/sbin/nologin --no-create-home weft
```

These users exist purely to enable peer auth. Daemons that connect as them — directly via systemd `User=...`, or indirectly via `sudo -u <user>` — get authenticated to Postgres with no password to manage. Login attempts (SSH, `su`) are blocked by `nologin`.

`sudo` runs commands without invoking a login shell, so `sudo -u paperclip psql -d paperclip` works despite the `nologin` shell.

### 9. Set up local backup scaffolding

This is the **local** backup skeleton. Off-host shipping to Backblaze B2 is a separate runbook (Tuesday work). Verify the local pipeline first; off-host on top of an unverified local pipeline is just two failure modes layered.

```bash
sudo install -d -m 0750 -o postgres -g postgres /var/backups/postgresql
```

Create `/usr/local/bin/postgres-backup.sh`:

```bash
#!/usr/bin/env bash
# Local nightly Postgres backup. Off-host shipping is a separate stage.
set -euo pipefail

BACKUP_DIR=/var/backups/postgresql
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
RETENTION_DAYS=14

for db in paperclip weft; do
    out="${BACKUP_DIR}/${db}-${TIMESTAMP}.dump"
    sudo -u postgres pg_dump --format=custom --no-owner --no-acl \
        --file="${out}" "${db}"
    chmod 0640 "${out}"
done

# Prune backups older than RETENTION_DAYS.
find "${BACKUP_DIR}" -type f -name '*.dump' -mtime +${RETENTION_DAYS} -delete
```

Install:

```bash
sudo install -m 0750 -o root -g postgres /tmp/postgres-backup.sh /usr/local/bin/postgres-backup.sh
```

systemd timer at `/etc/systemd/system/postgres-backup.service`:

```ini
[Unit]
Description=Postgres logical backup (paperclip + weft)
After=postgresql@16-main.service
Requires=postgresql@16-main.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/postgres-backup.sh
```

And `/etc/systemd/system/postgres-backup.timer`:

```ini
[Unit]
Description=Nightly Postgres backup at 03:00 UTC

[Timer]
OnCalendar=*-*-* 03:00:00 UTC
Persistent=true
RandomizedDelaySec=15min

[Install]
WantedBy=timers.target
```

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now postgres-backup.timer
sudo systemctl list-timers postgres-backup.timer
```

Custom-format dumps (`--format=custom`) are restorable with `pg_restore` and support selective object restore — the right default per ADR 0002.

## Verification

Run all of these. Each one is a load-bearing assertion. **Verify before trust** — a backup pipeline you have not test-restored does not exist.

```bash
# Cluster is up and well.
sudo systemctl status postgresql@16-main          # active (running)

# Bound to loopback only.
ss -tlnp | grep ':5432'                           # only 127.0.0.1:5432 and [::1]:5432

# Roles and databases exist as expected.
sudo -u postgres psql -c '\du'                    # paperclip, weft, postgres present
sudo -u postgres psql -c '\l'                     # paperclip and weft databases present, correct owners

# Each role can connect to its own database via peer auth.
sudo -u paperclip psql -d paperclip -c 'SELECT current_user, current_database();'
sudo -u weft      psql -d weft      -c 'SELECT current_user, current_database();'

# Cross-database access is blocked.
sudo -u paperclip psql -d weft      -c 'SELECT 1;' && echo "BAD: paperclip can read weft" || echo "OK: cross-db blocked"
sudo -u weft      psql -d paperclip -c 'SELECT 1;' && echo "BAD: weft can read paperclip" || echo "OK: cross-db blocked"

# Backup runs cleanly and produces non-empty output.
sudo systemctl start postgres-backup.service
ls -lh /var/backups/postgresql/                   # both *.dump files present, > 0 bytes

# Test restore against a throwaway database. The single most-skipped verification.
sudo -u postgres createdb paperclip_restore_test
sudo -u postgres pg_restore --dbname=paperclip_restore_test \
    /var/backups/postgresql/paperclip-*.dump
sudo -u postgres psql -d paperclip_restore_test -c '\dt'  # tables (or empty) restored
sudo -u postgres dropdb paperclip_restore_test
```

If the restore step fails, the backup pipeline is broken regardless of what the dump file size suggests. Fix before continuing.

## Rollback

Two flavors, one for config-level mistakes (recoverable, non-destructive) and one for full uninstall (destructive — only if the cluster has no real data and the install is fundamentally wrong).

### Config rollback (non-destructive)

```bash
sudo cp /etc/postgresql/16/main/postgresql.conf.orig /etc/postgresql/16/main/postgresql.conf
sudo cp /etc/postgresql/16/main/pg_hba.conf.orig     /etc/postgresql/16/main/pg_hba.conf
sudo systemctl restart postgresql@16-main
```

### Full uninstall (destructive — wipes the cluster)

Only use if the cluster has **no real data** and the install needs to be redone from a clean state. Once Paperclip or Weft has written application state, this path destroys that state.

```bash
sudo systemctl disable --now postgres-backup.timer postgres-backup.service
sudo systemctl stop postgresql@16-main
sudo apt remove --purge -y postgresql-16 postgresql-client-16 postgresql-contrib-16 postgresql-common
sudo rm -rf /var/lib/postgresql /etc/postgresql /var/log/postgresql
sudo rm -f /usr/local/bin/postgres-backup.sh
sudo rm -f /etc/systemd/system/postgres-backup.{service,timer}
sudo userdel paperclip 2>/dev/null || true
sudo userdel weft 2>/dev/null || true
sudo systemctl daemon-reload
```

## Secrets

**No passwords are committed to this repo, ever.** The `<GENERATED_AT_DEPLOY>` placeholder in step 7 is replaced at deploy time with a freshly-generated password per role:

```bash
PAPERCLIP_PG_PASSWORD=$(openssl rand -base64 32)
WEFT_PG_PASSWORD=$(openssl rand -base64 32)

sudo -u postgres psql -c "ALTER ROLE paperclip WITH PASSWORD '${PAPERCLIP_PG_PASSWORD}';"
sudo -u postgres psql -c "ALTER ROLE weft      WITH PASSWORD '${WEFT_PG_PASSWORD}';"
```

The generated values land in:

- **Paperclip** — its `.env` (or systemd `EnvironmentFile=`) as part of `DATABASE_URL=postgres://paperclip:${PAPERCLIP_PG_PASSWORD}@127.0.0.1:5432/paperclip`. The file is mode `0600`, owned by `paperclip:paperclip`.
- **Weft** — its secret store (the `password` / `api_key` field types per architecture report Section 2) for any TCP path that needs it. Weft itself prefers peer auth via the local socket, in which case no password is needed for the Weft↔Postgres connection at all.

Operator keeps a copy in their own password manager. Rotation playbook is a separate runbook (TODO).

## Concerns / Open questions

- **Paperclip-in-Docker vs peer auth.** Peer auth requires the connecting process's OS UID to match the Postgres role name. A Paperclip container connecting from outside the host UID namespace cannot satisfy that — it will land on the `host ... scram-sha-256` line in `pg_hba.conf` and authenticate by password. This is why the runbook adds both `local ... peer` and `host ... scram-sha-256` lines for each role. The cleaner Docker config (UID mapping plus socket bind-mount) is deferred to [`install-weft-and-paperclip.md`](install-weft-and-paperclip.md), where the Docker run config is decided. As-is, password auth on loopback is the working default.
- **`archive_command = '/bin/true'` accepts WAL deletion.** With `archive_mode = on` and a no-op archive command, Postgres considers each WAL segment "archived" and recycles it normally. There is **no point-in-time recovery (PITR) capability** until a real archive command is wired in. Until then, recovery floor is the most recent `pg_dump` (≤ 24h old once the timer is enabled). Acceptable for an empty cluster being deployed today; flip to a real command (Tuesday) before first paying-client data lands.
- **Memory tuning is conservative.** The 2 GB-RAM-VPS sizing is a safe starting point, not optimal. Re-evaluate `shared_buffers`, `work_mem`, and `effective_cache_size` after one week of real load using `pg_stat_statements` and the actual filesystem-cache hit rate. The sample size today is zero workloads.
- **No separate data disk.** `/var/lib/postgresql/16/main` lives on the root disk. For the volume this cluster will see in week one, that's fine. If write IO becomes a bottleneck or backup snapshots become awkward, migrate to a dedicated mount and document in a separate runbook.
- **No off-host backup yet.** Local backups under `/var/backups/postgresql/` survive Postgres failures and OS-level mistakes. They do not survive disk loss or VPS loss. The Backblaze B2 shipping runbook is the next item; do not consider this cluster "backed up" until that pipeline is also test-restored end to end.

## References

- [PostgreSQL 16 documentation](https://www.postgresql.org/docs/16/) — server admin, client auth, continuous archiving, backup chapters.
- [Linux downloads (Ubuntu) — postgresql.org](https://www.postgresql.org/download/linux/ubuntu/) — official PGDG repo setup.
- [PostgreSQL versioning policy](https://www.postgresql.org/support/versioning/) — Postgres 16 EOL November 2028.
- [Ubuntu 24.04 LTS](https://ubuntu.com/server/docs) — server documentation index.
- [ADR 0002 — Postgres single instance, shared process](../../docs/adr/0002-postgres-single-instance-shared-process.md) — the decision this runbook implements.
- [Architecture report Section 2](../../docs/architecture/2026-04-27-fulfillment-architecture-report.md) — the Postgres-sharing rationale and Restate-uses-its-own-RocksDB note.
