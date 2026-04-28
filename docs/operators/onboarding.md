# Operator onboarding

**Status: stub.** This document is the structure for onboarding a future operator — a second engineer, a contractor, or future-Neo after a break long enough that the system's working state has faded from memory. Substance fills in when one of those situations actually happens, because the right onboarding doc is the one that surfaces during a real onboarding rather than the one written in the abstract.

## Sections this document will have

When this document is filled in, it will cover at minimum:

- **Day-zero account provisioning.** Tailscale identity creation and tagging; GitHub account and `Neo-The-Architect` org membership where applicable; Hostinger account access (if appropriate to the role); password manager invitation; the credentials inventory in [`command-reference.md`](command-reference.md#auth-inventory) brought to current state.
- **Reading order.** A curated path through this repo for a new operator: README → architecture report → ADRs in numeric order → process documents → command reference → runbooks. The path produces a working mental model without the new operator having to invent a reading order.
- **First-week shadow exercises.** Concrete tasks the new operator performs alongside the existing operator before independent work begins. Examples (subject to revision when this stub fills): execute a runbook in the operator's companion window while the existing operator runs the operator window; review one open PR end-to-end using the [code review checklist](../processes/code-review-checklist.md); run through the cold-start checklist in `command-reference.md` against a real session.
- **Independence criteria.** What "ready to operate independently" means in concrete terms. The criteria are observed, not declared.
- **Communication norms.** How the new operator and the existing operator coordinate — the chat channel, the cadence of check-ins, the escalation path.
- **Boundaries.** What the new operator should not do without the existing operator's explicit go-ahead during the onboarding period (e.g. direct production-state changes, ADR authorship, client-facing communication).

## Why this is a stub

The right onboarding document is calibrated to a real onboarding scenario. Writing it now, before any onboarding has happened, would produce confident-sounding but untested material — a familiar failure mode that the [incident-response stub](../processes/incident-response.md#why-this-is-a-stub) names by analogy.

The stub exists so that *when* a real onboarding scenario arrives — even an emergency one (operator hospitalized, contractor brought in for a single engagement) — the structure is here to fill, not a blank page to start from.

## Triggers for filling this stub

Any of these triggers a substantive revision, in approximately the order they are likely to occur:

1. The operator returns from a break of two weeks or longer and notices the system's working state has decayed in memory. The operator's notes about what was hard to remember become the first draft of this document.
2. A contractor is engaged for a specific time-bounded scope. The contractor's onboarding produces real data about what was needed; the document is updated immediately after the engagement.
3. A second permanent operator joins. This is the most rigorous filling — independence criteria, communication norms, and boundaries all matter substantively.

If trigger 1 happens before triggers 2 or 3, this document gets the operator's notes-from-memory pass even though there is no second operator yet — the future-Neo case is itself a valid scenario.

## Pointers in the meantime

While this document is a stub, the following pointers are the working substitute:

- The [command reference](command-reference.md) is the first document any new operator should read.
- The [README at the repo root](../../README.md) names the project, its operating model, and the canonical references.
- The [architecture report](../architecture/2026-04-27-fulfillment-architecture-report.md) is the design document that everything else descends from.
- The [ADR index](../adr/README.md) is the timeline of decisions that constrain the system's current shape.
- The [process documents](../processes/) describe how the team works.
