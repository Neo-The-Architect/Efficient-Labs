# case-studies/

Public-facing engagement writeups. Each case study describes a problem, the workflow shipped, and the measured outcome from the four-week followup loop (architecture report Section 6, Step 25).

## How case studies get here

Case studies are a side effect of doing the work, not a separate workstream. Per architecture report Section 7, the Paperclip "Content Publishing" agent runs a weekly Routine that:

1. Scans completed engagements for the `case-study allowed: yes` flag in the client's `PUBLISH_POLICY.md`.
2. Pulls the PRD summary, the workflow archetype (sanitized), and the followup-loop outcome metric.
3. Writes a draft to `case-studies/_drafts/{client-slug-or-anonymous}.md`.
4. Files an Issue against the operator for review.

The operator reviews the draft, edits if needed, and on approval moves the file from `_drafts/` to the directory root, which publishes it.

## Layout

- `_drafts/` — agent-generated drafts awaiting operator review. Never published from here directly.
- `*.md` (root) — published case studies. These are the public artifacts.

## Consent gates

A draft does not get written unless the client's `PUBLISH_POLICY.md` has the case-study checkbox set. A name is not used unless the name-attribution checkbox is also set. Defaults are no across the board until the client actively flips them post-delivery. Compliance is mechanical, not discretionary (architecture report Section 7).

## Why anonymized counts

A case study with a synthetic name and the real workflow shape is more publishable than a case study with a real name and a watered-down workflow. Default to anonymizing aggressively; promote to named only when the client explicitly asks.
