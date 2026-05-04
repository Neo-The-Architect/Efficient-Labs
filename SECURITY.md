# Security policy

Efficient Labs takes security seriously. This document describes how to disclose vulnerabilities and what reporters can expect from the operator in response. It is the public-facing contract for security disclosures; the internal threat model and security posture are documented separately in [`docs/security/`](docs/security/) and in the relevant ADRs (notably [ADR 0005](docs/adr/0005-tailscale-ssh-as-primary-access-path.md) for host-access posture).

## Disclosure channels

There are two private channels for vulnerability disclosure. Use either; do not file public GitHub issues for vulnerability reports.

### 1. GitHub Security Advisories (preferred)

Open a private advisory through the repository's **Security → Report a vulnerability** flow:

> https://github.com/Neo-The-Architect/Efficient-Labs/security/advisories/new

This is the preferred channel because the entire disclosure conversation, fix coordination, and CVE assignment (if applicable) happen in a single threaded view that both the reporter and the operator can reference. The advisory is private until publication.

### 2. Email (fallback)

The email channel is published in this section once the operator's security email is provisioned. **Status: TBD — placeholder pending.** Until the email is published, the GitHub Security Advisories flow is the only documented channel.

When the email is provisioned, this section will list:

- The disclosure email address.
- Optional PGP key fingerprint for sensitive reports.
- The format the operator prefers reports in (vulnerability summary, reproduction steps, suggested severity, contact for follow-up).

## What is in scope

- **The Efficient Labs production fulfillment surface** operated on the EL VPS — including (when deployed) Postgres, Restate, Weft, Paperclip, and Tailscale Funnel-published services.
- **Code, configuration, runbooks, and documentation** in this repository to the extent that an issue in any of them would compromise the security of the production fulfillment surface or of clients using a system Efficient Labs has provisioned.
- **The marketing site** (when deployed) and any other publicly-reachable surface operated by Efficient Labs.

## What is out of scope

- **Vendor systems** Efficient Labs does not operate. Vulnerabilities in Anthropic, Hostinger, Tailscale, Stripe, GitHub, or any other vendor used by Efficient Labs should be reported to those vendors directly. If a vendor issue affects Efficient Labs' security posture, a report through one of the channels above is welcome — but the operator's role is to coordinate with the vendor, not to fix the vendor's product.
- **Issues with the Sustainable Use License compliance posture** of any third-party software (e.g. n8n) — this is a licensing question, not a security one. See [ADR 0003](docs/adr/0003-n8n-licensing-posture-standard-tier-only-week-1.md).
- **Theoretical attacks against architectural choices** (e.g. "Tailscale's control-plane could be compromised") that do not reduce to a concrete vulnerability the operator can act on. Discussion of such topics is welcome through the public-safe security issue template (`[security]` issues), but they are not vulnerability reports.

## What to expect after disclosure

Efficient Labs is a single-operator company. Response times reflect that reality honestly — they are not the SLAs of a large organization, and reporters should know that going in.

- **Acknowledgment.** Best-effort within 24 hours of disclosure. The acknowledgment will name a single point of contact (the operator) and confirm that the report has been received and is being investigated.
- **Triage.** Best-effort within 72 hours. The triage response includes the operator's preliminary assessment of severity, scope, and the likely fix shape.
- **Fix or written explanation.** Best-effort within one week of triage. For critical-severity issues with active exploitation potential, the operator will work continuously until a fix is shipped or a documented mitigation is in place. For lower-severity issues, the fix may be scheduled into a regular work session and the reporter will be informed of the schedule.
- **Public disclosure timing.** Coordinated. The default is that the advisory is published once a fix is shipped and clients (when they exist) have had reasonable time to apply or be migrated to the fixed version. Reporters who wish to publish on a specific timeline are asked to coordinate with the operator; the operator commits to not blocking reasonable timelines indefinitely.

## Safe harbor

Good-faith security research on Efficient Labs systems is welcomed. Researchers acting in good faith — meaning their work is intended to identify and report vulnerabilities, not to cause harm or steal data — will not face legal action from Efficient Labs for activities that satisfy all of the following:

1. The research targets only systems Efficient Labs operates (the in-scope surface above).
2. The research does not intentionally degrade availability of those systems for clients or users (no DoS testing without prior coordination).
3. The research does not exfiltrate data beyond what is necessary to demonstrate the vulnerability, and any data inadvertently accessed is reported and destroyed.
4. The reporter discloses through the private channels above and gives the operator reasonable time to respond before any public publication.

If you are in doubt about whether a specific test would satisfy these conditions, ask first through the private channel. The operator will respond.

## Why this exists

The repo is a public artifact and the operator wants the security disclosure process to be visible from day one. A vulnerability disclosure policy is one of the things a careful prospective client looks for; not having one signals either inattention to security or unwillingness to be reachable. Both signals are wrong about Efficient Labs, and this document closes that gap.

The "TBD email" placeholder is itself an honest signal: the policy is real, the GitHub channel is fully operational, and the email channel is on a known finite list of things to provision before the first paying client. That is preferable to fabricating an email that goes nowhere.

## Related: operational discipline against unintentional disclosure

Vulnerability disclosure is one half of the disclosure surface this document governs. The other half is operational discipline: the day-to-day rules that prevent the operator's private context from leaking into public artifacts through ordinary contribution work. The anonymization protocol — including the locked verification language for anonymization grep checks and the close-and-reopen procedure for force-push correction — is documented under [`CONTRIBUTING.md`](CONTRIBUTING.md). It is referenced here so that anyone evaluating the security posture of this repository sees both halves of the disclosure surface in one map.

## Updates

This document is versioned through git like every other artifact in the repo. Material changes (the addition of an email address, a change to response times, a change to scope) land through PRs reviewed by the operator. Stylistic edits and link updates may land without ceremony.
