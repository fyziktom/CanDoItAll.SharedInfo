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
- Generate clients from the OpenAPI document. `GET /api/processes/contract` returns only a
  compiled `METHOD /path` list with no shapes.
- Check `GET /api/access/status` before assuming bearer tokens are required.
- Do not reinstall or use `candoitall_processes`; that MCP server has been removed.

## Current Commands

| Concern | Endpoint |
| --- | --- |
| Contract | `GET /api/processes/contract` |
| Launch preflight | `POST /api/processes/launch/check` |
| Durable launch | `POST /api/processes/launch` |
| Prepared launch status | `GET /api/processes/launch/{admissionId}` |
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

Use `POST /api/processes/launch/check` to review a launch. It compiles the selected
process template, resolves step executors, and returns the launch plan and readiness
findings. Launch check creates no run and dispatches nothing. Unless readiness blocks it,
it saves a durable preparation bound to the caller and returns `observation.admissionId`
(`stage` `Planned`). The preflight asks every runtime tool provider for an inert tool
inventory of the step's declared operations; a tool listed there is a discoverable
capability, not an executable grant, and dispatch composes its own tools from the saved
execution.

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
- `callerIntentId`
- `preparedAdmissionId`

Generate `callerIntentId` once per intended launch and send it unchanged with the check,
the launch and every retry. A retry must repeat every member except `execute` exactly,
and a launch retried after its run was accepted must also repeat `execute`; different
input returns 409 `process.launch_intent_conflict`. Without these identifiers every call
creates a new preparation, and every launch a new run.

`execute: false` avoids enqueuing immediate dispatcher execution but is not a dry run.
The launch endpoint still creates a durable run when readiness allows launch. The run is
still activated, and the dispatch recovery scan can run its ready steps later. Do not
use it to pause a run.

After a lost or failed launch response, resend the identical request with the same
`callerIntentId` (or `preparedAdmissionId`); it returns the same run and creates nothing
new. `GET /api/processes/launch/{admissionId}` reads a preparation only when you already
hold its id, for example from the check. A 400 or 403 does not prove that no preparation
was saved.

With authorization enabled, the token needs `sub` and `exp` claims. A preparation is
bound to that subject, and the launch must happen before the token that created the
preparation expires and while the project's lifetime is unchanged.

## Operator Actions

Dispatch ready work:

```http
POST /api/processes/runs/{runId}/dispatch
Content-Type: application/json

{
  "requestedBy": "api-client"
}
```

Dispatch executes ready steps synchronously inside the request: at most 200 passes, with
each step bounded by the step timeout (60 minutes by default). It bypasses the background
worker's queue and per-run lock. Use it only when nothing is progressing the run. A repeat
can execute newly ready steps, and a disconnect cancels the step in progress without
undoing its effects.

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
  "reason": "Reject an empty project name in the settings form; two unit tests fail."
}
```

Cancel and rework both return 200 with an `outcome`. Only a cancel `Applied` means the run
is cancelled; a rework `Applied` or `Duplicate` means the step is queued. A cancel `reason`
is not stored. A rework `reason` is passed to the step's executor verbatim, without
redaction: write a concrete correction and never include secrets.

## Read Process State

- Use `GET /api/processes/live?take=50&windowMinutes=240` for active and recently active
  runs. `take` is clamped to `1..500`; `windowMinutes` is clamped to one minute through
  30 days.
- Use `GET /api/processes/runs/{runId}` for deep live state.
- Use `GET /api/processes/runs/{runId}/history` for a bounded live timeline. `fromUtc`
  defaults to 24 hours before `toUtc`; `toUtc` defaults to now; `take` is clamped to
  `1..1000`. It returns the oldest `take` events (default 100) and has no continuation
  value: set `fromUtc` to the last event's `occurredAtUtc` and skip known `eventId`s.
  Child-run events are excluded, and an unknown run returns an empty list, not 404.
- Use `GET /api/processes/runs` for cursor-paged durable records. Available filters
  are `projectId`, `definitionId`, `rootRunId`, `disposition`, `participantId`,
  `fromUtc`, `toUtc`, `take`, and `cursor`. A record exists only after a run ends
  (Succeeded, Failed, Cancelled or Blocked). `projectId`, `definitionId` and
  `participantId` match only records whose facts are assembled. Repeat the filters with
  every `cursor`.
- Use `GET /api/processes/runs/{runId}/summary` for a paged summary with
  `stepOffset`, `stepTake`, `runtimeEventMinuteOffset`, and
  `runtimeEventMinuteTake`.
- Use `GET /api/processes/runs/{runId}/graph` for the bounded durable step graph with
  `stepOffset` and `stepTake`.
- Use `GET /api/processes/runs/analytics` for durable aggregate analytics filtered by
  project, definition, root run, participant, or time window.
- Read [durable run records](references/durable-run-records.md) before choosing between
  the live and durable reads or interpreting record totals.

### Process SSE Boundary

The Process Manager chat can reuse a bounded immutable snapshot of the already-loaded
selected-run shell inside the host process. That snapshot is invocation context, not
a durable process record and not an HTTP resource. The `/api/processes/live`,
`/api/processes/runs/{runId}`, and history routes continue to read the canonical
application/projection boundary.

The process SSE routes emit signal-only lifecycle categories: `started`, `progress`,
`needsAttention`, `completed`, `failed`, and `cancelled`. Envelopes include exact/root run
ids plus durable global/root source sequences. Restricted events mask their event type
and do not expose actor, correlation, or payload-hash details.

Both routes emit `process.run.changed` with `eventId`, `globalSequence`,
`rootSequence`, `rootRunId`, exact `runId`, `category`, `eventType`, `sensitivity`,
`occurredAtUtc`, `isTerminal`, and `needsAttention`. The exact-run route filters by
`runId`; it does not subscribe to every descendant of `rootRunId`. `eventId`, `rootRunId`
and `runId` are objects of the form `{"value":"<GUID>"}`, not strings. A terminal signal
does not close the stream.

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

Delivery is best effort: a signal can be skipped or arrive twice. Deduplicate by
`eventId`, not by the host-local SSE id, and treat each signal only as a prompt to read
canonical state, not as a replacement for the projection/read APIs.

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
  route when the `runId` is already known.
- Do not invent older process authoring, artifact, assignment, escalation, approval, or
  template routes unless the running contract reintroduces them.

## Validation

1. Compare `GET /api/processes/contract` with the running OpenAPI document.
2. Run `launch/check` and inspect readiness before a durable launch.
3. After dispatch, cancellation, or rework, read live detail and history.
4. Confirm the documented errors. A 403 from check, launch or launch status has no JSON
   envelope and may render as the host's HTML status page. The all-zero GUID currently
   returns 500 on several live-run routes. Launch 400s (`process.launch_check_failed`,
   `process.launch_failed`) do not return the cause.

## Source Route Appendix

<!-- api-docs-skills-parity:routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/processes/contract` |
| `GET` | `/api/processes/events/stream` |
| `POST` | `/api/processes/launch` |
| `POST` | `/api/processes/launch/check` |
| `GET` | `/api/processes/launch/{admissionId}` |
| `GET` | `/api/processes/live` |
| `GET` | `/api/processes/runs` |
| `GET` | `/api/processes/runs/analytics` |
| `GET` | `/api/processes/runs/{runId}` |
| `POST` | `/api/processes/runs/{runId}/cancel` |
| `POST` | `/api/processes/runs/{runId}/dispatch` |
| `GET` | `/api/processes/runs/{runId}/events/stream` |
| `GET` | `/api/processes/runs/{runId}/graph` |
| `GET` | `/api/processes/runs/{runId}/history` |
| `POST` | `/api/processes/runs/{runId}/steps/{stepInstanceId}/rework` |
| `GET` | `/api/processes/runs/{runId}/summary` |
<!-- api-docs-skills-parity:routes:end -->
