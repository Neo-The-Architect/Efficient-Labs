# Infrastructure state audit — 2026-04-28

**Author:** Claude Code (sandbox)
**Reviewer-of-record:** NeoTheArchitect (operator, on PR review)
**Branch:** `chore/audit-existing-runbooks-2026-04-28`
**Auditor stance:** Findings only. No auto-fixes. Operator authorizes fixes as separate PRs.

## Executive summary

Three infrastructure runbooks and one architecture-report snapshot were audited as a desk audit (no commands executed against a test VPS). The Postgres and Restate runbooks are substantively close to deploy-ready and exhibit good discipline (verification commands, rollback paths, security posture aligned with ADR 0002 and ADR 0005). The Weft/Paperclip runbook remains a stub and **is the single most consequential gap** — the architecture report's Week-1 milestone cannot be hit until that runbook is brought to DRAFT-ready and 5–7 prerequisite ADRs land. A cross-cutting **serious** finding is that both runnable runbooks reference a "hardened baseline" prerequisite that has no documented procedure on disk; this gap blocks honest execution of either runbook by anyone other than the operator.

**Severity counts:** 1 blocker, 11 serious, 9 minor across the four artifacts.

The architecture report shows minor staleness in prescriptive ADR numbering (Section 8 predicts ADR numbers that the actual ADRs do not match) but no substantive contradictions with ADRs 0001–0005. The report stays as a 2026-04-27 snapshot; ADRs supersede where divergence exists.

## Methodology

- **Scope:** read each artifact in full; compared each against the relevant ADRs (0001–0005) and the architecture report's Section 5, 7, 8, 9 commitments; checked for internal consistency, security-posture alignment, verification depth, and rollback completeness.
- **Not in scope:** executing any command against a real Ubuntu 24.04 host; verifying upstream package versions against live registry data; verifying Restate or Weft binary release naming against the current GitHub releases page (the audit mark these as *unverified pending VPS test*); reviewing legal-policy stubs (Phase C scope, not Phase D).
- **Severity definitions used:**
  - **Blocker** — a deploy run cannot honestly proceed without addressing this.
  - **Serious** — high-confidence issue that would cause a deploy-time failure or a documented gap that compounds risk; resolvable but should be addressed before first paying client.
  - **Minor** — polish, future-proofing, hardening that is not load-bearing for week-1 deploy.
- **Confidence:** desk-audit confidence. Items marked *unverified pending VPS test* require a real test execution to confirm.

## Findings — Artifact 1: `infra/runbooks/install-postgres.md`

**Overall:** Substantively close to deploy-ready. ADR 0002 alignment is excellent. Verification depth is strong (test-restore is included, which is the most-skipped verification step in industry). Concerns section honestly flags five real concerns. Issues below are mostly polish, with one serious deploy-time risk on password generation.

### Serious

1. **Password generation produces URL-unsafe characters that will break `DATABASE_URL`.**
   - File: `infra/runbooks/install-postgres.md`, line 342.
   - Current: `openssl rand -base64 32` produces 43-char base64 strings containing `/`, `+`, `=`. The Secrets section then writes these into `DATABASE_URL=postgres://paperclip:${PAPERCLIP_PG_PASSWORD}@127.0.0.1:5432/paperclip` (line 351). Postgres' libpq URL parser does not natively decode unencoded `/` or `+` in the password segment; deployments will fail or silently use the wrong password.
   - Fix: change to `openssl rand -hex 32` (64 hex chars, URL-safe), or pipe through `tr -d '/+='` and document the slight entropy reduction, or document URL-encoding explicitly as a deploy-time step. Recommended: switch to `-hex 32`.
   - Effort: 5 minutes. One-line edit plus a comment explaining why hex.

2. **Hardened-baseline prerequisite is undocumented (cross-cutting).**
   - File: `infra/runbooks/install-postgres.md`, line 21 ("Hardened baseline already in place — Lynis ≥ 85, Tailscale-only ingress, no public TCP except those exposed deliberately via Funnel").
   - There is no runbook in `infra/runbooks/` that produces this hardened baseline. ADR 0005 documents the Tailscale SSH posture (one component) but not the full baseline (Lynis run, ufw rules, unattended-upgrades, kernel parameters, fail2ban, etc.).
   - A reader following this runbook on a fresh Ubuntu 24.04 host will land on step 1 with no guidance for the prerequisite, and will either skip it (silent insecurity) or invent their own (drift).
   - Fix: author `infra/runbooks/harden-vps-baseline.md` as a separate runbook before the next deploy. Same severity finding applies to the Restate runbook.
   - Effort: 1–2 working days to author and verify, including running Lynis end-to-end on a test VPS.

### Minor

3. **`apt update` ordering at step 1.**
   - File: `infra/runbooks/install-postgres.md`, line 35.
   - Current: `sudo apt install -y curl ca-certificates gnupg lsb-release` runs without a preceding `sudo apt update`. On a freshly cloud-init'd Ubuntu 24.04 image this typically works (cloud-init refreshed the cache during boot), but on an arbitrary 24.04 host with stale cache the install may fail or pick the wrong package version.
   - Fix: prepend `sudo apt update &&` to line 35.
   - Effort: <5 minutes.

4. **`gnupg` package installed but unused.**
   - File: `infra/runbooks/install-postgres.md`, line 35.
   - The signed-by approach uses the `.asc` armored key file directly. There is no `gpg --dearmor` step, so `gnupg` is not needed.
   - Fix: remove `gnupg` from the apt install line.
   - Effort: <5 minutes.

5. **Backup script provenance for `/tmp/postgres-backup.sh` is implicit.**
   - File: `infra/runbooks/install-postgres.md`, lines 207–231.
   - The script body is shown in a code block, then `sudo install -m 0750 -o root -g postgres /tmp/postgres-backup.sh /usr/local/bin/postgres-backup.sh` is run — but the runbook does not explicitly say to write the code block's contents to `/tmp/postgres-backup.sh` first. A literal-following operator would hit "no such file or directory."
   - Fix: prepend a step that uses a heredoc to write the script to `/tmp/postgres-backup.sh`, or instruct the operator to commit the script under `infra/scripts/postgres-backup.sh` and `install` from the checked-out repo path.
   - Effort: 10 minutes.

6. **Backup systemd unit runs as root, then `sudo`s to postgres internally.**
   - File: `infra/runbooks/install-postgres.md`, lines 234–245.
   - The unit has no `User=` directive, so it runs as root. The script then `sudo -u postgres pg_dump ...`. Cleaner: set `User=postgres` in the unit and drop the `sudo` from the script. Less privilege at the systemd boundary.
   - Fix: add `User=postgres` and `Group=postgres` to the `[Service]` section; drop `sudo -u postgres` from the script.
   - Effort: 10 minutes plus re-test.

7. **Cross-runtime memory budget mismatch with Restate runbook prereq.**
   - File: `infra/runbooks/install-postgres.md`, line 22 (≥ 2 GB RAM) vs. `infra/runbooks/install-restate.md`, line 39 (≥ 4 GB total when both runtimes coexist).
   - The Postgres runbook's standalone 2 GB minimum is correct *for Postgres alone* but the operator following it for the EL VPS (which will host Postgres + Restate + Weft + Paperclip) needs the stricter total. The Restate runbook calls this out; the Postgres runbook does not back-reference.
   - Fix: add a line in the Postgres prereq section: "On the EL VPS (which co-hosts Restate, Weft, Paperclip), see `install-restate.md` for the full-stack RAM minimum (≥ 4 GB)."
   - Effort: 5 minutes.

8. **`pg_hba.conf` `peer` line for `paperclip-in-Docker` is documented but architecture decision is deferred.**
   - File: `infra/runbooks/install-postgres.md`, lines 358 (Concerns).
   - The runbook honestly notes that Paperclip-in-Docker hits the `host ... scram-sha-256` line because the Docker container's UID does not match the host's `paperclip` UID. The "cleaner Docker config" (UID mapping + socket bind-mount) is deferred to the Weft/Paperclip runbook. This is a real architectural decision (do we tighten Docker's UID namespace, or do we accept loopback password auth as the working default?) and it is currently parked in a Concerns paragraph rather than ADR'd.
   - Fix: open an ADR (`ADR 0006 — Paperclip Docker UID strategy and Postgres auth path`) when the Weft/Paperclip runbook is brought to DRAFT-ready.
   - Effort: 0.5 working day for the ADR; gated on Weft/Paperclip runbook authoring.

## Findings — Artifact 2: `infra/runbooks/install-restate.md`

**Overall:** Strong runbook, especially for a single-binary durable executor with version-schema drift risk. License acceptance, BUSL-1.1 acknowledgement, systemd hardening directives, and Tailscale-Serve-not-Funnel for admin access are all correctly handled. Six serious findings reflect *unverified-pending-VPS-test* gaps that the runbook itself acknowledges in its Concerns section — those are honest gaps, but they remain gaps until closed.

### Serious

9. **Healthcheck path is unspecified — verification step requires deploy-time discovery.**
   - File: `infra/runbooks/install-restate.md`, lines 317–319 (Verification: `curl -fsS http://127.0.0.1:9070/<HEALTH_PATH>`).
   - The runbook acknowledges this in Concerns (line 394) but the verification block uses a literal `<HEALTH_PATH>` placeholder. The operator hitting this step has to consult `restate-server --help` and `journalctl -u restate` to discover the real path.
   - Fix: pin a Restate version, run `restate-server --help` against it, capture the actual healthcheck path, commit. Pairs with the version-pinning gap (item 10).
   - Effort: 30 minutes once a Restate version is pinned and a test VPS is available.

10. **`<RESTATE_VERSION>`, `ARCH`, and tarball naming are all unverified.**
    - File: `infra/runbooks/install-restate.md`, lines 43, 53–54.
    - The pinned version is a placeholder. The architecture (`x86_64-unknown-linux-musl`) is hardcoded. The tarball naming pattern (`restate-server-${ARCH}.tar.xz`) is the runbook's best guess at Restate's release-asset naming — not verified against any specific release.
    - Fix: pick a Restate version (e.g. the latest stable from `github.com/restatedev/restate/releases`), download against the actual asset name from that release, update the runbook with the verified naming pattern, and add an ARCH-detection line (`ARCH=$(uname -m)-unknown-linux-musl`).
    - Effort: 30 minutes including download and checksum verification.

11. **Restate config schema is unverified against any specific Restate version.**
    - File: `infra/runbooks/install-restate.md`, lines 102–125 (the config block) and 393 (Concerns).
    - The keys (`worker.storage-rocksdb.path`, `[ingress]`, `[admin]`, `cluster-name`, `node-name`, `[rocksdb]`) are best-effort against late-1.x. The runbook flags this honestly. But the config block as written may not work against the actual pinned binary.
    - Fix: pin a version, validate the config against that version's schema (per Concerns, the validation subcommand name varies — discover via `--help`), update keys if needed.
    - Effort: 1–2 hours after version pinning.

12. **`restate.service.template` mirror command path is wrong (will not execute).**
    - File: `infra/runbooks/install-restate.md`, lines 197–200.
    - Current: `sudo cp /etc/systemd/system/restate.service /home/<OPERATOR>/workspace/efficient-labs/infra/systemd/restate.service.template`.
    - The path `/home/<OPERATOR>/workspace/efficient-labs/...` is the sandbox path, not a path that exists on the EL VPS. An operator following this verbatim on the VPS will get "No such file or directory."
    - Additionally: `infra/systemd/` is empty in the repo today (verified). The template should live in the repo first and be deployed *to* the VPS, not copied *from* the VPS to a workstation.
    - Fix: invert the flow — author `infra/systemd/restate.service.template` in the repo, then in the runbook step 5 say `sudo install -m 0644 -o root -g root <repo-checkout>/infra/systemd/restate.service.template /etc/systemd/system/restate.service`.
    - Effort: 15 minutes for the runbook edit; pairs with item 13.

13. **`OnFailure=` alert path is commented out — architecture demands it be live.**
    - File: `infra/runbooks/install-restate.md`, lines 170–172.
    - Architecture report Section 5 (the multi-component fallback table) explicitly says "Restate down means Weft executions stall" and the right response is "systemd auto-restart plus an operator alert." The `OnFailure=restate-failure-alert.service` line is present but commented out, so the alert side of the contract is not wired.
    - Fix: define the `restate-failure-alert.service` unit (a oneshot that POSTs to a Discord webhook or sends an email), commit it under `infra/systemd/`, uncomment the `OnFailure=` line.
    - Effort: 0.5 working day to define and verify the alert path. Gated on operator's chosen alert channel.

14. **Hardened-baseline prerequisite is undocumented (cross-cutting; same as item 2).**
    - File: `infra/runbooks/install-restate.md`, line 37.
    - Same gap as Postgres runbook. Fix is shared.

### Minor

15. **`tar` snapshot trap leaves partial files on tar failure.**
    - File: `infra/runbooks/install-restate.md`, lines 254–259.
    - If `tar` fails, `set -e` exits the script, the `EXIT` trap fires (Restate restarts — good), but the partial `.tar.zst` file remains. The retention prune at the bottom (`find ... -mtime +14`) does not run because of `set -e`. A failed snapshot leaves residue that an operator must clean up manually.
    - Fix: add a cleanup step in the trap that removes a partial DST if the script did not reach the prune step.
    - Effort: 15 minutes.

16. **Tailscale Serve CLI invocation should be verified against the current Tailscale version.**
    - File: `infra/runbooks/install-restate.md`, line 223.
    - `sudo tailscale serve --bg --https=9070 http://127.0.0.1:9070` looks plausible but Tailscale Serve's CLI has gone through revisions. Worth validating against the current `tailscale --version` on the VPS.
    - Fix: validate at deploy time; capture exact invocation.
    - Effort: 5 minutes at deploy time.

## Findings — Artifact 3: `infra/runbooks/install-weft-and-paperclip.md`

**Overall status:** Stub. The stub itself is honest (heavy use of TODO markers; clearly labels incomplete decisions). The defect is not the stub *as a stub* but the dependency chain that blocks bringing it to DRAFT-ready.

**Architectural significance:** The architecture report Section 8 names "Pre-week zero" as the time to land Weft, Paperclip, Postgres, and Restate on the VPS. Postgres and Restate runbooks exist (with the gaps audited above). **Weft/Paperclip is the only remaining substrate runbook for week-1 deploy.** Until it is DRAFT-ready, the architecture's Week-1 milestone cannot be hit honestly.

### Blocker

17. **Stub status blocks Week-1 deploy per architecture report Section 8.**
    - File: `infra/runbooks/install-weft-and-paperclip.md` (entire file is 79 lines, mostly bullet stubs).
    - This is a stop-deploy item. Postgres + Restate + a missing Weft/Paperclip runbook is not a deployable stack.
    - Fix path: see "Effort estimate" below; gated on the ADRs in Serious findings 18–20.
    - Effort: 4–6 working days end-to-end (see breakdown in finding 21).

### Serious

18. **5 ADRs are needed before substantive runbook authoring is possible.**
    - File: dependencies of `infra/runbooks/install-weft-and-paperclip.md`, by line:
      - **Line 13 — Weft pinning vs vendoring.** Pin upstream commit SHA, or vendor `github.com/WeaveMindAI/weft` into a fork at `efficient-labs/weft-pinned`? Architecture report Section 9 names vendoring as the mitigation but does not formalize. Need an ADR.
      - **Line 14 — Paperclip image SHA pinning policy.** Architecture report Section 9 says "pin to specific image SHAs, not `:latest`" and mentions a fortnightly upgrade ritual. Not yet ADR'd. Need an ADR with cadence and rollback procedure.
      - **Line 39 — Docker-run-via-systemd vs Docker Compose for Paperclip.** Runbook prefers plain Docker via systemd ("one runtime less"), but the decision is parked in a comment. Need an ADR.
      - **Cross-reference — Weft license acceptance.** O'Saasy MIT-with-SaaS-restriction (architecture report Section 9). Analogous to the BUSL-1.1 acceptance for Restate but not yet recorded. Need an ADR or an addition to the runbook's License section.
      - **Line 44 — Paperclip secret-reference syntax for env-var injection.** "TODO: confirm Paperclip's secret-reference syntax" — this gates how the Anthropic API key reaches Paperclip. Either an ADR (if it's a policy choice) or a verified note in the runbook (if it's just doc-discovery work).
    - Fix: open these ADRs (or merge multiple into one ADR if the operator prefers fewer artifacts) before runbook authoring resumes.
    - Effort: 1–2 working days for the ADR work, mostly research and confirmation against upstream docs.

19. **2 additional ADRs may be needed depending on architecture report intent.**
    - **Tailscale Funnel exposure of Weft webhook surface.** Architecture report Section 6 says webhooks land at `efficient-labs.tailnet.ts.net/hooks/lead`. Funnel exposes this publicly — the only inbound public TCP path on the VPS. Significant surface; deserves its own ADR.
    - **Public lead-intake URL pattern.** Where exactly the webhook is exposed and what host it serves under. Depends on the Funnel ADR.
    - Fix: draft when the Funnel decision is formalized.
    - Effort: 0.5 working day.

20. **Wire-up testing requires VPS access and end-to-end integration.**
    - File: `infra/runbooks/install-weft-and-paperclip.md`, lines 51–69 (Wire-up section + Verification).
    - The verification section names integration assertions ("a trivial Weft program runs end-to-end and persists state in `weft` database"; "Weft → Paperclip HTTP call lands as a real Issue"). These cannot be authored credibly without first running them against a real VPS with both runtimes installed.
    - Fix: provision a test VPS or use the EL VPS itself in a sandbox-mode capacity; run the procedure once; capture exact commands and expected outputs.
    - Effort: 1–2 working days, gated on (a) Weft installable and (b) Paperclip installable, both of which depend on the ADRs above.

### Effort estimate to DRAFT-ready

21. **Total: 4–6 working days, sequenced.**
    - **Phase 1 (1–2 days):** open and close the 5 prerequisite ADRs (item 18).
    - **Phase 2 (1–2 days):** author Weft side of runbook against pinned commit SHA; author Paperclip side against pinned image SHA; commit `infra/systemd/weft.service.template` and `infra/systemd/paperclip.service.template`.
    - **Phase 3 (1–2 days):** wire-up testing on a real VPS (item 20); update runbook with verified commands and outputs.
    - The estimate excludes time for the cross-cutting hardened-baseline runbook (item 2) which both runtimes also depend on.

## Findings — Artifact 4: `docs/architecture/2026-04-27-fulfillment-architecture-report.md`

**Stance:** Audit for staleness only. The report is a 2026-04-27 snapshot; it stays as-is. ADRs supersede where they diverge.

### Minor

22. **Prescriptive ADR numbering at Section 8 is off-by-N from actual numbering.**
    - File: `docs/architecture/2026-04-27-fulfillment-architecture-report.md`, lines 296, 298, 300.
    - Specifically:
      - Line 296: "Velocity gate: ADR 0004 captures the Weft-vs-Paperclip boundary decision." Reality: ADR **0001** does this.
      - Line 298: "Velocity gate: ADR 0005 documents the n8n license decision (Standard tier only for now, Sovereign tier blocked on Embed conversation)." Reality: ADR **0003** does this; the actual ADR 0005 is the Tailscale SSH posture.
      - Line 300: "Velocity gate: ADR 0006 documents the Architecture-B decision and the Architecture-C escape hatch." Reality: this ADR has not been written.
    - These were predictions about ADR sequencing. They didn't survive contact with the actual operating cadence (ADRs 0001, 0002 landed Apr 27; ADRs 0003, 0004 followed; ADR 0005 captured a posture not anticipated in Section 8). The predictions are stale; the underlying decisions either exist (different ADR number) or remain to be written (Architecture-B/C decision).
    - Stance: do not edit the report. ADR cross-reference table (in `docs/adr/README.md`) is authoritative for current numbering.
    - No fix proposed.

23. **Tailscale Free tier specifics may have drifted.**
    - File: `docs/architecture/2026-04-27-fulfillment-architecture-report.md`, line 324 ("Personal plan is 6 users, unlimited devices, 3 ACL groups, 50 tagged resources, Funnel and Serve included, network flow logs Premium-only").
    - Tailscale's tier offerings and limits have shifted over time. The specific numbers should be verified against current Tailscale pricing before any tier-related decision lands.
    - Stance: do not edit the report. Verify at next Tailscale-relevant decision point.
    - No fix proposed.

### No contradictions found

24. **ADRs 0001, 0002, 0003, 0004, 0005 are consistent with the report.** No edits to the report are recommended. ADR 0005 (Tailscale SSH) covers a posture the report did not articulate; ADR 0004 (commit attribution) covers a topic the report did not address. Both fill gaps without contradicting the report.

## Cross-cutting findings

### Serious

25. **No hardening-baseline runbook on disk.** Already counted in items 2 and 14. Listed once here as a single discrete fix.
    - Recommended fix: author `infra/runbooks/harden-vps-baseline.md`. Coverage: Lynis run + remediation, ufw rules, OpenSSH `systemctl mask` per ADR 0005, unattended-upgrades, kernel parameter tuning (sysctl), fail2ban-or-equivalent posture, time/NTP, AppArmor profile state.
    - Effort: 1–2 working days.

26. **`infra/systemd/` is empty; both Postgres and Restate runbooks reference templates that are not on disk.**
    - Verified: `ls infra/systemd/` returns empty.
    - Postgres runbook does not require a template (`postgresql.service` is package-managed); not a defect for Postgres specifically.
    - Restate runbook (item 12) instructs the operator to `cp` from `/etc/systemd/system/` to a non-existent path; the cleaner flow is to commit `infra/systemd/restate.service.template` first.
    - Weft/Paperclip runbook (item 18) names `infra/systemd/weft.service.template` and `infra/systemd/paperclip.service.template`; both missing.
    - Recommended fix: commit at least the Restate template now (the unit body is in the runbook); commit Weft and Paperclip templates as part of bringing that runbook to DRAFT-ready.
    - Effort: 30 minutes for Restate template.

## Summary recommendations — fixes needed before deploy

Sorted by severity, then by effort. Each is a candidate for a separate operator-authorized PR.

### Blockers

1. **Bring `install-weft-and-paperclip.md` to DRAFT-ready.** Item 17. Effort: 4–6 working days, sequenced; depends on items 18 (ADRs), 19 (Funnel ADRs), 20 (wire-up testing).

### Serious

2. **Switch Postgres password generation to `openssl rand -hex 32`.** Item 1. 5 minutes.
3. **Author `infra/runbooks/harden-vps-baseline.md`.** Items 2, 14, 25. 1–2 working days.
4. **Pin a Restate version; verify config schema, healthcheck path, ARCH/tarball naming against that version.** Items 9, 10, 11. 1–2 hours plus 30 minutes for asset verification, gated on test VPS access.
5. **Rewrite Restate `restate.service.template` flow to deploy from repo, not `cp` from VPS.** Item 12. 15 minutes plus the template commit (item 26).
6. **Wire `restate-failure-alert.service`; uncomment `OnFailure=` in Restate unit.** Item 13. 0.5 working day.
7. **Open the 5 prerequisite ADRs for Weft/Paperclip runbook.** Item 18. 1–2 working days.
8. **Open the 2 Tailscale-Funnel-related ADRs.** Item 19. 0.5 working day.

### Minor

9. **`apt update` ordering, `gnupg` removal, backup-script provenance, `User=postgres` on backup unit, RAM cross-reference.** Items 3, 4, 5, 6, 7. ~1 hour total, bundled into one Postgres-runbook polish PR.
10. **Tar-snapshot partial-file cleanup; Tailscale Serve invocation verification.** Items 15, 16. 20 minutes plus deploy-time check.
11. **ADR 0006 — Paperclip Docker UID strategy.** Item 8. 0.5 working day; gated on Weft/Paperclip runbook DRAFT-ready.
12. **Commit Restate systemd template under `infra/systemd/`.** Item 26 (Restate part). 30 minutes.

## Out of scope

The audit did not cover the following. Each is a candidate for a future audit or a separate work item.

- **Backblaze B2 backup-shipping runbook.** Referenced by both Postgres and Restate runbooks (Tuesday work per the runbooks themselves) but not yet drafted.
- **Marketing site deployment runbook.** Astro on Cloudflare Pages per architecture report Section 6. Not yet drafted.
- **Cloudflare Pages configuration.** Includes DNS, certificate management, and the `efficient-labs.tailnet.ts.net` Funnel mapping for the Weft webhook surface.
- **Tailscale ACL snapshot.** ADR 0005 names this as a follow-up gap (`infra/tailscale/acl-snapshot.md`); not yet committed.
- **Hostinger emergency console runbook.** ADR 0005 names this as a gap (recovery path when Tailscale control plane is unreachable). Not yet drafted.
- **Actual VPS test execution.** No commands were run against any host during this audit. Items marked *unverified pending VPS test* require a real test execution.
- **Weft program archetypes, Paperclip SKILL.md authoring, n8n archetype taxonomy.** All architecture-substrate work, not infrastructure-runbook scope.
- **`legal/` review.** Phase C scope. Counsel review is the operative trigger, not this audit.
- **Architecture report substantive review.** This audit is staleness-only per the operator's scope.
- **Marketing site source.** Architecture, layout, content — separate workstream.

## Confidence note

This is a desk audit. Two classes of finding are explicitly unverified:

1. **Items requiring a real Restate version pin** (findings 9, 10, 11): confidence is "the runbook honestly flags these gaps; the gaps are real." Resolution requires a test-VPS deploy.
2. **Items requiring upstream-asset verification** (Restate tarball naming, Tailscale CLI flags): confidence is "the patterns are plausible against community norms; they should be checked against current upstream artifacts at deploy time."

For everything else, confidence is "high — the issue is identifiable from the runbook text alone and would surface during a deploy attempt."
