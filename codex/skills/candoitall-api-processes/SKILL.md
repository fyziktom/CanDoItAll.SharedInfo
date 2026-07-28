---
name: candoitall-api-processes
description: Use when launching, dispatching, cancelling, reworking, or observing live CanDoItAll process runs through the current HTTP API.
---

# CanDoItAll Processes API

Use this skill for process runtime control and readback through the main CanDoItAll web
API.

## Contract Source

- Use the shared
  [OpenAPI snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  for the complete route and parameter contract when it matches the target source
  version.
- Check the snapshot's [provenance manifest](../_candoitall-api-shared/manifest.json)
  before relying on it.
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
| Durable record summary | `GET /api/processes/runs/{runId}/summary` |
| Durable record graph | `GET /api/processes/runs/{runId}/graph` |
| Durable record analytics | `GET /api/processes/runs/analytics` |

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

## Read Process State

- Use `GET /api/processes/live?take=50&windowMinutes=240` for active and recently active
  runs. `take` is clamped to `1..500`; `windowMinutes` is clamped to one minute through
  30 days.
- Use `GET /api/processes/runs/{runId}` for deep live state.
- Use `GET /api/processes/runs/{runId}/history` for a bounded live timeline. `fromUtc`
  defaults to 24 hours before `toUtc`; `toUtc` defaults to now; `take` is clamped to
  `1..1000`.
- Use `GET /api/processes/runs` for cursor-paged durable records. Available filters
  are `projectId`, `definitionId`, `rootRunId`, `disposition`, `participantId`,
  `fromUtc`, `toUtc`, `take`, and `cursor`.
- Use `GET /api/processes/runs/{runId}/summary` for a paged summary with
  `stepOffset`, `stepTake`, `runtimeEventMinuteOffset`, and
  `runtimeEventMinuteTake`.
- Use `GET /api/processes/runs/{runId}/graph` for the bounded durable step graph with
  `stepOffset` and `stepTake`.
- Use `GET /api/processes/runs/analytics` for durable aggregate analytics filtered by
  project, definition, root run, participant, or time window.

### Manager Snapshot And Activity Boundary

The Process Manager chat can reuse a bounded immutable snapshot of the already-loaded
selected-run shell inside the host process. That snapshot is invocation context, not
a durable process record and not an HTTP resource. The `/api/processes/live`,
`/api/processes/runs/{runId}`, and history routes continue to read the canonical
application/projection boundary.

The current HTTP contract has no process-manager agent-activity SSE endpoint. External
clients must use the documented process and agent execution evidence routes. Do not
infer a snapshot or event-stream route from UI activity feedback.

## Project-Structure Bridge

For project-node-bound work use:

- `POST /api/project-structure/projects/{projectId}/nodes/{nodeId}/process-definition`
- `POST /api/project-structure/projects/{projectId}/nodes/{nodeId}/process/start`

Resolve project and node identifiers through the Project Structure API. Validate both
the project-structure operation result and process readback.

## Operating Rules

- Prefer `launch/check` before `launch`.
- Preserve restricted-diagnostic and runtime-event privacy boundaries.
- Do not invent older process authoring, artifact, assignment, escalation, approval, or
  template routes unless the running contract reintroduces them.

## Validation

1. Compare `GET /api/processes/contract` with the running OpenAPI document.
2. Run `launch/check` and inspect readiness before a durable launch.
3. After dispatch, cancellation, or rework, read live detail and history.
4. Confirm expected structured errors for invalid or missing live-run operations.

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
| `GET` | `/api/processes/runs/{runId:guid}/graph` |
| `GET` | `/api/processes/runs/{runId:guid}/history` |
| `GET` | `/api/processes/runs/{runId:guid}/summary` |

<!-- api-docs-skills-parity:routes:end -->
