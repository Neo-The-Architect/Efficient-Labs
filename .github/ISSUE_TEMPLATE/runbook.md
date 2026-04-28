---
name: Runbook (author or revise)
about: Propose authoring a new runbook, or revising an existing one. Use this when the work product is a runbook, distinct from a code change or an infrastructure change.
title: "[runbook] "
labels: ""
assignees: ""
---

<!--
  Runbooks are durable artifacts. Authoring or revising one is a structured
  task with a known shape (see docs/processes/runbook-execution-protocol.md).
  This template captures what is needed before the work begins.
-->

## Service or surface

<!-- Which service the runbook covers. -->

## Status

<!-- Pick one. -->

- [ ] **New runbook** — does not exist on disk yet.
- [ ] **Revision of an existing runbook** — name the file path: `infra/runbooks/<name>.md`.
- [ ] **DRAFT promotion to VERIFIED** — runbook exists and has been executed; this issue tracks the verification commit.

## Reviewer

<!--
  Who reviews the runbook before merge. Default: the operator. If a
  domain expert (a Postgres specialist, a Restate developer) is asked
  to review, name them and the channel they were contacted through.
-->

## Deploy date (target)

<!--
  When this runbook is intended to be executed against production. The
  date informs the urgency of the runbook's verification pass — a runbook
  that will be executed Friday cannot graduate to VERIFIED on Friday
  morning, because verification needs a fresh-host execution that is not
  the production execution itself.
-->

## ADR / PRD references

<!--
  ADRs that the runbook implements or assumes. The Postgres install
  runbook, for example, implements ADR 0002 (Postgres single instance,
  shared process). Naming the references here keeps the runbook
  consistent with the decisions it depends on.
-->

## Scope

<!--
  What the runbook covers and — critically — what it does not. Runbooks
  in this repo are intentionally portable (no host-specific identifiers,
  no real passwords) so that another operator could fork the repo and
  run the runbook on their own host. This section names any portability
  edge cases.
-->

## Verification plan

<!--
  How the runbook moves from DRAFT to VERIFIED:
    - Where the fresh-host execution happens (the production VPS, a test
      VPS, a local VM).
    - What "complete" means (the runbook's `## Verification` section
      passes end-to-end with no unresolved discrepancies).
    - Who signs the verification commit.
-->

## Open questions

<!--
  Anything load-bearing that is not yet resolved at the time this issue
  is filed. Example: vendor-specific behavior on the target host that
  the runbook author has not tested.
-->
