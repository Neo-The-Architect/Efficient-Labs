# Repo hooks — anonymization gate

Git hooks that enforce the public-repo anonymization protocol from Foundation
Document v1.2 Section 4.5 / Section 15. Two hooks:

- `pre-commit` scans staged content against the operator's canonical denylist
  at `/home/neo/vault/anonymization-denylist.txt`. Fails closed if unreadable.
- `commit-msg` requires the locked verification line in every commit message.

## Activate in this clone

```sh
git config core.hooksPath .githooks
```

`pre-commit` framework users (`pip install pre-commit && pre-commit install`)
get the same logic via `.pre-commit-config.yaml` at the repo root.

## Operator setup (one-time, after creating the denylist)

Grant the `claude` user read-only access to the denylist without exposing the
rest of the vault:

```sh
sudo setfacl -m u:claude:--x /home/neo
sudo setfacl -m u:claude:--x /home/neo/vault
sudo setfacl -m u:claude:r-- /home/neo/vault/anonymization-denylist.txt
```

## Local testing

Override the denylist path with a fixture file:

```sh
DENYLIST_PATH=/tmp/test-denylist.txt git commit ...
```

## Bypass for non-content commits

Merge, revert, fixup, and squash commits skip both hooks automatically. For
unusual cases, set `ANONYMIZATION_VERIFY_SKIP=1` on the `git commit` invocation.
Use sparingly — the audit trail benefits from uniform attestation.
