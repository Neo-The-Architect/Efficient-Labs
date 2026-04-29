# Next Phases Scope v1

> **Status:** Active planning document. Captures Phases E through J following the Phase D infrastructure audit and Foundation Document v1.1 commit.
> **Author:** NeoTheArchitect (operator), with Claude as drafting partner.
> **Date:** 2026-04-29
> **Supersedes:** Nothing — this is v1.
> **Discipline:** Reread when starting a new phase. Update via amendment commit when scope shifts.

## Context

Phases A-D shipped the engineering discipline scaffold. The Phase D audit (`docs/audit/2026-04-28-infrastructure-state-audit.md`) identified the work that remains to bring the infrastructure to deployable state for first paying client. Foundation Document v1.1 (`docs/vision/efficient-labs-foundation.md`) established Path D — wedge funds the mission, mission shapes the wedge.

This document scopes the next 6 phases (E through J) as bulk-completable work blocks, sequenced for shipping discipline. Phases are ordered by dependency, not by ideal sequence — early phases unblock later phases.

## Phase index

| Phase | Title | Estimated work | Primary deliverables |
|---|---|---|---|
| E | Audit fix sprint — quick wins | 2-3 days | 4-5 small PRs closing audit items 3-7, 12, 16, 26 |
| F | Hardened-baseline runbook | 1-2 days | `infra/runbooks/harden-vps-baseline.md` |
| G | Weft/Paperclip prerequisite ADRs | 1-2 days | ADRs 0006-0011 (5-6 ADRs) |
| H | Restate hardening | 1 day | Restate version pin, config validation, template flow fix, OnFailure alert wiring |
| I | Weft/Paperclip runbook DRAFT | 2-3 days | `infra/runbooks/install-weft-and-paperclip.md` brought to DRAFT-ready |
| J | Wedge product MVP scaffolding | 3-5 days | Lead intake → qualification → Stripe → n8n delivery flow |

Total estimated work: 10-16 working days. Phases E and J are parallel-eligible (do not block each other and serve different concerns).

---

## Phase E — Audit fix sprint (quick wins)

### Purpose

Land the bundle of audit findings that are 5-minute to 1-hour fixes. Demonstrates ongoing audit-fix cadence as a public artifact pattern. Closes a meaningful number of audit items per session without requiring deep work.

### Audit items addressed

- Item 3 — `apt update` ordering in Postgres runbook
- Item 4 — Remove unused `gnupg` from Postgres runbook
- Item 5 — Backup script provenance in Postgres runbook
- Item 6 — `User=postgres` on backup systemd unit
- Item 7 — Cross-runtime RAM minimum reference between Postgres and Restate runbooks
- Item 12 — Restate template flow rewrite (deploy from repo, not cp from VPS)
- Item 16 — Tailscale Serve invocation deploy-time verification note
- Item 26 — Commit Restate systemd template under `infra/systemd/`

### Suggested PR sequence

Bundle by file affected:

1. **PR `docs(runbook): postgres install runbook polish bundle`** — items 3, 4, 5, 6, 7. Single Postgres-runbook PR, ~1 hour work.
2. **PR `feat(systemd): commit restate service template`** — item 26. New file `infra/systemd/restate.service.template` with the unit body extracted from the Restate runbook. ~30 minutes.
3. **PR `docs(runbook): rewrite restate template deployment flow`** — item 12. Updates Restate runbook to `install` from repo path instead of `cp` from VPS. Depends on PR 2. ~30 minutes.
4. **PR `docs(runbook): tailscale serve deploy-time verification note`** — item 16. ~15 minutes.

### Acceptance criteria

- All 4 PRs merged to main
- Each PR resolves a specific audit item (linked via `Resolves: #<issue>` in commit message)
- Anonymization grep run before each push (per established discipline)
- Audit document updated to mark closed items (or separate tracking issue updated)

### Out of scope for Phase E

- Item 1 (Postgres password) — already closed via PR #9
- Item 2 / 14 / 25 (hardened-baseline runbook) — Phase F
- Items 9, 10, 11, 13 (Restate version pinning, config validation, OnFailure) — Phase H
- Items 17-21 (Weft/Paperclip blockers) — Phases G, H, I
- Item 8 (ADR 0006 Paperclip Docker UID) — Phase G
- Item 15 (tar-snapshot cleanup) — bundled into Phase H Restate hardening if convenient

---

## Phase F — Hardened-baseline runbook

### Purpose

Author `infra/runbooks/harden-vps-baseline.md` to close the second-largest gap from the audit (cross-cutting items 2, 14, 25). Both Postgres and Restate runbooks reference a "hardened baseline already in place" prerequisite that has no documented procedure on disk. Without this runbook, neither existing runbook can be honestly executed by anyone other than the operator.

### Coverage required

- Lynis run + remediation procedure (target Lynis ≥ 90)
- ufw rules for Tailscale-only ingress
- OpenSSH `systemctl mask` per ADR 0005
- `unattended-upgrades` configuration
- Kernel parameter tuning via sysctl
- fail2ban posture (or equivalent)
- Time/NTP configuration
- AppArmor profile state verification

### Acceptance criteria

- Runbook produces Lynis ≥ 90 on a fresh Ubuntu 24.04 VPS
- All commands verified executable on test VPS
- Rollback section covers how to revert each hardening step
- Verification section includes specific Lynis warning IDs that should NOT appear after run
- Status: DRAFT (not VERIFIED) until first end-to-end execution captured in evidence pack

### Test methodology

- Provision a fresh Hostinger VPS (or use a development tier)
- Execute runbook end-to-end
- Capture Lynis output before and after
- Document any deviations between runbook and actual execution
- Update runbook with verified commands and outputs
- Promote from DRAFT to VERIFIED only after one successful end-to-end execution

### Out of scope for Phase F

- Backup-and-restore for the hardened state (separate runbook)
- Multi-VPS hardening playbook (this is single-VPS)
- Any application-layer hardening (Postgres, Restate, Weft, Paperclip have their own runbooks)

---

## Phase G — Weft/Paperclip prerequisite ADRs

### Purpose

Land the 5-6 ADRs the Weft/Paperclip runbook needs as decision prerequisites before substantive runbook authoring is possible. These ADRs address audit items 18 and 19.

### ADRs to author

Numbering follows current ADR sequence (0006 next available). Group by logical cluster for review efficiency.

**Cluster 1 — Weft sourcing and licensing:**
- ADR 0006 — Weft pinning vs vendoring strategy (audit item 18, line 13)
- ADR 0007 — Weft license acceptance (O'Saasy MIT-with-SaaS-restriction; analogous to BUSL-1.1 acceptance)

**Cluster 2 — Paperclip operational decisions:**
- ADR 0008 — Paperclip image SHA pinning policy (audit item 18, line 14)
- ADR 0009 — Docker-via-systemd vs Compose for Paperclip (audit item 18, line 39)
- ADR 0010 — Paperclip secret-reference syntax for env-var injection (audit item 18, line 44)

**Cluster 3 — Network exposure:**
- ADR 0011 — Tailscale Funnel exposure for Weft webhook surface (audit item 19)

### Suggested PR sequence

- **PR 1: ADRs 0006 + 0007 (Weft sourcing + licensing)** — single PR, two ADRs in one cluster
- **PR 2: ADRs 0008-0010 (Paperclip operational)** — single PR, three ADRs
- **PR 3: ADR 0011 (Funnel exposure)** — single PR, one substantive ADR

Three PRs total. Each PR uses the existing ADR template (`docs/adr/_template.md`).

### Acceptance criteria

- All 6 ADRs accepted (status: Accepted)
- README.md in `docs/adr/` updated to list new ADRs
- Each ADR cross-references the audit finding it addresses
- Each ADR includes alternatives considered, consequences, and review date

### Out of scope for Phase G

- ADR 0012 (Paperclip Docker UID strategy, audit item 8) — gated on Weft/Paperclip runbook reaching DRAFT-ready, deferred to Phase I
- Public lead-intake URL pattern ADR (audit item 19 second half) — bundled into ADR 0011 if scope allows, otherwise separate later

---

## Phase H — Restate hardening

### Purpose

Close the Restate-specific audit findings that require version pinning and validation: items 9, 10, 11, 13, plus item 15 (tar snapshot cleanup) bundled in for convenience.

### Work blocks

1. **Pin Restate version.** Pick latest stable from `github.com/restatedev/restate/releases`. Document version in runbook.
2. **Verify ARCH detection and tarball naming.** Replace hardcoded `x86_64-unknown-linux-musl` with `ARCH=$(uname -m)-unknown-linux-musl` or equivalent. Verify against actual release asset naming.
3. **Validate config schema against pinned version.** Run config validation (subcommand discovered via `--help`). Update keys if schema differs from runbook.
4. **Discover healthcheck path.** Run `restate-server --help` and `journalctl -u restate` against pinned version to find actual healthcheck path. Replace `<HEALTH_PATH>` placeholder.
5. **Wire OnFailure alert path.** Define `restate-failure-alert.service` (oneshot POST to operator-chosen alert channel — Discord webhook or email). Commit under `infra/systemd/`. Uncomment `OnFailure=` in main Restate unit.
6. **Tar snapshot cleanup trap.** Add cleanup step to remove partial `.tar.zst` if script does not reach prune step.

### Suggested PR sequence

- **PR 1: Restate version pin + ARCH + config + healthcheck path** — single PR closing items 9, 10, 11. Gated on test VPS access for verification.
- **PR 2: OnFailure alert wiring** — single PR closing item 13. New systemd unit, runbook update.
- **PR 3: Tar snapshot cleanup trap** — single PR closing item 15. Small change.

### Acceptance criteria

- Restate runbook references a pinned version (no placeholder)
- Healthcheck verification command in runbook executes successfully against pinned binary
- Config validation step in runbook produces no errors
- OnFailure alert fires on simulated Restate crash
- Audit items 9, 10, 11, 13, 15 marked closed

### Dependencies

- Test VPS access (or use of EL VPS in sandbox-mode capacity)
- Operator decision on alert channel (Discord webhook or email recommended; SMS deferred)

### Out of scope for Phase H

- Backblaze B2 backup-shipping runbook (audit out-of-scope item)
- Multi-region Restate deployment

---

## Phase I — Weft/Paperclip runbook DRAFT

### Purpose

Bring `infra/runbooks/install-weft-and-paperclip.md` from stub to DRAFT-ready. This closes the audit's single blocker (item 17). Per audit estimate: 4-6 working days end-to-end across 3 sub-phases.

### Sub-phases (per audit item 21)

**Sub-phase I.1 — Weft installation procedure** (1 day)

- Author runbook section for Weft installation against pinned commit SHA per ADR 0006
- Commit `infra/systemd/weft.service.template`
- Verification commands for Weft binary execution
- Rollback procedure

**Sub-phase I.2 — Paperclip installation procedure** (1 day)

- Author runbook section for Paperclip installation against pinned image SHA per ADR 0008
- Commit `infra/systemd/paperclip.service.template`
- Docker-via-systemd flow per ADR 0009
- Secret-reference syntax per ADR 0010
- Verification commands for Paperclip startup
- Rollback procedure

**Sub-phase I.3 — End-to-end wire-up testing** (1-2 days)

- Provision test VPS (or sandbox-mode on EL VPS)
- Execute Postgres runbook, Restate runbook, hardened-baseline runbook, Weft installation, Paperclip installation in sequence
- Verify trivial Weft program runs end-to-end and persists state in `weft` database
- Verify Weft → Paperclip HTTP call lands as a real Issue in Paperclip
- Capture exact commands and expected outputs into runbook
- Document any deviations and update runbook accordingly

**Sub-phase I.4 — ADR 0012** (0.5 day, gated on I.3 completion)

- ADR 0012 — Paperclip Docker UID strategy and Postgres auth path (audit item 8)
- Decision deferred from Phase G; resolution informed by I.3 testing

### Acceptance criteria

- Runbook status: DRAFT-ready (not VERIFIED until first production deploy)
- Runbook references all required ADRs (0006-0010, 0012)
- Both systemd templates committed to `infra/systemd/`
- Verification section contains commands and expected outputs from real test execution
- Concerns section honestly flags any remaining unverified items

### Dependencies

- Phases F, G, H all complete (hardened-baseline runbook exists, ADRs 0006-0011 accepted, Restate hardened)
- Test VPS access
- Operator availability for sub-phase I.3 (multi-day execution)

### Out of scope for Phase I

- Production deployment to a paying-client VPS (separate engagement)
- Weft program archetypes (Phase J or later workstream)
- Paperclip SKILL.md authoring (separate workstream)

---

## Phase J — Wedge product MVP scaffolding

### Purpose

Build the revenue-generating wedge product per Foundation Document v1.1 Section 6 — the lead intake → qualification → Stripe Checkout → n8n delivery flow. This is what produces first revenue in Horizon 1.

This phase is **parallel-eligible** with Phases E through I. It does not depend on infrastructure audit fixes for non-regulated SMB clients — the substrate as it exists today is genuinely deployable for a first paying client.

### Strategic justification

Foundation Document v1.1 success metrics for Horizon 1 are "$5-15K USD revenue" and "1-3 case studies in public repo." Neither is achievable without Phase J running. Path D explicitly states "wedge funds the mission" — substrate perfection that delays revenue is a violation of Path D discipline.

### Work blocks

**Block J.1 — Lead intake** (1 day)

- Public form (Astro page on Cloudflare Pages or simple HTML on marketing site)
- Form posts to Tailscale Funnel endpoint hitting Weft `lead-intake` workflow
- Weft workflow validates input, persists to Postgres `leads` table, triggers qualification flow
- Out of scope: CAPTCHA (deferred until spam emerges as real problem)

**Block J.2 — Qualification** (1 day)

- Automated qualification scoring based on lead form fields
- Auto-qualified leads receive Stripe Checkout link via email
- Manual-review leads route to operator inbox for triage
- Qualification logic captured in Weft program, not n8n (architecture report Section 7)

**Block J.3 — Stripe Checkout integration** (1 day)

- Stripe Checkout session creation via Weft program
- Successful payment triggers `engagement-init` Weft workflow
- Failed/abandoned payments captured for follow-up
- Test mode + production mode both supported

**Block J.4 — n8n delivery workflow scaffolding** (1-2 days)

- Per-engagement n8n workflow instance creation
- Workflow templates per engagement type (defined in `08-projects/wedge-templates/` in private vault, public references via SKILL pattern)
- Workflow output back to Postgres `engagements` table
- Client-facing delivery artifact (PDF, dashboard, or workflow URL depending on engagement)

### Acceptance criteria for J as a whole

- End-to-end test: synthetic lead → qualification → Stripe Checkout (test mode) → workflow delivery → engagement record persisted
- All four blocks have runbooks committed to `infra/runbooks/wedge-product/`
- Public marketing page references the lead intake form
- Operator-side dashboard for engagement status (Plane.so per Foundation Document Section 6, deployed after first client)

### Dependencies

- Postgres runbook executed on EL VPS (already drafted, polished in Phase E)
- Weft runbook DRAFT-ready (Phase I) OR temporary scaffolding without Weft for first client (acceptable for non-regulated SMB)
- Stripe account active (already exists per Foundation Document)
- Domain DNS for marketing site (already exists per Foundation Document)
- n8n Standard tier license (already accepted per ADR 0003)

### Out of scope for Phase J

- Sovereign tier hosted deployment (blocked on n8n Embed license per ADR 0003)
- Full back-office portal (Foundation Document defers to after first client live)
- Multi-tenant client database (Postgres single-instance per ADR 0002 sufficient through first 5-10 clients)
- BAA / regulated-client engagement flow (gated on Phases F, G, I plus insurance per Foundation Document Section 9)

---

## Cross-phase considerations

### Phase parallelization map

```
[E: Quick wins]──┐
                 ├──>[F: Hardened baseline]──┐
                 │                            ├──>[I: Weft/Paperclip]──>[Production-ready]
                 ├──>[G: ADRs 0006-0011]──────┤
                 │                            │
                 └──>[H: Restate hardening]───┘

[J: Wedge product] runs parallel to all above
```

Phase J does not block on E-I. Operator can ship first paying client with current substrate plus J, then harden via E-I in parallel or after.

### Stop conditions (per phase)

Each phase has explicit stop-and-reassess triggers:

- **Phase E:** if any quick-win PR exposes a deeper gap not yet in audit, stop and update audit document before continuing.
- **Phase F:** if Lynis ≥ 90 cannot be achieved on Ubuntu 24.04 baseline, stop and reassess target (drop to ≥ 85 or escalate to higher hardening framework).
- **Phase G:** if any ADR cluster reveals a previously-undocumented architectural decision, stop and amend Foundation Document v1.1 before continuing.
- **Phase H:** if Restate version pin reveals incompatibility with current runbook, stop and reassess Restate adoption (does the architecture survive a different durable executor?).
- **Phase I:** if wire-up testing fails repeatedly, stop and consider whether Weft is the right substrate vs alternatives.
- **Phase J:** if first lead intake test reveals fundamental flow breakage, stop and reassess wedge product shape before continuing scaffolding.

### Acceptance criteria for the scope as a whole

This document (`docs/planning/next-phases-scope.md`) is considered fulfilled when:

- All 6 phases (E-J) reach acceptance criteria as defined per phase
- Audit document `docs/audit/2026-04-28-infrastructure-state-audit.md` has all 21 actionable items closed (with the explicit out-of-scope items remaining out of scope)
- Foundation Document v1.1 Horizon 1 success metrics are met ($5-15K revenue, 1-3 case studies, Lynis ≥ 90)

When fulfilled, this v1 scope document is superseded by a v2 document covering Horizon 2 work (SoverClaw, PII-redacting bridge, Trust Layer, ECS productization).

### Discipline notes

- Per Foundation Document Section 4.5 Principle 3 — "every public commit is a deposit toward trust." Each phase's PRs ship with public anonymization grep verification per established protocol.
- Per The Orchestration Framework's Files Over Memory principle — this scope document is canonical until amended. Memory or chat references are caching layers only.
- Per The Orchestration Framework's Decisions Are First-Class Objects — material scope changes go through ADRs, not amendments to this document.

---

**See also:**
- [Phase D infrastructure audit](../audit/2026-04-28-infrastructure-state-audit.md) — source of audit items E and H reference
- [Foundation Document v1.1](../vision/efficient-labs-foundation.md) — strategic foundation this scope serves
- [The Orchestration Framework](https://github.com/Neo-The-Architect/The-Orchestration-Framework) — operating methodology
