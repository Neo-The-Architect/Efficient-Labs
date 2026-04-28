# Changelog

All notable changes to the Efficient Labs public repository are recorded in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) for any tagged releases. There are no tagged releases yet — the repo is pre-release; entries are recorded against the date of merge to `main`.

The changelog is the high-altitude view. Detailed authorship and review information lives in the git log and the PR record; this file is curated for readability by anyone evaluating the repo's progression — the operator, future-self, prospective clients, auditors.

## [Unreleased]

### Added

- **Engineering process scaffold (Layers 1 + 5 partial).** Architecture Decision Records gain a template (`docs/adr/_template.md`) and an index (`docs/adr/README.md`). Two new ADRs land: [ADR 0004](docs/adr/0004-commit-attribution-claude-author-neo-reviewer.md) records the commit-attribution discipline (Claude as author, Neo as reviewer-of-record), and [ADR 0005](docs/adr/0005-tailscale-ssh-as-primary-access-path.md) records the host-access posture (Tailscale SSH primary, OpenSSH masked). Process documentation begins in `docs/processes/`: a runbook execution protocol, the issue-to-fix PRD-driven workflow, an incident-response stub, and a blameless postmortem template. (PR: feat/scaffold-phase-a-decision-discipline)
- **Issue and PR lifecycle scaffold (Layer 2).** GitHub issue templates land for bug, feature, public-safe security, infrastructure change, and runbook authoring/revision (`.github/ISSUE_TEMPLATE/`). Pull request template (`.github/PULL_REQUEST_TEMPLATE.md`) with the discipline-check section. `CODEOWNERS` records ownership explicitly even with one owner. Two further process documents land in `docs/processes/`: a self-review code review checklist for the solo+AI workflow, and the branch-protection spec for `main`. `SECURITY.md` publishes the vulnerability disclosure policy, with the GitHub Security Advisories flow as the primary private channel and the email channel marked TBD pending operator email provisioning. (PR: feat/scaffold-phase-b-issue-pr-lifecycle)

## [2026-04-27]

The repository's foundation session. All entries below were merged in a single sitting after the architecture report was finalized; commits are grouped by topic in the order they landed.

### Added

- **Restate install runbook draft.** `infra/runbooks/install-restate.md` lands as a `DRAFT` runbook for the Restate durable executor. Pending operator deploy verification and an audit pass (planned as part of the engineering scaffold's Phase D).
- **Postgres install runbook draft.** `infra/runbooks/install-postgres.md` lands as a `DRAFT` runbook for the single-instance Postgres 16 setup that ADR 0002 specifies. Two databases (`paperclip`, `weft`), two roles, localhost binding only.
- **Infrastructure runbook stubs.** `infra/runbooks/install-weft-and-paperclip.md` and the `infra/` directory layout land as scaffolding for the production fulfillment surface.
- **First three Architecture Decision Records.** [ADR 0001](docs/adr/0001-weft-paperclip-architectural-boundary.md) records the architectural boundary between Weft and Paperclip; [ADR 0002](docs/adr/0002-postgres-single-instance-shared-process.md) records the shared-Postgres-instance decision; [ADR 0003](docs/adr/0003-n8n-licensing-posture-standard-tier-only-week-1.md) records the n8n licensing posture (Standard tier only, Sovereign tier blocked pending an n8n Embed license).
- **Repository thesis and README.** `README.md` rewritten to state the project thesis, the repo structure, and the current status. Replaces the placeholder README from the initial commit.
- **Public mono-repo scaffold.** `case-studies/`, `docs/`, `infra/`, `legal/`, `marketing-site/`, `n8n-archetypes/`, `paperclip-skills/`, `plugin-paperclip-weft-bridge/`, `weft-programs/` directories created per the architecture report Section 8 layout.
- **Canonical fulfillment architecture report.** `docs/architecture/2026-04-27-fulfillment-architecture-report.md` imported as the canonical design document. Subsequent decisions are reconciled against this report through ADRs.
- **Initial commit.** Repository created on GitHub under `Neo-The-Architect/Efficient-Labs`. License: MIT (`LICENSE`).

[Unreleased]: https://github.com/Neo-The-Architect/Efficient-Labs/compare/main...HEAD
