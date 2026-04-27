# legal/

Templates for the contractual surface that wraps Efficient Labs engagements. Three documents live here once drafted and counsel-reviewed:

1. **MSA** — Master Services Agreement template covering scope, deliverables, payment, IP assignment, and a build-in-public clause. The build-in-public clause is **opt-out by default**, **opt-in for name attribution**. Per architecture report Section 7.
2. **DPA** — Data Processing Agreement template (Efficient Labs as processor, client as controller) listing sub-processors: Anthropic, Stripe, Hostinger, Apollo, Tavily, OpenRouter (if the LLM fallback chain triggers), ElevenLabs (if voice features ship). GDPR Article 28 compliant.
3. **Public-build playbook** — operator-and-client-facing document describing what gets published, when, and under what consent state. References the per-client `PUBLISH_POLICY.md` boundary file pattern.

## Status

**Placeholder.** No content yet. These are the three documents that must exist *before* the first paying client signs. None of them are written yet. Counsel review is non-optional — this is the one place the build-in-public stack does not move-fast-and-break-things (architecture report Section 7).

## Why this directory is public

The templates are public so prospective clients can read them before a sales conversation. The signed instances are private, held in the relevant per-client repo or in document storage outside this monorepo.
