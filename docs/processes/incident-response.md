# Incident response

**Status:** Stub. This document holds the structure for production incident response at Efficient Labs and will be filled in substantively the first time a real incident happens (or before the first paying client comes online, whichever is sooner).

## What an incident is

An incident is a deviation from the expected production state of a service Efficient Labs operates that is severe enough to warrant immediate operator attention. Examples (illustrative, not exhaustive):

- A client-facing service is down or returning errors.
- A backup has failed or is silently producing unrestorable artifacts.
- A security event has occurred — credential disclosure, unauthorized access, data exfiltration, or strong evidence any of these are imminent.
- The host's hardened-baseline posture has degraded (Lynis score drop, unexpected listening port, masked unit unmasked) without an authorized change.
- A vendor outage (Hostinger, Tailscale, Anthropic, Stripe) is materially affecting fulfillment.

Routine alerts (a brief retry burst, a slow query) are not incidents. The boundary is: would the operator want to know about this in the next 10 minutes regardless of what else they are doing? If yes, it is an incident.

## Triage

When an incident is identified, the operator runs the following checklist in order. The checklist is short on purpose — long checklists are skipped under stress.

1. **Capture the time and the symptom.** A one-line note in the incident log (TBD: where the log lives — see open question below). Timestamp matters for the postmortem timeline.
2. **Stop further changes.** Do not deploy, do not run runbooks, do not push commits to `main` until the incident is contained. The exception is a change that is part of the containment.
3. **Read the most recent change history.** `git log -20` and the most recent merged PRs. Most production issues are caused by the most recent change; ruling that in or out is the cheapest first move.
4. **Read the relevant logs.** `journalctl -u <service> --since '15 minutes ago'` for service-level incidents. Tailscale admin console for access incidents. `dmesg | tail` for host-level (OOM, disk-full, kernel) incidents.
5. **Decide containment.** If the cause is the most recent change and rollback is safe, roll back. If the cause is a vendor outage, confirm via the vendor status page and wait. If the cause is unknown after 15 minutes, escalate to the next step.

## Escalation criteria

Escalate to a deeper investigation (longer than 15 minutes of triage) when any of the following is true:

- Cause is not identified within 15 minutes of triage.
- A client-facing service is degraded for more than 5 minutes.
- A security event is suspected.
- Multiple services are affected simultaneously.
- The triage commands themselves are returning unexpected output (suggests the host itself is in a degraded state).

Escalation today means the operator commits a longer block of focused time. As the team grows, escalation will mean paging another responder; the criteria above are the trigger conditions for that page.

## Postmortem trigger threshold

A postmortem is written for any incident that meets one of:

- **Customer-impacting.** Any client-facing service was degraded or unavailable for more than 1 minute.
- **Security-relevant.** Any incident with a credential, data, access, or authentication dimension, regardless of impact.
- **Process failure.** The runbooks, ADRs, or other engineering artifacts produced wrong results when followed correctly. (A wrong runbook is a defect; the postmortem captures the lesson.)
- **Operator-discretion.** The operator decides the incident is worth a postmortem regardless of the criteria above (e.g. a near-miss with high learning value).

Small, fully-recovered incidents that do not meet any criterion above are noted in the incident log but do not get a full postmortem.

The postmortem template is at [`postmortem-template.md`](postmortem-template.md).

## What is not in this document yet (open questions)

- **Where the incident log lives.** Today there is no incident log because there have been no incidents. The log should be a single file in this repo (likely `docs/operations/incident-log.md`, not yet created) where each incident gets a one-line entry with timestamp, symptom, resolution, and a pointer to the postmortem if one was written. Land this file before the first paying client.
- **Paging path.** Today the operator is the only responder and is reachable through the operator's primary devices (laptop, phone). Paging is not formalized. Once a second responder exists or once SLA commitments are made to clients, this section names the paging path explicitly.
- **Vendor escalation contacts.** The list of who to contact at each vendor (Hostinger support, Tailscale support, Anthropic support, Stripe support) and the SLA each vendor offers. Not yet on disk; should be in `docs/operators/vendor-escalation.md` (not yet created) when this document is filled out.
- **Incident severity classification.** No formal SEV1/SEV2/SEV3 scheme yet. For a single-operator company without external SLAs, the binary "is this an incident" is sufficient; this document grows a severity scheme when the SLA structure of paying engagements requires one.
- **Communication during incidents.** Today there are no clients to communicate with during an incident. When the first paying client is onboarded, the publish-policy template (in `legal/publish-policy-template.md`, when that lands) gates what is shared publicly during an incident. This document grows a section on client communication at that point.

## Why this is a stub

This document is intentionally a stub because filling it out now, before any incident has happened, would produce confident-sounding but untested process. The right time to write a substantive incident-response document is right after the first incident — the postmortem of that incident is the source material for everything above the stub.

The stub exists so that *when* the first incident happens, the operator has a structure to fill in rather than a blank page to start from under stress.
