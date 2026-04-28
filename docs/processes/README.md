# Processes

This directory holds the operating discipline of Efficient Labs — the documents that describe *how* the work is done, distinct from the [ADRs](../adr/README.md) (which describe *what was decided*) and the [runbooks](../../infra/runbooks/) (which describe *what to do on a host*).

Process documents are durable. They evolve when the underlying practice evolves; they are not aspirational statements of how the team would like to work in some imagined future. A process document that does not match how the team actually operates is a defect — either the document gets updated to reflect reality, or the practice gets corrected to match the document.

## Index

| Document | One-line description |
| --- | --- |
| [Runbook execution protocol](runbook-execution-protocol.md) | The discipline for authoring, executing, and verifying runbooks. Single-command discipline, two-window pattern, stop on error, DRAFT → VERIFIED status flow. |
| [Issue-to-fix pattern](issue-to-fix-pattern.md) | The PRD-driven workflow used to delegate substantive engineering work to Claude Code in sandbox, with operator review through the PR chain. |
| [Incident response](incident-response.md) | Triage checklist, escalation criteria, and postmortem trigger threshold. Stub today; fills out substantively after first real incident. |
| [Postmortem template](postmortem-template.md) | Blameless postmortem template. Sections for summary, timeline, root cause, impact, what went well, what went poorly, action items, lessons. |

## Documents that should land here but have not yet

The seven-layer engineering scaffold PRD authorized only a partial Layer 5. The following process documents are deferred to a future session and will be added to this directory when authored:

- **Sprint cadence.** How weekly planning, mid-week check-ins, and end-of-week review work for a solo+AI workflow. Stub when the cadence stabilizes; today the cadence is being established session-by-session.
- **Release procedure.** How a change moves from `main` to deployed-on-VPS to verified-in-production. Will document tagging conventions, the deploy runbook (which itself does not yet exist), the rollback path, and the announcement template (when there is anyone to announce to).
- **Code review checklist.** The self-review checklist for the solo+AI workflow. Lands as part of Phase B of the seven-layer scaffold (see the corresponding PR description for details).
- **Branch protection settings.** Documents the GitHub branch-protection configuration this repo enforces (or aspires to enforce). Lands as part of Phase B.

## How to add a process document

A new process document is appropriate when:

- The practice it describes is established, not aspirational.
- The practice is durable enough that capturing it pays back the cost of keeping the document current.
- The practice is shared between the operator and Claude Code (or any future executor) and the handoff benefits from being explicit on disk.

Author the document, add a row to the index above, open a PR. The PR description names what practice the document captures and what triggered the decision to write it down now.

When a process changes, the document changes — through a PR, like any other artifact. A process change without a corresponding documentation update is a defect against this directory.
