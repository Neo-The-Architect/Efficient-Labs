<!--
  Pull request template for Efficient Labs.

  PR descriptions are review artifacts. They tell a future-Neo, an auditor,
  or a prospective client (some of whom read the PR record before they read
  the code) what the PR did, why, and how to know it worked. Don't skip
  sections — write "N/A" for sections that genuinely don't apply, but the
  default is to fill every section.

  Discipline rules from the issue-to-fix pattern apply (see
  docs/processes/issue-to-fix-pattern.md): one PR per phase or per logical
  unit, no scope expansion mid-PR, honest framing.
-->

## Linked issue / PRD

<!--
  Issue number, PRD reference, ADR number, or chat-derived authorization.
  Use "Closes #N" if this PR closes the issue on merge. If the work was
  authorized through a PRD that lives off-disk, name the PRD by date and
  one-line summary so a future reader can ask the operator about it.
-->

## What changed

<!--
  A clear, factual summary of every meaningful change. Group by file or
  by logical unit, whichever is clearer. The goal is that a reviewer can
  understand the shape of the diff before opening the diff.
-->

## Why

<!--
  The reason the change is being made. The problem it solves, the
  capability it unlocks, the risk it retires. Tie back to ADRs, runbooks,
  PRDs, or chat decisions where applicable.
-->

## How tested / verified

<!--
  What you ran or observed to confirm the change works. Specifics:
    - Commands executed and their output (for code or runbook changes).
    - Files reviewed and what was checked (for documentation changes).
    - Cross-references confirmed (for changes that touch multiple
      artifacts and need internal consistency).
  "Will be tested when deployed" is acceptable when the change is a
  runbook draft awaiting its verification pass — but say so explicitly,
  do not gloss it.
-->

## Rollback plan

<!--
  If the change is wrong or causes an incident, what undoes it?
  - For documentation changes: revert the commit.
  - For code changes: revert the commit, plus any data migration to undo.
  - For infrastructure changes: the rollback section of the runbook
    referenced in the linked issue. Link it here.

  Changes that have no documented rollback are higher-risk than they look.
  Naming the rollback explicitly forces the conversation about what
  rollback would actually mean.
-->

## Discipline check

<!--
  Confirm before requesting review. These are not bureaucracy; they are
  the things the reviewer will check, so checking them yourself first
  saves a round-trip.
-->

- [ ] PR scope matches the linked issue / PRD. No silent scope expansion.
- [ ] Stubs are marked as stubs. Inferences are explicit.
- [ ] No edits to existing files in `main` outside the authorized scope.
- [ ] No secrets in the diff (`.env` files, credential strings, real passwords, real hostnames where portability is supposed to be preserved).
- [ ] Conventional-commit-style commit message(s) on the branch.
- [ ] CHANGELOG updated if this PR introduces a user-facing change.
- [ ] Honest framing throughout — does the PR description describe what was actually done, including what was *not* done?

## Screenshots / artifacts (if UI)

<!--
  When the change affects a rendered surface (the marketing site, a
  GitHub-rendered README, an admin console), attach a before/after view
  so the reviewer does not have to render it themselves.
-->

## Reviewer notes

<!--
  Anything that would help the reviewer be efficient: a specific section
  to read first, a non-obvious tradeoff to flag, a known limitation that
  is intentional, a follow-up issue already filed for deferred work.
-->
