# Postmortem: <one-line title — service or capability and the symptom>

<!--
  Template for blameless postmortems at Efficient Labs.
  Copy this file to docs/operations/postmortems/YYYY-MM-DD-<short-slug>.md
  and fill in. Postmortems live in the repo because they are durable artifacts
  — the system's memory of what went wrong and what was learned.

  Blameless: the postmortem describes what happened and what changed; it does
  not assign moral fault to a person or to Claude Code. Causes are systemic,
  not individual. If a person made the wrong decision under the information
  available, the question is what information should have been available; if
  a runbook produced a wrong result when followed correctly, the question is
  what about the runbook produced the wrong result.
-->

- **Date of incident:** YYYY-MM-DD
- **Date of postmortem:** YYYY-MM-DD
- **Author:** <author name; typically the operator>
- **Severity:** Customer-impacting | Security-relevant | Process failure | Operator-discretion
  <!-- See docs/processes/incident-response.md for the criteria. -->
- **Status:** Draft | Reviewed | Closed

## Summary

<!--
  Two or three sentences that a reader can use to decide whether to read the
  full postmortem. State the symptom, the duration, the impact, and the
  resolution at the highest level.
-->

## Timeline

<!--
  All timestamps in UTC. Each entry is a single line: timestamp, brief event.
  Be precise about who did what — "the operator ran X" or "Claude Code in
  sandbox produced Y" — because the timeline is the spine of the analysis.

  Anchor the timeline on the moment the incident began (which may be earlier
  than the moment it was detected) and continue past the resolution to include
  the verification that the system was healthy.
-->

- **HH:MM** — Event.
- **HH:MM** — Event.
- **HH:MM** — Event.

## Root cause

<!--
  What actually went wrong. The first answer is rarely the right one — keep
  asking "and why did that happen?" until the answer is something the system
  can be changed to prevent, not something a person can be told to do
  differently.

  If the cause is a chain of contributing factors rather than a single thing,
  list them with the most upstream first. Mark each with whether it is the
  proximate cause, a contributing factor, or a missing safety mechanism.
-->

## Impact

<!--
  Who or what was affected and how much. Be specific:
    - Services degraded or down: which, for how long.
    - Clients affected: how many, what they saw.
    - Data: any loss, any disclosure, any unauthorized access.
    - Cost: vendor charges, engineering time, reputation.
  If the impact was zero, say so explicitly — a near-miss with no impact is
  still a learning event and the impact section records that.
-->

## What went well

<!--
  The detection mechanisms, automation, runbooks, alerts, or operator instincts
  that limited the blast radius. Keep this section because postmortems where
  this is empty are signals that the system has no working defenses, not that
  nothing went well — there is always something. Naming what worked reinforces
  the parts of the system that should be invested in further.
-->

## What went poorly

<!--
  The detection gaps, missing runbooks, ambiguous documentation, brittle
  configurations, or process shortcuts that contributed to the duration or
  severity of the incident. This is not a list of blame — it is the inventory
  of changes the system has the option to make.
-->

## Action items

<!--
  Each action item is a concrete, owned, dated change. The format is:
    - [ ] <action>. **Owner:** <name>. **Due:** YYYY-MM-DD. **Tracking:** <issue or PR link>
  Action items without an owner and a due date are not action items — they are
  wishes. Do not write wishes here.

  After the postmortem is reviewed, the action items are tracked through their
  closure. A postmortem with open action items past their due date is itself a
  signal — escalate or re-schedule, do not silently let them lapse.
-->

- [ ] Action. **Owner:** . **Due:** YYYY-MM-DD. **Tracking:** .

## Lessons

<!--
  One or two sentences capturing what the team should remember from this
  incident. The lessons section is the memorable summary — when a future
  operator searches the postmortems for prior art, the lesson is what they
  will read first.
-->
