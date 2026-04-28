---
name: Infrastructure change
about: Propose a change to the production fulfillment surface — services, configuration, hardening, observability, backup. Use this for anything that changes the host's running state.
title: "[infra] "
labels: ""
assignees: ""
---

<!--
  Infrastructure changes touch the live VPS. They are higher-risk than
  documentation or scaffolding changes and need more rigor up front.
  Every section below is required before triage; an issue with empty
  sections is sent back for completion.
-->

## Service affected

<!--
  Which service or surface this change touches. Examples: Postgres,
  Restate, Weft, Paperclip, Tailscale ACL, systemd unit definitions,
  backup target, observability pipeline. Be specific.
-->

## Current state

<!--
  What is true on the production host today, with the source-of-truth
  link. If the current state is documented in a runbook or ADR, link it.
  If it is not documented, that is itself a finding worth flagging.
-->

## Target state

<!--
  What the production host should look like after this change lands.
  Same level of specificity as the Current state section — config values,
  unit states, listening ports, file paths, version pins.
-->

## Runbook reference

<!--
  Pointer to the runbook that, when executed, achieves the target state.
  If a runbook does not exist yet, this section captures that gap and the
  change cannot be merged until the runbook lands.
  Path format: `infra/runbooks/<runbook-name>.md`.
-->

## Rollback plan

<!--
  Concrete steps to revert if the change does not produce the target state
  or if it produces unexpected side effects. The rollback plan is required;
  changes without one are not authorized to deploy.

  The rollback plan is in single-command discipline: each step a discrete
  command with documented expected output. See
  `docs/processes/runbook-execution-protocol.md`.
-->

1.
2.
3.

## Verification

<!--
  How to confirm the change actually achieved the target state, beyond
  "the runbook completed without error." Specific commands and their
  expected outputs.
-->

## Risk and blast radius

<!--
  What can go wrong, what would be affected, who would notice. Be honest:
  "if this fails, the production database is unavailable for N minutes"
  is the kind of statement that helps triage; "minimal risk" is not.
-->

## ADR or PRD references

<!--
  ADRs that constrain or justify this change. PRDs (if any) that
  authorized it. Architecture report sections it implements.
-->
