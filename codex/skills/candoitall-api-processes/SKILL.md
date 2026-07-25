---
name: candoitall-api-processes
description: Use when launching, operating, observing, or reviewing CanDoItAll process runs, including durable run snapshots, summaries, graphs, and analytics, through the current HTTP API.
---

# CanDoItAll Processes API

Use this skill for process runtime control and readback through the main CanDoItAll web
API. The API has two related read models: live runtime projections and durable terminal
run records.

## Contract Source

- Use the shared
  [OpenAPI snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  for the complete route and parameter contract when it matches the target source
  version.
- Check the snapshot's [provenance manifest](../_candoitall-api-shared/manifest.json)
  before relying on it.
- Read the
  [durable run-record reference](references/durable-run-records.md) before constructing
  completed-run dashboards, summaries, graphs, or analytics. It supplies response and
  error details not currently inferred by the generated OpenAPI document.
- When the target host differs, inspect its live `/openapi/v1.json` or
  `/swagger/v1/swagger.json` document.
- Read `GET /api/processes/contract` before generating clients or smoke tests.
- Check `GET /api/access/status` before assuming bearer tokens are required.
- Do not reinstall or use `candoitall_processes`; that MCP server has been removed.

## Current Commands

| Concern | Endpoint |
| --- | --- |
| Contract | `GET /api/processes/contract` |
| Launch preflight | `POST /api/processes/launch/check` |
| Durable launch | `POST /api/processes/launch` |
| Dispatch | `POST /api/processes/runs/{runId}/dispatch` |
| Cancel | `POST /api/processes/runs/{runId}/cancel` |
| Rework | `POST /api/processes/runs/{runId}/steps/{stepInstanceId}/rework` |
| Live list | `GET /api/processes/live` |
| Live detail | `GET /api/processes/runs/{runId}` |
| Live history | `GET /api/processes/runs/{runId}/history` |
| Durable record list | `GET /api/processes/runs` |
| Durable analytics | `GET /api/processes/runs/analytics` |
| Durable summary | `GET /api/processes/runs/{runId}/summary` |
| Durable graph | `GET /api/processes/runs/{runId}/graph` |

## Launch

Use `POST /api/processes/launch/check` for a non-mutating launch preflight. It compiles
the selected process template, resolves step executors, and returns the launch plan and
readiness findings without creating a run.

Use `POST /api/processes/launch` only when a durable run is intended. Request fields:

- `definitionKey`
- `processDefinitionId`
- `liveRunProfileKey`
- `projectId`
- `projectNodeId`
- `requestedBy`
- `variables`
- `runReadiness`
- `execute`

`execute: false` avoids enqueuing immediate dispatcher execution but is not a dry run.
The launch endpoint still creates a durable run when readiness allows launch.

## Operator Actions

Dispatch ready work:

```http
POST /api/processes/runs/{runId}/dispatch
Content-Type: application/json

{
  "requestedBy": "api-client"
}
```

Cancel a run:

```http
POST /api/processes/runs/{runId}/cancel
Content-Type: application/json

{
  "requestedBy": "api-client",
  "reason": "Operator requested process run cancellation."
}
```

Request rework:

```http
POST /api/processes/runs/{runId}/steps/{stepInstanceId}/rework
Content-Type: application/json

{
  "requestedBy": "api-client",
  "reason": "Operator requested process step rework."
}
```

## Choose A Read Model

- Use `GET /api/processes/live?take=50&windowMinutes=240` for active and recently active
  runs. `take` is clamped to `1..500`; `windowMinutes` is clamped to one minute through
  30 days.
- Use `GET /api/processes/runs/{runId}` for deep live state.
- Use `GET /api/processes/runs/{runId}/history` for a bounded live timeline. `fromUtc`
  defaults to 24 hours before `toUtc`; `toUtc` defaults to now; `take` is clamped to
  `1..1000`.
- Use `GET /api/processes/runs` for compact, cursor-paged terminal records.
- Use `/summary` for bounded hard facts and the managed manager narrative.
- Use `/graph` for a paged step dependency graph.
- Use `/analytics` for terminal-run aggregates and source watermarks.

Live projection freshness is an operating signal. Durable records instead expose source
sequences, terminal time, schema version, completeness, and independent facts/narrative
stage status.

## Project-Structure Bridge

For project-node-bound work use:

- `POST /api/project-structure/projects/{projectId}/nodes/{nodeId}/process-definition`
- `POST /api/project-structure/projects/{projectId}/nodes/{nodeId}/process/start`

Resolve project and node identifiers through the Project Structure API. Validate both
the project-structure operation result and process readback.

## Operating Rules

- Prefer `launch/check` before `launch`.
- Treat `factsStatus` and `narrativeStatus` independently; a missing narrative does not
  mean the durable record or facts are absent.
- Treat `metrics.endedAtUtc` as business completion time. Do not substitute
  `recordUpdatedAtUtc`, which is stage-maintenance time.
- Follow `nextCursor` unchanged; do not derive offsets from it.
- Preserve restricted-diagnostic and runtime-event privacy boundaries.
- Do not invent older process authoring, artifact, assignment, escalation, approval, or
  template routes unless the running contract reintroduces them.

## Validation

1. Compare `GET /api/processes/contract` with the running OpenAPI document.
2. Run `launch/check` and inspect readiness before a durable launch.
3. After dispatch, cancellation, or rework, read live detail and history.
4. For terminal runs, verify durable list and summary separately.
5. For analytics, verify the effective time window, facts denominator, and data
   watermarks.
6. Confirm expected `400` and `404` error codes from the durable reference.

## Source Route Appendix

<!-- api-docs-skills-parity:routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/processes/contract` |
| `POST` | `/api/processes/launch/check` |
| `POST` | `/api/processes/launch` |
| `POST` | `/api/processes/runs/{runId:guid}/dispatch` |
| `POST` | `/api/processes/runs/{runId:guid}/cancel` |
| `POST` | `/api/processes/runs/{runId:guid}/steps/{stepInstanceId:guid}/rework` |
| `GET` | `/api/processes/live` |
| `GET` | `/api/processes/runs` |
| `GET` | `/api/processes/runs/analytics` |
| `GET` | `/api/processes/runs/{runId:guid}` |
| `GET` | `/api/processes/runs/{runId:guid}/summary` |
| `GET` | `/api/processes/runs/{runId:guid}/graph` |
| `GET` | `/api/processes/runs/{runId:guid}/history` |

<!-- api-docs-skills-parity:routes:end -->
