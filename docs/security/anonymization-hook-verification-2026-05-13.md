# Anonymization hook verification - 2026-05-13

## Status

Verified. The Efficient-Labs repository has the same anonymization gate hooks as Orchestral, the clone is configured to use them, and both active implementation agents can run the pre-commit gate against the operator-private denylist.

## Scope

This verification covers the public Efficient-Labs repository clone at `/home/claude/workspace/efficient-labs`.

The private denylist remains outside the repository at `/home/neo/vault/anonymization-denylist.txt`. This document records access and hook execution status only. It does not include denylist contents.

## Evidence

| Check | Result |
| --- | --- |
| `.githooks/pre-commit` matches Orchestral | Pass |
| `.githooks/commit-msg` matches Orchestral | Pass |
| `core.hooksPath` is `.githooks` | Pass |
| `claude` can read the private denylist | Pass |
| `codex` can read the private denylist | Pass |
| `claude` can run `.githooks/pre-commit` with the private denylist | Pass |
| `codex` can run `.githooks/pre-commit` with the private denylist | Pass |

Verification commands used:

```sh
cmp -s .githooks/pre-commit /home/claude/workspace/Orchestral/.githooks/pre-commit
cmp -s .githooks/commit-msg /home/claude/workspace/Orchestral/.githooks/commit-msg
git config --get core.hooksPath
sudo -u claude -H bash -lc 'cd /home/claude/workspace/efficient-labs && test -r /home/neo/vault/anonymization-denylist.txt && DENYLIST_PATH=/home/neo/vault/anonymization-denylist.txt .githooks/pre-commit'
sudo -u codex -H bash -lc 'cd /home/claude/workspace/efficient-labs && test -r /home/neo/vault/anonymization-denylist.txt && DENYLIST_PATH=/home/neo/vault/anonymization-denylist.txt .githooks/pre-commit'
```

## ACL boundary

The operator granted `claude` and `codex` traverse access to `/home/neo` and `/home/neo/vault`, plus read-only access to `/home/neo/vault/anonymization-denylist.txt`. The broader vault remains non-readable.

The repair command was run from `/home/neo/v5-efficient-labs-hooks-acl-repair-2026-05-13.sh`.

## Operational note

The gate fails closed if the denylist cannot be read. That is intentional for public-repo commits. When a new implementation agent is allowed to commit to Efficient-Labs, repeat the narrow ACL pattern for that agent rather than copying the denylist into the repo.
