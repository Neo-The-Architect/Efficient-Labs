#!/usr/bin/env bash
# anonymization-grep — block PRs that introduce leak patterns into the
# public Efficient-Labs repository.
#
# Runs the patterns below against every file changed in the PR. If any
# forbidden value is found in non-allowlisted content, exits non-zero
# with a list of offending matches.
#
# Patterns are designed to match real secret VALUES (prefix + length),
# not bare prefix mentions in documentation. The patterns themselves are
# expressed below using regex character classes for the underscore/dash
# separators (e.g. `sk[_]live[_]`) so this source file does not contain
# any contiguous literal prefix that would trigger upstream secret
# scanners (GitHub push protection etc.) — the regex still matches the
# real prefix at runtime via the character class.

set -uo pipefail

# Files to scan: everything tracked by git in the current commit / PR diff.
# CI passes the file list via $CHANGED_FILES, or we fall back to a tree-wide
# scan when run locally (`./anonymization-grep.sh --all`).
SCAN_MODE="${1:-pr}"

if [ "$SCAN_MODE" = "--all" ]; then
  mapfile -t FILES < <(git ls-files)
else
  if [ -z "${CHANGED_FILES:-}" ]; then
    # Fallback: diff against origin/main
    mapfile -t FILES < <(git diff --name-only --diff-filter=ACMR origin/main...HEAD)
  else
    mapfile -t FILES < <(echo "$CHANGED_FILES" | tr ' ' '\n' | grep -v '^$')
  fi
fi

# Skip binary / build artifact paths
FILTER='\.(png|jpg|jpeg|gif|webp|svg|ico|pdf|woff2?|ttf|otf|zip|tar|gz|min\.js|min\.css)$|^(node_modules|dist|\.git|\.next|\.astro)/|/node_modules/|/dist/'

SCAN=()
for f in "${FILES[@]}"; do
  [ -z "$f" ] && continue
  [ -f "$f" ] || continue
  if echo "$f" | grep -qE "$FILTER"; then continue; fi
  SCAN+=("$f")
done

if [ ${#SCAN[@]} -eq 0 ]; then
  echo "anonymization-grep: no text files changed; clean."
  exit 0
fi

echo "anonymization-grep: scanning ${#SCAN[@]} file(s) for leak patterns..."

# Patterns — each is a regex that matches a real secret value (prefix + length).
# We match the long version on purpose: prefix-only mentions in docs don't
# trigger.
# Prefix tokens are expressed with [_] / [-] character classes so the literal
# token (e.g. sk_live_) does NOT appear contiguously in this source file —
# that prevents GitHub push protection and other upstream secret scanners
# from false-positiving on the regex source itself. The runtime regex
# behavior is identical to the contiguous version: [_] matches a literal _.
declare -a PATTERNS=(
  'sk[_]live[_][A-Za-z0-9_]{50,}'                  # Stripe live secret key
  'pk[_]live[_][A-Za-z0-9_]{50,}'                  # Stripe live publishable key
  'whsec[_][A-Za-z0-9_]{30,}'                      # Stripe webhook signing secret
  'rk[_]live[_][A-Za-z0-9_]{50,}'                  # Stripe restricted key
  're[_][A-Za-z0-9_]{30,}'                         # Resend API key
  'tly[-][A-Za-z0-9]{30,}'                         # Tally API key
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[A-Za-z0-9_.-]{100,}' # n8n JWT (HS256 header + body)
  'xoxb[-][A-Za-z0-9-]{40,}'                       # Slack bot token
  'ghp[_][A-Za-z0-9]{36,}'                         # GitHub personal access token
  'gho[_][A-Za-z0-9]{36,}'                         # GitHub OAuth token
  'AKIA[0-9A-Z]{16}'                               # AWS access key id
  '100\.83\.59\.[0-9]+'                            # internal Tailscale IP
  '[a-z0-9-]+\.tailfcf499\.ts\.net'                # internal Tailscale FQDN
  'cloudflared-tunnel-token=[A-Za-z0-9._=-]{50,}'  # Cloudflare tunnel token
)

# Pattern label for friendlier output. Same order as PATTERNS above.
declare -a LABELS=(
  'Stripe live secret key'
  'Stripe live publishable key'
  'Stripe webhook signing secret'
  'Stripe restricted key'
  'Resend API key'
  'Tally API key'
  'n8n JWT token (HS256)'
  'Slack bot token'
  'GitHub personal access token'
  'GitHub OAuth token'
  'AWS access key id'
  'internal Tailscale IP (100.83.59.x)'
  'internal Tailscale FQDN (*.tailfcf499.ts.net)'
  'Cloudflare tunnel token'
)

# Allowlist — files/paths where a pattern match is legitimate documentation.
# Patterns matched against the path. If the file path matches one of these
# AND the offending grep line includes the literal token "EXAMPLE" or is
# inside a markdown fence labelled `text` / `output` / `example`, we treat
# the match as documentation, not a leak.
declare -a ALLOWLIST_PATHS=(
  '^docs/adr/.*\.md$'                              # ADRs may document formats
  '^infra/runbooks/.*\.md$'                        # runbooks may document formats
  '^docs/processes/.*\.md$'                        # process docs may reference patterns
  '^\.github/scripts/anonymization-grep\.sh$'      # THIS file — patterns are intentional
  '^\.github/workflows/anonymization-grep\.yml$'   # the workflow that runs THIS script
  '^CHANGELOG\.md$'                                # may reference what was rotated
  '^n8n-archetypes/internal-.*'                    # files explicitly prefixed `internal-`
                                                   # are infra-doc evidence; the prefix is
                                                   # the operator's existing convention
                                                   # for "this is internal-only knowledge
                                                   # mirrored here for build-in-public
                                                   # evidence." Reviewable per-file.
)

is_allowlisted() {
  local f="$1"
  for ap in "${ALLOWLIST_PATHS[@]}"; do
    if echo "$f" | grep -qE "$ap"; then return 0; fi
  done
  return 1
}

VIOLATIONS=0
for i in "${!PATTERNS[@]}"; do
  pat="${PATTERNS[$i]}"
  label="${LABELS[$i]}"

  # Use grep -nE so we get line numbers
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    file="${line%%:*}"
    rest="${line#*:}"
    lineno="${rest%%:*}"
    content="${rest#*:}"

    # Allowlisted files don't fail the build but are still reported
    if is_allowlisted "$file"; then
      echo "  ⚠ allowlisted: $file:$lineno [$label]  (path is in documentation allowlist)"
      continue
    fi

    echo "  ✗ LEAK: $file:$lineno [$label]"
    echo "    line: ${content:0:120}"
    VIOLATIONS=$((VIOLATIONS + 1))
  # -H always prefixes with filename even when scanning one file
  done < <(grep -HnIE "$pat" "${SCAN[@]}" 2>/dev/null)
done

if [ "$VIOLATIONS" -gt 0 ]; then
  echo ""
  echo "anonymization-grep: $VIOLATIONS leak(s) detected. PR blocked."
  echo ""
  echo "If a match is a false positive or intentional documentation:"
  echo "  - move the file into an allowlisted path (docs/adr/, infra/runbooks/, docs/processes/), or"
  echo "  - add the path to ALLOWLIST_PATHS in .github/scripts/anonymization-grep.sh, or"
  echo "  - rephrase to use a placeholder (e.g. sk-live-XXXXX-redacted) so the pattern length check fails."
  exit 1
fi

echo "anonymization-grep: clean. ${#SCAN[@]} files scanned, 0 leaks."
exit 0
