# Contributing to Efficient Labs

Thanks for your interest in this repository.

Before reading further, the honest framing — because everything below depends on it:

> Efficient Labs is operated by [@Neo-The-Architect](https://github.com/Neo-The-Architect) (single operator, Philippines), with significant engineering work performed by Claude Code (Anthropic's LLM, accessed through the Claude Code CLI in a sandboxed account on the operator's VPS) under operator review. This repository demonstrates disciplined solo-operator-plus-AI execution. Contributions are welcome via pull request; security disclosures via [`SECURITY.md`](SECURITY.md).

That framing has consequences for how contribution works here, and they are spelled out below. The short version: review is by one human, response times reflect that, scope is bounded by what the operator can responsibly maintain, and the discipline of the workflow is itself part of what this repo demonstrates.

## What Efficient Labs is

A single-operator company building automation for SMBs using a stack of [Weft](https://github.com/Quentin-Feuillade-Montixi/weft), [Paperclip](https://paperclip.ai), n8n (Standard tier only — see [ADR 0003](docs/adr/0003-n8n-licensing-posture-standard-tier-only-week-1.md)), Postgres, and Restate, hosted on a hardened VPS with Tailscale-based access (see [ADR 0005](docs/adr/0005-tailscale-ssh-as-primary-access-path.md)). The architecture report at [`docs/architecture/2026-04-27-fulfillment-architecture-report.md`](docs/architecture/2026-04-27-fulfillment-architecture-report.md) is the canonical design document.

The repo is public from day one because the public-build pattern (architecture report Section 7) is part of how the company finds and convinces clients. The private surface — actual client workflows, PRDs, lead data, credentials — never lands here.

## Operating model

This repository's commits are typically authored by `Claude <noreply@anthropic.com>`, with the operator (`Neo-The-Architect`) acting as reviewer-of-record through the GitHub PR review chain. The convention is documented in [ADR 0004](docs/adr/0004-commit-attribution-claude-author-neo-reviewer.md). It is unusual; it is intentional; it is not pretending to be otherwise.

What this means for contributors:

- **A PR you open is reviewed by the operator personally.** There is no gatekeeping team or review rotation. The operator reads every line.
- **Response times reflect a single-operator schedule.** Best-effort acknowledgment within 48 hours; substantive response within a week is the norm. Faster for security disclosures (see [`SECURITY.md`](SECURITY.md)). Slower if the operator is in a delivery push for a paying client — that work takes priority.
- **The bar for merge is operability, not novelty.** A small PR that fixes a documentation error, tightens a runbook, or improves a check is more valuable here than a large feature PR that the operator has to spend a day understanding.

## How to file an issue

Issues are how a problem, idea, or question becomes durable on disk. The repo has issue templates for several shapes:

- **[Bug report](.github/ISSUE_TEMPLATE/bug.md)** — when something behaves differently than the runbook, ADR, or documentation says it should.
- **[Feature request](.github/ISSUE_TEMPLATE/feature.md)** — when you want a capability that does not exist today.
- **[Public-safe security topic](.github/ISSUE_TEMPLATE/security.md)** — for CVEs in dependencies, posture questions, or doc gaps. **Not for vulnerability disclosure** — see [`SECURITY.md`](SECURITY.md) for the private channel.
- **[Infrastructure change](.github/ISSUE_TEMPLATE/infra.md)** — when you propose a change to the live host or service configuration.
- **[Runbook authoring/revision](.github/ISSUE_TEMPLATE/runbook.md)** — when the work product is a new or revised runbook.

Pick the template that fits, fill it out, and submit. An empty or under-filled template will be sent back with a request to complete the missing sections.

If your issue does not match any template, the bug report template is the best default — give the operator the same shape of context (what you observed, what you expected, what you tried) and the triage step will rehome it as needed.

## How to submit a pull request

1. **Fork the repo and clone your fork.** This is a standard GitHub flow; if you have not done it before, GitHub's docs at https://docs.github.com/en/get-started/quickstart/fork-a-repo are the authoritative starting point.
2. **Create a feature branch.** Names follow the convention `feat/<short-slug>` for features, `fix/<short-slug>` for bug fixes, `docs/<short-slug>` for documentation-only changes. The conventional-commit prefix in the branch name signals the shape of the PR before the diff is opened.
3. **Make the change.** Keep the PR scope tight — one logical change per PR. Adjacent fixes go in their own PRs (see [`docs/processes/issue-to-fix-pattern.md`](docs/processes/issue-to-fix-pattern.md) on why silent scope expansion is a discipline failure).
4. **Run the local checks.** Today there are no automated CI checks (CI lands as Layer 3 of the seven-layer scaffold; see [`docs/processes/branch-protection.md`](docs/processes/branch-protection.md) for the aspired status). The local checks are by hand: read the diff, check links resolve, confirm no secrets, confirm no edits outside scope.
5. **Open the PR.** The repo's [pull request template](.github/PULL_REQUEST_TEMPLATE.md) walks through the discipline-check sections. Every section matters; "N/A" is acceptable when a section genuinely does not apply.
6. **Respond to review.** The operator may approve, request changes, or request changes plus a revised approach. Treat review feedback as information, not as judgment — the goal is to land the right change, and the operator's review is the path to figuring out what that is.

## What kinds of contribution are most welcome

- **Documentation corrections.** Typos, broken links, factual errors in runbooks or ADRs, clarifications where the prose is ambiguous. These are the highest-leverage contributions for a public-build repo.
- **Cross-platform portability fixes.** The runbooks aim to be portable (no host-specific identifiers, no real passwords) — if you spot something that breaks portability, that's a bug worth filing.
- **Public-safe security observations.** A CVE in a pinned version, a missing hardening step that the runbooks should call out, a question about the posture documented in [ADR 0005](docs/adr/0005-tailscale-ssh-as-primary-access-path.md). Use the public-safe security issue template for these; use [`SECURITY.md`](SECURITY.md) for actual vulnerability reports.
- **Improvements to the public artifacts that demonstrate the stack** — the n8n archetypes, the paperclip-skills, the Weft programs (when they land). These are designed to be reusable; better versions of them benefit the broader Weft / Paperclip / n8n communities.

## What kinds of contribution are *not* a fit

- **Substantive changes to the architecture report.** The report at [`docs/architecture/2026-04-27-fulfillment-architecture-report.md`](docs/architecture/2026-04-27-fulfillment-architecture-report.md) is a snapshot of the design as of its date. Updates to the architecture happen through new ADRs, not edits to the report. If you have feedback on the architecture, file a feature-request issue or open an ADR proposal — do not edit the report directly.
- **Edits to ADRs that are already `Accepted`.** A merged ADR captures a decision that has been taken. Subsequent decisions land as new ADRs, possibly superseding the prior one. The numbering policy (see [`docs/adr/README.md`](docs/adr/README.md)) is monotonic; gaps are fine; never renumber.
- **Adjacent fixes folded into your PR without authorization.** If you see another problem while working on yours, file a separate issue or open a separate PR. The operator's review effort is calibrated to the size of one PR; a stealth two-fix PR is harder to review and harder to revert.
- **Generated code without context.** Substantial blocks of LLM-generated code with no explanation of what they do, why, and how the contributor verified them are not landed in this repo. The discipline that the operator applies to Claude-generated work — review every line, name what was inferred, verify before merge — applies to contributor-generated work as well.

## Code of conduct

Contributors are expected to follow the [Contributor Covenant](docs/contributors/CODE_OF_CONDUCT.md), which lives in this repo. The short version: be respectful, focus on the work, and assume good faith. The operator reserves the right to remove comments, reject PRs, and (in rare cases) ban contributors who consistently violate the spirit of the covenant.

## Development setup

A development setup document lives at [`docs/contributors/dev-setup.md`](docs/contributors/dev-setup.md). It is currently a stub — the repo is documentation-heavy and code-light at the time of this writing, so "set up to run the code" is mostly "clone the repo and read." When the runnable code lands (Weft programs, Paperclip skills, the marketing site), the dev-setup document grows substance.

## License

Contributions are accepted under the same MIT license that covers the rest of the repository. By submitting a pull request, you confirm that you have the right to contribute the code under this license.

## Why these rules

The discipline matters because the artifacts have to tell the truth about themselves. A repo that overstates the depth of its review process, the rigor of its CI, or the size of its team will erode credibility the moment a careful reader notices. This document tries to do the opposite: tell the truth about the constraints, name the asymmetries, set realistic expectations, and let the discipline of the operating model be visible from the start.

If you have read this far, the operator thanks you for the patience. Open an issue or a PR — there is real work here that small careful contributions improve.
