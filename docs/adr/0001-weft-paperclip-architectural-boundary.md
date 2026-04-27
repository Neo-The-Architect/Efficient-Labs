# ADR 0001 — Weft / Paperclip architectural boundary

- **Status:** Accepted
- **Date:** 2026-04-27
- **Captures:** Section 1 of `docs/architecture/2026-04-27-fulfillment-architecture-report.md`
- **Supersedes:** —

## Context

Efficient Labs runs two general-purpose orchestration systems on the same VPS: Weft (typed dataflow language with durable execution and human-in-the-loop primitives) and Paperclip (multi-agent business OS with `SKILL.md`, Hindsight memory, budget ceilings, and Routines). Both can in principle drive the fulfillment loop end-to-end. Letting either own the whole loop hides the property the operator most values: a typed contract at every boundary between deterministic flow and judgment work. Letting them overlap arbitrarily produces ad-hoc decisions and entangled state.

The architecture report Section 1 walks the loop step by step and assigns ownership. This ADR captures the rule and the resulting responsibility split as the load-bearing decision.

## Decision

**Weft owns the deterministic outer loop.** Specifically: typed durable orchestration, compile-time-checked dataflow, webhook ingest, third-party API calls with typed contracts (Apollo, Tavily, Stripe), pure-function pricing, single-shot LLM calls templated against a typed input (proposal generation, qualification gating), human-in-the-loop pauses via Restate awakeables, cron-based monitoring, and tier-conditional delivery branches.

**Paperclip owns the judgment-heavy inner loop.** Specifically: PRD generation (Solutions Architect agent), n8n workflow file generation (n8n CTO agent, `claude_local` adapter, per-client `cwd`), workflow QA review (separate QA agent), client-onboarding intake-bundle assembly (Onboarding agent), inbound support triage (Support agent), and the entirety of internal Efficient Labs ops (CEO weekly review, Sales pipeline, Ops financial close, Content Publishing — all long-lived agents with company-scoped Hindsight memory and cron-driven Routines).

**Hybrid steps default to Weft outer / Paperclip inner.** Lead qualification runs deterministic rules in a Weft `code` node first; ambiguous cases escalate to a Weft `LlmInference` call. Onboarding orchestration is Weft (Email + Human Trigger), but the intake-bundle judgment is a Paperclip Issue. Workflow review is a three-layer gate: Weft schema validator → Paperclip QA agent critique → operator approval via `POST /api/companies/{cid}/approvals`.

The full per-step responsibility table from architecture report Section 1 is the authoritative version. This ADR refers to it rather than duplicating it.

## Consequences

**Positive.** Every cross-boundary call is a typed contract — Weft HTTP node calls Paperclip REST endpoints with bearer auth; Paperclip events flow back via the (forthcoming) plugin event bridge. The operator can read where any piece of work lives by asking "is this deterministic or judgment-heavy?" and "does this need persistent agent memory?" The two systems can be upgraded and operated independently — Paperclip's calver churn does not touch Weft's runtime, and Weft's breaking changes do not touch Paperclip agents.

**Negative.** Two runtimes to operate (one Postgres process, but two databases; two backup sets to verify; two upgrade rituals). One more integration boundary to keep healthy (the plugin event bridge, until that ships, polling). Operator must internalize the rule before assigning a new piece of work to either system.

**Kill switch.** If Paperclip's bus-factor risk materializes (architecture report Section 9), Architecture C (standalone Claude Code script triggered by a Weft `code` or HTTP node directly against the Anthropic API) replaces every Paperclip-owned step except internal ops. Internal ops would migrate to a thinner orchestrator — likely Weft cron triggers driving direct Anthropic API calls — losing Hindsight memory but preserving the loop. This fallback is the subject of ADR 0006 (forthcoming, per architecture report Section 8 Week 3 milestone).

## Concerns / Open questions

None blocking. The decision is decision-grade per the architecture report. Re-examine if Weft adds first-class agent-loop primitives (subsuming Paperclip's value) or if Paperclip ships native typed-dataflow primitives (subsuming Weft's value). Neither is on either project's public roadmap as of 2026-04-27.
