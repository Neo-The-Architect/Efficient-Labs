# Development setup

**Status: stub.** This document will have substance once there is runnable code in the repo. Today the repo is documentation-heavy and code-light, so "set up to run" is mostly "clone and read."

## What works today

```sh
git clone https://github.com/Neo-The-Architect/Efficient-Labs.git
cd Efficient-Labs
```

That is the entire setup. There is no build step, no dependency manager, no test suite — yet.

## Reading order for new contributors

1. The [README at the repo root](../../README.md) — the project thesis and current status.
2. The [architecture report](../architecture/2026-04-27-fulfillment-architecture-report.md) — the canonical design document. Long, but the rest of the repo is downstream of it.
3. The [ADR index](../adr/README.md) — the timeline of decisions that constrain the system's current shape.
4. [`CONTRIBUTING.md`](../../CONTRIBUTING.md) — the contribution model and what kinds of contribution are a fit.

## How to contribute today

- File an issue using the appropriate [issue template](../../.github/ISSUE_TEMPLATE/) — bug, feature, security, infrastructure, or runbook.
- Open a pull request against `main`. The [PR template](../../.github/PULL_REQUEST_TEMPLATE.md) renders automatically and walks through the discipline-check section.
- Follow the [code review checklist](../processes/code-review-checklist.md) for self-review before requesting review.

## When this stub fills out

The triggers are concrete: when one of the following lands, this document grows the corresponding setup section.

- **Weft programs** — a TypeScript Restate project. This document grows a Node.js / pnpm setup section, environment variable conventions, and how to run a Weft program against a local Restate instance.
- **Paperclip skills** — Claude Skills directory structure. This document grows the skill authoring conventions and the local testing harness.
- **Marketing site** — a static or minimally-dynamic site, deployment via Cloudflare Pages or Vercel (TBD per Section 8 of the architecture report). This document grows the local preview and deploy preview workflow.
- **n8n archetypes** — workflow JSON exports. This document grows the import-export discipline and the local n8n setup for archetype validation.

Until any of those lands, the stub is the document.
