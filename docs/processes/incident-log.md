# Incident log

**Status:** Empty pre-client log. Efficient Labs has no public client-impacting incidents recorded in this repository as of this document's creation.

This file is the public-safe index of incidents and near-misses that matter to the operating discipline. It is intentionally concise. Detailed investigation belongs in a postmortem linked from the log entry.

## Entry format

Use one line per incident:

| Date | Severity | Surface | Symptom | Resolution | Postmortem |
| --- | --- | --- | --- | --- | --- |
| _No incidents recorded yet._ |  |  |  |  |

## What gets logged here

Log an event here when any of the following is true:

- a client-facing service is degraded or unavailable;
- a security-relevant event is suspected or confirmed;
- a backup, deploy, access path, payment path, or public trust surface fails in a way that requires operator intervention;
- a vendor outage materially affects fulfillment;
- the operator decides the near-miss has enough learning value to preserve.

## What does not get logged here

- Raw credentials, tokens, session identifiers, private support URLs, client data, or prospect data.
- Full terminal transcripts.
- Private hostnames, public IP addresses, or internal file paths unless already disclosed elsewhere intentionally.
- Routine retries that self-heal without operator action.

## Relationship to postmortems

The trigger threshold for a full postmortem lives in [`incident-response.md`](incident-response.md). If an event does not meet that threshold, this log entry can be the entire record.

If an event does meet the threshold, create a postmortem from [`postmortem-template.md`](postmortem-template.md), then link it in the `Postmortem` column.
