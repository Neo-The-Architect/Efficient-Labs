# Fulfillment architecture for Efficient Labs

**TL;DR.** Build the fulfillment loop as a **Weft-primary, Paperclip-secondary** stack on the hardened VPS, with Claude (via direct Anthropic API) as the intelligence layer and n8n strictly as the deliverable. Weft owns deterministic flow, typed data, durable state, and human-in-the-loop checkpoints. Paperclip owns judgment-heavy agent work that benefits from autonomy and memory — chiefly the n8n workflow generation and the internal "CEO/Sales/Ops" board. Avoid Tangle entirely for client work (no on-prem, no DPA, no sub-processor disclosure as of April 27, 2026); use Claude Code pointed at the Weft repo to author Weft programs in private. Run Postgres as a single shared external instance with role-separated databases for Paperclip and Weft; do not share the embedded-postgres on 54329. Self-host Restate on the same VPS (single binary, RocksDB, BUSL-1.1). Use Stripe Standard + Stripe Billing + Stripe Tax — Connect is unnecessary. Do **not** offer a managed-n8n MRR tier in the first 60 days: n8n's Sustainable Use License explicitly forbids hosting-and-charging, so the Sovereign tier needs an n8n Embed conversation (~$50K/yr range, unverified) before it ships. Sequence: Week 1 ship Weft + Paperclip + Postgres + Restate on the VPS with a public lead-intake graph; Week 2 ship the proposal/PRD half of the loop with operator-as-CTO-reviewer; Week 3 ship the n8n-generation Paperclip agent for handoff-tier deliverables. The managed-tier and SOC 2 Type I work begins after the first three paying clients land. Every artifact except client-confidential PRDs and credentials ships to a public mono-repo as the build-in-public flywheel.

---

## Section 1 — Architectural boundary: Weft vs Paperclip

The decision rule is sharp once you accept what each system actually is. **Weft is a typed dataflow language with durable execution and HITL primitives** — it earns its place wherever flow is deterministic, types matter, the graph survives restart, and a human pause is part of the contract. **Paperclip is an agent operating system** — it earns its place wherever an autonomous agent needs a long-lived context (SKILL.md), a budget ceiling, persistent memory (Hindsight), and the ability to take many sub-steps under one Issue without the orchestrator caring about each one. Where you have one obvious answer, take it. Where both could work, let Weft win on the outer loop and Paperclip win on the inner judgment, because that gives you a typed contract at every boundary.

**Lead webhook ingest** lives in Weft. The catalog ships a webhook trigger node and the marketing-site form is a deterministic POST with a known body shape — exactly the place Weft's compile-time type checking earns its keep. Paperclip's API has no inbound webhook router; you would reinvent it.

**Lead enrichment** lives in Weft. Apollo and Tavily web search are first-class Weft enrichment nodes. The output is a typed `enriched_lead` record. Forcing this into a Paperclip agent gives you nothing but token cost and unbounded judgment where you want neither.

**Lead qualification scoring** is **hybrid, but Weft-anchored**. Run a deterministic rule pass first inside a Weft `code` node (industry, employee count, signals, hard exclusions). Only if the rule layer returns "ambiguous" do you escalate to a Weft `LlmInference` call with structured output for a judgment score. This keeps token spend bounded and the pipeline auditable.

**Proposal/scope generation** lives in Weft. The `LlmInference` node with a templated system prompt and the enriched lead as input produces a draft proposal. This is one LLM call, not an agent loop; it doesn't need Paperclip's machinery. The prompt template lives in version control.

**Pricing calculation** lives in Weft as a pure `code` node. Pricing is a function of tier × scope × custom add-ons; it must be deterministic and auditable. Never let an LLM set a price.

**Stripe checkout link generation and payment confirmation** lives in Weft. The HTTP node hits Stripe's REST API to create a Checkout Session; a separate webhook trigger receives `checkout.session.completed`. Both directions are typed and deterministic.

**Post-payment client onboarding** is **hybrid, with Weft owning the orchestration and Paperclip owning the long-form intake judgment**. Weft sends the welcome email (Email node) and provisions the intake form (Human Trigger node). When the form returns, Weft hands the raw responses plus enriched lead context to a Paperclip Issue assigned to a "Client Onboarding" agent whose SKILL.md teaches it how to assemble an Asset Bundle (credentials needed, integrations to confirm, edge cases to flag). The agent comments back into the Issue; Weft polls or receives the result via the plugin event bridge.

**PRD generation** is **Paperclip-owned**. This is the single most leveraged judgment task in the loop. A "Solutions Architect" Paperclip agent with a SKILL.md for the Efficient Labs PRD format reads the intake bundle, asks clarifying sub-issues if needed, and produces a markdown PRD. Hindsight memory across PRDs makes it better over time — a Weft `LlmInference` call cannot accumulate that. The Issue is created and tracked by Weft via HTTP; the operator approves the PRD via Paperclip's `POST /api/companies/:id/approvals`.

**n8n workflow file generation** is **Paperclip-owned, executed by a `claude_local` adapter agent.** This is Architecture B from Section 4 (full reasoning there). A Paperclip "n8n CTO" agent with a `cwd` set to a per-client git workspace, a SKILL.md that encodes the n8n JSON schema and Efficient Labs' workflow archetypes, and budget ceiling enforcement, reads the PRD and writes the JSON. It commits to a private client repo. Weft observes completion via the API.

**Workflow review and refinement** is **a three-layer gate**. Layer 1: a deterministic Weft `code` node validates the JSON against n8n's schema (catches malformed nodes, missing connections). Layer 2: a second Paperclip "QA" agent reads the workflow and writes a critique Issue. Layer 3: the operator reviews the diff in the client repo and either approves via Paperclip approval endpoint or comments to send back. The operator gate is non-negotiable for v1; you can soften to spot-checks once you have telemetry on agent quality.

**Delivery** is **Weft-owned and conditional on tier**. For Standard (handoff) tier, Weft's Email node attaches the JSON file or links to a one-time download URL. For Sovereign (managed) tier, a Weft `code` node provisions a per-client n8n systemd unit on the VPS (separate Linux user, separate Postgres DB, distinct `N8N_ENCRYPTION_KEY`, Tailscale Funnel binding). **Sovereign tier should not ship until n8n Embed licensing is resolved** — see Section 9.

**Support intake** is **hybrid**. Inbound channel (email, intake form, Discord) hits Weft webhook → Weft creates a Paperclip Issue assigned to a "Support" agent → agent triages, may resolve directly, may escalate to operator via approval. The escalation gate stops AI from auto-closing real bug reports.

**Recurring monitoring of hosted-tier client n8n instances** is **Weft cron triggers**. Five-minute cron node hits each client n8n's `/healthz`, parses the response, writes status to Postgres. On failure: Weft pauses, opens a Paperclip Issue, notifies the operator via the browser extension Human Query node. Don't put monitoring inside Paperclip — agents are expensive heartbeats; cron is free.

**Internal Efficient Labs ops** is **fully Paperclip**. The "CEO weekly review," "Sales pipeline," "Ops financial close," and "Content publishing" agents are exactly what Paperclip was designed for: long-lived agents with company-scoped Hindsight memory, SKILL.md operating procedures, cron-driven Routines, budget ceilings, and approval-gated actions. Weft doesn't need to be involved unless an internal workflow itself needs to call out to typed external services.

```
                  ┌───────────────────────── EXTERNAL EDGE ──────────────────────────┐
                  │                                                                   │
   Marketing site form ─────► Weft webhook trigger (typed JSON)                       │
                  │                          │                                         │
                  │                          ▼                                         │
                  │                  Weft enrichment chain                             │
                  │       (Apollo → Tavily → enriched_lead: EnrichedLead)              │
                  │                          │                                         │
                  │                          ▼                                         │
                  │              Weft qualification (rules → LLM gate)                 │
                  │                          │                                         │
                  │                          ▼                                         │
                  │       Weft proposal draft (LlmInference, structured output)        │
                  │                          │                                         │
                  │                          ▼                                         │
                  │       Weft pricing (code node, pure function)                      │
                  │                          │                                         │
                  │                          ▼                                         │
                  │   ┌────── Weft Human Trigger: operator approves proposal ───────┐ │
                  │   │             (browser extension, Restate awakeable)           │ │
                  │   └──────────────────────────┬───────────────────────────────────┘ │
                  │                              ▼                                     │
                  │           Weft → Stripe Checkout (HTTP node)                       │
                  │                              │                                     │
                  │                              ▼                                     │
                  │     Stripe webhook ─► Weft `checkout.session.completed` trigger    │
                  │                              │                                     │
                  │                              ▼                                     │
                  │            Weft welcome email + Human Trigger: intake form         │
                  │                              │                                     │
                  ╰──────────────────────────────┼─────────────────────────────────────╯
                                                 ▼
            ┌────────────────────────── PAPERCLIP BOARD (per-client company) ─────────────────────┐
            │                                                                                       │
            │  Weft HTTP ──► POST /api/companies/{cid}/issues  (assigneeAgentId = onboarding)       │
            │                            │                                                          │
            │                            ▼                                                          │
            │     [Onboarding agent, claude_local, SKILL.md = intake-bundle]                        │
            │                            │ comments work product back                               │
            │                            ▼                                                          │
            │      Weft polls /api/issues/{id} OR plugin-sdk event bridge → Weft resume             │
            │                            │                                                          │
            │                            ▼                                                          │
            │  Weft HTTP ──► new Issue (assigneeAgentId = solutions_architect)                      │
            │                            │                                                          │
            │                            ▼                                                          │
            │     [Solutions Architect agent → drafts PRD.md, requests approval]                    │
            │                            │                                                          │
            │  POST /api/companies/{cid}/approvals  ◄── Operator approves in Paperclip UI           │
            │                            │                                                          │
            │                            ▼                                                          │
            │  Weft HTTP ──► new Issue (assigneeAgentId = n8n_cto, blockedBy = none)                │
            │                            │                                                          │
            │                            ▼                                                          │
            │     [n8n CTO agent, claude_local, cwd = /var/lib/efficient-labs/clients/{cid}/]       │
            │     reads PRD.md, writes workflow.json, commits to private GitHub repo                │
            │                            │                                                          │
            │                            ▼                                                          │
            │     [QA agent (separate company role) reviews workflow.json, files critique]          │
            │                            │                                                          │
            │  POST /api/companies/{cid}/approvals  ◄── Operator approves shipping                  │
            │                            │                                                          │
            ╰────────────────────────────┼──────────────────────────────────────────────────────────╯
                                         ▼
                       Weft delivery branch (typed Tier enum):
                          ├─ Standard: Email node attaches JSON  +  GitHub release
                          └─ Sovereign: code node provisions n8n systemd unit + Tailscale Funnel
                                         │
                                         ▼
                        Weft cron (5-min) monitoring loop  ──► on failure ──►
                          Paperclip Support Issue + Human Query to operator
```

---

## Section 2 — Paperclip ↔ Weft state-sharing

The integration is asymmetric and that asymmetry is the design. Weft can call Paperclip cleanly via HTTP because the Paperclip REST API is well-documented, bearer-auth, and idempotent. Paperclip cannot natively call Weft because **Paperclip ships no outbound webhook system today** — issue #1790 ("Outbound webhook system for agent and issue events") is open and explicitly confirmed unshipped by maintainer responses. Treat that as load-bearing fact.

**Direction 1 — Weft → Paperclip.** Use the Weft HTTP node against Paperclip's REST API. The endpoints you need are confirmed: `POST /api/companies/{id}/issues` to create work, `POST /api/companies/{id}/approvals` to request operator approval, `PATCH /api/issues/{id}` for `blockedByIssueIds` and `status` mutations, `GET /api/issues/{id}/comments?after=...` for tailing agent output. Auth is `Authorization: Bearer pcp_board_…` with a long-lived board API key minted once and stored in Weft's secret store (Weft's `password`/`api_key` field types get stripped from publish artifacts, so this is the right home for it). The `X-Paperclip-Run-Id` header should be set on all mutations for audit. There is no OpenAPI spec, so you are coding against the prose API reference at `skills/paperclip/references/api-reference.md` plus issue threads.

**Direction 2 — Paperclip → Weft.** Three options, ranked by robustness:

1. **Plugin SDK event bridge (recommended).** Write a small in-process Paperclip plugin (`@paperclipai/plugin-sdk`) that subscribes to `issue.created`, `issue.status.changed`, `issue.work_product.added`, `agent.run.completed`, and `approval.granted` events via `ctx.events.on(...)` and POSTs each event to a Weft webhook trigger URL. This is the native, supported observation surface. ~150 LOC of TypeScript. Lives in your public mono-repo as `paperclip-plugin-weft-bridge`.

2. **Polling.** A Weft cron node hits `GET /api/issues/?assigneeAgentId={id}&status=in_progress&since={cursor}` every 30–60 seconds. Simpler, but introduces 30–60s latency and load on Paperclip. Acceptable for the v1 loop where human-in-the-loop already adds minutes.

3. **MCP server bridge.** `@paperclipai/mcp-server` is a thin MCP wrapper over the REST API; it exposes 8 tools (get_issue, update_issue_status, add_comment, list_comments, create_sub_issue, list_issues, hire_agent, request_approval) over stdio. **MCP is for AI agents to consume, not for service-to-service integration.** Don't use it as an event bus.

**Recommendation: plugin event bridge for events, HTTP for commands. Polling as the initial fallback while the plugin is being built.**

**Postgres sharing.** Do not share the embedded Postgres on 54329. The `embedded-postgres` driver bakes credentials, the schema is owned by 38+ Drizzle migrations that change with every calver release, and Paperclip's docs do not document external connection as a supported integration. The right pattern is **one external Postgres process on the VPS, two databases, two roles**: `paperclip` DB owned by `paperclip` role with `DATABASE_URL` set in Paperclip's environment to point at it, and `weft` DB owned by `weft` role used by Weft's metadata. This eliminates the embedded-postgres driver entirely (Paperclip supports external `DATABASE_URL`), gives you one backup target, and prevents schema-evolution races. Restate brings its own RocksDB and does not need Postgres at all.

**Shared message bus.** No. Postgres `LISTEN/NOTIFY` is technically present (it's vanilla Postgres) but Paperclip does not document channel names and treats it as unsupported; relying on it would couple you to undocumented internals. Redis pub/sub or NATS would add a third runtime to operate. The plugin event bridge gives you the same outcome with one less moving piece.

**Latency profile.** A Weft Human Query is implemented on top of Restate awakeables — the program literally suspends in the durable executor until a resolution is delivered. A "wait until Paperclip Issue resolves" cannot ride that mechanism directly because Paperclip doesn't know about Weft's awakeable IDs. Two patterns work:

- **Long pause via plugin bridge.** When Weft creates the Paperclip Issue, it embeds an awakeable token in the Issue body. The plugin observes `issue.status.changed → done` and POSTs `{awakeable_id, result}` back to a Weft resume webhook. End-to-end: a human-day pause survives crashes natively. **This is the architecturally correct pattern** and matches Weft's Human Query semantics.
- **Polling pause.** Weft cron polls `/api/issues/{id}` every minute until status flips. Lossy in the sense that the loop wakes up on its own clock, not the event clock; but trivial to ship in week one.

Use polling first (week 1), graduate to plugin bridge (week 3+) when the plugin is written and tested.

**Tradeoff summary.** The plugin path is the destination architecture; polling is the bootstrap. Both fit on the single VPS. Both keep Paperclip as the agent OS and Weft as the typed durable orchestrator without entangling their schemas.

---

## Section 3 — Tangle deployment posture

**Tangle is not self-hostable as of April 27, 2026.** No on-prem build, no Tangle Enterprise SKU, no source-release roadmap, no Docker image, no BYOK-mode, no air-gapped path. The Weft deploy docs explicitly say "anything session-like you see on weavemind.ai hosted pages is cloud-side and not part of the open source drop." The WeaveMindAI GitHub org has only two repos (`weft` and `Webfurl`); no `tangle/` exists. The Enterprise pricing tier mentions "white-label deployment" but in WeaveMind's vocabulary that means publishing user-facing pages on WeaveMind cloud under a custom brand, not deploying the platform into customer infrastructure. The license (O'Saasy) explicitly forbids running a competing hosted service.

**Data exposure if you used Tangle anyway.** Prompts and generated Weft code traverse: browser → app.weavemind.ai → WeaveMind backend → OpenRouter → Anthropic/OpenAI/etc. Quentin confirmed on HN pre-launch that OpenRouter is the path, with no Anthropic-direct option. There is no published privacy policy, no DPA, no sub-processor list, no SOC 2, no GDPR Article 28 controller/processor agreement, no "do not retain / do not train" toggle, no data-residency statement on weavemind.ai. None of this would pass a basic vendor-risk review for regulated-industry clients. For Efficient Labs' ICP this is a non-starter.

**Replacing Tangle with Claude Code.** Quentin himself endorsed this path on LinkedIn ("If you want to use AI to build you can use my app, but on the back it is using this os repo"). The repo includes a `.claude/` directory in its root, which is a Claude Code configuration directory — strong signal that Quentin uses Claude Code against the Weft repo for his own work. The replacement recipe is concrete: clone `github.com/WeaveMindAI/weft` into a workspace, point Claude Code at `catalog/`, `DESIGN.md`, `CONTRIBUTING.md`, `ROADMAP.md`, and the docs site (cache `weavemind.ai/docs/{nodes,connections,types,groups,parallel,humans,deploy}` locally), then ask Claude Code to emit `.wft` files. The compiler does the heavy lifting Tangle's "self-correcting builder" claims to do — typing catches missing connections and architectural mistakes at compile time, which is the same leverage. The "20× faster than Cursor and Claude Code" headline is a single anecdote ("4 minutes vs 1h30") with no published methodology, no benchmark, no eval harness; treat as marketing.

**Recommended posture: never use Tangle on client work. Use it during personal dev exploration if you want to compare; otherwise skip entirely.** If WeaveMind ever ships a self-hostable Tangle Enterprise tier, revisit. Until then, pointing Claude Code (Sonnet 4.6 or Opus 4.7 via direct Anthropic API, not OpenRouter) at the Weft repo is both the sovereignty-correct path and the public-build-correct path — every Weft program you write becomes a public artifact whose authorship story is "an AI wrote it from the public docs," which is itself a credible demo of your stack.

The one caveat: if Quentin opens a private Tangle-on-prem conversation (his stated awareness on HN — *"deploy without choosing between 'all cloud' and 'all self-hosted'"* — suggests he could entertain it), it might unlock 20× iteration on internal tooling that never touches client data. That's a six-month-out conversation, not a week-one decision.

---

## Section 4 — Workflow generation logic placement

**Recommendation: Architecture B — Paperclip-managed Claude Code agent — wins, with Architecture C as the fallback if Paperclip's bus-factor risk materializes.**

**Architecture A (Weft-native) loses on craft.** Building a Weft node that emits n8n JSON would mean either (a) a single `LlmInference` call with a giant prompt that rarely produces valid JSON for non-trivial workflows, or (b) a custom Rust node that wraps an iterative agent loop — at which point you've reinvented Paperclip inside Weft, badly. Weft's compile-time type checking does not extend to the *content* of a `String` output port; producing valid n8n JSON from a single LLM call is precisely the kind of brittle judgment-heavy task Weft is honest about not being good at. Pros: single runtime, one less integration. Cons: poor output quality on real workflows, no SKILL.md memory, no Hindsight learning, no per-agent budget, no agent-loop resume, no multi-turn correction. Reject.

**Architecture B (Paperclip CTO agent) wins on every axis except minimalism.** A Paperclip "n8n CTO" agent with `adapterType: claude_local` runs Claude Code as a subprocess in a per-client `cwd` (a git worktree at `/var/lib/efficient-labs/clients/{cid}/`). The SKILL.md teaches it the n8n JSON schema, lists Efficient Labs' workflow archetypes, encodes the validation rules. Hindsight memory (bank-scoped `paperclip::{efficient-labs}::{n8n-cto}`) accumulates patterns across engagements — "the last six clients with HubSpot wanted X, so the default for HubSpot is X." Budget ceilings cap token spend per workflow. The agent reads the PRD, asks sub-Issue questions if needed, writes `workflows/main.json`, runs a local validator, commits to the private client repo, and posts the commit SHA back via comment. Weft observes via the plugin bridge or polling.

What Architecture B buys: maintainability (the agent's behavior is configured, not coded), debuggability (every agent run has a heartbeat trail, every JSON change has a git diff), version control (per-client repo is the source of truth), public-build value (the "n8n CTO agent" itself is a public artifact you can showcase — it's the most ownable piece of the IP), output quality (multi-turn agent with tool use beats single-shot LLM), type safety at the boundary (the agent's output is validated by a Weft `code` node before delivery, giving you the typed contract you wanted). What it costs: one more Paperclip company to operate, exposure to Paperclip's bus-factor risk, calver-velocity churn risk on Paperclip API.

**Architecture C (Standalone Claude Code script triggered by Weft) is the explicit fallback.** If Paperclip becomes unmaintained or its API breaks, a Weft `code` node can shell out to the Anthropic API directly with a structured prompt template (the Weft `code` node is Python, sandboxed; whether it permits `subprocess` is unverified — it likely does not, in which case use the HTTP node against `api.anthropic.com/v1/messages` with the Files API for context). Output JSON is captured, validated by a sibling `code` node, returned to the graph. Pros: simplest possible, zero Paperclip dependency, single failure surface. Cons: no agent loop (single-shot generation produces lower quality on real workflows), no SKILL.md/Hindsight learning curve, no multi-turn correction, you reinvent budget tracking. Use only if Paperclip dies.

**Decision rationale by axis.**

- *Maintainability:* B (configuration files) > C (one prompt template) > A (custom Rust node).
- *Debuggability:* B (heartbeat trail, git diff per change) > C (single LLM call log) > A (graph trace, but content opaque).
- *Type safety:* All three rely on a post-generation validator; B and C feed back through Weft's typed `code` validator equivalently. A is no better despite being "in" the typed graph.
- *Version control:* B owns this — per-client git repo is native. C and A would need to be retrofitted with git.
- *Public-build storytelling:* B wins. A "Paperclip agent that writes n8n JSON" is a more striking demo than "a Python script that calls an LLM." It also lets you open-source the SKILL.md, the n8n archetype library, and the `paperclip-plugin-weft-bridge` as three distinct marketing artifacts.
- *Output quality:* Empirically, multi-turn agents with tool use and memory beat single-shot LLM calls on structured-output tasks at the n8n-workflow scale. B's agent loop dominates.

Build B. Keep C as a documented escape hatch in the ADR.

---

## Section 5 — Multi-component fallback architecture

The honest answer is that on a single-VPS deployment, most fallbacks are "pause-and-retry plus operator alert" because there is no second VPS to fail over to. The interesting design question is *which* failures warrant *which* response and at what cost.

| Component | What fails when down | Right response | Cost | Operator alert |
|---|---|---|---|---|
| **Anthropic API** | All Claude calls — Paperclip agents, PRD gen, n8n CTO agent | Multi-vendor for Weft `LlmInference` (route via OpenRouter to a backup model). Paperclip pause-and-retry; cannot transparently fall back per agent. | Low for Weft; near-zero for Paperclip pause | Email + Discord webhook on Restate retry storm |
| **Weft runtime** | Lead intake, all flows, monitoring | Pause-and-retry: Restate persists in-flight executions; restart resumes. No fallback substitute. | Free | Systemd `OnFailure` + Tailscale Funnel healthcheck |
| **Paperclip** | All agent work, PRD, n8n gen, internal ops | Graceful degradation: Weft can still run the deterministic half (intake, enrichment, qual, Stripe). New PRDs queue. | Operator manually catches up on PRDs | Plugin bridge heartbeat miss → Weft alert |
| **Stripe** | Checkout creation, payment confirmation | Pause-and-retry on the webhook side; Weft retries Checkout Session creation with exponential backoff. | Trivial (Stripe SLA is high) | Stripe status RSS in operator dashboard |
| **n8n (deliverable)** | Client workflow stops running | Standard tier: not your problem (client owns). Sovereign tier: per-client systemd auto-restart, then operator pager. | Per-client monitoring already in place | Paperclip Support Issue + browser extension query |
| **Postgres** | Both Weft metadata and Paperclip both fail | Single point of failure on this VPS. Mitigations: WAL archiving to off-host S3, nightly `pg_dump` to Backblaze B2, RTO 4h via restore. | Backup tooling = 1 day of work | Disk monitoring + replication-lag alert |
| **Restate** | All Weft durable executions stall | Single binary on disk; systemd auto-restart. State persists in RocksDB on the same disk as Postgres. | Free | Healthcheck on Restate admin port |
| **VPS itself** | Everything | Off-host backups (Postgres, `~/.paperclip/`, client repos already on GitHub). RTO ~2h to spin up replacement Hostinger KVM 4 and restore. | Backup tooling cost only | Tailscale device-down alert + UptimeRobot-style external probe |

**Anthropic outage specifics.** The interesting case. Weft's `LlmConfig` accepts `model: "anthropic/claude-sonnet-4.6"` as an OpenRouter slug — confirmed from the README example. Whether `LlmConfig` exposes a fallback-chain field is **unverified** (it would live in `catalog/ai/llm_config/frontend.ts`, which couldn't be inspected). The pragmatic pattern: build a small Weft sub-graph that catches `LlmInference` errors via a Gate node and re-runs with a different model slug (`google/gemini-2.5-pro` or `openai/gpt-5`). OpenRouter itself supports model-fallback chains in the request body; if Weft passes those through, a single config field gets you transparent fallback.

The Paperclip side is harder. **Paperclip agents are pinned to a single adapter at a time** — the `adapterConfig.model` is a fixed string per agent. There is no "if Anthropic fails, try Codex" semantic. You can, however, configure two redundant agents (`n8n_cto_claude` and `n8n_cto_codex`) with the same SKILL.md and have Weft assign Issues to whichever is healthy. At quality-delta level: Sonnet 4.6 on Claude Code is materially better at structured-output and tool use than current Gemini or OpenAI offerings on this kind of work; falling back will produce lower-quality JSON. Mitigation: pause-and-retry until Anthropic recovers is usually the right call. Most outages are sub-hour; a paid client engagement can absorb that, especially if you tell them.

**Quality delta numbers are unverified;** real comparison requires your own eval set. Claim made conservatively from public benchmarks rather than measured.

---

## Section 6 — End-to-end "lead to shipped workflow" runbook

Step counts assume Standard (handoff) tier. Sovereign tier adds steps 21–23. Where a step's component is "UNKNOWN-verify" the architecture is sound but the specific Weft node or Paperclip endpoint hasn't been independently confirmed in this research.

**Step 1 — Form submission lands.** Marketing site (Astro on Cloudflare Pages, public TCP at the edge — *not* on the VPS) POSTs `{name, email, company, problem_summary, urgency}` to a Tailscale Funnel-exposed Weft webhook URL on `efficient-labs.tailnet.ts.net/hooks/lead`. Component: Weft webhook trigger. Duration: <100ms. Failure mode: 5xx → marketing site retries with exponential backoff; final fail logs to Sentry. Public artifact: marketing site source + form schema in public mono-repo.

**Step 2 — Lead persistence.** Weft writes raw payload to a `leads` Postgres table via the storage node. Output: `lead_id: UUID`. Duration: <50ms. Failure: Restate retries; persists payload in awakeable state.

**Step 3 — Apollo enrichment.** Weft `apollo_enrich` node calls Apollo with `{lead.email}`. Output: `enriched_lead: EnrichedLead {company_size, industry, tech_stack, contact_role}`. Duration: 1–3s. Failure: Apollo 429 → Weft retries with backoff; sustained failure → typed null and pipeline continues with degraded enrichment.

**Step 4 — Web research.** Weft Tavily node does `web_search({company_name, recent news})`. Output: `web_signals: List<Signal>`. Duration: 2–5s. Failure: same as Apollo.

**Step 5 — Pack into qual context.** Weft `Pack` node combines lead, enriched_lead, web_signals into `QualContext`. Type checked at compile time. Duration: <10ms.

**Step 6 — Rule-based filter.** Weft `code` node evaluates hard exclusions (industry blocklist, employee count below threshold, missing fields). Output: `qual_decision: enum {pass, fail, ambiguous}`. Duration: <50ms. **Public artifact: the rule code itself is opinionated and shippable as a marketing example.**

**Step 7 — LLM qualification on ambiguous.** Conditional Gate node: if `ambiguous`, call `LlmInference` with structured output prompt for fit score 0–10 plus reasoning. Model: `anthropic/claude-haiku-4.5` via direct Anthropic API. Duration: 2–4s. Failure: model error → fall back to `anthropic/claude-sonnet-4.6` then to OpenRouter `gemini-2.5-flash`. Cost: $0.001–0.003 per qualified lead.

**Step 8 — Operator pause: qualify decision.** Weft Human Trigger node sends a form to operator's browser extension with the qual context and proposed verdict. Operator clicks accept/reject/edit. Duration: minutes to hours (Restate awakeable, days OK). Public artifact: redacted version of the form template gets shipped as a Loom recording for marketing.

**Step 9 — Proposal draft.** Weft `LlmInference` with Sonnet 4.6 and templated system prompt produces a markdown proposal: scope, timeline, deliverable type (Standard vs Sovereign), price range. Duration: 8–15s. Failure: same fallback chain.

**Step 10 — Pricing calc.** Weft `code` node computes price = base × tier_multiplier + complexity_addons. Pure function, no LLM. Output: `price_cents: u64`. Duration: <10ms. Public artifact: pricing function published as standalone gist with redacted multipliers.

**Step 11 — Operator pause: approve proposal.** Human Trigger again. Operator approves, edits, or kills. If approved, Weft proceeds.

**Step 12 — Stripe Checkout creation.** Weft HTTP node `POST api.stripe.com/v1/checkout/sessions` with line items. Output: `checkout_url: String`. Duration: <500ms. Failure: retry; sustained failure pages operator.

**Step 13 — Email proposal.** Weft Email node sends proposal markdown rendered to HTML + Stripe link to lead. Duration: <2s. Failure: requeues.

**Step 14 — Wait for payment.** Weft pauses on a separate webhook trigger listening for `checkout.session.completed`. Duration: hours to days. Restate awakeable. Failure: 14-day timeout → Weft fires "lost lead" branch.

**Step 15 — Stripe webhook lands.** Weft webhook trigger validates Stripe signature, resumes the original execution with `payment_status: paid`. Duration: <100ms. Public artifact: the signature-validation Weft program ships as a public template.

**Step 16 — Onboarding email + intake form.** Weft Email node sends "welcome, here's your intake form" linking to a Weft-published `/p/efficient-labs/intake-{client}` page. Concurrently a Weft Human Trigger pauses for the client's intake submission. Duration: minutes to days.

**Step 17 — Create Paperclip company + intake Issue.** Weft HTTP `POST /api/companies` (with `companies:create` perms) then `POST /api/companies/{cid}/issues` with the assembled intake bundle as the Issue body, `assigneeAgentId` = `onboarding-agent`. Output: `issue_id`. Duration: <500ms. **Public artifact: the per-client Paperclip company gets a public README in the engagement repo describing the agent roster.**

**Step 18 — Onboarding agent runs.** Paperclip `claude_local` adapter spawns Claude Code in the client workspace `cwd`. Agent reads SKILL.md, validates intake, asks clarifying sub-Issues if needed, writes `intake-bundle.md` to the workspace, posts comment "ready for PRD." Duration: 5–20 minutes including possible HITL on a sub-Issue. Cost tracked via `cost_events` against agent budget.

**Step 19 — PRD generation Issue.** Weft observes onboarding-done event (via plugin bridge), creates new Issue assigned to `solutions-architect` agent. Same shape. PRD agent reads intake, writes `PRD.md` in the workspace, requests approval via `POST /api/companies/{cid}/approvals`.

**Step 20 — Operator approval: PRD.** Operator reviews PRD in Paperclip UI, approves or sends back. Approval webhook (via plugin bridge) wakes Weft. Duration: 15–60 min of operator time.

**Step 21 — n8n CTO agent.** Weft creates Issue assigned to `n8n-cto`, blockedBy nothing now. Agent reads PRD, writes `workflows/main.json` plus `README.md` and example test fixtures, runs local n8n schema validator, commits and pushes to `github.com/efficient-labs-clients/{client-slug}` (private). Posts commit SHA. Duration: 20–90 minutes. Cost: $5–$30 of Anthropic tokens.

**Step 22 — QA agent review.** Separate agent reads diff, validates against PRD, files critique comments. Duration: 5–20 min.

**Step 23 — Operator approval: ship.** Operator reviews diff and QA notes, approves shipping. Final approval gate.

**Step 24 — Delivery (Standard tier).** Weft conditional branch: Email node attaches `workflows/main.json` plus a one-time download link for the README and fixtures. Public artifact: a sanitized version of the workflow archetype (anonymized) ships to the public templates repo.

**Step 24-alt — Delivery (Sovereign tier).** Weft `code` node provisions a per-client n8n: creates `n8n-{slug}` Linux user, materializes systemd unit, generates fresh `N8N_ENCRYPTION_KEY`, creates dedicated Postgres DB and role, binds n8n to `127.0.0.1:{unique_port}`, registers Tailscale Funnel mapping. **Gated by n8n Embed license — see Section 9.**

**Step 25 — Followup setup.** Weft cron Routine created to ping client weekly for 4 weeks asking for issues. Paperclip Support agent assigned to triage replies. Public artifact: case study draft auto-generated to `case-studies/_drafts/{client}.md` for operator review and (after consent) public publish.

Total elapsed time, optimistic, single client: 4–6 hours of wall time, ~2 hours of operator attention. Most of that is human pause time across steps 8, 11, 20, 23.

---

## Section 7 — Public-build credibility pattern

The public-build flywheel works only if the boundary between confidential and showable is bright, automated, and never up for ad-hoc decision after a mistake. Build the boundary into the file system, not into the operator's judgment.

**Repository topology.** Three GitHub orgs (or three top-level paths in one mono-repo): `efficient-labs-public/` (everything ships), `efficient-labs-templates/` (curated archetypes, sanitized), `efficient-labs-clients/` (private, per-client repos, never public). Anything in the first two orgs is on automatic GitHub Actions release; anything in the third is private by license.

**Per-engagement, what's public.** The Weft programs that orchestrate the loop are public. The Paperclip SKILL.md files for the canonical agents (Solutions Architect, n8n CTO, QA, Support, Onboarding) are public. The pricing function is public (with multipliers redacted). The intake form schema is public. The case study after operator and client consent is public. Generic workflow archetypes — "the Salesforce-to-Slack lead notifier" stripped of any client identifiers — are public.

**Per-engagement, what's private.** The actual `workflows/main.json` for the client. The `PRD.md`. Client credentials and secrets (live in Paperclip's `secrets` table, encrypted at rest, never leave the VPS). Client communications. Real Apollo enrichment data and qualification scores tied to a real lead. Anything with a logo, a name, a domain, or revenue numbers.

**The boundary file.** Each client repo has a top-level `PUBLISH_POLICY.md` with three checkboxes: case-study allowed (yes/no), workflow archetype derivative allowed (yes/no), name attribution allowed (yes/no/anonymized). Defaults: all "no" until the client actively flips them after delivery. The Paperclip "Content Publishing" agent will not promote a case study to public-draft until the boxes are checked, and the Weft archetype-extraction routine will not derive a public template until the second box is checked. Compliance is mechanical, not discretionary.

**Reusable templates worth open-sourcing immediately as marketing.** The `paperclip-plugin-weft-bridge` (the event bridge described in Section 2) — useful to any Paperclip user, demonstrates your stack mastery. The `weft-stripe-checkout` archetype — a Weft program that does Checkout Session + webhook handling correctly — useful to the Weft community at exactly the moment Quentin is onboarding 10 paying customers. The Efficient Labs SKILL.md library for the canonical roles — credibility that you operate Paperclip professionally, not just experimentally. A public "n8n workflow archetype taxonomy" — your opinionated catalog of the 20 canonical workflow shapes you've shipped, each linked to a sanitized JSON file. This is the most leveraged marketing asset you can produce because it ranks in search forever and signals authority.

**Auto-generated case studies.** Every fulfillment run already produces the artifacts of a case study: a PRD describing the problem, a workflow JSON describing the solution, an outcome metric collectable from the followup loop. The Paperclip "Content Publishing" agent's Routine can run weekly, scan completed engagements with the right consent flags, generate a draft case study to `case-studies/_drafts/`, and file an Issue for operator review. This makes the marketing engine a side effect of doing the work, not a separate workstream you have to remember to do.

**Consent and confidentiality framework.** Three documents, all in the public mono-repo at `legal/`. (1) Master Services Agreement template that includes a build-in-public clause: client may opt out, default is opt-out, name attribution requires explicit opt-in. (2) DPA template (you as processor, client as controller) listing your sub-processors (Anthropic, Stripe, Hostinger, OpenRouter if used, Apollo, Tavily, ElevenLabs if used). (3) Public-build playbook describing what gets published when. All three reviewed by counsel before the first paying client signs — this is the one place you cannot move-fast-and-break-things.

**Ethical guardrails.** Never publish a client's actual workflow JSON, even sanitized, without explicit consent — n8n workflow files often embed business logic that is itself the client's IP. Never publish PRDs. Never publish case studies that name a client without that specific opt-in. Never use real lead data in any public demo. Use synthetic clients (a fake "Acme Corp" with a fake B2B SaaS profile) for any demo footage or screencasts.

---

## Section 8 — Implementation sequence

Two-and-a-half weeks of build, anchored to weekly public-buildable milestones, sized for one operator running RSVP gates and ADRs per Velocity Framework. The discipline: do not build the entire fulfillment system before the first paying customer. Build *just enough* that a paying customer can land on the existing surface and be served, then build the rest as the customer reveals what's actually needed.

**Pre-week zero (1–2 days, before counting starts).** Provision external Postgres on the VPS (single instance, two databases `paperclip` and `weft`, two roles). Install Restate as a systemd unit (single binary, RocksDB on the data disk, BUSL-1.1 license accepted). Install Weft (`./dev.sh server` adapted to systemd), point it at `weft` Postgres database, confirm dashboard reachable on `127.0.0.1:5173` via Tailscale Serve only. Install Paperclip via Docker, set `DATABASE_URL` to the external `paperclip` DB, set `PAPERCLIP_DEPLOYMENT_MODE=authenticated` and `PAPERCLIP_DEPLOYMENT_EXPOSURE=tailnet`. Verify `paperclipai db:backup` runs to off-host Backblaze B2 nightly. Write ADR 0003 documenting the Postgres-shared-process choice. Public artifact: `infra/` directory in the mono-repo with the systemd units, the Caddyfile (if used), the backup cronjobs. Push.

**Week 1 — Public lead intake graph.** Goal: a marketing site form posts to a Weft webhook, and a lead lands in Postgres after enrichment, qualification, and operator approval. No Paperclip involvement yet. No Stripe yet. No PRD yet. Ship: marketing site (Astro on Cloudflare Pages), Weft program for steps 1–11 of the runbook, a hardcoded operator email address for HITL, the `paperclip-plugin-weft-bridge` skeleton (no events bound yet), the public mono-repo structure with `weft-programs/`, `paperclip-skills/`, `n8n-archetypes/`, `infra/`, `legal/`, `case-studies/`. Public-buildable milestone: a tweet/post showing the live form, the typed Weft graph, the resulting Postgres row, with a link to the open repo. Velocity gate: ADR 0004 captures the Weft-vs-Paperclip boundary decision. RSVP at end of week.

**Week 2 — Proposal-to-payment loop.** Goal: a qualified lead receives a proposal, pays via Stripe, and lands in a Paperclip company with an intake bundle. Operator is the PRD writer this week — no PRD agent yet. Ship: Weft proposal generation (LlmInference with the production prompt), Weft pricing function, Stripe Checkout integration, Stripe webhook handler, Weft → Paperclip company creation via HTTP, the canonical Paperclip "Onboarding" agent's SKILL.md, a written-by-hand PRD template that lives in the client repo. Public-buildable milestone: a public Loom of the operator running through the end-to-end loop with a synthetic Acme client, a public-repo update with the SKILL.md library, an "Open-source: Weft + Paperclip + Stripe end-to-end" GitHub README that ranks. Velocity gate: ADR 0005 documents the n8n license decision (Standard tier only for now, Sovereign tier blocked on Embed conversation). RSVP.

**Week 3 — n8n CTO agent and first delivery.** Goal: a Paperclip "n8n CTO" agent reads a PRD and produces n8n JSON committed to a private client repo. Operator reviews and ships. Standard tier only. Ship: the n8n CTO SKILL.md (the most carefully crafted artifact in the system), the n8n schema validator as a Weft `code` node, the QA agent, the operator approval gate at delivery, the per-client GitHub repo automation. Public-buildable milestone: a public case study (synthetic client) showing the agent writing a non-trivial workflow, with the SKILL.md and prompt visible. The GitHub repo passes 100 stars in week three if the milestones land. Velocity gate: ADR 0006 documents the Architecture-B decision and the Architecture-C escape hatch. RSVP.

**Week 4+ — On-demand only, driven by the first paying customer.** Build the plugin event bridge to replace polling. Build the followup/monitoring loop. Build the Sovereign tier (only after Embed license clarity). Build SOC 2 Type I prep. Build the Hindsight self-host integration. None of these block the first paying customer if Steps 1–25 of the runbook work in their Standard-tier form.

**Discipline rules.** No sub-week builds without an Issue and an RSVP gate. No new ADR without a kill switch (every architectural commitment must have a documented "if this fails, we do X"). No private code where public code suffices — when in doubt, ship to the public mono-repo. No managed-tier work until the n8n license question is closed in writing. Single-operator load is real: assume 25 productive build-hours per week, which is barely enough for this plan; cut scope before cutting quality.

---

## Section 9 — Open risks and unknowns

The risks the operator may not have priced.

**Tangle pricing model and data flow.** Tangle is not currently usable for client work (Section 3). The marketing tier "Enterprise: white-label deployment" does not mean self-hosted; it means hosted-on-WeaveMind-with-your-brand. There is no published privacy policy, no DPA, no sub-processor list, no SOC 2. Decision: do not use Tangle for any client-touching work. Revisit only if WeaveMind ships an on-prem SKU.

**Paperclip bus-factor.** Maintainer is pseudonymous (@cryppadotta / Dotta) with co-publisher @devinfoley. Bus factor effectively 1–2. Calver releases ship near-daily; the project is publicly described by its maintainer as "a shadow of our potential" with calls for PR triage help. Mitigation: pin to specific image SHAs, not `:latest`. Run a fortnightly upgrade ritual, not continuous. Maintain Architecture C (standalone Claude Code script) as the documented fallback so the n8n CTO function survives Paperclip going dark. Consider sponsoring or contributing PRs back as a relationship-building hedge.

**Weft bus-factor.** Maintainer is single (Quentin Feuillade-Montixi). Two months old, zero releases tagged, license is non-OSI (O'Saasy MIT-with-SaaS-restriction). LinkedIn star counts (~700–1k) conflict with the live repo header; the discrepancy is unexplained and worth verifying before committing. Quentin himself warns "if you are evaluating it for production, treat it as a foundation to build on, not a finished product. Breaking changes are expected." Mitigation: pin to specific commit SHAs, vendor the Weft repo into a fork at `efficient-labs/weft-pinned`, contribute upstream when it makes sense, treat Weft as your own dependency to maintain rather than someone else's product to consume.

**n8n licensing changes.** The Sustainable Use License explicitly forbids "hosting n8n and charging users for access" and "letting your customers connect their own credentials and build workflows." n8n staff have confirmed in community threads that consulting (build-and-deliver) is fine but managed-hosting-as-a-service is not. The Sovereign tier as currently described crosses the line. The fix is an n8n Embed license; community claims of ~$50K/year exist but are not officially confirmed (UNKNOWN — n8n requires direct contact with sales). **The Sovereign tier should not ship until that conversation closes.** The Standard (handoff) tier is unambiguously fine.

**Restate dependency.** Restate is a separate process, not embedded in Weft. License is BUSL-1.1 (source-available, reverts to Apache 2.0 ~3–4 years post-release). Single binary; uses RocksDB locally; no Postgres dependency of its own. Footprint: tunable via `RESTATE_ROCKSDB_TOTAL_MEMORY_SIZE`, sized for ~1 GB on a low-volume workload. Auto-restart via systemd. The risk surface is low; the operational surface is real (one more thing on the backup checklist, one more thing to monitor). Document its presence in the runbook and accept the BUSL terms — for self-hosted internal use they're not a problem.

**Postgres conflict.** Paperclip's embedded-postgres on 54329 conflicts with no one if it stays embedded, but the recommendation in Section 2 is to migrate Paperclip to an external Postgres so Weft can share the instance. Confirmed via Paperclip docs that `DATABASE_URL` override is supported in Docker. Risk: schema migrations during Paperclip calver upgrades touch a database that Weft also uses; mitigation is database-level isolation (separate `paperclip` and `weft` databases on the same Postgres cluster), not schema-level isolation.

**Tailscale Free tier.** Personal plan is 6 users, unlimited devices, 3 ACL groups, 50 tagged resources, Funnel and Serve included, network flow logs Premium-only. The wall arrives at user 7 — every human (operator + co-founder + contractor + each client human you put on the tailnet) counts. Mitigation: use Tailscale Funnel for client n8n UI exposure rather than putting clients on the tailnet, keep the tailnet to operator + ops devices. Standard at $8/seat/mo is the next tier; budget it from week 2 as a cost-of-doing-business when you hire your first contractor.

**Stripe Connect vs Standard.** Connect is for marketplaces; Efficient Labs is a normal B2B SaaS subscription business. Use Stripe Standard plus Stripe Billing plus Stripe Tax. Connect would add KYC and compliance burden for zero benefit. Stripe Tax handles EU VAT B2B reverse charge automatically against VIES; enable it from day one for $0.005/transaction effectively. Do not collect tax manually.

**Compliance posture for managed multi-tenant n8n.** Even with the Embed license obtained, running multiple clients' n8n instances as separate processes on a shared VPS is process-isolation-only — weaker than VM-isolation, weaker than separate VPS-per-client. Acceptable for SMB clients without sensitive data; not acceptable for PHI (Hostinger does not appear to sign HIPAA BAAs — verify directly if a PHI client materializes; otherwise carve those workloads to AWS/Azure HIPAA-eligible infrastructure with BAA). SOC 2 Type II for a single-operator firm: feasible at $30–50K all-in for year one, but the elapsed time is 9–18 months including the Type II observation window, so plan SOC 2 Type I (3–6 months, ~$10–20K) as the year-one credibility signal. GDPR processor obligations (DPA, sub-processor disclosure, 72-hour breach notification, encryption at rest, EU region pinning of Postgres) need to be in place before the first EU client signs. The ten controls listed in the supporting research (per-client process isolation, network isolation via Funnel, encryption at rest, encryption in transit, identity-and-access via Tailscale + n8n 2FA, centralized 90-day logging, encrypted off-host backups, written incident response runbook, vulnerability management via unattended-upgrades and Renovate, public DPA + sub-processor list pages) are the defensible-without-certification baseline and should be in place by end of week 4.

**Quality delta of fallback models.** The Section 5 claim that "Sonnet 4.6 is materially better than Gemini or GPT-5 on n8n JSON generation" is a conservative inference from public benchmarks, not a measured claim on this specific task. Build a small eval harness in week 4+ that runs the same PRD through three models and grades the JSON; only then is the fallback-quality claim defensible.

**The unverifiables that matter.** The Weft `LlmConfig` field set (max_tokens, structured-output schemas, tool-use, fallback chains) is not documented in fetched material. The Weft `code` node's permission to spawn subprocesses is unverified — likely sandboxed away, in which case Architecture C requires the HTTP-to-Anthropic path rather than a CLI shell-out. Whether per-project standalone Rust binaries actually exist as a Weft build target today, or whether that's marketing aspiration, is unverified — current evidence points to "one Weft server hosts many projects" and the per-project-binary story is roadmap. Whether the Weft `weft-api` "files" subsystem can persist arbitrary blobs to disk for export (n8n JSON output) versus being limited to managed media is unverified. Resolve all four by inspecting `catalog/ai/llm_config/frontend.ts`, `weft-nodes/src/sandbox.rs`, the build CLI, and `weft-api/src/routes/files.rs` in week one of implementation, and update ADRs accordingly. Where any of these blocks the architecture, fall back to the documented escape hatches: HTTP node for everything Weft doesn't natively support, custom Rust nodes (two-file pattern in `catalog/`) for anything that needs to be in the typed graph, sidecars for anything that needs to be a separate process.

---

## Conclusion: what changed in understanding

The interesting realization across this research is that the architectural question isn't "Weft or Paperclip" — it's "how thin can the Weft layer stay while still earning the type-safety it sells." Weft is most valuable as the *outer*, deterministic, durable orchestrator with HITL primitives baked in. Paperclip is most valuable as the *inner*, judgment-heavy agent OS where the work is open-ended and SKILL.md plus Hindsight memory plus budget ceilings are load-bearing. The boundary between them is the natural place to enforce typed contracts, which is the architectural property the operator most values. Run them both, give them their own database and their own agent identities, let them talk over HTTP plus a small plugin event bridge, and never let either own the other's responsibilities.

Three non-obvious findings worth committing to memory. First, **Tangle is a non-starter for client work today** and pretending otherwise wastes a six-month research budget on a vendor conversation that won't close — but pointing Claude Code at the Weft repo gets you 80–90% of the value with zero data-exposure risk. Second, **the n8n Sustainable Use License silently kills the Sovereign tier as currently scoped**; the Standard handoff tier is fine, but managed-hosting MRR needs an Embed license obtained in writing before the first dollar of recurring revenue from that tier. Third, **Paperclip's missing outbound-webhook system is a real product gap** that you can convert into your first public open-source contribution to the Paperclip ecosystem — `paperclip-plugin-weft-bridge` is both your integration solution and your most leveraged marketing asset to the Paperclip community, which has 30K+ stars and is hungry for plugins. Build that plugin in week three and ship it under MIT. The build-in-public flywheel doesn't need to be invented — it's already implicit in the architecture, as long as the file-system boundaries between public and private are mechanical rather than discretionary, and as long as every ADR ships to the same public mono-repo where the code lives.

The architecture is decision-grade. Where it's not certain — Weft v0.1 internals, Paperclip calver churn, n8n Embed pricing, SOC 2 timing — the ADRs and escape hatches are explicit. Build it.
