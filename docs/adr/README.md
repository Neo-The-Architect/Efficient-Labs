# Architecture Decision Records (ADRs)

This directory holds the Architecture Decision Records for Efficient Labs. An ADR documents a single decision: what was decided, what forced the decision, what changes as a result, and what could reverse it. ADRs are the durable record of the system's reasoning — they exist so that a future operator (or auditor, or successor) can read them in order and understand why the system looks the way it does without having to reconstruct the conversations that produced it.

ADRs are written *after* the decision is made, not as a proposal mechanism. A decision under active debate belongs in a working document, an issue, or a chat thread; it becomes an ADR once the decision is settled.

## Index

| # | Title | Status | Date |
| --- | --- | --- | --- |
| [0001](0001-weft-paperclip-architectural-boundary.md) | Weft / Paperclip architectural boundary | Accepted | 2026-04-27 |
| [0002](0002-postgres-single-instance-shared-process.md) | Postgres single instance, shared process | Accepted | 2026-04-27 |
| [0003](0003-n8n-licensing-posture-standard-tier-only-week-1.md) | n8n licensing posture: Standard tier only, Sovereign tier blocked | Accepted | 2026-04-27 |
| [0004](0004-commit-attribution-claude-author-neo-reviewer.md) | Commit attribution: Claude as author, Neo as reviewer-of-record | Accepted | 2026-04-25 |
| [0005](0005-tailscale-ssh-as-primary-access-path.md) | Tailscale SSH as the primary operator access path | Accepted | 2026-04-28 |

## Numbering policy

ADR numbers are **monotonic, four-digit, zero-padded** integers. The next ADR is the highest existing number plus one — gaps from withdrawn or duplicate ADRs are fine and **must never be renumbered**, because every prior ADR's references to a number are durable, and every commit, PR, and external link that mentions an ADR number is a fixed pointer.

A worked example: ADR 0003 references "ADR 0005" in its concerns section as a placeholder for a number that had not yet been assigned. When ADR 0005 was eventually authored, it landed as a different topic (Tailscale SSH access path) than the placeholder reference suggested (n8n licensing). The placeholder reference in 0003 was left as a historical note; the licensing decision lives at 0003 itself. **The numbers do not encode topic — they encode order of authorship.** Look up an ADR by number through this index, not by guessing from the topic.

A withdrawn ADR keeps its number and stays in the index with status `Withdrawn`. A superseded ADR keeps its number and stays in the index with status `Superseded by NNNN`. Both remain readable — the rationale they captured at the time is part of the system's history.

## When to write an ADR

Open a new ADR when the answer to any of these is "yes":

- Did this change introduce a constraint that subsequent decisions will have to respect?
- Did this change rule out an alternative that a reasonable operator might have picked?
- Will a future reader, looking at the system, ask "why did you do it this way?" and deserve a real answer?

If none of those apply, the change probably does not need an ADR. Routine implementation choices, well-trodden patterns, and decisions that flow obviously from prior ADRs do not need their own document.

## Authoring process

1. Copy `_template.md` to `NNNN-<short-kebab-slug>.md`. Pick `NNNN` as the next free integer after the highest existing ADR.
2. Fill in the sections. Be concrete. Reference architecture report sections, prior ADRs, and external sources by link. If the decision was reached in a conversation that is not preserved on disk, add the post-hoc honesty line described in the template.
3. Set status to `Accepted` (when the decision is final) or `Proposed` (when the document is opening the discussion). Most ADRs in this repo will land directly as `Accepted` — see the note above about ADRs being written after decisions, not as proposals.
4. Add the row to the index above. The index is the discoverability surface for the directory; an ADR not listed here is hard to find.
5. Open a PR. The PR review is the operator's record of approval. Merge to `main` ratifies the ADR.

## Authoring discipline

ADRs in this repo are written in the same operating voice as the runbooks: factual, specific, no hedging on the decision itself, honest about uncertainty in the consequences and concerns sections. A reader should be able to act on what an ADR says — provision a system, write a contract, defend a position to a client — without having to call the operator to clarify.

The honest-about-provenance line is non-negotiable for ADRs reconstructed from off-disk discussions. Documenting what was decided is the contract; documenting how the record was produced is the discipline.
