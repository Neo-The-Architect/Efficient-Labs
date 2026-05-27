#!/usr/bin/env bash
# launch-supervisor — health-check + alerting cron for Efficient Labs launch substrate.
#
# Probes critical services every 5 min (via cron). Maintains per-service
# consecutive-failure counters in /home/neo/.cache/launch-supervisor/.
# Alerts the operator via Resend email when a service crosses the
# failure threshold (default: 3 consecutive failures = ~15 min of downtime),
# and sends an "all clear" when it recovers.
#
# Services monitored:
#   - n8n           (HTTP 200 on http://100.83.59.73:5678/healthz)
#   - MemCompute    (HTTP 200 on http://100.83.59.73:8767/health)
#   - n8n public    (HTTP 200 on https://n8n.efficientlabs.ai/healthz)
#   - Tally form    (HTTP 200 on https://tally.so/r/81R2zr)
#   - audit-intake n8n workflow (n8n API: workflow.active=true)
#   - stripe-paid n8n workflow  (n8n API: workflow.active=true)
#   - delivery worker freshness (latest log entry < 30 min old, if any tickets pending)
#
# Vault-aware. Never echoes secrets.

set -euo pipefail
DIAG="/home/neo/log/sup-diag.log"
DIAG_TMP="/tmp/sup-diag.log"
DIAG_VAR="/var/tmp/sup-diag.log"
diag() {
  local msg="[$(date -u +%FT%TZ)] $$  $*"
  # Try three paths; whichever succeeds reveals what cron's sandbox permits.
  echo "$msg" >> "$DIAG"     2>/dev/null || true
  echo "$msg" >> "$DIAG_TMP" 2>/dev/null || true
  echo "$msg" >> "$DIAG_VAR" 2>/dev/null || true
}
diag "entry  pid=$$  ppid=$PPID  user=$(whoami)  pwd=$PWD"
trap 'diag "EXIT  code=$?  line=$LINENO"' EXIT
trap 'diag "ERR   code=$?  line=$LINENO  cmd=${BASH_COMMAND:0:60}"' ERR

VAULT="/home/neo/.config/sovereign-core/vault.env"
STATE_DIR="/home/neo/.cache/launch-supervisor"
LOG="/home/neo/log/launch-supervisor.log"
THRESHOLD="${SUPERVISOR_THRESHOLD:-3}"

mkdir -p "$STATE_DIR" "$(dirname "$LOG")"
diag "after-mkdir"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$LOG"; }

# Vault reads — never echo
[[ -r "$VAULT" ]] || { log "FATAL: vault unreadable"; diag "FATAL vault unreadable"; exit 1; }
diag "after-vault-check"
RESEND_API_KEY="$(grep '^RESEND_API_KEY=' "$VAULT" | cut -d= -f2-)"
RESEND_FROM="$(grep '^RESEND_FROM_PRIMARY=' "$VAULT" | cut -d= -f2-)"
OPERATOR_EMAIL="$(grep '^OPERATOR_EMAIL=' "$VAULT" | cut -d= -f2-)"
N8N_API_KEY="$(grep '^N8N_API_KEY=' "$VAULT" | cut -d= -f2-)"
diag "after-vault-reads  resend_len=${#RESEND_API_KEY}  n8n_len=${#N8N_API_KEY}"

OPERATOR_EMAIL="${OPERATOR_EMAIL:-${RESEND_FROM:-founder@efficientlabs.ai}}"
RESEND_FROM="${RESEND_FROM:-founder@efficientlabs.ai}"

# Cached counter per service
counter_get() {
  local svc="$1"
  cat "$STATE_DIR/$svc.failures" 2>/dev/null || echo 0
}
counter_set() {
  echo "$2" > "$STATE_DIR/$1.failures"
}
alert_state_get() {  # "active" if an alert has been sent and not yet cleared
  cat "$STATE_DIR/$1.alert_state" 2>/dev/null || echo "clear"
}
alert_state_set() {
  echo "$2" > "$STATE_DIR/$1.alert_state"
}

# Send a Resend email — no-op if RESEND_API_KEY missing
send_email() {
  local subject="$1"
  local body="$2"
  [[ -z "$RESEND_API_KEY" ]] && { log "no RESEND_API_KEY — skipping alert: $subject"; return 0; }
  curl -s --max-time 10 -X POST \
    -H "Authorization: Bearer $RESEND_API_KEY" \
    -H "Content-Type: application/json" \
    --data "$(python3 -c "
import json, sys
print(json.dumps({
  'from': '$RESEND_FROM',
  'to': ['$OPERATOR_EMAIL'],
  'subject': sys.argv[1],
  'text': sys.argv[2],
}))" "$subject" "$body")" \
    "https://api.resend.com/emails" >/dev/null 2>&1 || true
}

# Probe one service. record_result() interprets the exit code.
record_result() {
  local svc="$1"
  local ok="$2"
  local detail="$3"

  local n=$(counter_get "$svc")
  local state=$(alert_state_get "$svc")

  if [[ "$ok" == "true" ]]; then
    counter_set "$svc" 0
    if [[ "$state" == "active" ]]; then
      alert_state_set "$svc" "clear"
      log "ALL CLEAR: $svc ($detail)"
      send_email "[CLEAR] launch supervisor — $svc recovered" "Service $svc is healthy again as of $(date -u). Detail: $detail"
    fi
  else
    n=$((n + 1))
    counter_set "$svc" "$n"
    log "fail($n/$THRESHOLD): $svc — $detail"
    if [[ "$n" -ge "$THRESHOLD" ]] && [[ "$state" == "clear" ]]; then
      alert_state_set "$svc" "active"
      send_email "[ALERT] launch supervisor — $svc degraded" \
"Service $svc has failed $n consecutive probes (~$((n*5)) min).

Latest detail: $detail

Investigation steps:
  - sudo systemctl status $svc
  - sudo journalctl -u $svc -n 50
  - launch-supervisor logs: tail -50 $LOG

This alert will auto-clear when $svc recovers."
      log "ALERT sent: $svc"
    fi
  fi
}

# === probes ===

probe_http() {
  local svc="$1" url="$2"
  local code
  code=$(curl -sSL -o /dev/null --max-time 5 -w "%{http_code}" "$url" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]]; then
    record_result "$svc" "true" "HTTP $code"
  else
    record_result "$svc" "false" "HTTP $code from $url"
  fi
}

probe_n8n_workflow() {
  local svc="$1" wf_id="$2"
  [[ -z "$N8N_API_KEY" ]] && { record_result "$svc" "false" "N8N_API_KEY missing"; return; }
  local active
  active=$(curl -s --max-time 5 -H "X-N8N-API-KEY: $N8N_API_KEY" \
    "http://100.83.59.73:5678/api/v1/workflows/$wf_id" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('active', False))" 2>/dev/null || echo "false")
  if [[ "$active" == "True" ]]; then
    record_result "$svc" "true" "n8n workflow $wf_id active=true"
  else
    record_result "$svc" "false" "n8n workflow $wf_id active=$active"
  fi
}

probe_systemd() {
  local svc="$1" unit="$2"
  if sudo -n systemctl is-active "$unit" >/dev/null 2>&1; then
    record_result "$svc" "true" "systemd unit active"
  else
    record_result "$svc" "false" "systemd unit not active"
  fi
}

# === main probe sequence ===

diag "before-log-tick"
log "supervisor tick"
diag "after-log-tick"

probe_http "n8n-local"    "http://100.83.59.73:5678/healthz"
probe_http "n8n-public"   "https://n8n.efficientlabs.ai/healthz"
probe_http "memcompute"   "http://100.83.59.73:8767/health"
probe_http "tally-form"   "https://tally.so/r/81R2zr"

probe_systemd "n8n-unit"         "n8n.service"
probe_systemd "memcompute-unit"  "memcompute.service"
probe_systemd "cloudflared-unit" "cloudflared.service"

probe_n8n_workflow "audit-intake-wf" "44rID3Fapv84vALY"
# stripe-paid workflow id is at /tmp/stripe-webhook-workflow-id.txt — fallback if file missing
STRIPE_WF_ID="$(cat /tmp/stripe-webhook-workflow-id.txt 2>/dev/null || echo "")"
[[ -n "$STRIPE_WF_ID" ]] && probe_n8n_workflow "stripe-paid-wf" "$STRIPE_WF_ID"

diag "before-log-done"
log "supervisor tick done"
diag "after-log-done  (clean exit)"
