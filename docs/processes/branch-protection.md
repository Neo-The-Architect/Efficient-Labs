# Branch protection

This document describes the GitHub branch-protection settings that the Efficient Labs repository enforces (or aspires to enforce) on the `main` branch. Branch protection is configured through the GitHub UI (Settings → Branches → Branch protection rules); this file is the on-disk record of what should be configured there.

The file exists so that the repo's protection posture is reviewable from the repo itself. A future operator setting up a fork, an auditor evaluating the discipline, or the operator after a long break can read this file and know what should be true in the GitHub UI without having to log in to verify. When the GitHub UI and this file disagree, the file is the spec; the UI gets adjusted.

## Current rule set (`main`)

The settings below should be enabled on the `main` branch protection rule. Each is annotated with the reasoning, the current status (enabled / aspired), and any exceptions.

### Restrict who can push to `main`

**Setting:** Restrict pushes that create matching branches → enable. Also: Disallow force pushes; Disallow deletions.

**Status:** Enabled (sandbox-enforced and GitHub-enforced).

The sandbox in which Claude Code operates already refuses direct pushes to `main` — see the verification work that exercised this in the session preceding the seven-layer scaffold PRD. GitHub's branch protection adds the server-side enforcement so that the rule survives sandbox configuration drift. Force-pushes and deletions are also disallowed; `main` is append-only by merge.

The exception in normal operation: zero. Every change to `main` arrives through a PR.

### Require a pull request before merging

**Setting:** Require a pull request before merging → enable. Required approving reviews: 1.

**Status:** Aspired with a documented note for the solo workflow.

In a multi-engineer team, "1 required reviewer" means one engineer other than the author. In the Efficient Labs solo workflow, the operator is both the de facto author (through Claude Code authorization) and the only reviewer. GitHub's branch protection cannot distinguish "self-approval" from "approval by another engineer," and configuring 1 required reviewer in this context creates a permanent paperwork step where the operator approves their own PR.

The honest middle path is documented as follows:

- The setting is **aspired** — a follow-up issue tracks enabling it once the team is two engineers.
- Until then, the discipline is enforced by the operator following the [code review checklist](code-review-checklist.md) before merge, and by the PR description itself recording the review (the operator's `Approved` review or the merge action).
- The Claude Code commit-attribution convention (see [ADR 0004](../adr/0004-commit-attribution-claude-author-neo-reviewer.md)) means that even the solo workflow has an asymmetric author/reviewer pair on every PR — Claude as author, operator as reviewer-of-record. That pairing is what makes self-approval not a contradiction in this context.

When the team grows, this section is updated to remove the aspired-pending caveat.

### Require status checks to pass before merging

**Setting:** Require status checks to pass before merging → enable; require branches to be up to date before merging → enable.

**Status:** Aspired pending CI (Layer 3 of the seven-layer scaffold).

CI does not exist yet. When Layer 3 lands (lint, secret-scanning, structure-validation), the resulting checks become required status checks. Until CI exists, this section is the placeholder that will be filled in once the workflows are committed.

The minimum required checks once CI lands (anticipated, subject to revision when the CI PR is authored):

- `lint` — Markdown linting for documentation changes; YAML linting for `.github/` files; shell linting for any committed scripts.
- `secret-scan` — Push-protection-equivalent scan for secret patterns (gitleaks or equivalent).
- `structure-check` — Validation that ADR numbering is monotonic, that runbooks declare a status header, that linked files in `.md` documents resolve.

### Require conversation resolution before merging

**Setting:** Require conversation resolution before merging → enable.

**Status:** Enabled.

PR-thread comments are not noise; they are the record of the review. A merged PR with unresolved comments either silently abandons feedback or merges with known issues. Either is a discipline failure. The setting forces the explicit action: the comment is resolved (with a fix, with a "won't fix" rationale, with a follow-up issue) before merge.

### Require signed commits

**Setting:** Require signed commits → enable.

**Status:** Aspired. Documented asymmetry (see ADR 0004).

The current state: Claude Code commits are unsigned because the sandbox does not hold a signing key. Operator-authored commits are unsigned today because operator signing is not yet provisioned. Both are subject to PR review, which is the substitute trust signal.

The aspired state: operator-authored commits are signed with the operator's hardware key. Claude-authored commits remain unsigned (the sandbox is not a place a signing key should live), and the asymmetry is documented in [ADR 0004](../adr/0004-commit-attribution-claude-author-neo-reviewer.md) and in this file. The setting is enabled once the operator's signing key is provisioned and the Claude-author exception is noted as a known and accepted asymmetry.

A follow-up issue tracks the operator-key provisioning.

### Require linear history

**Setting:** Require linear history → enable.

**Status:** Enabled.

`main` is rebased or squash-merged, never merge-commit-merged. Squash merge is the default for PRs in this repo because each PR is one logical unit (one phase of a PRD, one fix, one feature) and the squashed commit message captures the unit's intent without preserving the WIP commits inside the branch.

The setting prevents accidental merge commits from breaking the linear history.

### Allow specified actors to bypass required pull requests

**Setting:** Disabled. No bypass list.

**Status:** Enabled (no bypass).

There is no operator role that bypasses the PR requirement. Even hotfixes go through a PR — the PR can be opened, approved, and merged in 60 seconds during an incident, but it is still a PR. The audit trail matters more than the speed of typing past the requirement.

## Rules not yet adopted

Settings GitHub offers that this repository does not currently use, with the reasoning:

- **Require deployments to succeed before merging.** Not applicable until there are deploy environments. Will be revisited when staging or production deploy automation lands.
- **Lock branch.** Not applicable; `main` is not a frozen branch, just a protected one.
- **Restrict pushes that bypass settings (admin enforcement).** Will be enabled once the asymmetric concerns above (signed commits, required reviews) are resolved. Until then, the operator's admin role is the unblock path during exceptional circumstances; admin enforcement is enabled when no exceptional circumstances are anticipated.

## Verification

The protection rules above are configured through the GitHub UI. To verify the configuration matches this document:

1. Navigate to the repository **Settings → Branches** page.
2. Inspect the protection rule applying to `main`.
3. Compare each enabled / disabled setting with the corresponding section above.
4. Where this document says "aspired," confirm that an issue is open tracking the enablement.

Discrepancies between the GitHub UI and this document are bugs. Either the document is updated to match a deliberate change to the UI (with the reasoning recorded), or the UI is corrected to match the spec. There is no acceptable steady state where the two disagree.

A future automation step (deferred to Layer 3 / CI) is to verify the configuration programmatically using the GitHub API. Until then, the verification is a manual step performed at each scaffold review.

## When to revise this document

- When a new branch protection setting is enabled or disabled, document the change here in the same PR.
- When the team composition changes (e.g. adds a second engineer) such that an "aspired" setting can be promoted to enabled, update the section.
- When a CI workflow lands that produces a new status check, add the check to the required-status-checks section.
- When an ADR ratifies a change to the protection posture, update accordingly.

The file is part of the repo's spec, not an artifact of one moment in time.
