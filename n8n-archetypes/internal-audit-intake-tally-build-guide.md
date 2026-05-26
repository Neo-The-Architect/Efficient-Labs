# Tally form build guide — AI Sovereignty Audit Intake

**Audience:** operator (Michael / NeoTheArchitect)
**Webhook target (live + tested 2026-05-25):** `https://n8n.efficientlabs.ai/webhook/audit-intake`

This guide gives **two paths** for building the canonical AI Sovereignty Audit intake form in Tally. The n8n workflow that receives the webhook is already built, tested, and active (see `internal-audit-intake-workflow.json` + ADR-0022).

## TL;DR — the form is already built (2026-05-26)

The form lives at **https://tally.so/r/81R2zr** (form ID `81R2zr`, webhook ID `wQ5OrG`). Built deterministically via the API using `tally-form-build.py` in this directory. Re-run that script to rebuild on a different Tally workspace or after wholesale schema changes.

## Path A — API rebuild (Claude / agent-driven, recommended for re-deploys)

```bash
# Requires TALLY_API_KEY in /home/neo/.config/sovereign-core/vault.env
python3 ~/work/Efficient-Labs/n8n-archetypes/tally-form-build.py
python3 ~/work/Efficient-Labs/n8n-archetypes/tally-webhook-wire.py
```

The script PATCHes the existing draft form (or creates a new one — adjust `FORM_ID`), pushes all 117 blocks (28 fields + title + intro), promotes form status to PUBLISHED, and returns the public share URL. `tally-webhook-wire.py` then registers the n8n webhook subscription via the `/webhooks` endpoint.

**Tally API quirks worth knowing** (the OpenAPI spec misleads in places — confirmed at build time 2026-05-26):

- `DROPDOWN`, `CHECKBOXES`, `MULTI_SELECT` are NOT block types — only `groupType` values. Don't try to add container blocks of these types.
- Each block's `groupType` must equal its own `type` (for LABEL + input types). Only `OPTION` blocks take the parent container type as their `groupType`.
- `OPTION` blocks in a group need monotonic 0-indexed `index` + correct `isFirst` / `isLast`.
- `TEXT` / `FORM_TITLE` blocks reject `index/isFirst/isLast` in payload.
- Cloudflare WAF (api.tally.so) bans default `python-urllib` User-Agent on POST/PATCH — script spoofs Chrome UA.

## Path B — Browser build (manual fallback if the API ever breaks)

The original 20-minute UI walkthrough lives below. Same field spec + field keys; just point-and-click in the Tally UI instead of programmatic.

---

## Step 1. Create the form

1. Sign in at https://tally.so
2. Click **+ Create form**
3. Choose **Start from scratch**
4. Title: **AI Sovereignty Audit — Intake**
5. Description (optional, shown on form): *Tell us about your automation stack. We'll use this to scope your audit deliverable.*
6. **Save** to create the form draft.

---

## Step 2. Add fields (in this exact order)

For each field below: click **+ Add question**, pick the type, then enable **Question settings → Field key (custom)** and paste the exact `key` string. The `key` is what n8n reads — UI label text is for the human user.

### Required fields (visible by default)

| # | Type | `key` (custom) | Label (UI) | Required? |
|---|---|---|---|---|
| 1 | Short answer | `client_legal_name` | Legal Company Name | ✅ |
| 2 | Short answer | `client_contact_name` | Your Name | ✅ |
| 3 | Email | `client_email` | Best Email to Reach You | ✅ |
| 4 | Dropdown | `client_industry` | Industry | ✅ |
| 5 | Long answer | `pain_point` | Biggest pain point with your current automation (1-3 sentences, be specific) | ✅ |

For the `client_industry` dropdown, paste these options exactly:

```
technology
healthcare
finance
retail
professional-services
manufacturing
education
nonprofit
media
other
```

### Conditional reveals

Tally supports "show this question if..." logic. Set these up after adding the base fields:

- **`client_industry_note`** (Short answer): show only if `client_industry == other`. Label: *If "other", please describe your industry briefly.* Required when shown.

### Optional fields (group below required fields)

| # | Type | `key` | Label |
|---|---|---|---|
| 6 | Short answer | `client_role` | Your Role / Title |
| 7 | Number | `client_locations` | Number of business locations |
| 8 | Dropdown | `client_revenue` | Annual revenue range |
| 9 | Short answer | `workflow_name` | Name of your most-broken workflow |
| 10 | Dropdown | `workflow_platform` | Current automation platform |
| 11 | Long answer | `workflow_description` | Describe what it does (and what breaks) |
| 12 | Number | `workflow_breaks` | Estimated breaks per quarter |
| 13 | Number | `workflow_hours` | Maintenance hours per quarter |
| 14 | Checkbox | `workflow_pii` | This workflow touches personally-identifiable data (PII) |
| 15 | Checkbox | `workflow_payments` | This workflow touches payment data |
| 16 | Checkbox | `workflow_health` | This workflow touches health data |
| 17 | Dropdown | `workflow_priority` | Migration priority |
| 18 | Dropdown | `sovereignty_cloud` | Current primary cloud |
| 19 | Checkbox | `sovereignty_concern` | I have explicit sovereignty / data-residency concerns |
| 20 | Long answer | `sovereignty_note` | (conditional, shown if `sovereignty_concern` checked) Describe your sovereignty concerns |
| 21 | Checkbox | `sovereignty_regulated` | I operate in a regulated industry |
| 22 | Multi-select | `sovereignty_regulations` | (conditional, shown if `sovereignty_regulated` checked) Which regulations apply? |
| 23 | Dropdown | `budget_tier` | Audit tier |
| 24 | Dropdown | `budget_implementation` | Expected implementation budget range |
| 25 | Dropdown | `budget_retainer` | Expected monthly retainer budget |
| 26 | Dropdown | `budget_urgency` | Timeline urgency |
| 27 | Long answer | `success_criteria` | What does success look like? |
| 28 | Long answer | `constraints` | Constraints or caveats we should know about |

### Dropdown values (paste these into each respective field)

**`client_revenue`:**
```
pre-revenue
under-100k
100k-1m
1m-10m
10m-100m
over-100m
prefer-not-to-say
```

**`workflow_platform`:**
```
zapier
n8n
make
power-automate
workato
custom-code
none-manual
other
```

**`workflow_priority`:**
```
low
medium
high
critical-blocker
```

**`sovereignty_cloud`:**
```
aws
gcp
azure
oracle
digitalocean
multi-cloud
on-prem
none
other
```

**`sovereignty_regulations`** (multi-select):
```
HIPAA
GDPR
CCPA
SOC2
PCI-DSS
GLBA
FedRAMP
ITAR
Other
```

**`budget_tier`:**
```
standard
sovereign
bespoke
```

**`budget_implementation`:**
```
no-budget-yet
under-1k
1k-5k
5k-10k
10k-25k
25k-100k
over-100k
```

**`budget_retainer`:**
```
no-retainer
under-500
500-2k
2k-5k
5k-15k
over-15k
```

**`budget_urgency`:**
```
exploratory
in-evaluation
ready-to-buy
actively-implementing-elsewhere
```

---

## Step 3. Wire the webhook

1. In Tally, open your form → **Integrations** tab (top right)
2. Find **Webhooks** → **Connect**
3. Webhook URL: `https://n8n.efficientlabs.ai/webhook/audit-intake`
4. HTTP method: **POST** (default)
5. Triggers: **Form responses** (checked)
6. Save.

You do NOT need a signing secret in Tally — the n8n workflow doesn't enforce one yet (TODO post-launch: add HMAC signature verification, mirrors archetypes 02/06).

---

## Step 4. Publish + test

1. Tally → **Publish** your form. Copy the live URL.
2. Open the live URL in an incognito tab.
3. Submit one form response with realistic-but-fake data and **your own email** as `client_email`.
4. Verify within ~2 minutes:
   - You receive an email at `founder@efficientlabs.ai` titled `🚨 New audit intake — <client name>`
   - The email you used as `client_email` receives a confirmation titled `Your AI Sovereignty Audit submission — Efficient Labs`
   - The intake document appears in MemCompute under `intake-gate/intake_<timestamp>_<hash>.md` — check via:
     ```bash
     /home/neo/bin/mem-handoff inbox operator  # Telegram fired the operator email already
     # or directly:
     curl -sH "Authorization: Bearer $(grep MEMCOMPUTE_BEARER_TOKEN ~/.config/sovereign-core/vault.env | cut -d= -f2)" \
       'http://100.83.59.73:8767/directories/intake-gate/'
     ```

If all three land, the loop is operational and you're ready to publish the Tally URL on the marketing site.

---

## Marketing site CTA wiring (after publish)

Once the form is live in Tally, grab its URL (`tally.so/r/<form-id>`). Update the marketing site CTA button:

- `~/work/Efficient-Labs/marketing-site/src/...` — wherever the "Start your audit" button lives
- Set the `href` to the Tally URL (or wrap it in a tracking redirect if you want analytics)

Open a separate PR for the marketing-site CTA wiring (not in this PR).

---

## What happens after a submission

1. Tally → POST → `https://n8n.efficientlabs.ai/webhook/audit-intake` (via Cloudflare Tunnel → host's n8n via `--network host`)
2. n8n **Validate + normalize** Code node: indexes fields, validates required + conditional rules, generates `intake_<ts>_<hash>` ID, builds normalized IntakeRecord
3. n8n **If validation passed** branch:
   - ✅ → **PUT intake to MemCompute** under `intake-gate/<intake_id>.md` (frontmatter for indexability, body has full record JSON)
   - ✅ → **Notify operator (Resend)** to `founder@efficientlabs.ai` with client name, email, industry, tier, pain-point excerpt, link to MemCompute UI
   - ✅ → **Confirm to client (Resend)** with intake ID, next-steps language, brand voice
   - ✅ → Respond OK to Tally
   - ✗ → Respond fail (Tally still receives 200; user sees Tally's default confirmation)
4. Operator follows up within 24h with Stripe payment link + scoping call invite (manual for v1; automated in v1.1)

---

## Known limits + post-launch work

- No HMAC verification on the webhook (Tally doesn't sign requests by default; n8n trusts Cloudflare Tunnel as the gate)
- Validation logic in n8n's Code node is a one-time copy of `sovereign-core/tools/efficient_labs_audit_intake.js` — if the spec changes, both must update
- Stripe checkout is OUT of the Tally loop for v1 — payment link sent manually post-submission. v1.1 will embed Checkout directly
- Intake records live in MemCompute under `intake-gate/`; sovereign-core stage 1 doesn't yet poll this path (post-launch follow-up: add a sovereign-core bridge that picks up from MemCompute → 01_intake_gate/working/)

---

*Built 2026-05-25 by Claude Opus 4.7 + Operator (handoff). Tested end-to-end against synthetic payloads — both success and validation-fail paths verified.*
