# Vendor escalation

**Status:** Pre-client stub. This document names the vendor escalation shape before the first paying client, without publishing private account contacts, support portal credentials, contract IDs, or emergency phone numbers.

The goal is to make incident triage faster without pretending Efficient Labs has enterprise support relationships that do not exist yet.

## When to use this document

Use this document when an incident appears to depend on a vendor system Efficient Labs does not operate directly. Examples:

- VPS or network provider outage;
- Tailscale access or mesh connectivity issue;
- GitHub availability or repository-access issue;
- AI provider capacity, authentication, or API degradation;
- Stripe checkout, billing, or webhook delivery issue;
- Cloudflare Pages, DNS, or edge-routing issue after the public launch surface exists.

If the issue is inside code, configuration, or infrastructure Efficient Labs operates directly, start with [`../processes/incident-response.md`](../processes/incident-response.md) instead.

## Escalation checklist

Before opening a vendor ticket, capture the smallest useful evidence packet:

1. UTC timestamp and local timestamp.
2. Impact summary: what is broken, who is affected, and whether any client-facing surface is degraded.
3. Last known-good time.
4. Recent Efficient Labs changes that could plausibly explain the issue.
5. Vendor status-page result or public incident link, if one exists.
6. Sanitized error output: no tokens, no customer data, no private host identifiers unless the vendor needs the identifier inside its private support portal.
7. Current containment decision: wait, retry later, fail over, pause work, or rollback.

## Vendor classes

| Vendor class | Examples | First check | Escalation path |
| --- | --- | --- | --- |
| VPS / host | Hostinger or current VPS provider | Provider status page, VPS console, host reachability from Tailscale and public network | Provider support portal; private account identifiers stay outside git |
| Mesh access | Tailscale | Tailscale admin console, device status, ACL changes, existing-session behavior | Tailscale support if access is broadly degraded |
| Source control | GitHub | GitHub status, local `git status`, branch protection, token scope | GitHub support or repository security advisory flow as appropriate |
| AI providers | Anthropic, OpenAI, Google Gemini | Provider status, CLI/API auth probe, quota/capacity error classification | Provider support/docs; capacity errors are tracked as degraded dependency, not operator auth failure |
| Payments | Stripe | Stripe dashboard, webhook delivery log, checkout-session state | Stripe support; preserve event IDs privately |
| Edge / site | Cloudflare Pages or chosen host | Deployment status, DNS, edge logs, public URL check | Provider support after ruling out local deployment error |

## What must not be committed

- Account IDs, invoice IDs, contract IDs, support-ticket private URLs, or emergency phone numbers.
- API keys, OAuth tokens, webhook signing secrets, or session cookies.
- Client names, client data, or prospect data.
- Raw terminal transcripts that include hostnames, IP addresses, or private paths.

Private vendor details belong in the operator's password manager or private vault. This public document only stores the escalation shape.

## Before first paying client

Complete these items before a client-facing SLA depends on the stack:

- Confirm the active support path for the VPS provider.
- Confirm the active support path for Stripe before taking payment.
- Confirm where AI-provider quota/capacity incidents are logged internally.
- Decide whether Cloudflare Pages, Vercel, or another host owns the public trust-layer deployment.
- Add a private operator note, outside this repo, with account-specific support links.

## Relationship to incident response

[`../processes/incident-response.md`](../processes/incident-response.md) decides whether something is an incident and how to triage it. This document answers one narrower question: if the cause is likely a vendor, what evidence should the operator collect and where does the escalation live?

Every vendor escalation that affects a client-facing surface should leave a one-line entry in [`../processes/incident-log.md`](../processes/incident-log.md). If the incident meets the postmortem threshold, the postmortem records the vendor timeline and whether the escalation path worked.
