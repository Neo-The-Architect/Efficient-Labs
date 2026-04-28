# The issue-to-fix pattern

This document describes the operating workflow Efficient Labs uses to turn an identified issue (a bug, a missing capability, an audit finding, an architectural gap) into a merged fix. It is the workflow that produced the seven-layer engineering scaffold landed in the April 28 PRs; this document is itself written under the workflow it describes.

The pattern exists for a specific reason: the substantive engineering work in this repo is performed by Claude Code in a sandboxed account, with the operator (NeoTheArchitect) acting as decision authority and reviewer-of-record (see [ADR 0004](../adr/0004-commit-attribution-claude-author-neo-reviewer.md)). That arrangement only produces good work when the handoff between human and AI is structured. Unstructured prompts produce drift, scope creep, and silently dropped requirements. Structured prompts — PRDs — produce reviewable PRs that the operator can sign off on quickly.

## The cycle

```
issue identified  →  PRD authored  →  PRD handed to Claude Code in sandbox
                                                ↓
                                       Claude Code asks clarifying questions
                                                ↓
                                       operator answers, PRD ratified
                                                ↓
                                       Claude Code executes phase by phase
                                                ↓
       PR per phase  ←  commit  ←  tests/verification (where applicable)
                                                ↓
                                       operator reviews PR, approves or requests changes
                                                ↓
                                       merge to main  →  deploy / publish
```

Each arrow in the cycle is a discrete handoff. Each handoff produces an artifact that survives the conversation that produced it.

## What a PRD looks like

A PRD authored for handoff to Claude Code includes the following sections, in order. The seven-layer scaffold PRD that produced this document is the canonical example; future PRDs should match its structure.

### Front matter

- **Author** — the human writing the PRD. Today this is the operator.
- **Assigned to** — the executor. Today this is `Claude Code (sandbox)`.
- **Status** — `Draft`, `Active execution`, `Complete`, `Withdrawn`.
- **Date** — the date the PRD was authored.

### Context

A two- or three-paragraph statement of the world as it exists when the PRD is written, the gap or issue that motivates the work, and the constraint set the executor must operate within. Context is not the place for the solution; it is the place for the problem.

### Authorization scope

What the executor is authorized to do. State it positively (the things to do) and negatively (the things explicitly out of scope). The negative scope is as important as the positive — without it, the executor will quietly accumulate side work that drifts the PR away from the operator's mental model.

### Phases

A multi-phase PRD names each phase explicitly: branch name, files to create or modify, commit message, PR title, PR description requirements. Each phase ends with a hard stop — the executor reports back, the operator reviews, and only then does the next phase begin. Hard stops are non-negotiable: they prevent compound errors from cascading across phases, and they keep the operator's review effort proportional to a single PR rather than a mega-merge.

### Discipline rules

Any operating constraints that apply across all phases: branch-naming rules, commit-message conventions, files that must not be modified, external resources that must not be fetched, time budgets per phase. These are the rules the executor consults when in doubt; they exist so that judgment calls trend the right way without re-prompting.

### Out of scope

Explicit statement of what the PRD does *not* authorize, with reasoning. The full vision often extends past the current PRD's scope; documenting the deferred work in the PRD itself prevents the executor from quietly starting it and prevents the operator from losing the thread of what was deferred.

### Clarifying questions checkpoint

A final instruction to the executor: before starting any work, read the PRD twice, surface any clarifying questions, and confirm acknowledgment. The clarifying-questions checkpoint is the only time before execution that the operator catches misunderstandings cheaply. Skipping it costs more than running it costs.

## What the executor does

When Claude Code (or any executor) receives a PRD, the protocol is:

1. **Read it twice.** First pass for shape, second pass for detail. The executor's first prompt-back is rarely the right one; the second pass surfaces the load-bearing details.
2. **Cross-reference against the workspace.** A PRD that says "create file X" can collide with an existing file X. The executor runs a recon pass against `git ls-files` (or the equivalent) and reports collisions before starting. The cost is three minutes; the benefit is no mid-phase surprises.
3. **Surface clarifying questions.** Sharp, scoped questions, not open-ended musings. A clarifying question is one whose answer changes what the executor will write. A musing is one that does not.
4. **Confirm acknowledgment** with a single statement before starting (e.g. "PRD acknowledged, beginning Phase A"). The acknowledgment is the executor's signature on what it understood; the operator can compare to what the executor produces.
5. **Execute one phase at a time.** Single commit per phase, single PR per phase, hard stop after each PR is opened. Report PR number, wait for the operator.
6. **Honest framing in artifacts.** Where a deliverable is a stub, mark it as a stub. Where a deliverable is a draft pending verification, mark it as such. Where the executor inferred something rather than read it from on-disk fact, the inference is explicit. The artifacts are the operator's record of what is real and what is not — they have to tell the truth.

## What the reviewer does

The operator reviewing a PR has three responsibilities:

- **Confirm scope match.** Does the PR do what the phase said it would do? Nothing more, nothing less? Drift in either direction is a request-for-changes.
- **Confirm honest framing.** Are stubs marked as stubs? Are inferences explicit? Are deferred items deferred, not silently dropped?
- **Confirm operability.** When the PR concerns runbooks, scripts, or configuration, the operator asks: would I be willing to execute this against the production VPS? If the answer is "not without changes," the changes go in the request-for-changes.

A PR that satisfies all three is approved and merged. A PR that does not is sent back with specific, actionable requests; the executor revises and the cycle continues.

## Why this works

The pattern works because it makes every handoff legible. The PRD is the operator's commitment to a problem statement. The clarifying questions are the executor's commitment to having understood. The PR is the executor's commitment to having delivered. The review is the operator's commitment to the result. None of the commitments is verbal; all of them are on disk, in the repo or the PR record, where they will outlive the conversation that produced them.

The pattern is recursive: this document was authored as part of Phase A of the PRD that produced the seven-layer engineering scaffold. The PRD itself follows the structure described above; the file you are reading is one of the deliverables of that PRD's Phase A. The pattern documents itself by being the thing that produces itself.

## Anti-patterns to avoid

- **Open-ended chat prompts as a substitute for PRDs.** "Hey Claude, can you scaffold the engineering process docs for this repo?" produces a disorganized commit dump. A PRD with phase boundaries produces reviewable PRs.
- **Mega-PRs that bundle multiple phases.** Tempting because each individual phase feels small. Costly because the operator's review effort is non-linear in the size of the PR — at some size the operator simply rubber-stamps, and the discipline collapses.
- **Skipping the clarifying-questions checkpoint.** Fast in the moment, expensive when the executor produces work the operator did not actually ask for.
- **Silent scope expansion mid-phase.** The executor sees an obvious adjacent fix and folds it in without asking. The next reviewer cannot tell what was authorized and what was added; trust in the artifact erodes. Adjacent fixes go in their own PR with their own authorization.
- **Skipping the recon pass for PRD-target file collisions.** The executor assumes the PRD's target paths are clean and discovers mid-phase that one of them already exists. The right move is to flag it during the clarifying-questions checkpoint and let the operator decide; the wrong move is to pick a heuristic and ship.

## When to author a new PRD

Author a new PRD when the work satisfies any of:

- The work spans more than a single small commit's worth of effort.
- The work touches more than one file or directory.
- The work introduces a constraint that subsequent work will have to respect (in which case an ADR may also be appropriate — see [docs/adr/README.md](../adr/README.md)).
- The work is being delegated to an executor (Claude Code in sandbox, a contractor, a future-self after a long break) who needs the operator's intent encoded in a durable document.

Trivial single-file fixes do not need a PRD; the PR description is sufficient. Most other work does.
