# infra/scripts/

Operational scripts that run on the production VPS. Tracked here so changes are reviewable; the canonical executable copy lives at `/home/neo/bin/` on the host.

## `launch-supervisor.sh`

Health-check + alerting cron for the Efficient Labs launch substrate. Probes critical services every 5 minutes (via cron). Maintains per-service consecutive-failure counters in `/home/neo/.cache/launch-supervisor/`. Alerts the operator via Resend email when a service crosses the failure threshold (default: 3 consecutive failures = ~15 min of downtime), and sends an "all clear" when it recovers.

Services monitored:

- `n8n` (HTTP 200 on `http://100.83.59.73:5678/healthz`)
- MemCompute (HTTP 200 on `http://100.83.59.73:8767/health`)
- n8n public (HTTP 200 on `https://n8n.efficientlabs.ai/healthz`)
- Tally form (HTTP 200 on `https://tally.so/r/81R2zr`)
- audit-intake n8n workflow (n8n API: `workflow.active=true`)
- stripe-paid n8n workflow (n8n API: `workflow.active=true`)

### Diagnostic taps

The script writes a checkpoint line to all three of `/home/neo/log/`, `/tmp/`, `/var/tmp/` on each invocation. This is deliberate diagnostic instrumentation: it lets the operator distinguish "script never started" from "script ran but errored before logging" by checking which paths the diag-line landed in.

Under the current cron hardening drop-in (`PrivateTmp=true` + `ProtectHome=true`, installed 2026-04-23), cron-spawned processes get a sandboxed `/tmp` and `/home/` is inaccessible to writes — so a healthy cron firing produces NO writes to any of the three diag paths and NO write to the main log. Manual invocations from an interactive shell DO produce diag entries normally.

### Known issue: cron-hardening blocks all worker output

Per the urgent dispatch-board handoff `2026-05-27T13-45-23Z_claude_URGENT_cron-hardening-blocks-workers`, the cron hardening drop-in's `ProtectHome=true` prevents this script (and the other cron-driven workers `audit_delivery_worker` and `audit_followup_worker`) from writing anywhere under `/home/neo/`. Every cron firing is a silent no-op.

Fix options are A/B/C in that handoff. Operator decision pending.

### Updating the live copy

After landing changes via PR, sync the executable copy on the host:

```bash
cp /home/neo/work/Efficient-Labs/infra/scripts/launch-supervisor.sh /home/neo/bin/launch-supervisor
chmod +x /home/neo/bin/launch-supervisor
```
