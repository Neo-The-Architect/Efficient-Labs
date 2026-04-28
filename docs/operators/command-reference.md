# Operator command reference

**Living document, draft v1 from workspace context.** This reference is reconstructed from the on-disk artifacts available to the executor at authoring time (the architecture report, ADRs 0001–0005, the existing runbooks, the repository structure, and the README). It will be augmented from the operator's external canonical reference in a follow-up commit. Where a command or path is **inferred** rather than verifiable from the workspace, the line is annotated `[INFERRED]`. Where a value is a placeholder pending the operator's input, it is annotated `[TBD]`.

The reference is for the operator (NeoTheArchitect) returning to the system after a short or long break. It is not a runbook — runbooks live in `infra/runbooks/` and are authored under the [runbook execution protocol](../processes/runbook-execution-protocol.md). This document is the *index* the operator opens first to remember how the cold-start surface looks.

---

## Cold-start checklist — coming back after a break

Run through these in order. Each step is a single command or a single observation; stop at the first unexpected output.

1. **Identify yourself.** `whoami` — confirm you are the user you intended to be (operator on operator's laptop; `claude` in the sandbox; never `root` for routine work).
2. **Confirm tailnet membership.** `tailscale status` — confirm you can see the production VPS in the device list with the expected tags.
3. **Reach the VPS.** `tailscale ssh neo@<vps-tailnet-name>` — the only operator access path per [ADR 0005](../adr/0005-tailscale-ssh-as-primary-access-path.md). No `-i <key-file>`, no port flag, no flags at all in the typical case.
4. **Survey the host.** Once on the VPS: `uptime`, `df -h`, `systemctl --failed`, `journalctl --since '1 hour ago' -p err` — five seconds of telemetry that flags anything obviously broken.
5. **Check the public-build repo.** From the operator laptop or from the sandbox: `cd /home/claude/workspace/efficient-labs && git status && git log --oneline -5` — confirm `main` is clean and matches origin.
6. **Open the active PRs.** `gh pr list --state open` — pick up where you left off.
7. **Read the most recent CHANGELOG entry.** Reminds you what merged most recently. The CHANGELOG is the high-altitude diff against memory.

---

## Surfaces and access paths

| Surface | What it is | How to reach it |
| --- | --- | --- |
| **Operator laptop** | The operator's primary device. Holds the Tailscale identity, the GitHub credentials, the operator-side repo clones. | Local. |
| **Production VPS** | Hostinger VPS, Ubuntu 24.04, hardened baseline (Lynis ≥ 85, Tailscale-only ingress). Hosts Postgres, Restate, Weft, Paperclip when deployed. | `tailscale ssh neo@<vps-tailnet-name>` per [ADR 0005](../adr/0005-tailscale-ssh-as-primary-access-path.md). |
| **Claude Code sandbox** | A user account on the VPS (`claude`) with no `sudo`, scoped to engineering work. The repo at `/home/claude/workspace/efficient-labs` is the working directory. | From the operator account: `su - claude` (operator drops into the sandbox user). From outside: not directly reachable; goes through the operator session. |
| **GitHub repo** | `Neo-The-Architect/Efficient-Labs`, public. Source of truth for code, runbooks, ADRs, process docs. | Web UI; `gh` CLI; `git` over HTTPS using `gh auth git-credential` as the credential helper. |
| **Hostinger hPanel** | The VPS provider's control panel. The web terminal there is the documented fallback if Tailscale connectivity is lost — see issue #3. | Browser. Credentials in the operator's password manager. |
| **Tailscale admin console** | The control plane for tailnet membership, ACL, and SSH authorization. The source of truth for "who can SSH where." | https://login.tailscale.com/admin |
| **Anthropic console** | Claude API key management, usage, billing. | https://console.anthropic.com |
| **Stripe dashboard** | When deployed: payment events, customer records, subscription state. Not yet active. | https://dashboard.stripe.com |
| **GitHub Security Advisories** | The private channel for vulnerability disclosure (see [`SECURITY.md`](../../SECURITY.md)). | Repository → Security → Advisories. |

---

## The two-user discipline

The VPS hosts two operator-relevant users:

- **`neo`** — the operator. Has `sudo`. The user that runs runbooks, edits system configuration, manages systemd units, and owns the production state.
- **`claude`** — the sandbox user. **No `sudo`.** Owns the working directory `/home/claude/workspace/efficient-labs/`. Runs Claude Code, performs engineering work that does not require root.

The discipline:

- **Never run Claude Code as `neo`.** Engineering work happens in the `claude` account so that the sandbox cannot accidentally modify production state through a wayward command. The boundary is enforced by Linux permissions, not by trust.
- **Never run runbooks as `claude`.** Runbooks change production state and require `sudo`. The `claude` account does not have `sudo`, so the boundary is enforced by capability, not by remembering.
- **Switch with `su - claude`** (operator drops into the sandbox) and `exit` (operator returns to their own session). Never run `sudo -u claude bash -c '<command>'` for routine work — sudoers may not allow it (verified during the 2026-04-28 setup session) and it confuses session ownership.

---

## Common operations (copy/paste)

### Git: pull, branch, commit, push

```bash
# Sync main with origin
cd /home/claude/workspace/efficient-labs
git checkout main && git pull origin main

# Start a feature branch
git checkout -b feat/<short-slug>

# Stage and commit (specific files, not -A)
git add <file1> <file2>
git commit -m "feat(area): one-line description"

# Push and open PR
git push -u origin feat/<short-slug>
gh pr create --title "Short title" --body "..."
```

Direct push to `main` is blocked at multiple layers (sandbox, GitHub branch protection — see [`docs/processes/branch-protection.md`](../processes/branch-protection.md)). Every change goes through a PR.

### gh CLI: status, PR ops, issue ops

```bash
gh auth status                                     # confirm logged in
gh pr list --state open                            # open PRs
gh pr view <number>                                # PR details
gh pr checks <number>                              # CI status (when CI lands)
gh pr merge <number> --squash --delete-branch      # squash merge after review
gh issue create --title "..." --body "..."         # file an issue
gh issue list --state open                         # active issues
```

### systemd (on the VPS, as operator)

```bash
sudo systemctl status <unit>           # current state
sudo systemctl restart <unit>          # restart
sudo journalctl -u <unit> -n 50        # last 50 log lines
sudo journalctl -u <unit> --since '15 minutes ago'
sudo systemctl list-units --failed     # everything that's broken
```

### Tailscale (on either side)

```bash
tailscale status                       # device list and connectivity
tailscale ssh neo@<vps-tailnet-name>   # operator session on the VPS
tailscale serve status                 # what is exposed via Serve
tailscale funnel status                # what is exposed publicly via Funnel
```

### Postgres (on the VPS, when deployed)

```bash
sudo -u postgres psql                  # superuser shell
sudo -u postgres psql -c '\l'          # list databases (expect: paperclip, weft)
sudo -u postgres psql -c '\du'         # list roles
ss -tlnp | grep 5432                   # confirm localhost-only binding
sudo systemctl status postgresql@16-main
```

See [ADR 0002](../adr/0002-postgres-single-instance-shared-process.md) for the database/role design and [`infra/runbooks/install-postgres.md`](../../infra/runbooks/install-postgres.md) for the install/configuration runbook.

---

## Auth inventory

This section names the credentials the operator holds and where each lives. None of the actual credential values are committed — only the inventory.

| Credential | Stored in | Used for |
| --- | --- | --- |
| Tailscale account login | Operator's password manager | Tailscale admin console; SSH access via `tailscale ssh` |
| Tailscale hardware MFA | Operator's hardware token | MFA on the Tailscale account |
| GitHub account login | Operator's password manager | GitHub web UI |
| GitHub personal access token / `gh` auth | `~/.config/gh/hosts.yml` on each device that runs `gh` | Authenticated `gh` and `git` operations |
| Hostinger hPanel login | Operator's password manager | VPS web terminal fallback (issue #3) |
| Anthropic API key | `[TBD]` — operator decides whether sandbox or only-on-VPS | Claude API calls from production code (when deployed) |
| Stripe API keys | `[TBD]` — to be provisioned during week-2 ship | Production payment processing (when deployed) |
| Postgres role passwords (`paperclip_owner`, `weft_owner`) | `[TBD]` — generated during runbook execution; stored in the operator's password manager and in the per-service secrets file on the VPS | Postgres role authentication (when deployed) |
| Per-client repo deploy keys | `[TBD]` — generated per engagement | Pushing to private client repos (when first paying client lands) |

The credential discipline:

- Never commit a credential to the repo. The [code review checklist](../processes/code-review-checklist.md) calls out a secret-grep step.
- Rotate when an operator device is lost or sold. Rotation is identity-level for Tailscale (revoke device in admin console) and credential-level for everything else.
- The password manager is the single source of truth for human-typed credentials. Other surfaces (hPanel, Tailscale, Anthropic) hold derived state but never the master credential.

---

## Emergency recovery

### If Tailscale connectivity is lost (cannot SSH to the VPS)

1. Confirm the symptom — `tailscale status` on the operator laptop shows the VPS as offline or unreachable, but `tailscale.com/status` page shows control plane healthy.
2. **Do not panic-mask additional surfaces.** The Tailscale-only access posture is the right answer ([ADR 0005](../adr/0005-tailscale-ssh-as-primary-access-path.md)) — recovery is the documented Hostinger web terminal fallback.
3. Open the Hostinger hPanel → VPS → Web Terminal. Authenticate with the Hostinger account credentials. Open a shell on the host as `root` (the hPanel default) or as `neo`.
4. From the host: `tailscale status` to inspect the host's view of the tailnet. If the host disagrees with the laptop, the issue is local-tailnet-state on the host. `sudo tailscale logout` and `sudo tailscale up --auth-key=<fresh-key>` to re-enroll. Confirm the device reappears in the Tailscale admin console.
5. Issue #3 tracks the substantive runbook for this procedure. Until the runbook lands, this section is the working summary.

### If Claude Code is frozen / unresponsive

1. Confirm the symptom — Claude Code session in the sandbox does not respond to keystrokes or has gone silent for >30 seconds with no tool calls.
2. From a fresh terminal on the operator laptop: `tailscale ssh neo@<vps-tailnet-name>`, then `su - claude`, then check the running Claude Code process: `pgrep -af claude` (`[INFERRED]` — exact command depends on how Claude Code is invoked).
3. If a stale process is identified, the operator can `kill <pid>`. Restart Claude Code with the canonical launcher: `/home/neo/launch-claude.sh` `[INFERRED]` (the launcher path is referenced in the original PRD context but is not yet on disk; verify before relying on it).
4. If the issue persists, the next escalation is the Anthropic console (check API status) and the Tailscale admin console (check the sandbox's tailnet posture).

### If the local repo desyncs from origin

1. `git status` to see what is on disk.
2. `git fetch origin` to update remote tracking.
3. `git log --oneline origin/main..HEAD` to see local-only commits; `git log --oneline HEAD..origin/main` to see remote-only commits.
4. **Never `git reset --hard` or `git push --force` to recover** unless you have read both diffs and understood what each side has. Recovery from the wrong side of a force-push is more expensive than the time saved by skipping the diff read. The discipline-check in the PR template names this explicitly.

---

## Sandbox launch

The Claude Code sandbox is launched from the operator account on the VPS. The launcher is at `/home/neo/launch-claude.sh` `[INFERRED]` — referenced in the original PRD context and reasonable given the two-user discipline, but the launcher itself is not on disk in the public repo. The launcher is expected to:

1. Drop the operator into the `claude` user (`su - claude` or equivalent).
2. `cd` to the working directory `/home/claude/workspace/efficient-labs`.
3. Invoke the Claude Code CLI with appropriate environment for the sandbox.

When the launcher contents are committed (likely under `infra/scripts/` or kept private in `/home/neo/`), this section is updated with the exact behavior.

---

## Key URLs

- Public repo: https://github.com/Neo-The-Architect/Efficient-Labs
- Open PRs: https://github.com/Neo-The-Architect/Efficient-Labs/pulls
- Open issues: https://github.com/Neo-The-Architect/Efficient-Labs/issues
- ADR index: https://github.com/Neo-The-Architect/Efficient-Labs/tree/main/docs/adr
- Architecture report: https://github.com/Neo-The-Architect/Efficient-Labs/blob/main/docs/architecture/2026-04-27-fulfillment-architecture-report.md
- SECURITY.md: https://github.com/Neo-The-Architect/Efficient-Labs/blob/main/SECURITY.md
- Tailscale admin: https://login.tailscale.com/admin
- Hostinger hPanel: https://hpanel.hostinger.com `[INFERRED]` — verify the operator's actual hPanel URL.
- Anthropic console: https://console.anthropic.com
- Stripe dashboard: https://dashboard.stripe.com (when active)

---

## What this document is *not*

- It is not a runbook. Runbooks live in `infra/runbooks/`.
- It is not an exhaustive command-by-command tutorial. It is a memory aid for an operator who already knows the commands but needs the right sequence and context.
- It is not the source of truth for any credential. Credentials live in the operator's password manager.
- It is not maintained automatically. When commands change, paths move, or surfaces are added, this document is updated by hand through a PR.

---

## Update protocol

When the operator notices this document is wrong (a path is stale, a command no longer works, a surface has been added or retired), file the change as a PR using the standard discipline. Mark the PR as `docs(operators)` so it shows up clearly in the changelog. Inferred lines are upgraded to verified lines as the operator confirms each one.
