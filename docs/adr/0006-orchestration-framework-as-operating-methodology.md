# ADR 0006 — Efficient Labs operates within The Orchestration Framework

- **Status:** Accepted
- **Date:** 2026-04-29
- **Captures:** The architectural relationship between Efficient Labs (the business) and The Orchestration Framework (the operating methodology). Establishes that the engineering discipline visible in this repo — ADRs, runbooks, audits, public commit attribution — instantiates a methodology that pre-exists the business and is published independently.
- **Supersedes:** —

## Context

Recorded on 2026-04-29 by Claude Code under operator direction; the original methodology was authored by the operator independently and operated in private form for some time before being published. Decision authority: NeoTheArchitect (operator).

Efficient Labs requires a coherent operating methodology that defines how the operator commands the agentic stack of AI tools, how decisions are captured, how files are organized, how rhythms keep the system honest, and how failure modes are anticipated. The previous five ADRs (`0001` Weft/Paperclip boundary, `0002` Postgres single-instance, `0003` n8n licensing, `0004` commit attribution, `0005` Tailscale SSH) record specific architectural choices, but none of them captures the underlying methodology those choices express. The discipline visible across all five ADRs — the captures-and-supersedes pattern, the kill-switch convention, the "decision authority: operator" provenance line, the public-by-default posture — is not arbitrary; it is the local instantiation of a general methodology.

That methodology has now been published publicly, as a separate repository, at https://github.com/Neo-The-Architect/The-Orchestration-Framework. It defines six philosophical foundations (orchestrator principle, files-over-memory, three layers of state, token efficiency, decisions-as-artifacts, killswitch), a vault file architecture, four agentic-stack roles, three operating rhythms, three trigger words, and seven recurring failure modes with countermeasures. Codifying the relationship between business and methodology in an ADR removes ambiguity for future contributors, prospective clients evaluating the engineering posture, and future-self auditing whether the framework is still being followed.

The choice to publish the methodology as a separate repository — rather than inline it into Efficient Labs or keep it private — was made deliberately and is captured in the framework's own repo. This ADR closes the loop on the Efficient Labs side.

## Decision

**Efficient Labs operates within The Orchestration Framework methodology**, published publicly at https://github.com/Neo-The-Architect/The-Orchestration-Framework. The methodology defines the philosophical foundations, file architecture, agentic stack roles, operating rhythms, trigger words, and failure modes that govern how Efficient Labs work is conducted.

**Specific implementations within Efficient Labs instantiate the methodology rather than substitute for it.** The engineering discipline scaffold (Layers 1–7), the ADR pattern, the runbook protocol, the audit-and-publish cadence, the public-vs-private repo boundary, and the build-in-public posture are all specific instantiations of the framework's general principles applied to the business's particular context. They do not replace the methodology; they express it.

**Future ADRs and runbooks may reference framework concepts by name** without re-deriving them. When a runbook says "the operator session" it inherits ADR 0005's Tailscale-SSH posture; when an ADR says "decision-as-artifact" it inherits the framework's [philosophy 5](https://github.com/Neo-The-Architect/The-Orchestration-Framework/blob/main/philosophy/05-decisions-as-artifacts.md); when a script references the killswitch it inherits the framework's [philosophy 6](https://github.com/Neo-The-Architect/The-Orchestration-Framework/blob/main/philosophy/06-killswitch.md). The framework is the canonical source for these concepts; this repo is an implementation that draws from it.

**Efficient Labs follows the latest version of the framework** unless an explicit version pin is made via a subsequent ADR. The framework is at v0.1 at the time of this decision; future framework versions are inherited automatically as they ship, on the assumption that the framework's evolution remains aligned with the business's needs. If a future framework change is incompatible with Efficient Labs' current posture, that incompatibility is itself a decision that warrants an ADR — either updating Efficient Labs to follow the new version or pinning to a prior version with the rationale recorded.

## Consequences

### Positive

- **Engineering discipline is principled, not intuited.** A future reader, an auditor, or a prospective client can read the framework and understand *why* the discipline visible in this repo is shaped the way it is, rather than treating each ADR and runbook as an isolated craft choice.
- **Future ADRs and runbooks compress.** Concepts the framework already names (the orchestrator principle, files-over-memory, decisions-as-artifacts, the killswitch, the seven failure modes) can be referenced rather than re-explained. New documents land shorter and clearer.
- **Trust accretion compounds.** Clients evaluating Efficient Labs find both the business's engineering discipline (this repo) AND the underlying methodology (the framework repo). That two-layer credibility is unusual in the AI consultancy market and is structurally hard to fake.
- **Methodology adoption by other operators is unblocked.** Because the framework is published independently, other operators can adopt it without entangling with the Efficient Labs business. The methodology lives or dies on its own merits, and its survival reinforces (or invalidates) the discipline this repo expresses.

### Negative

- **Cross-repo sync discipline is now a requirement.** When the framework evolves, documents in this repo that reference framework concepts by name should be reviewed for accuracy. The cost is real but bounded — the framework's stable trunk (the ten directories, the four roles, the six principles) is unlikely to change shape often.
- **A future framework change could create lag.** If the framework introduces a concept that materially changes how a piece of Efficient Labs work should be done, there is a window where this repo lags. The mitigation is the version-pin escape hatch (a follow-up ADR pins to a prior framework version) but the cost is friction during the lag window.
- **Two repos to maintain instead of one.** The framework's lifecycle is now decoupled from the business's. The operator carries the cost of evolving both. This was a deliberate trade — see Alternatives.

### Kill switch

This ADR is reversed if any of the following becomes true:

- The Orchestration Framework is taken down, abandoned, or ceases to be maintained as a public artifact, and Efficient Labs needs the methodology to remain accessible to clients and contributors. Mitigation in that case: fork the framework into a private mirror, document the fork in a successor ADR, and continue operating against the mirrored version.
- The framework's evolution diverges materially from Efficient Labs' needs (e.g., the framework adopts a posture that is incompatible with the business's regulatory or commercial constraints) and a version pin is no longer sufficient. The replacement would be a methodology-fork ADR forking the framework's content as Efficient Labs' internal methodology, breaking the cross-reference posture.
- The business's character changes such that the framework no longer applies (e.g., a transition from solo-operator-plus-AI to a multi-engineer team running a 24x7 service). The framework is explicit that some of its postures (Tailscale SSH for solo operators, Claude-as-author commit attribution) are appropriate for the current operator profile and should be revisited as the profile changes. A successor ADR would record the transition.

## Alternatives Considered

- **Operate without explicit methodology citation.** Rejected: leaves the engineering discipline appearing intuitive rather than principled. A prospective client reading this repo without the framework reference can see *that* the discipline is unusual but not *why* it takes the specific shape it does. The methodology citation closes that gap.
- **Inline the methodology into Efficient Labs directly.** Rejected: couples the business's lifecycle to the methodology's lifecycle and prevents independent methodology adoption by other operators. The business is one instantiation of the methodology; the methodology should be free to apply elsewhere without entangling with the business's commercial constraints.
- **Keep the methodology private.** Rejected: eliminates the trust-accretion benefit of build-in-public credibility. Private methodology paired with public business asks the prospective client to take the methodology on trust; public methodology lets the prospective client verify the methodology against the business's actual practice.

## Concerns / Open Questions

- **The Orchestration Framework is at v0.1 — early version.** ADRs and runbooks in this repo that reference framework concepts may need amendment if the framework's structure changes substantially before v1.0. The mitigation is light-touch: review framework changes during the monthly system audit (per the framework's own monthly rhythm) and update affected documents incrementally rather than in large batches.
- **Cross-repo sync discipline is unspecified.** A formal procedure for detecting drift between this repo's framework references and the framework's current state has not been defined. The current posture is ad-hoc operator review during the monthly audit. A future ADR may specify a tighter procedure (e.g., automated link-checking against the framework repo, or a periodic doc-cross-reference audit) if the ad-hoc posture proves insufficient.
- **Framework version visibility in this repo.** This ADR does not pin a specific framework version. There is currently no record in this repo of *which* framework version is being followed at any given time. If multiple version-pinning ADRs accumulate over time (or if the framework introduces breaking changes), a `docs/operating-methodology-version.md` or equivalent may be warranted. Tracked as a follow-up; not blocking for this ADR.
