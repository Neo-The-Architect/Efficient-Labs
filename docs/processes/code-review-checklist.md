# Code review checklist

This document is the self-review checklist for the Efficient Labs solo+AI workflow. It is honest about the constraint: there is one human reviewer (the operator) on every PR, and the substantive engineering work in those PRs is performed by Claude Code in a sandbox. The traditional "second pair of eyes" review model — two engineers, one author and one reviewer — does not apply. The discipline that replaces it is structured self-review using this checklist.

The checklist exists because solo review without structure trends toward rubber-stamping, especially under time pressure. With the checklist, the operator is doing the same discrete checks every time, in the same order, and the artifacts produced (PR descriptions, commit messages, the diff itself) carry the discipline forward to a future reviewer who was not there.

## When to apply this checklist

Every PR before merge to `main`. No exceptions for "small" PRs — small PRs are where the most embarrassing mistakes hide, because the operator's attention is calibrated to the size of the diff rather than to the importance of what the diff touches.

The checklist is also applied by Claude Code as a *self-check* before opening a PR. The PR description's "Discipline check" section in the PR template (see [`.github/PULL_REQUEST_TEMPLATE.md`](../../.github/PULL_REQUEST_TEMPLATE.md)) records the result of that self-check; the operator's review uses this document to verify the self-check was honest.

## The checklist

### 1. Scope match

- [ ] Does the PR do what the linked issue, PRD, or chat authorization said it would do?
- [ ] Does the PR do **only** that? No silently-expanded scope, no "while I was in there" adjacent fixes.
- [ ] If the PR introduces something not authorized in the original scope, is that addition itself called out explicitly in the PR description and justified?

The single most common solo+AI failure mode is silent scope expansion. The executor sees a related issue and folds in a fix because "it's right there." The PR becomes harder to review, the diff becomes harder to revert, and trust in the artifact erodes. Adjacent fixes go in their own PR with their own authorization — even if it costs an extra round-trip.

### 2. Honest framing

- [ ] Are stubs marked as stubs? (Search the diff for "stub" — every stub document should be explicit about its stub status.)
- [ ] Are inferences distinguished from on-disk facts? (When the executor wrote "the system is X," is X actually verifiable from the workspace, or is X an inference the reviewer needs to ratify?)
- [ ] Are deferred items deferred (with a tracking issue), not silently dropped?
- [ ] Where the executor describes "what was decided" or "what is true," is the source of that statement traceable — to an ADR, a runbook, a chat artifact, or the executor's own inference?

The build-in-public credibility of this repo depends on the artifacts telling the truth about themselves. A PR that overstates the current state of the system — claiming a stub is substantive, claiming an inference is fact — is a credibility-erosion event the moment a careful reader notices.

### 3. Diff coherence

- [ ] Does the diff make sense to a future reader who was not in the conversation that produced it? Pretend you have never seen this PR before; would you understand the change from the diff and the PR description alone?
- [ ] Are commit messages in the conventional-commit style and the imperative voice?
- [ ] Are the file changes coherent as a single unit? (For multi-phase scaffolds, each phase is one PR; for fixes, one PR per fix.)
- [ ] Is there any dead code, commented-out code, or unused import that crept in during execution? (Discipline rule: do not leave landmines for the next reviewer.)

### 4. Verification documented

- [ ] For runbook PRs: is the runbook's status header accurate (DRAFT vs VERIFIED)? Has any DRAFT-to-VERIFIED promotion been done by an actual fresh-host execution, not just by a code review?
- [ ] For code or script PRs: are the test commands run and their output documented in the PR description?
- [ ] For documentation PRs: are the cross-references checked (every link in the new files resolves; every link from existing files into the new files resolves)?
- [ ] For configuration PRs: is the rollback plan concrete and executable? Would the operator on duty during an incident be able to run it without re-deriving it?

### 5. Secrets and portability

- [ ] No real passwords, API keys, tokens, or credential strings in the diff. (Search for `password`, `secret`, `key`, `token`, `BEGIN PRIVATE`, `BEGIN OPENSSH`, and obvious provider prefixes like `AKIA`, `sk-`, `gho_`, `xoxb-`.)
- [ ] No real hostnames, IP addresses, or vendor-specific identifiers in runbooks where portability is a stated goal.
- [ ] No `.env` files committed.
- [ ] No personally-identifying information (operator's home address, phone number, full legal name beyond what is already public).

The Efficient Labs repo is public from day one. Anything committed is committed permanently — even after a force-push to delete it, GitHub's caches and any cloned forks retain the data. Treat every commit as if it will be public forever, because it will be.

### 6. Operability (for changes that touch the live system)

- [ ] Would the operator be willing to execute this against the production VPS? If the answer is "not without changes," request changes.
- [ ] Is the change reversible? If not, is the irreversibility called out and the operator's authorization clearly recorded?
- [ ] Does the change preserve the hardened baseline (Lynis ≥ 85, Tailscale-only ingress, no public TCP except those exposed deliberately via Funnel)? See [ADR 0005](../adr/0005-tailscale-ssh-as-primary-access-path.md).
- [ ] If the change introduces a new service or dependency, is the licensing posture verified? (See [ADR 0003](../adr/0003-n8n-licensing-posture-standard-tier-only-week-1.md) for a worked example of why licensing checks matter.)

### 7. Documentation discipline

- [ ] Did this PR introduce a decision worth recording as an ADR? If so, is the ADR in the PR (or filed as a follow-up issue with explicit acknowledgment that the decision is unrecorded until the ADR lands)?
- [ ] Did this PR change a process? If so, is the corresponding process document updated?
- [ ] Did this PR change something user-facing or noteworthy? If so, is `CHANGELOG.md` updated?
- [ ] Are all internal links in the changed files still valid? (No stale references to renamed or moved files.)

## What this checklist does not replace

- **It does not replace running the runbook.** Reviewing a runbook PR for clarity and discipline is different from executing the runbook. DRAFT runbooks are reviewable but are not promoted to VERIFIED until they have been executed end-to-end.
- **It does not replace external review for high-risk paths.** Substantive legal documents (`legal/*.md`) are DRAFT pending legal review; the operator's self-review does not ratify them as legally binding. Substantive security claims may benefit from an external auditor's review before being treated as marketing-ready.
- **It does not replace the operator's judgment.** The checklist surfaces the discrete questions; the operator decides what answers are good enough. A PR that passes every checkbox but feels wrong is allowed to be sent back. The discipline is the floor, not the ceiling.

## Updating the checklist

This checklist evolves when the workflow evolves. New failure modes that are not caught by the current checklist become new checkboxes; obsolete checkboxes are removed when the workflow no longer produces the failure mode they catch. Updates land through PRs reviewed by the operator like any other artifact.

If a PR ships a defect that the checklist did not catch, the postmortem (see [`postmortem-template.md`](postmortem-template.md)) names the gap as an action item: either a new checkbox or a clarification of an existing one. The checklist gets sharper over time the same way the runbooks do.
