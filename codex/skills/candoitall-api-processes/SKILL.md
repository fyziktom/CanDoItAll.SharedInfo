---
name: candoitall-api-processes
description: Use when launching, dispatching, cancelling, reworking, observing, or reviewing CanDoItAll process runs through the current HTTP API instead of the removed Processes MCP server.
---

# CanDoItAll Processes API

Use this skill when a task needs process runtime control through the CanDoItAll web API.

Processes are the durable orchestration layer, but the current HTTP surface is intentionally narrow. Sources of truth: `src/App/CanDoItAll.Web/Api/ProcessesApi.cs` and `src/App/CanDoItAll.Web/Api/ProcessRunRecordsApi.cs`.

## Access

- Start the CanDoItAll web app and inspect Swagger/OpenAPI at `/swagger` or `/swagger/v1/swagger.json`.
- Check `GET /api/access/status` before assuming bearer tokens are required.
- If JWT is active, send `Authorization: Bearer <token>`.
- Do not reinstall or use `candoitall_processes`; that MCP server has been removed.
- Do not document older process authoring, artifact, assignment, escalation, direct-message, manager-directive, approval, or template routes as current HTTP commands unless the process API source reintroduces them.

## Current Commands

The current source-backed process API exposes these commands:

- `GET /api/processes/contract`
- `POST /api/processes/launch/check`
- `POST /api/processes/launch`
- `POST /api/processes/runs/{runId}/dispatch`
- `POST /api/processes/runs/{runId}/cancel`
- `POST /api/processes/runs/{runId}/steps/{stepInstanceId}/rework`
- `GET /api/processes/live`
- `GET /api/processes/runs`
- `GET /api/processes/runs/analytics`
- `GET /api/processes/runs/{runId}`
- `GET /api/processes/runs/{runId}/summary`
- `GET /api/processes/runs/{runId}/graph`
- `GET /api/processes/runs/{runId}/history`

Use `GET /api/processes/contract` first when building clients or smoke tests. It returns the current endpoint list and boundary summary from the running host.

Use `POST /api/processes/launch/check` for non-mutating launch preflight. It compiles the selected process template, resolves step executors, returns the launch plan and readiness findings, and does not create a process run.

## Launch

`POST /api/processes/launch/check`

`POST /api/processes/launch`

`ProcessLaunchApiRequest` fields:

- `definitionKey`
- `processDefinitionId`
- `liveRunProfileKey`
- `projectId`
- `projectNodeId`
- `requestedBy`
- `variables`
- `runReadiness`
- `execute`

Example:

```http
POST /api/processes/launch/check
Content-Type: application/json
```

```json
{
  "definitionKey": "business-plan-development",
  "projectId": "00000000-0000-0000-0000-000000000000",
  "projectNodeId": "node-id",
  "requestedBy": "api-client",
  "variables": {
    "Topic": "New offer"
  },
  "runReadiness": true,
  "execute": false
}
```

`launch/check` ignores `execute` and is the safe preflight path when the caller must not create a durable run.

`POST /api/processes/launch` always creates and schedules a durable run when readiness allows launch. `execute: false` avoids enqueuing immediate dispatcher execution; it is not a dry run. Use `execute: true` only when the caller intends to enqueue runtime execution immediately.

The launch response includes:

- `definitionId`
- `launchPlanId`
- `runId`
- `stage`
- `route`
- `launchPlan`
- `warnings`

## Dispatch And Operator Actions

Dispatch ready work:

```http
POST /api/processes/runs/{runId}/dispatch
Content-Type: application/json
```

```json
{
  "requestedBy": "api-client"
}
```

Cancel a run:

```http
POST /api/processes/runs/{runId}/cancel
Content-Type: application/json
```

```json
{
  "requestedBy": "api-client",
  "reason": "Operator requested process run cancellation."
}
```

Request rework for a step instance:

```http
POST /api/processes/runs/{runId}/steps/{stepInstanceId}/rework
Content-Type: application/json
```

```json
{
  "requestedBy": "api-client",
  "reason": "Operator requested process step rework."
}
```

The dispatch path runs through `ProcessRuntimeDispatchApplicationService` and `ProcessRuntimeEngine`. Cancel and rework run through `ProcessRuntimeOperatorApplicationService`.

## Readback

List live processes:

```http
GET /api/processes/live?take=50&windowMinutes=240
```

Query fields:

- `take`: clamped to 1..500, default `50`.
- `windowMinutes`: clamped to 1 minute..30 days, default `240`.

Read one run:

```http
GET /api/processes/runs/{runId}
```

This route is the live/deep runtime projection. Prefer the durable record routes below for completed-run lists, dashboards, graphs, analytics, cost history, and manager readback.

List durable process-run records:

```http
GET /api/processes/runs?projectId={projectId}&definitionId={definitionId}&disposition=Succeeded&fromUtc=2026-06-01T00:00:00Z&toUtc=2026-07-01T00:00:00Z&take=50
```

Durable-list query fields:

- `projectId`: optional project identifier.
- `definitionId`: optional process definition identifier.
- `rootRunId`: optional root process run identifier.
- `disposition`: optional `Succeeded`, `Failed`, `Cancelled`, or `Escalated`.
- `participantId`: optional persisted participant/agent identifier.
- `fromUtc`: optional inclusive terminal timestamp.
- `toUtc`: optional exclusive terminal timestamp.
- `take`: 1..200, default `50`.
- `cursor`: opaque cursor returned as `nextCursor`; pass it unchanged and do not derive offsets from it.

The durable list is deliberately compact. Each row contains identity, disposition,
completeness, facts/narrative stage status and retry timestamps, aggregate metrics,
source sequence, schema version, and `recordUpdatedAtUtc`. It does not return participant
collections, manager narrative text/previews, hard-fact JSON, worker leases, or
diagnostic references. Follow the summary route only for a selected run.

Read one durable summary and its bounded hard facts:

```http
GET /api/processes/runs/{runId}/summary?stepOffset=0&stepTake=100&runtimeEventMinuteOffset=0&runtimeEventMinuteTake=200
```

`stepOffset` defaults to `0`. `stepTake` defaults to `100` and must be `1..200`.
Use `facts.stepPage.totalCount` and `facts.stepPage.hasMore` to page the step
collection. Identifier collections are independently capped and include their
total counts.

`runtimeEventMinuteOffset` defaults to `0`. `runtimeEventMinuteTake` defaults to
`200` and must be `1..200`. Use `facts.runtimeEventMinuteBucketPage.totalCount`
and `hasMore` to page the minute buckets independently from step facts.

The response exposes:

- typed run/root/parent, plan, definition/version, and project identifiers;
- disposition, lifecycle, schema version, source sequences, and freshness;
- completeness plus available/missing evidence sources and warning codes;
- facts and narrative stage status, attempt count, and next retry timestamp without worker leases or diagnostic references;
- step counts, repetitions, timing, token categories, estimated/actual cost, executions, tool calls, artifacts, incidents, escalations, and subprocess totals;
- bounded participant, workflow, subprocess, execution, artifact, and paged per-step facts;
- exact total and manager runtime-event counts, paged minute buckets, and bounded category aggregates using `RunLifecycle`, `Step`, `Dispatch`, `Manager`, or `Other`;
- the manager narrative and its manager agent, execution run, policy, model, and generated-at provenance when generation is complete.

Per-step generated `ResultSummary` text is intentionally neither persisted in
durable hard facts nor exposed by the HTTP API because it is unclassified model
output. Live diagnostic surfaces retain their separate access and sensitivity
policy. The durable manager narrative is the managed readback surface for
qualitative results.

Runtime-event aggregates expose only minute timestamps, counts, durations, typed
categories, and category time ranges. Raw event names, payload details, actors,
and payload hashes are intentionally not part of this API contract.

`factsStatus` and `narrativeStatus` are independent. A record can have complete hard facts while its manager narrative is still pending or has failed. Never treat an absent narrative as an absent run record.

Read the durable step dependency graph:

```http
GET /api/processes/runs/{runId}/graph?stepOffset=0&stepTake=100
```

Graph nodes use the same `stepOffset`/`stepTake` bounds. `nodePage` reports the
total node count and whether another page exists. Dependency edges are emitted
only when both endpoints are present on the returned node page, so clients must
not infer that a page-local graph is the entire run.

Read aggregate durable analytics:

```http
GET /api/processes/runs/analytics?projectId={projectId}&fromUtc=2026-06-01T00:00:00Z&toUtc=2026-07-01T00:00:00Z
```

Analytics accepts `projectId`, `definitionId`, `rootRunId`, and `participantId`.
The time window defaults to the last 30 days and cannot exceed 366 days.
`matchingRunCount` counts every current terminal record matching the filters.
`factsAvailableRunCount` is the denominator for duration, token, cost,
repetition, execution, rework, incident, escalation, tool-call, and artifact
totals. Within that denominator, `evidenceCompleteRunCount` reports complete
evidence and `evidencePartialRunCount` reports assembled but partial evidence.
`factsUnavailableRunCount` reports matching records excluded from metric totals.
Each disposition row uses `matchingRunCount`, so disposition counts cover records
regardless of facts availability or evidence completeness.
`dataThroughUtc` is the latest terminal-event time included by the filters and
`sourceGlobalSequenceWatermark` is the largest included source sequence. These
are persisted data watermarks; worker claims and narrative retries do not advance
them. `recordUpdatedAtUtc` on list/summary records is stage-maintenance time and
must not be interpreted as a canonical source watermark.

Read recent run history:

```http
GET /api/processes/runs/{runId}/history?fromUtc=2026-06-25T00:00:00Z&toUtc=2026-06-25T12:00:00Z&take=100
```

History query fields:

- `fromUtc`: defaults to 24 hours before `toUtc`.
- `toUtc`: defaults to current UTC.
- `take`: clamped to 1..1000, default `100`.

Run and history responses expose live projection freshness. Durable record responses expose source sequence, terminal time, record update time, schema, lifecycle, and stage completeness. Analytics exposes persisted data-through/sequence watermarks. The runtime projector advances in the background; treat stale source watermarks or backlog as an operating signal, not as proof that a run is complete.

For backfilled durable records, `endedAtUtc` remains the canonical terminal-event
time while `recordUpdatedAtUtc` is the later projection materialization/update
time. Do not use record update time as the business completion timestamp or data
watermark.

## Project-Structure Bridge

Node-bound process work is currently exposed through the Project Structure API and runtime tools:

- `POST /api/project-structure/projects/{projectId}/nodes/{nodeId}/process-definition`
- `POST /api/project-structure/projects/{projectId}/nodes/{nodeId}/process/start`
- `project_structure_node_process_definition_link`
- `project_structure_node_process_start`
- `project_structure_process_subprocess_launch`

Use the project-structure bridge when a process is linked to a project node or when governed subprocess launch is required inside process automation.

## Direct Tool Boundary

The current source tree does not contain `ProcessAgentRuntimeToolProvider`, and `AddProcessesModule` does not register direct `processes_*` runtime tools.

If a prompt or older doc asks for `processes_definition_save`, `processes_runs_list`, `processes_artifact_record`, `processes_step_transition`, or similar direct process tools, do not invent them. Use the HTTP commands in this skill or the project-structure bridge commands above, then record the missing direct tool as a hardening gap.

## Not Current HTTP Commands

These older route families are not currently mapped by `src/App/CanDoItAll.Web/Api/ProcessesApi.cs`:

- `/api/processes/definitions`
- `/api/processes/templates`
- `/api/processes/runs/start`
- `/api/processes/runs/stop`
- step transition or rerun-agent routes
- step-scoped artifacts or assignments
- direct messages
- manager directives
- escalations
- operator approvals
- launch-plan HR/provisioning routes

Do not call those routes until they are reintroduced with typed handlers, OpenAPI visibility, tests, and refreshed skill documentation.

## Validation

- Before launch, call `POST /api/processes/launch/check` when you need readiness diagnostics without creating a run.
- After launch, read back `GET /api/processes/runs/{runId}` when `runId` is present.
- After dispatch, cancel, or rework, read the run and history routes.
- For completed-run lists and dashboards, use `GET /api/processes/runs`; follow `nextCursor` without modifying it.
- For completion readback, accept hard facts when `factsStatus` is `Completed`, and inspect `narrativeStatus` separately.
- Use `/summary`, `/graph`, and `/analytics` before loading canonical history or execution details.
- For node-bound process starts, validate both the project-structure operation result and the process run readback.
- For docs-only skill updates, run `git diff --check` and regenerate the source route appendix.
- For runtime behavior changes, add focused tests around `ProcessesApi`, `ProcessLaunchApplicationService`, `ProcessRuntimeDispatchApplicationService`, and `ProcessRuntimeOperatorApplicationService`.

## Source Route Appendix

<!-- api-docs-skills-parity:routes:start -->

Processes API route appendix. Generated from Minimal API registrations; refresh from `src/App/CanDoItAll.Web/Api/ProcessesApi.cs` and `src/App/CanDoItAll.Web/Api/ProcessRunRecordsApi.cs` when routes change.

| Method | Route |
| --- | --- |
| `GET` | `/api/processes/contract` |
| `POST` | `/api/processes/launch` |
| `POST` | `/api/processes/launch/check` |
| `GET` | `/api/processes/live` |
| `GET` | `/api/processes/runs` |
| `GET` | `/api/processes/runs/analytics` |
| `GET` | `/api/processes/runs/{runId:guid}` |
| `POST` | `/api/processes/runs/{runId:guid}/cancel` |
| `POST` | `/api/processes/runs/{runId:guid}/dispatch` |
| `GET` | `/api/processes/runs/{runId:guid}/graph` |
| `GET` | `/api/processes/runs/{runId:guid}/history` |
| `GET` | `/api/processes/runs/{runId:guid}/summary` |
| `POST` | `/api/processes/runs/{runId:guid}/steps/{stepInstanceId:guid}/rework` |

<!-- api-docs-skills-parity:routes:end -->
