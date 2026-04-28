---
name: Bug report
about: Report a defect — something behaves differently than the runbook, ADR, or documentation says it should.
title: "[bug] "
labels: ""
assignees: ""
---

<!--
  Use this template for defects: a runbook step failed, a script produced
  the wrong output, a documented behavior is not what actually happens.
  Keep the report concrete — every section below should be answerable from
  what you observed, not what you suspect.
-->

## Summary

<!-- One or two sentences. What is broken, in plain language. -->

## Reproduction steps

<!--
  Numbered steps a future operator can follow to reproduce the failure.
  Be specific: exact commands, exact files, exact host (anonymized if needed).
-->

1.
2.
3.

## Expected behavior

<!--
  What should have happened, with the source of truth that says so.
  Cite the ADR, runbook, or documentation that defines the correct behavior.
-->

## Actual behavior

<!--
  What actually happened. Paste exact error output. Do not paraphrase.
  If the output is long, attach as a code block or a separate file linked
  here, not as a screenshot — text is searchable.
-->

```
<paste output here>
```

## Environment

- **Host / surface:** <production VPS / Claude Code sandbox / local dev / other>
- **Service version (if applicable):** <e.g., postgresql 16.4, restate 1.x>
- **OS / kernel:** <e.g., Ubuntu 24.04, kernel 6.x>
- **Date observed (UTC):**
- **Most recent merged PR before failure:** <PR number / commit SHA>

## Severity

<!--
  Pick one. Severity is about impact and urgency, not how interesting the bug is.
-->

- [ ] **Blocker** — production fulfillment surface is degraded or unavailable; client-facing impact in progress.
- [ ] **Serious** — a runbook or critical path is broken in a way that will cause an incident if not fixed before the next deploy.
- [ ] **Minor** — incorrect behavior that has a documented workaround or affects only non-production paths.

## Logs / artifacts

<!--
  Attach (or paste) journalctl excerpts, terminal sessions, screenshots of
  GitHub or vendor admin consoles, anything that helps a future operator
  reconstruct the failure without being there.
-->

## Suggested fix (optional)

<!--
  If you have a concrete suggestion for the fix, include it here. Otherwise
  leave blank — the triage step will decide.
-->
