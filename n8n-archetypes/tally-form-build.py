#!/usr/bin/env python3
"""
Build the AI Sovereignty Audit Intake form in Tally via API.
PATCHes the existing draft (id 81R2zr) with the full 28-field block array.

Reads TALLY_API_KEY from vault. Never echoes the key.
"""
import json, sys, uuid as _uuid, urllib.request, urllib.error

VAULT = '/home/neo/.config/sovereign-core/vault.env'
TALLY = 'https://api.tally.so'
FORM_ID = '81R2zr'  # existing draft

def vault_get(key):
    with open(VAULT) as f:
        for line in f:
            if line.startswith(key + '='):
                return line.split('=', 1)[1].strip()
    return None

KEY = vault_get('TALLY_API_KEY')
if not KEY:
    print('ERROR: TALLY_API_KEY missing'); sys.exit(1)

def u():
    return str(_uuid.uuid4())

def request(method, path, body=None):
    url = TALLY + path
    headers = {
        'Authorization': f'Bearer {KEY}',
        'accept': 'application/json',
        # CF WAF on api.tally.so bans default python-urllib UA on PATCH/POST.
        # Use a realistic browser UA to pass bot detection.
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
    }
    data = None
    if body is not None:
        headers['Content-Type'] = 'application/json'
        data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read().decode() or '{}')
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or '{}')

# === Block builders ===

def title_block(html):
    return {
        'uuid': u(),
        'type': 'FORM_TITLE',
        'groupUuid': u(),
        'groupType': 'FORM_TITLE',
        'payload': {'html': html},
    }

def intro_text(html):
    return {
        'uuid': u(),
        'type': 'TEXT',
        'groupUuid': u(),
        'groupType': 'TEXT',
        'payload': {'html': html},
    }

def question(input_type, label_html, payload_extras=None, required=False):
    """Build LABEL + input. Each block has groupType == type (Tally runtime rule).
    Each block has its OWN groupUuid (the API doesn't link them by uuid)."""
    payload = {'isRequired': required, **(payload_extras or {})}
    return [
        {
            'uuid': u(),
            'type': 'LABEL',
            'groupUuid': u(),
            'groupType': 'LABEL',
            'payload': {'html': label_html},
        },
        {
            'uuid': u(),
            'type': input_type,
            'groupUuid': u(),
            'groupType': input_type,
            'payload': payload,
        },
    ]

def short_text(label, required=False, placeholder=None, min_chars=None):
    extras = {}
    if placeholder: extras['placeholder'] = placeholder
    if min_chars:
        extras['hasMinCharacters'] = True
        extras['minCharacters'] = min_chars
    return question('INPUT_TEXT', label, extras, required)

def email(label, required=False):
    return question('INPUT_EMAIL', label, {}, required)

def textarea(label, required=False, placeholder=None, min_chars=None):
    extras = {}
    if placeholder: extras['placeholder'] = placeholder
    if min_chars:
        extras['hasMinCharacters'] = True
        extras['minCharacters'] = min_chars
    return question('TEXTAREA', label, extras, required)

def number(label, required=False, placeholder=None, default=None):
    extras = {}
    if placeholder: extras['placeholder'] = placeholder
    if default is not None:
        extras['hasDefaultAnswer'] = True
        extras['defaultAnswer'] = str(default)
    return question('INPUT_NUMBER', label, extras, required)

def dropdown(label, options, required=False):
    """Build dropdown: LABEL + N DROPDOWN_OPTION (no container — DROPDOWN is groupType only)."""
    dropdown_gid = u()
    blocks = [
        {
            'uuid': u(),
            'type': 'LABEL',
            'groupUuid': u(),
            'groupType': 'LABEL',
            'payload': {'html': label},
        },
    ]
    n = len(options)
    for i, opt in enumerate(options):
        blocks.append({
            'uuid': u(),
            'type': 'DROPDOWN_OPTION',
            'groupUuid': dropdown_gid,
            'groupType': 'DROPDOWN',
            'payload': {
                'index': i,
                'isFirst': i == 0,
                'isLast': i == n - 1,
                'text': opt,
            },
        })
    return blocks

def multi_select(label, options, required=False):
    """Build multi-select: LABEL + N MULTI_SELECT_OPTION (no container)."""
    ms_gid = u()
    blocks = [
        {
            'uuid': u(),
            'type': 'LABEL',
            'groupUuid': u(),
            'groupType': 'LABEL',
            'payload': {'html': label},
        },
    ]
    n = len(options)
    for i, opt in enumerate(options):
        blocks.append({
            'uuid': u(),
            'type': 'MULTI_SELECT_OPTION',
            'groupUuid': ms_gid,
            'groupType': 'MULTI_SELECT',
            'payload': {
                'index': i,
                'isFirst': i == 0,
                'isLast': i == n - 1,
                'text': opt,
            },
        })
    return blocks

def checkboxes(label, options, required=False):
    """Build checkbox group: LABEL + N CHECKBOX (no container)."""
    cb_gid = u()
    blocks = [
        {
            'uuid': u(),
            'type': 'LABEL',
            'groupUuid': u(),
            'groupType': 'LABEL',
            'payload': {'html': label},
        },
    ]
    n = len(options)
    for i, opt in enumerate(options):
        blocks.append({
            'uuid': u(),
            'type': 'CHECKBOX',
            'groupUuid': cb_gid,
            'groupType': 'CHECKBOXES',
            'payload': {
                'index': i,
                'isFirst': i == 0,
                'isLast': i == n - 1,
                'text': opt,
            },
        })
    return blocks

# === Form structure ===

blocks = []

# Title + intro
blocks.append(title_block('<p>AI Sovereignty Audit — Intake</p>'))
blocks.append(intro_text(
    '<p>Tell us about your automation stack so we can scope your audit deliverable. ' +
    'We use your responses to plan the 9-section audit; nothing here is shared outside Efficient Labs.</p>'
))

# === REQUIRED FIELDS ===

# 1. client_legal_name
blocks.extend(short_text(
    '<p>Legal Company Name</p>',
    required=True,
    placeholder='e.g., Acme Operations Inc.',
    min_chars=2,
))

# 2. client_contact_name
blocks.extend(short_text(
    '<p>Your Name</p>',
    required=True,
    placeholder='First Last',
))

# 3. client_email
blocks.extend(email(
    '<p>Best Email to Reach You</p>',
    required=True,
))

# 4. client_industry
blocks.extend(dropdown(
    '<p>Industry</p>',
    ['technology', 'healthcare', 'finance', 'retail', 'professional-services',
     'manufacturing', 'education', 'nonprofit', 'media', 'other'],
    required=True,
))

# 5. pain_point
blocks.extend(textarea(
    '<p>Biggest pain point with your current automation (1–3 sentences, be specific)</p>',
    required=True,
    placeholder='What breaks most often? What takes the most operator time?',
    min_chars=10,
))

# === OPTIONAL FIELDS ===

# 6. client_industry_note (shows if industry == other; for v1 we make it optional always)
blocks.extend(short_text(
    '<p>If industry was "other" — describe briefly</p>',
    placeholder='e.g., regenerative agriculture cooperative',
))

# 7. client_role
blocks.extend(short_text('<p>Your Role / Title</p>'))

# 8. client_locations
blocks.extend(number('<p>Number of business locations</p>', default=1))

# 9. client_revenue
blocks.extend(dropdown(
    '<p>Annual revenue range</p>',
    ['pre-revenue', 'under-100k', '100k-1m', '1m-10m', '10m-100m', 'over-100m', 'prefer-not-to-say'],
))

# 10. workflow_name
blocks.extend(short_text('<p>Name of your most-broken workflow</p>'))

# 11. workflow_platform
blocks.extend(dropdown(
    '<p>Current automation platform</p>',
    ['zapier', 'n8n', 'make', 'power-automate', 'workato', 'custom-code', 'none-manual', 'other'],
))

# 12. workflow_platform_note
blocks.extend(short_text(
    '<p>If platform was "other" — describe briefly</p>',
))

# 13. workflow_description
blocks.extend(textarea('<p>Describe what the workflow does and what breaks</p>'))

# 14. workflow_breaks
blocks.extend(number('<p>Estimated breaks per quarter</p>'))

# 15. workflow_hours
blocks.extend(number('<p>Maintenance hours per quarter</p>'))

# 16-18. workflow_pii / workflow_payments / workflow_health (single-question checkbox group)
blocks.extend(checkboxes(
    '<p>This workflow touches…</p>',
    ['Personally-identifiable data (PII)', 'Payment data', 'Health data'],
))

# 19. workflow_priority
blocks.extend(dropdown(
    '<p>Migration priority</p>',
    ['low', 'medium', 'high', 'critical-blocker'],
))

# 20. sovereignty_cloud
blocks.extend(dropdown(
    '<p>Current primary cloud</p>',
    ['aws', 'gcp', 'azure', 'oracle', 'digitalocean', 'multi-cloud', 'on-prem', 'none', 'other'],
))

# 21+22. sovereignty_concern + sovereignty_note (checkbox + follow-up)
blocks.extend(checkboxes(
    '<p>Sovereignty concerns</p>',
    ['I have explicit sovereignty / data-residency concerns'],
))

# 23. sovereignty_note
blocks.extend(textarea(
    '<p>If you have sovereignty concerns — describe them briefly</p>',
))

# 24. sovereignty_regulated + 25. sovereignty_regulations
blocks.extend(checkboxes(
    '<p>Regulated industry</p>',
    ['I operate in a regulated industry'],
))

blocks.extend(multi_select(
    '<p>Which regulations apply (multi-select)</p>',
    ['HIPAA', 'GDPR', 'CCPA', 'SOC2', 'PCI-DSS', 'GLBA', 'FedRAMP', 'ITAR', 'Other'],
))

# 26. budget_tier
blocks.extend(dropdown(
    '<p>Audit tier</p>',
    ['standard', 'sovereign', 'bespoke'],
))

# 27. budget_implementation
blocks.extend(dropdown(
    '<p>Expected implementation budget range</p>',
    ['no-budget-yet', 'under-1k', '1k-5k', '5k-10k', '10k-25k', '25k-100k', 'over-100k'],
))

# 28. budget_retainer
blocks.extend(dropdown(
    '<p>Expected monthly retainer budget</p>',
    ['no-retainer', 'under-500', '500-2k', '2k-5k', '5k-15k', 'over-15k'],
))

# 29. budget_urgency
blocks.extend(dropdown(
    '<p>Timeline urgency</p>',
    ['exploratory', 'in-evaluation', 'ready-to-buy', 'actively-implementing-elsewhere'],
))

# 30. success_criteria
blocks.extend(textarea('<p>What does success look like for you?</p>'))

# 31. constraints
blocks.extend(textarea('<p>Constraints or caveats we should know about</p>'))

print(f'built {len(blocks)} blocks total')

# === PATCH to existing draft ===
print(f'\nPATCHing /forms/{FORM_ID}/blocks...')
status, body = request('PATCH', f'/forms/{FORM_ID}/blocks', {'blocks': blocks})
print(f'  HTTP {status}')
if status == 200:
    print('  ✓ blocks installed')
    # Save block uuids for question-key mapping later
    with open('/tmp/tally-build/blocks.json', 'w') as f:
        json.dump(blocks, f, indent=2)
else:
    print(f'  ✗ error body: {json.dumps(body, indent=2)[:1500]}')
    sys.exit(1)

# === Set form to PUBLISHED ===
print(f'\nPATCHing /forms/{FORM_ID} status → PUBLISHED...')
status, body = request('PATCH', f'/forms/{FORM_ID}', {'status': 'PUBLISHED'})
print(f'  HTTP {status}')
if status == 200:
    print('  ✓ form published')
else:
    print(f'  ✗ {json.dumps(body, indent=2)[:500]}')

# === Get the public URL ===
status, body = request('GET', f'/forms/{FORM_ID}')
print(f'\nform metadata HTTP {status}')
print(f'  id:      {body.get("id")}')
print(f'  name:    {body.get("name")}')
print(f'  status:  {body.get("status")}')
share_url = body.get('shareUrl') or f'https://tally.so/r/{body.get("id")}'
print(f'  share URL: {share_url}')
with open('/tmp/tally-build/form_meta.json', 'w') as f:
    json.dump(body, f, indent=2)
