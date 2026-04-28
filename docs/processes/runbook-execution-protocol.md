# Runbook execution protocol

This document is the operating discipline for authoring, executing, and verifying runbooks at Efficient Labs. It is the protocol that has produced every runbook in `infra/runbooks/` to date and that every future runbook must follow before it can be marked `VERIFIED`.

The protocol exists because runbook drift is the cheapest failure mode in the business: a runbook that worked once on a fresh host but is wrong on the next one will burn an entire afternoon and erode trust in the discipline. The cost of writing a runbook the right way is paid once; the cost of trusting a runbook that lies is paid forever.

## The four rules

### 1. Single-command discipline

A runbook step contains exactly one command (or one tightly coupled command pair, e.g. `cp` followed by `chmod` on the file just copied). The operator runs the command, observes the output, and confirms it matches the expected result before proceeding to the next step. Compound steps that bundle a `&&` chain of unrelated operations are forbidden — when something goes wrong in the middle of such a chain, the recovery point is ambiguous.

The exception is when the runbook has marked a sequence as a single semantic operation that is genuinely atomic (e.g. "edit the config file, then `systemctl restart` to apply" is one operation, not two). The marker is explicit: the section header names the semantic operation, and a single fenced code block contains the commands.

### 2. Stop on error

Any non-expected output is a stop. The runbook author cannot anticipate every error the operator will see; the runbook describes the happy path and a small set of named failure modes with documented recovery. If the operator sees output that is not the documented happy path and is not a documented failure, the protocol is: stop, do not improvise, capture the output, decide whether to escalate to runbook revision or to abort the operation.

The corollary is that runbooks must be honest about what the expected output is. A step that says "run this and continue" without telling the operator what success looks like is a step that cannot detect failure.

### 3. Two-window pattern

Runbook execution uses two terminal windows:

- **Operator window.** The window where the operator runs the actual commands against the host. This is the authoritative session — what is in this window is what is on the host.
- **Companion window.** The window where the operator can run read-only commands (`systemctl status`, `journalctl`, `ss -tlnp`, `ls`, `cat`) to verify state without disturbing the operator window's command history. This window is also where the operator copies-and-pastes from the runbook so that the operator window's history shows clean execution.

The pattern keeps the operator window clean for postmortem reading and lets the operator verify side effects without context-switching. It is light discipline — both windows are normal SSH sessions — and it pays back the cost the first time a step's expected verification command is needed in a hurry.

### 4. Verify before the next action

Every step is followed by an explicit verification — either a command whose output confirms the expected state, or a documented observation the operator must make in the companion window. Verification is not optional and is not deferred. A step that produces a side effect (a file written, a service restarted, a database created) is incomplete until the side effect is observed.

Verification commands belong in the runbook itself, not in the operator's memory. If the operator is supposed to run `systemctl status postgresql@16-main.service` and confirm `active (running)` after step 4, the runbook step ends with that command and that expected output.

## Capture corrections during execution, not after

The first execution of a runbook against a real host is also the runbook's verification pass. Errors found during the first execution — typos, missing prerequisites, version drift, output that does not match — are captured *as the operator hits them*, not after the runbook is done. The capture method is explicit:

- The operator opens a side note (a chat thread, a draft commit message, a sticky note — the medium does not matter, persistence does) and writes down the discrepancy as soon as it is observed.
- The operator does not fix the runbook in flight unless the fix is required to continue. The first execution is a verification pass; mid-execution edits compromise the verification by changing the artifact under test.
- After the runbook is complete (or aborted), the captured discrepancies are folded back into the runbook in a single revision PR. The PR's commit message lists every correction with a one-line rationale.

The cost of this discipline is modest: a few minutes of note-taking during execution. The cost of skipping it is high: discrepancies forgotten by the time the runbook is "done," and the next operator hits the same problems.

## Status discipline: DRAFT → VERIFIED

Every runbook carries a status header at the top:

- **`DRAFT`** — the runbook has been authored but has not been executed end-to-end against a real host. A draft is reviewable but is not yet trustworthy. The header should specify what the draft is awaiting (e.g. `DRAFT — pending operator deploy verification`).
- **`VERIFIED`** — the runbook has been executed end-to-end against a real host with no unresolved discrepancies. The header records the verification: who executed it, on what date, against what host (anonymized). Example: `VERIFIED — executed 2026-05-02 by operator on production VPS`.

A runbook may not be promoted from `DRAFT` to `VERIFIED` until:

1. The runbook has been executed end-to-end on a fresh host.
2. Every discrepancy captured during execution has been resolved (either folded into the runbook or explicitly waived with a note).
3. The verification commit is in the PR record, with the operator's review.

A `VERIFIED` runbook that is later found to be wrong is demoted to `DRAFT` until the bug is fixed and re-verified. There is no in-between status; either the runbook is currently trustworthy or it is not.

## Concrete example: the Postgres install runbook (Saturday, 2026-04-25 onward)

`infra/runbooks/install-postgres.md` is the working example for this protocol. The runbook was drafted Saturday from architecture report Section 6 plus the operator's prior experience installing Postgres on Ubuntu hosts. The draft was committed with status `DRAFT — pending operator deploy verification` and remains in that state at the time this protocol document is written.

When the operator executes the runbook for real (planned for the deployment session following the audit covered in Phase D of the seven-layer scaffold PRD), the protocol prescribes:

1. **Single-command discipline already applied in authoring.** Each step is one fenced code block per semantic operation. The PGDG repo install (step 1) is a four-command sequence treated as one atomic operation; it is fenced as one block with the documented expected outcome (the `apt install -y postgresql-16` line completes without error).
2. **Stop on error is documented per step.** Step 3 ("Back up the default config files before editing") names the recovery path explicitly: `cp <file>.orig <file>` and `systemctl restart postgresql@16-main` if a later step breaks the cluster. Steps without documented recovery require the operator to stop and escalate.
3. **Two-window pattern is required.** The operator window runs the PGDG install and the configuration edits. The companion window runs `systemctl status postgresql@16-main`, `ss -tlnp | grep 5432` (to confirm localhost-only binding), and `sudo -u postgres psql -c '\l'` (to confirm the two databases exist after step N).
4. **Verification commands live in the runbook.** The runbook does not say "verify the cluster is up" — it says `sudo systemctl status postgresql@16-main` with the expected `active (running)` output. Step 2 is a worked example of this convention.

The corrections discipline is what produces the runbook's first revision PR after the verification pass. Anticipated correction surface, from the runbook's drafting context: the PGDG repo URL or signing key fingerprint may change between drafting and execution; the pgvector or pgaudit extension setup may need a slightly different command on a fresh 24.04 host than the runbook assumes; `pg_hba.conf` ordering may need adjustment for the two-role / two-database scheme. None of these are blockers; all are the kind of small reality-check the verification pass exists to catch.

## Authoring a new runbook

The conventions captured in `infra/runbooks/install-postgres.md` are the format other runbooks follow:

- Start with `# Runbook: <title>` and the `**Status:**` line.
- One-paragraph statement of what the runbook does and why, with explicit reference to any ADR that constrains the decisions inside.
- Portability statement (no host-specific identifiers, no real passwords) so that another operator could fork the repo and run the runbook on their own host.
- `## Purpose`, `## Prerequisites`, `## Steps` as the top-level sections.
- Numbered steps under `## Steps`, each with a `### N. <action>` header, a one- or two-paragraph context block explaining *why* the step is necessary, the command(s) in a fenced code block, and the verification.
- A closing `## Verification` section that lists the end-to-end checks the operator runs to confirm the runbook is complete and the system is in the expected state.
- A closing `## Rollback` section that lists the steps to undo the runbook, in the order they should be performed, with the same single-command and verify-before-next discipline.

Runbooks that omit `## Rollback` are incomplete. There is no operation in the production fulfillment surface that does not need a documented undo path.
