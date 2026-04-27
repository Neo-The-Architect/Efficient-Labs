# Runbook: install Weft and Paperclip

Land both orchestration runtimes on the EL VPS, each pointed at its own database in the shared external Postgres (per [ADR 0002](../../docs/adr/0002-postgres-single-instance-shared-process.md)). Weft installs from source against a pinned commit SHA. Paperclip installs from Docker against a pinned image SHA. Both are systemd-managed and exposed only through the tailnet.

## Purpose

Stand up the typed durable orchestrator (Weft) and the multi-agent business OS (Paperclip) on the VPS, with the boundary captured in [ADR 0001](../../docs/adr/0001-weft-paperclip-architectural-boundary.md). Both share Postgres but neither shares schema with the other. Both depend on Restate ([install-restate.md](install-restate.md)) for durable execution surfaces, though Paperclip uses Restate only indirectly via Weft.

## Prerequisites

- TODO: Postgres is up with `paperclip` and `weft` databases and roles per [install-postgres.md](install-postgres.md).
- TODO: Restate is up and healthy per [install-restate.md](install-restate.md).
- TODO: Weft commit SHA pinned. Vendoring decision: clone `github.com/WeaveMindAI/weft` into a fork at `efficient-labs/weft-pinned` per architecture report Section 9 mitigation, or pin against upstream — TODO decide before first install.
- TODO: Paperclip Docker image SHA pinned. Never `:latest` per architecture report Section 9 calver-churn warning.
- TODO: Anthropic API key provisioned and stored in Paperclip's encrypted secrets table (Weft reads via Paperclip secret reference, *not* via env var).
- TODO: Tailscale tailnet configured; `efficient-labs.tailnet.ts.net` resolves; Funnel and Serve mappings prepared.
- TODO: Backblaze B2 bucket prepared for `paperclipai db:backup` nightly target.
- TODO: `infra/systemd/weft.service.template` and `infra/systemd/paperclip.service.template` reviewed.

## Steps

TODO. Sketch:

### Weft

1. Clone the pinned Weft repository to `/opt/efficient-labs/weft` as the `weft` Linux user (no shell, restricted home).
2. Build via the repo's `dev.sh` flow adapted for non-interactive use. TODO: confirm whether `dev.sh server` can be invoked with environment-config and no interactive prompts.
3. Configure Weft to connect to `postgres://weft:...@127.0.0.1:5432/weft` and to the local Restate instance.
4. Materialize the systemd unit from `infra/systemd/weft.service.template`. `OnFailure` action goes to the operator alert path.
5. Bind the dashboard to `127.0.0.1:5173`.
6. Set up Tailscale Serve mapping for operator access to the dashboard (operator-only, never Funnel).
7. Set up Tailscale Funnel mapping for the public webhook surface (`efficient-labs.tailnet.ts.net/hooks/...`) — webhooks need public reachability; the dashboard does not.
8. Enable and start the service.

### Paperclip

1. Pull the pinned Paperclip Docker image; verify the digest.
2. Create dedicated `paperclip` Linux user.
3. Materialize the Docker run config (or compose file) — TODO: choose plain `docker run` via systemd vs. compose. Plain Docker via systemd is simpler and matches the "one runtime less" posture.
4. Set environment:
   - `DATABASE_URL=postgres://paperclip:...@127.0.0.1:5432/paperclip` — this disables Paperclip's embedded-postgres on 54329 per [ADR 0002](../../docs/adr/0002-postgres-single-instance-shared-process.md).
   - `PAPERCLIP_DEPLOYMENT_MODE=authenticated`
   - `PAPERCLIP_DEPLOYMENT_EXPOSURE=tailnet`
   - Anthropic API key reference (TODO: confirm Paperclip's secret-reference syntax for env-var injection).
5. Materialize the systemd unit from `infra/systemd/paperclip.service.template`.
6. Set up Tailscale Serve mapping for the Paperclip UI (operator-only).
7. Configure `paperclipai db:backup` nightly cron to ship encrypted backups to Backblaze B2.
8. Enable and start the service.

### Wire-up

1. Mint a long-lived Paperclip board API key (`pcp_board_...`) and store it in Weft's secret store using the `password` or `api_key` field type (these get stripped from publish artifacts per architecture report Section 2).
2. Verify Weft can `POST /api/companies/{id}/issues` against Paperclip with that key.
3. Verify the embedded-postgres driver did not start on 54329 (`nc -z 127.0.0.1 54329` should fail).

## Verification

TODO:

- `systemctl status weft` shows active.
- `systemctl status paperclip` shows active.
- Weft dashboard reachable from the operator device through Tailscale Serve.
- Paperclip UI reachable from the operator device through Tailscale Serve.
- A trivial Weft program runs end-to-end and persists state in the `weft` database.
- A trivial Paperclip Issue is creatable from the UI and persists in the `paperclip` database.
- Weft → Paperclip HTTP call from a Weft test program lands as a real Issue in Paperclip.
- The public webhook endpoint (`efficient-labs.tailnet.ts.net/hooks/test`) is reachable from the public internet through Tailscale Funnel.
- The Weft dashboard is *not* reachable from the public internet.
- The Paperclip UI is *not* reachable from the public internet.
- Postgres on 54329 is *not* listening (Paperclip is using external).

## Rollback

TODO:

- If a Weft commit pin breaks against the database schema, downgrade to the previous pinned SHA. Weft has no migration framework as of 2026-04-27; schema changes are inspected manually before pinning a new SHA.
- If a Paperclip image pin breaks (calver migration touches `paperclip` database in unexpected ways), pin to the previous image SHA. Open an upstream issue. Database-level isolation per ADR 0002 ensures Weft is unaffected.
- If both runtimes are wedged, pause-and-retry per architecture report Section 5: restart, give Restate a chance to resume in-flight executions, then escalate. Off-host Postgres backup + RocksDB filesystem snapshot is the recovery floor.
