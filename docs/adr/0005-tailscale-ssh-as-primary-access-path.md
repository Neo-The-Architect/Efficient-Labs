# ADR 0005 — Tailscale SSH as the primary operator access path

- **Status:** Accepted
- **Date:** 2026-04-28
- **Captures:** The host-access posture for the Efficient Labs VPS. Establishes the surface that all subsequent runbooks (Postgres, Restate, Weft/Paperclip) assume when they say "from an operator session."
- **Supersedes:** —

## Context

Recorded post-hoc on 2026-04-28 by Claude Code under operator direction; the original decision discussion is not preserved on disk. Decision authority: NeoTheArchitect (operator).

The Efficient Labs VPS hosts the production fulfillment surface — Postgres, Restate, Weft, Paperclip, and (future) Tailscale Funnel ingress. Operator access to this host is required for runbook execution, incident response, observability checks, and routine administration. The hardened-baseline requirement (Lynis ≥ 85, no public TCP except those exposed deliberately via Funnel) constrains the access path: traditional `sshd` listening on the public internet, even hardened with key-only auth and a non-default port, is a surface that does not exist on this host.

Three candidate access paths were on the table:

1. **OpenSSH on a non-standard port, key-only, fail2ban-fronted, public-facing.** The conventional hardened-VPS posture. Public surface; key files distributed to operator devices; revocation is "remove the key from `authorized_keys`." Well-understood, widely documented, reasonably auditable.
2. **OpenSSH bound to localhost only, reachable via Tailscale tailnet.** OpenSSH is left running but only listens on the loopback or tailnet interface. Operator devices SSH over the tailnet to the host's tailnet IP. Authentication is still SSH key-based; reachability is gated by tailnet membership.
3. **Tailscale SSH as the primary access path; OpenSSH masked.** Tailscale's built-in SSH server (the `tailscaled` SSH feature) handles authentication using the operator's Tailscale identity. OpenSSH is `systemctl mask`-ed entirely — not running, not bound, not reachable. Revocation is performed in the Tailscale admin console by removing the device or revoking the user's auth key.

The operator's hardening posture and the existing tailnet membership for the operator's devices made option 3 the clear best fit, but it was not previously formalized as an ADR. The runbooks drafted Saturday and Monday assume "operator session on the host" without specifying the access path. This ADR closes that gap.

## Decision

**Tailscale SSH is the primary and only operator access path to the Efficient Labs VPS.** OpenSSH is `systemctl mask`-ed — the unit cannot be started without an explicit unmask, and is not running, not listening, and not reachable by any path. The host has no public TCP listening surface for operator access.

Authentication is identity-based, performed by `tailscaled` against the Tailscale control plane, using the operator's Tailscale identity. Authorization for SSH access on the host is configured through the tailnet's access control list (ACL), pinning the set of identities allowed to reach the host on port 22.

Revocation is performed in the Tailscale admin console: removing a device, revoking an auth key, or removing a user from the ACL takes effect at the next ACL push (seconds, not minutes). There is no `authorized_keys` file to maintain on the host, no per-device key rotation, no race condition between distributing a key and revoking the prior one.

This decision is **deferred-decision-aware**: it is the right answer for the current operator profile (single human operator, small set of personal devices, no team members, no rotating contractor access) and the current threat model (commodity attackers scanning IPv4, not nation-state actors targeting Tailscale's control plane). The kill switch documents the conditions under which this should be revisited.

## Access matrix

| Identity | Devices | Reachable users on VPS | Notes |
| --- | --- | --- | --- |
| `neo@` (operator's Tailscale identity) | Operator's primary laptop, secondary laptop, phone | `neo`, `claude`, `root` (via `sudo` after `su - claude` or direct as `neo`) | Phone access is for emergencies — incident triage, runbook reads — not routine work. |
| `claude@` (sandbox identity, future) | The Claude Code sandbox VM, when provisioned with its own tailnet membership | `claude` (own user only; no sudo) | Not yet wired. The sandbox today inherits the operator's tailnet membership through device-level routing. Migrate when the sandbox gets its own identity. |

The host's `sshd` config (now masked) is not the source of truth for who can log in. The Tailscale ACL is. The ACL lives in the Tailscale admin console; a snapshot of the relevant section is committed to `infra/tailscale/acl-snapshot.md` (when that file lands — currently a gap).

## Revocation procedure

To revoke access for a specific device: Tailscale admin console → Machines → select device → Remove. The device loses tailnet membership at the next control plane push (seconds). The host's view of the tailnet updates as soon as `tailscaled` polls.

To revoke access for an entire identity (e.g. compromised account): Tailscale admin console → Users → select user → Revoke. All devices belonging to that identity are removed simultaneously.

To revoke an auth key (used to add new devices): Tailscale admin console → Settings → Keys → revoke the specific key. Devices already enrolled with that key remain enrolled until separately removed.

There is no host-side revocation step. The host respects whatever the tailnet ACL says.

## Threat model

This decision is appropriate for the **identity-based access** threat model, not the **key-file-based access** threat model. The two have different strengths and weaknesses:

**Identity-based (Tailscale SSH).** Authentication relies on the integrity of the operator's Tailscale account, the operator's device-level OS security, and Tailscale's control plane. Compromise vectors include: phishing or credential theft for the Tailscale account, malware on an enrolled device, a compromise of Tailscale's control plane that issues unauthorized device tokens. Mitigations: Tailscale account uses hardware-backed MFA; enrolled devices have full-disk encryption and screen-lock auto-engage; the tailnet has an explicit ACL rather than allow-all.

**Key-file-based (OpenSSH).** Authentication relies on the integrity of private key material on operator devices. Compromise vectors include: theft of a device with an unencrypted key, weak key passphrase, accidental publication of a key in a backup or repo. Mitigations are well-known (passphrase, hardware key, strict file permissions) but every operator device that needs access multiplies the surface.

For a single-operator company, identity-based is simpler to reason about and simpler to revoke. For a larger team or a high-value target, the calculus changes — see kill switch.

## Consequences

### Positive

- **No public TCP listener for operator access.** The host's external attack surface is the Tailscale Funnel-published services (when those are configured) and ICMP, nothing else. SSH-scanning bots see a closed port.
- **Identity-based revocation.** Removing access for a lost device or a rotated team member is a single admin-console action; no host-side file mutation required.
- **MFA for free.** The Tailscale account requires MFA; SSH access inherits that posture without per-host MFA configuration.
- **Auditable access log.** The Tailscale admin console records connection events; combined with `journalctl` on the host, this provides a complete picture of who logged in when.

### Negative

- **Single-vendor dependency.** If Tailscale's control plane is unavailable, no new SSH sessions can be established (existing sessions continue). For a single-operator company in non-emergency operation this is acceptable; a multi-engineer team running a 24x7 service would want a second access path.
- **Account-compromise blast radius.** Compromising the operator's Tailscale account compromises every host that trusts the operator's identity. The mitigation is hardware-backed MFA on the Tailscale account, plus the device-level controls listed above.
- **No emergency local console fallback documented.** If the host loses tailnet connectivity (e.g. Tailscale control plane outage coinciding with the operator needing to administer the host), the recovery path is the VPS provider's web console (Hostinger), not SSH. This needs a documented runbook (gap, tracked).

### Kill switch

This ADR is reversed if any of the following becomes true:

- The team grows past one operator and a clear delegation model is needed that Tailscale SSH cannot express cleanly (e.g. break-glass access during pager rotation for a third-party SRE).
- Tailscale changes its pricing or licensing such that the access path becomes commercially untenable (currently in the free tier for a single-user team).
- A regulatory or audit framework Efficient Labs commits to (SOC 2, ISO 27001) requires a different access posture that Tailscale SSH cannot satisfy. None are committed today; if one lands, the ADR follows.
- Tailscale's threat model is meaningfully invalidated by a public security event (e.g. control-plane key compromise of a kind that materially changes the trust assumption).

The replacement, in any of these cases, is OpenSSH bound to the tailnet interface (option 2 above) plus a documented break-glass console procedure. Going back to public OpenSSH (option 1) is not on the table.

## Alternatives Considered

- **Option 1 (public-facing OpenSSH on non-standard port, key-only, fail2ban-fronted).** Rejected: a public TCP listening port is a surface this host should not have. The marginal hardening (port obscurity, fail2ban) is well-understood but does not change the fact that the surface exists.
- **Option 2 (OpenSSH bound to tailnet interface).** Rejected as the primary path: keeps a key-file-based authentication posture even though tailnet membership already gates reachability. Strictly more moving parts than option 3 with no security gain. Held as the documented fallback in the kill switch above.

## Concerns / Open Questions

- **Tailscale ACL snapshot is not yet committed.** The ACL is the source-of-truth for who can SSH where. A read-only snapshot in `infra/tailscale/acl-snapshot.md` would let a future reader (or auditor) understand the access posture from the repo alone. Tracked as a follow-up; should land before the first paying client.
- **Local console emergency procedure.** The Hostinger web console is the documented fallback if tailnet connectivity is lost. The exact recovery runbook (how to log in, what credentials, what to do once on the box) is not yet on disk. Tracked as a gap.
- **Sandbox identity migration.** The Claude Code sandbox today reaches the host through the operator's tailnet membership. When the sandbox gets its own Tailscale identity (with appropriately scoped ACL allowing only `claude@` user access, no `sudo`), this ADR's access matrix is updated and a follow-up ADR may be opened if the change is substantive enough.
- **MFA recovery.** If the operator loses the hardware MFA token for the Tailscale account, account recovery is on Tailscale's terms. The recovery procedure should be tested before it is needed; this is an operational drill that has not yet been performed.
