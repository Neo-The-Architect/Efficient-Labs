# ADR NNNN — <decision title in one line>

<!--
  Numbering: monotonic. Pick the next free integer after the highest existing
  ADR. Gaps from withdrawn or duplicate ADRs are fine — never renumber.
  File name: NNNN-<short-kebab-slug>.md, e.g. 0007-backup-retention-policy.md.
  Title above: matches the slug, written as a complete declarative phrase.
-->

- **Status:** Proposed | Accepted | Superseded by NNNN | Deprecated | Withdrawn
- **Date:** YYYY-MM-DD
- **Captures:** <pointer to the source artifact this ADR formalizes — e.g. a
  section of the architecture report, a chat decision, a postmortem action item.
  Use a relative path. Omit the bullet entirely if not applicable.>
- **Supersedes:** <ADR number(s) this replaces; em-dash if none>

## Context

<!--
  What forced the decision. What was true about the system, the constraints,
  the deadlines, the alternatives that made *this* the moment to decide.
  Reference architecture report sections, prior ADRs, and external sources by
  link. Keep it factual: a future reader should be able to reconstruct the
  pressure that produced the decision without reading any chat history.

  If the decision was reached in a conversation that is not preserved on disk,
  say so explicitly with a single line such as:
    "Recorded post-hoc on YYYY-MM-DD by <author> under operator direction;
     the original decision discussion is not preserved on disk.
     Decision authority: <operator>."
  This is the honesty discipline — ADRs document outcomes, but provenance is
  not optional.
-->

## Decision

<!--
  One declarative paragraph stating exactly what was decided. No hedging.
  If the decision has multiple parts (e.g. "ship A, defer B, block C"), state
  each part as its own paragraph or its own bolded lead-in.
-->

## Consequences

<!--
  What changes as a result. Split into the lenses that matter:
    - Positive: capabilities unlocked, risks retired, ambiguity resolved.
    - Negative: costs accepted, capabilities forfeited, risks introduced.
    - Kill switch (optional): the explicit condition under which this decision
      will be reversed, and what replaces it. Not all ADRs need a kill switch,
      but include one whenever the decision is conditional on assumptions that
      could falsify (a vendor's licensing position, a benchmark, a price band).
-->

### Positive

### Negative

### Kill switch

## Alternatives Considered

<!--
  For each alternative: a one-line summary of what it was, then a one- or
  two-line statement of why it was not selected. The point is not to relitigate
  — it is to make the decision space legible to a future reader who will ask
  "did you consider X?" and deserves a real answer.
-->

## Concerns / Open Questions

<!--
  What is still unresolved after this decision lands. Items here should
  graduate over time: each gets resolved (and the resolution noted in the ADR
  itself or in a follow-up ADR), or escalates into its own ADR. An ADR with
  an unresolved Concerns section after six months is a signal to revisit.
-->
