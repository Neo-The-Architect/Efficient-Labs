# ADR 0004 — Commit attribution: Claude as author, Neo as reviewer-of-record

- **Status:** Accepted
- **Date:** 2026-04-25
- **Captures:** Operating discipline for the public Efficient Labs repo. Establishes the commit-attribution convention that downstream artifacts (CONTRIBUTING.md, CHANGELOG.md, the operator command reference, the build-in-public marketing surface) all rely on.
- **Supersedes:** —

## Context

Recorded post-hoc on 2026-04-28 by Claude Code under operator direction; the original decision discussion is not preserved on disk. Decision authority: NeoTheArchitect (operator).

Efficient Labs is a solo-operator company. The operator (NeoTheArchitect) is the only human contributor. The substantive engineering work — runbook authoring, ADR drafting, code generation, infrastructure scripts — is performed by Claude (Anthropic's LLM, accessed through the Claude Code CLI in a sandboxed user account on the operator's VPS, and through the claude.ai chat interface for design and review work). The operator's role is decision authority, code review, deployment authorization, and operational responsibility.

This raises a commit-attribution question that has no industry-standard answer yet. Three candidate conventions were on the table:

1. **Operator-as-author.** All commits are authored by `NeoTheArchitect`. Claude is invisible in the git history. The repo reads like a single human wrote it. This is the convention most public single-operator repos use today, including ones where AI tooling did substantial work.
2. **Operator-as-author with Co-Authored-By.** Commits are authored by `NeoTheArchitect`, with a `Co-Authored-By: Claude <noreply@anthropic.com>` trailer when Claude contributed substantively. GitHub renders both faces on the commit page. This is the default Claude Code commit footer.
3. **Claude-as-author, operator-as-reviewer-of-record.** Commits are authored by `Claude <noreply@anthropic.com>`. The operator's review and approval are recorded through the PR review chain — the operator opens (or approves) the PR, the merge to `main` is the operator's authorization signal. The git history is honest about who typed the bytes; the PR history is honest about who took responsibility for the bytes.

The operator's prior position on the build-in-public marketing surface — "Efficient Labs demonstrates disciplined solo-operator-plus-AI execution" — makes options 1 and 2 awkward. Option 1 is straightforwardly dishonest about how the work happens. Option 2 implies the operator typed the substance and Claude tidied it; that inverts the actual workflow.

Option 3 is honest about the workflow as it is actually performed today, and it scales: if Claude's role grows (more autonomous PRs, longer agentic chains) or shrinks (operator handles more substantive work directly), the commit history accurately reflects the change without a retrospective rewrite.

## Decision

**Adopt option 3.** Commits in this repo are authored by `Claude <noreply@anthropic.com>` when Claude is the substantive contributor. The operator (`NeoTheArchitect`) is the reviewer-of-record, recorded through the PR review chain and the merge-to-`main` signal. Commits authored directly by the operator (rare, expected mostly for emergency hotfixes outside the sandbox) use the operator's identity straightforwardly.

The Claude Code default commit footer (`🤖 Generated with [Claude Code]` / `Co-Authored-By: Claude`) is **not** added when Claude is the author — the author field already carries that information, and a co-authored-by trailer that names the same identity as the author is noise. The footer remains appropriate when the operator is the author and Claude assisted.

The PR description names the human-in-loop chain explicitly: which decisions came from the operator, which were made autonomously inside the sandbox, what authorization was given. Authorization is not implied by the commit identity; it is recorded in the PR.

## Consequences

### Positive

- **Honest provenance.** A future reader, an auditor, or a prospective client can read `git log` and see exactly who produced the substance. There is no rewriting if the human/AI mix changes.
- **Build-in-public credibility.** Efficient Labs sells operational sovereignty and disciplined solo-operator-plus-AI execution. The commit history is one of the artifacts that demonstrates the discipline. Faking single-author history would undermine the pitch the moment a careful prospect noticed.
- **Reviewer-of-record clarity.** The PR record is the canonical "who took responsibility for this" surface. The operator's GitHub identity appears on every PR review and merge — that signal is durable, queryable, and matches the legal reality (the operator is the human responsible for what is on the production VPS).
- **Scales to agentic work.** When Claude opens a PR autonomously inside the sandbox, the commit identity is already correct. The operator's review-and-merge is the authorization step, with no rewriting required.

### Negative

- **Cosmetic friction with tooling that assumes single-author repos.** Some commit-statistics dashboards and "who wrote this" plugins will report "Claude" as the dominant contributor. This is accurate; it may surprise readers expecting a human name. Mitigation: the README, the CONTRIBUTING.md, and the public-facing site all explain the convention up front.
- **GitHub does not natively render "AI authored, human reviewed" as a first-class concept.** The PR review chain is the substitute for that signal. Anyone evaluating provenance has to look at both `git log` and the PR record together. This is a documentation responsibility, not a tooling defect to fix.
- **Identity stability depends on a stable Claude email.** `Claude <noreply@anthropic.com>` is the chosen identity. If Anthropic changes the canonical address, prior commits keep the old address (no rewriting), and a follow-up ADR records the migration.

### Kill switch

This ADR is reversed if any of the following becomes true:

- Anthropic publishes guidance specifically discouraging this attribution pattern. (Current Anthropic guidance is silent on author-vs-co-author for AI-generated commits in solo-operator contexts; if that changes, this ADR follows.)
- A client, investor, or regulator raises a substantive objection to the convention that cannot be addressed through documentation alone.
- The mix of authorship inverts — if the operator becomes the substantive author for the bulk of work, the convention should follow reality, and a successor ADR records the flip.

## Alternatives Considered

- **Option 1 (operator-as-author).** Rejected: dishonest about how the work is performed and inconsistent with the operator's public positioning.
- **Option 2 (operator-as-author with Co-Authored-By).** Rejected: inverts the actual workflow. The operator is the reviewer; framing them as the author with Claude as a co-author misstates the substantive contribution.
- **Hybrid (operator-as-author for high-trust decisions, Claude-as-author for routine work).** Rejected as a primary policy: the boundary between "high-trust" and "routine" is fuzzy and would generate disputes about per-commit attribution. The PR-review chain already carries the high-trust signal — keeping author identity simple and consistent is cleaner.

## Concerns / Open Questions

- **Signed commits.** The repo does not currently require signed commits. Once the operator's signing key is provisioned, sign operator-authored commits; Claude-authored commits remain unsigned (the sandbox does not hold a signing key) but are still subject to PR review. This is documented in `docs/processes/branch-protection.md` (when that doc lands) as a known asymmetry, not a defect.
- **Commit message authorship voice.** Commit messages should be written in the imperative, not first person ("add feature" not "I added feature"), so the author identity is the only attribution signal. The runbook execution protocol enforces this.
- **Visibility on the marketing surface.** The repo's `README.md` and the public marketing site need to reference this convention so that visitors are not blindsided. Tracked as a follow-up content task; not blocking for this ADR.
