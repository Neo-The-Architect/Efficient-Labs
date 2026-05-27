# Audit fulfillment incident response

**Status:** DRAFT — first launch-week version. Iterate after each real incident.

Scope: anything that goes wrong between a customer submitting the Tally intake form and the PDF audit deliverable landing in their inbox. Architecture context: [ADR 0007](../adr/0007-audit-product-autonomous-fulfillment-pipeline.md).

## Tier-1 signals you'll see

The two automated channels you will get paged on:

1. **`launch-supervisor` alert email** — subject begins `[ALERT] launch supervisor — <service> degraded`. Body names which service failed 3+ consecutive probes (~15 min of downtime) and which command to start with.
2. **`launch-supervisor` recovery email** — subject begins `[CLEAR] launch supervisor — <service> recovered`. Sent automatically when the failing service starts probing healthy again. No action needed.

You may also see:

3. **Customer reply to a deliverable email.** Lands in operator inbox via the `reply-to` header on the Resend send. Treat as tier-2 unless the customer reports the deliverable is missing or corrupted.
4. **`[INTAKE]` / `[PAID]` emails not arriving** while you know real activity is happening. Usually means Resend send credit exhausted or n8n itself is degraded; check supervisor logs first.

## What's where

| Component | Purpose | Investigate via |
|---|---|---|
| n8n workflow `44rID3Fapv84vALY` | Tally webhook → MemCompute → Stripe Checkout → Resend confirm | `https://n8n.efficientlabs.ai/workflow/44rID3Fapv84vALY` (web UI) or `/api/v1/executions?workflowId=...` |
| n8n workflow `DTyLwBqgxbASClyr` | Stripe webhook → mark intake paid → queue delivery → Resend operator notify | Same UI / API as above |
| Delivery worker | Drains `delivery-queue/`, generates 9-section deliverable, attaches PDF, emails | Log: `/home/neo/log/audit-delivery-worker.log` |
| Launch supervisor | Health probes every 5 min | Log: `/home/neo/log/launch-supervisor.log` |
| MemCompute intake records | Per-client intake + payment state | `http://100.83.59.73:8767/ui/#/intake-gate/` (web UI, Tailscale-only) |
| MemCompute delivery queue | Pending + delivered tickets | `http://100.83.59.73:8767/ui/#/delivery-queue/` |
| MemCompute audit deliverables archive | Full markdown of every delivered audit | `http://100.83.59.73:8767/ui/#/audit-deliverables/` |

## Quick triage flow

When you get a `[ALERT] launch supervisor` email, work this order:

1. **Read the email body.** The supervisor names the failing service + the investigation command. Often that's the whole investigation.

2. **Check the most-recent execution(s) in n8n.** If the failing service is `audit-intake-wf` or `stripe-paid-wf`:
   ```bash
   export N8N_KEY=$(grep ^N8N_API_KEY= /home/neo/.config/sovereign-core/vault.env | cut -d= -f2-)
   # last 5 executions across all workflows
   curl -s -H "X-N8N-API-KEY: $N8N_KEY" "http://100.83.59.73:5678/api/v1/executions?limit=5" | python3 -m json.tool | head -30
   unset N8N_KEY
   ```
   If executions are failing, drill into one:
   ```bash
   # replace EXEC_ID with the failing one from above
   export N8N_KEY=$(grep ^N8N_API_KEY= /home/neo/.config/sovereign-core/vault.env | cut -d= -f2-)
   curl -s -H "X-N8N-API-KEY: $N8N_KEY" "http://100.83.59.73:5678/api/v1/executions/EXEC_ID?includeData=true" | python3 -c "import json,sys; d=json.load(sys.stdin); [print(k, ':', list(v[0].get('error',{}).get('message','OK')[:80] if isinstance(v[0].get('error',{}).get('message',''), str) else 'OK' for _ in [None])) for k,v in d['data']['resultData']['runData'].items()]"
   unset N8N_KEY
   ```

3. **Restart the failing service if it's a stuck-process pattern.**
   ```bash
   sudo systemctl status n8n.service
   sudo systemctl restart n8n.service   # restart re-pulls the docker container, ~30s
   sudo systemctl restart memcompute.service
   sudo systemctl restart cloudflared.service
   ```
   systemd `Restart=always` should already have done this; if the service is reported degraded the auto-restart is also degraded (e.g. a config error on boot).

4. **If a stuck delivery ticket is the issue,** the worker emails the operator on per-ticket exception. Investigate via:
   ```bash
   tail -100 /home/neo/log/audit-delivery-worker.log
   ```
   To re-process a specific ticket after fixing the upstream cause:
   ```bash
   source /home/neo/.nvm/nvm.sh && nvm use 22
   SOVEREIGN_CLAUDE_BIN=/home/neo/.nvm/versions/node/v20.20.2/bin/claude \
     node /home/neo/work/sovereign-core/scripts/audit_delivery_worker.js <intake_id>
   ```

5. **Pause the cron worker if you're about to deploy changes** that touch the deliverable generation path:
   ```bash
   crontab -l | grep -v audit_delivery_worker | crontab -
   # do your work
   # then re-add the line — see audit_delivery_worker.js for the exact line
   ```

## Common scenarios

### A. Customer reports they never got their deliverable email

1. Find their intake in MemCompute by company name or email.
2. Check `delivery_status` on `delivery-queue/<intake_id>.md`:
   - `pending_generation` → worker hasn't run yet OR worker is broken; check `/home/neo/log/audit-delivery-worker.log`.
   - `delivered` → Resend successfully accepted the send. Look up `resend_message_id` in Resend dashboard; check spam folder on customer side; resend manually if needed.
3. If the customer paid but no delivery ticket exists at all: the Stripe webhook failed. Check executions on workflow `DTyLwBqgxbASClyr`. Re-trigger by replaying the webhook from Stripe's dashboard.

### B. Customer complains the deliverable quality is poor

This is a v1 known risk; the section 2–9 prompts are scaffold-quality. **Do not refund automatically.** Steps:

1. Read the archived deliverable: `http://100.83.59.73:8767/ui/#/audit-deliverables/<intake_id>-audit.md`.
2. Read the intake record to understand what context the dispatcher had: `http://100.83.59.73:8767/ui/#/intake-gate/<intake_id>.md`.
3. If the issue is missing-context (the intake didn't provide enough detail), reach out to the customer for the missing pieces, regenerate the deliverable from the updated intake.
4. If the issue is a prompt-quality issue (the section template needs tightening), refine the template in `sovereign-core/lib/dispatchers/audit_section_prompts.js`, re-run the worker for the affected ticket.
5. If multiple customers report the same issue in the same section, that section's template needs to be in your top-3 priorities for the week.

### C. Stripe webhook returns 401 (signature mismatch)

The signing secret was rotated and the n8n workflow's inlined value is stale. Per ADR 0007's "Negative" section, the upgrade path is to read from `$env.STRIPE_WEBHOOK_SIGNING_SECRET`. Short-term fix:

1. Get the current signing secret from Stripe dashboard → Webhooks → `we_1TbGGiCxZS9XuuxwThskTayl` → Signing secret.
2. Update vault.env if not already done.
3. Edit workflow `DTyLwBqgxbASClyr` → "Verify Stripe signature" Code node → replace the inlined `SIGNING_SECRET = '...'` value.
4. Save the workflow.

### D. Tally form looks broken to a customer

`tally.so/r/81R2zr` is the public URL. Verify:

1. Visit the URL yourself, scroll all 26 questions.
2. Check `https://api.tally.so/forms/81R2zr` for `status: PUBLISHED`.
3. If it reverted to draft, re-publish via Tally MCP (see [Tally MCP gotchas memory](file:///home/neo/.claude/projects/-home-neo/memory/reference_tally_mcp.md) or the build script at `/home/neo/work/Efficient-Labs/n8n-archetypes/tally-form-build.py`).

### E. Supervisor is alerting but every component looks healthy

Maybe a stale state file. Reset:

```bash
rm -rf /home/neo/.cache/launch-supervisor/
/home/neo/bin/launch-supervisor   # manual probe to verify all-clear
```

## What this runbook does NOT cover

- Onboarding a real human team member into this stack — that's a separate runbook, not yet written.
- Stripe dispute / chargeback handling — Stripe dashboard is the source of truth; this pipeline is fire-and-forget at delivery time.
- Tax / VAT compliance — out of scope for this pipeline; Stripe Tax handles it from the payment side.
- Long-term substrate migrations (Temporal post-launch, Gemma local LLM, etc.) — ADR-tracked decisions, not in scope here.

## Last updated

2026-05-26 — initial draft after pipeline went green E2E. Revise after each real incident.
