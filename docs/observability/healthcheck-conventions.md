# Healthcheck conventions

**Status: stub.** The convention skeleton below is the structure that fills with substance when each service is deployed. Pre-deploy, the URL patterns and response shapes are guidance; post-deploy, they are tested.

## Convention skeleton

Every long-running service operated by Efficient Labs SHOULD expose two endpoints, when the service supports HTTP or can be wrapped by a sidecar that does:

| Endpoint | Purpose | Expected response |
| --- | --- | --- |
| `/healthz` | **Liveness.** "Is the process alive and responding at all?" Used by systemd `ExecStartPost` smoke checks and by external monitors. | `200 OK` with body `ok` (text/plain) when the process is responsive. Any non-2xx (or no response) indicates the process should be restarted. |
| `/readyz` | **Readiness.** "Is the service ready to accept work?" Used by orchestrators and load balancers (when applicable). | `200 OK` with a small JSON body summarizing readiness state when ready; `503 Service Unavailable` with a brief reason when not. |

**Latency target:** both endpoints SHOULD return in under 100ms under normal load. The `/readyz` endpoint MAY perform a single cheap dependency check (e.g. a `SELECT 1` against the database) but MUST NOT cascade — a healthcheck that calls another service's healthcheck creates fragility under partial outages.

## Per-service status

| Service | HTTP-native? | Healthcheck plan | Status |
| --- | --- | --- | --- |
| **Postgres** | No (TCP/5432, native protocol). | A small sidecar or a periodic `pg_isready` probe wrapped by a thin HTTP wrapper exposing `/healthz` and `/readyz`. The `/readyz` endpoint runs `SELECT 1` against both `paperclip` and `weft` databases. | Stub — lands when Postgres deploys per the runbook. |
| **Restate** | Yes (admin API on a separate port). | Restate exposes its own admin endpoints; the convention here is to alias them to `/healthz` and `/readyz` via the reverse-proxy layer (when one exists) or to document the native admin URLs in the runbook. | Stub — lands when Restate deploys per the runbook. |
| **Weft** | Yes (Restate worker; HTTP). | The Weft program registers with Restate; healthcheck is "is the Weft handler reachable from Restate's perspective." Exposed at `/healthz` and `/readyz` on the Weft program's HTTP port. | Stub — lands when Weft programs are written and deployed. |
| **Paperclip** | TBD (Claude Skills runtime; the host process determines the surface). | When Paperclip runs as a long-lived process, it exposes `/healthz` and `/readyz` from the host process. When Paperclip runs as one-shot skill executions, healthcheck is per-execution and not over HTTP. | Stub — lands when the Paperclip runtime shape is decided. |

## Why this is a stub

Healthchecks are integration artifacts: they make sense once the surrounding deploy and monitoring infrastructure exists. Today none of the four services is deployed on the EL VPS. Naming the convention now lets each service runbook reference a single source of truth instead of inventing its own healthcheck shape.

When each service deploys, the corresponding row in the table above is updated with the actual endpoint URL, the verified response shape, and any service-specific deviations from the convention skeleton.
