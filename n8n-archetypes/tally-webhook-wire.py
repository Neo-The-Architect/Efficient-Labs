#!/usr/bin/env python3
"""Wire Tally webhook to n8n + verify."""
import json, sys, urllib.request, urllib.error

def vault_get(k):
    with open('/home/neo/.config/sovereign-core/vault.env') as f:
        for ln in f:
            if ln.startswith(k+'='): return ln.split('=',1)[1].strip()
KEY = vault_get('TALLY_API_KEY')
FORM = '81R2zr'
WEBHOOK_URL = 'https://n8n.efficientlabs.ai/webhook/audit-intake'

def req(method, path, body=None):
    h = {'Authorization': f'Bearer {KEY}', 'accept': 'application/json',
         'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'}
    data = None
    if body is not None:
        h['Content-Type'] = 'application/json'
        data = json.dumps(body).encode()
    r = urllib.request.Request('https://api.tally.so'+path, data=data, headers=h, method=method)
    try:
        with urllib.request.urlopen(r, timeout=30) as rsp:
            return rsp.status, json.loads(rsp.read().decode() or '{}')
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or '{}')

# Inspect /webhooks endpoint for payload shape via OpenAPI
print('═══ Creating Tally → n8n webhook ═══')
payload = {
    'formId': FORM,
    'url': WEBHOOK_URL,
    'eventTypes': ['FORM_RESPONSE'],
}
status, body = req('POST', '/webhooks', payload)
print(f'  HTTP {status}')
if status in (200, 201):
    print(f'  ✓ webhook id: {body.get("id")}')
    print(f'  URL: {body.get("url")}')
    print(f'  eventTypes: {body.get("eventTypes")}')
else:
    print(json.dumps(body, indent=2)[:1500])
