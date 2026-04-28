# Contributor documentation

This directory holds documents written for contributors — anyone outside the operator who opens an issue or a pull request against this repository. The audience is mixed: developers familiar with open-source workflows, prospective clients evaluating the operating discipline, and curious passers-by.

## Index

| Document | Purpose |
| --- | --- |
| [Code of Conduct](CODE_OF_CONDUCT.md) | The Contributor Covenant. Standard, unmodified. The substantive constraint: be respectful, focus on the work, assume good faith. |
| [Development setup](dev-setup.md) | How to clone, run, and contribute. **Stub** — fills out when the runnable code lands (Weft programs, Paperclip skills, marketing site). Today the repo is documentation-heavy and code-light, so "set up to run" is mostly "clone and read." |

## What lives here vs. elsewhere

- **Top-level contribution guide:** the repo root [`CONTRIBUTING.md`](../../CONTRIBUTING.md) is the entry point. It links into this directory for the topical documents.
- **Pull request template:** at [`.github/PULL_REQUEST_TEMPLATE.md`](../../.github/PULL_REQUEST_TEMPLATE.md). Renders automatically when a contributor opens a PR.
- **Issue templates:** at [`.github/ISSUE_TEMPLATE/`](../../.github/ISSUE_TEMPLATE/). Render automatically when a contributor opens a new issue.
- **Code review checklist (operator side):** at [`docs/processes/code-review-checklist.md`](../processes/code-review-checklist.md). Contributors are welcome to read this — it tells you what the operator looks for, which lets you self-check before opening the PR.
- **Vulnerability disclosure:** at [`SECURITY.md`](../../SECURITY.md) at the repo root. Use the GitHub Security Advisories private channel; do not file public security issues.

## What contributors most often need from this directory

- **A clear answer to "is my contribution welcome?"** — see [`CONTRIBUTING.md`](../../CONTRIBUTING.md), specifically the "What kinds of contribution are most welcome" and "What kinds of contribution are *not* a fit" sections.
- **Confidence that the project is maintained.** The honest answer: it is maintained by a single operator, with substantive engineering work performed by Claude Code under the operator's review. Response times reflect this; review is human; the bar for merge is operability.
- **A sense of the operating discipline.** The [process documents](../processes/) describe how decisions get made, how runbooks are authored and verified, how PRs are reviewed, how the team handles incidents. Contributors who read these before opening a substantive PR have a meaningful advantage in landing the change.

## When to add a document here

A new document is appropriate when contributors repeatedly ask the same question and the answer would be more useful committed once than retyped each time. Stub-then-fill is acceptable; the [dev-setup](dev-setup.md) is a worked example of a stub that lands now and grows substance when the runnable code lands.

If a document outgrows the contributor framing — for example, becomes useful to operators, clients, or the public-facing security posture — it migrates to the appropriate sibling directory.
