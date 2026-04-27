# infra/

Infrastructure-as-text for the Efficient Labs VPS substrate. This directory holds the deployable artifacts and the runbooks that describe how to land them on the box. The VPS itself is hardened Ubuntu 24.04 on Hostinger, exposed to the internet only through Tailscale (Funnel for client-facing surfaces, Serve for operator-only surfaces).

Nothing in here contains secrets. Secrets live in Paperclip's encrypted `secrets` table on the VPS and never leave it. Anything that looks like a credential in a file checked in here is a placeholder.

## Layout

- `systemd/` — unit file templates for the long-running processes on the VPS: external Postgres, Restate, Weft, Paperclip, per-client n8n instances (Sovereign tier, gated on n8n Embed license — see ADR 0003).
- `runbooks/` — operator-facing install and operational procedures. Each runbook is opinionated about *this specific stack on this specific VPS* — they are not generic install guides.

## Conventions

- Unit files are templated with `{{placeholders}}` for anything that varies per environment (paths, ports, user names). Real values get substituted at deploy time.
- Runbooks have five sections: Purpose, Prerequisites, Steps, Verification, Rollback.
- Every component listed in the architecture report Section 5 fallback table has a corresponding runbook entry.
