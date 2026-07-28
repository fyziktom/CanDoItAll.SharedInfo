---
name: candoitall-api-processes
description: Use when launching, dispatching, cancelling, reworking, or observing live CanDoItAll process runs and SSE lifecycle signals through the HTTP API.
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
| All-run SSE signals | `GET /api/processes/events/stream` |
| Exact-run SSE signals | `GET /api/processes/runs/{runId}/events/stream` |
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

### Process SSE Boundary

The Process Manager chat can reuse a bounded immutable snapshot of the already-loaded
selected-run shell inside the host process. That snapshot is invocation context, not
a durable process record and not an HTTP resource. The `/api/processes/live`,
`/api/processes/runs/{runId}`, and history routes continue to read the canonical
application/projection boundary.

The process SSE routes emit signal-only lifecycle categories: started, progress,
needs-attention, completed, failed, and cancelled. Envelopes include exact/root run
ids plus durable global/root source sequences. Restricted events mask their event type
and do not expose actor, correlation, or payload-hash details.

Both routes emit `process.run.changed` with `eventId`, `globalSequence`,
`rootSequence`, `rootRunId`, exact `runId`, `category`, `eventType`, `sensitivity`,
`occurredAtUtc`, `isTerminal`, and `needsAttention`. The exact-run route filters by
`runId`; it does not subscribe to every descendant of `rootRunId`.

API replay is a bounded, host-local window even though process source events are
durable. Resume with either a non-negative `Last-Event-ID` header or equivalent
`after` query parameter; if both are supplied, they must be equal. The SSE `id` is an
API cursor, not `globalSequence`. An invalid or conflicting cursor returns HTTP `400`
with `sse.cursor-invalid`.

When the cursor is outside retention or ahead of the current host stream,
`stream.gap` reports `reason`, `requestedAfterSequence`, `firstAvailableSequence`,
`lastAvailableSequence`, and `resumeAfterSequence`. The connection continues from
that resume cursor and sends retained matching notifications. Reload live detail or
history before trusting subsequent signals because SSE cannot reconstruct the missed
projection state.

Projection notification is at-least-once. Deduplicate process signals by durable
`eventId` or `globalSequence`, not by the host-local SSE id. A process SSE event is a
prompt to query canonical state, not a replacement for the projection/read APIs.

The stream is pinned to the active database profile and runtime generation. A profile
switch cancels existing subscriptions. Reconnect against the active profile and
rebuild state from durable APIs; do not carry an SSE cursor across a profile switch or
process restart.

This implementation is intentionally limited to local/basic fan-out. Global and
exact-run subscriptions share one profile-global replay buffer and wake-up path, and
run filters are applied while reading bounded batches. It is not a claim of
token-rate or thousands-of-subscribers scalability.

## Project-Structure Bridge

For project-node-bound work use:

- `POST /api/project-structure/projects/{projectId}/nodes/{nodeId}/process-definition`
- `POST /api/project-structure/projects/{projectId}/nodes/{nodeId}/process/start`

Resolve project and node identifiers through the Project Structure API. Validate both
the project-structure operation result and process readback.

## Operating Rules

- Prefer `launch/check` before `launch`.
- Preserve restricted-diagnostic and runtime-event privacy boundaries.
- Use the global SSE route for fleet-level attention/terminal signals and the exact-run
  route when the `ProcessRunId` is already known.
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
| `GET` | `/api/processes/events/stream` |
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
| `GET` | `/api/processes/runs/{runId:guid}/events/stream` |
| `GET` | `/api/processes/runs/{runId:guid}/summary` |

<!-- api-docs-skills-parity:routes:end -->
