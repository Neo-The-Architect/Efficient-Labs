---
name: Security disclosure (PUBLIC ONLY — see SECURITY.md for private channel)
about: For security-related issues that are explicitly safe to discuss in public — e.g., a public CVE in a dependency that affects this repo, a question about the security posture, a documentation gap. **DO NOT** use for vulnerability disclosure.
title: "[security] "
labels: ""
assignees: ""
---

# Read this first

> ## ⚠️ Do not file public issues for vulnerability disclosure.
>
> If you have found a vulnerability in this repository or in the production fulfillment surface operated by Efficient Labs, **do not** describe it in a public GitHub issue. The disclosure channel is private; it is documented in [`SECURITY.md`](../SECURITY.md) at the repo root.
>
> The two channels:
>
> - **GitHub Security Advisories** — preferred. Use the **Security → Report a vulnerability** flow on the repository page. This creates a private advisory visible only to the operator and the reporter.
> - **Email** — fallback. The address is published in [`SECURITY.md`](../SECURITY.md). Use this if you cannot use GitHub's flow for any reason.
>
> Public issues for vulnerability disclosure will be deleted (not just closed) and the reporter will be redirected to the private channel.

---

This template is for **public-safe** security topics only. Examples that belong here:

- A CVE in a dependency this repo references (e.g., a Postgres CVE that affects the version pinned in `infra/runbooks/install-postgres.md`).
- A clarifying question about the security posture documented in the ADRs (e.g., "ADR 0005's threat model says X — what about scenario Y?").
- A documentation gap or ambiguity in `SECURITY.md` or related docs.
- A discussion about hardening choices that does not depend on undisclosed details of the production system.

If your topic does not clearly fit one of those, the safer choice is the private channel.

## Topic

<!-- One or two sentences naming what you want to raise. -->

## Context

<!--
  Background a future reader (or the operator on triage) needs to engage
  with the topic. Cite ADRs, runbooks, CVE identifiers, or external sources
  by link.
-->

## Public-safety check

<!--
  Confirm explicitly that this issue does not contain undisclosed details
  about the production system, credentials, or anything that would help an
  attacker. If you are not sure, use the private channel instead.
-->

- [ ] I confirm this issue does not contain non-public details about the production fulfillment surface, credentials, or unpatched vulnerabilities.

## Suggested resolution (optional)

<!--
  If you have a concrete suggestion (e.g., bump dependency to version X,
  add a sentence to ADR 0005, document the answer to the question), include
  it. Otherwise leave blank.
-->
