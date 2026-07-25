# Durable Process Run Records API

Use this reference with the shared OpenAPI snapshot for the durable process-run record
surface added by the `processes-snapshots` branch. It is derived from
`ProcessRunRecordsApi`, `ProcessRunRecordQueryService`, and the process run-record
contracts at source commit `065f31e0b527bcda2d499daf39e8a901e0231323`.

The generated OpenAPI document identifies the four operations and their parameters, but
the current Minimal API metadata publishes only a generic `200` response for them. The
typed response fields, validation rules, `400`, and `404` behavior below therefore
supplement, but do not replace, the exact runtime snapshot.

## Choose The Right Read Surface

| Need | Endpoint | Data model |
| --- | --- | --- |
| Active and recently active runs | `GET /api/processes/live` | Live runtime projection |
| Deep live state for one run | `GET /api/processes/runs/{runId}` | Live runtime projection |
| Recent runtime timeline | `GET /api/processes/runs/{runId}/history` | Live runtime projection |
| Completed-run list or dashboard | `GET /api/processes/runs` | Durable terminal record |
| Bounded hard facts and manager narrative | `GET /api/processes/runs/{runId}/summary` | Durable terminal record |
| Step dependency graph | `GET /api/processes/runs/{runId}/graph` | Durable terminal record |
| Aggregated terminal-run metrics | `GET /api/processes/runs/analytics` | Durable terminal records |

The durable endpoints return current records only; superseded records are excluded.
Their facts and narrative stages are independent and may complete at different times.

## List Records

```http
GET /api/processes/runs?projectId={projectId}&definitionId={definitionId}&rootRunId={rootRunId}&disposition=Succeeded&participantId={participantId}&fromUtc=2026-07-01T00:00:00Z&toUtc=2026-08-01T00:00:00Z&take=50
```

Query parameters:

| Parameter | Rules |
| --- | --- |
| `projectId` | Optional non-empty UUID |
| `definitionId` | Optional non-empty UUID |
| `rootRunId` | Optional non-empty UUID |
| `disposition` | Optional, case-insensitive `Succeeded`, `Failed`, `Cancelled`, or `Escalated` |
| `participantId` | Optional trimmed identifier, 1..256 characters |
| `fromUtc` | Optional inclusive terminal-time lower bound |
| `toUtc` | Optional exclusive terminal-time upper bound |
| `take` | Default `50`; must be `1..200` |
| `cursor` | Opaque cursor returned as `nextCursor`; pass it back unchanged |

When both times are supplied, `fromUtc` must be earlier than `toUtc`. Do not decode,
edit, or convert the cursor to an offset.

The response has `records` and `nextCursor`. Each compact record contains:

- `identity`: `runId`, `rootRunId`, optional `parentRunId`, `planId`, `definitionId`,
  `definitionVersionId`, and `projectId`;
- `disposition` and `completeness`;
- `factsStatus`, `factsAttemptCount`, and `factsNextAttemptAtUtc`;
- `narrativeStatus`, `narrativeAttemptCount`, and `narrativeNextAttemptAtUtc`;
- `metrics`;
- `sourceGlobalSequence`, `schemaVersion`, and `recordUpdatedAtUtc`.

The compact list deliberately omits hard-fact collections, manager narrative text,
worker leases, last-error classes, and diagnostic references. Follow the summary route
only for a selected run.

## Read A Summary

```http
GET /api/processes/runs/{runId}/summary?stepOffset=0&stepTake=100&runtimeEventMinuteOffset=0&runtimeEventMinuteTake=200
```

Paging rules:

| Parameter | Default | Rules |
| --- | ---: | --- |
| `stepOffset` | `0` | Must be non-negative |
| `stepTake` | `100` | Must be `1..200` |
| `runtimeEventMinuteOffset` | `0` | Must be non-negative |
| `runtimeEventMinuteTake` | `200` | Must be `1..200` |

The response contains `summary`, optional `facts`, and optional `narrative`.

### Summary

`summary` contains:

- typed identity, disposition, lifecycle state, and completeness;
- `evidence.available`, `evidence.missing`, and `completenessWarnings`;
- independent facts and narrative status, attempt count, next-attempt timestamp, and
  last-error class;
- aggregate metrics;
- up to 32 participant identifiers;
- an optional bounded narrative preview and its provenance;
- source global/root sequences, schema version, and `recordUpdatedAtUtc`.

The narrative preview bounds `overview` and `outcome` to 512 characters each.

### Hard Facts

When `facts` is present it contains:

- `stepPage` plus paged `steps`; use `totalCount`, `offset`, `take`, and `hasMore`;
- participant, workflow, subprocess-run, execution-run, and artifact identifiers, each
  accompanied by an exact total count;
- exact `totalRuntimeEventCount` and `managerRuntimeEventCount`;
- `runtimeEventMinuteBucketPage` plus minute buckets;
- bounded runtime-event category aggregates.

Identifier arrays are capped at 200 in the HTTP response even when their accompanying
count is larger. Each step exposes at most 256 dependency step identifiers and 64
execution-run identifiers.

Step facts include identity, step key/outcome, attempts, participant/workflow,
dependencies, execution runs, timing, token categories, estimated/actual cost, tool
calls, and artifact count.

Runtime minute buckets expose only `minuteUtc`, event counts, manager-event counts, and
duration. Category aggregates use `RunLifecycle`, `Step`, `Dispatch`, `Manager`, or
`Other` and expose counts and first/last timestamps.

### Manager Narrative

When `narrative` is present it contains:

- `overview` and `outcome`, each bounded to 2,048 characters;
- up to 12 items, each bounded to 512 characters, in `workCompleted`, `problems`,
  `decisions`, and `followUps`;
- provenance: manager agent, narrative execution run, generation policy, model, and
  generation timestamp.

Per-step generated result-summary text is intentionally not persisted in durable hard
facts or exposed by this API because it is unclassified model output. Raw runtime-event
names, payloads, actors, payload hashes, worker leases, and restricted diagnostic
references are also outside this contract.

## Read A Dependency Graph

```http
GET /api/processes/runs/{runId}/graph?stepOffset=0&stepTake=100
```

`stepOffset` defaults to `0`; `stepTake` defaults to `100` and must be `1..200`.

The response contains:

- the same durable `summary`;
- paged `nodes`;
- dependency `edges`;
- up to 200 subprocess run identifiers;
- `nodePage` with the total count and `hasMore`.

Edges are emitted only when both endpoints are present on the returned node page. A
page-local graph must not be interpreted as the complete run graph.

## Read Analytics

```http
GET /api/processes/runs/analytics?projectId={projectId}&definitionId={definitionId}&rootRunId={rootRunId}&participantId={participantId}&fromUtc=2026-07-01T00:00:00Z&toUtc=2026-08-01T00:00:00Z
```

The identity and participant filters follow the list-route rules. `toUtc` defaults to
the current UTC time and `fromUtc` defaults to 30 days before it. The range must be
strictly increasing and cannot exceed 366 days.

The response reports:

- the effective window and schema version;
- `matchingRunCount`;
- `factsAvailableRunCount`, `evidenceCompleteRunCount`,
  `evidencePartialRunCount`, and `factsUnavailableRunCount`;
- `dataThroughUtc` and `sourceGlobalSequenceWatermark`;
- duration, token categories, estimated/actual cost, repetitions, executions, rework,
  incidents, escalations, tool calls, and artifacts;
- matching-run counts by disposition.

`matchingRunCount` includes every current terminal record matching the filters.
Facts-derived metric totals use `factsAvailableRunCount` as their denominator.
Disposition counts use all matching records, including records whose facts are not
available.

`dataThroughUtc` is the latest included terminal-event time and
`sourceGlobalSequenceWatermark` is the largest included source sequence. Worker claims,
narrative retries, and other record maintenance do not advance those source watermarks.

## Status And Evidence Values

- Disposition: `Succeeded`, `Failed`, `Cancelled`, `Escalated`.
- Lifecycle: `Current`, `Superseded`; current HTTP queries exclude superseded records.
- Completeness: `SeedOnly`, `Partial`, `Complete`.
- Facts status: `Pending`, `Assembling`, `Completed`, `Failed`.
- Narrative status: `Pending`, `Generating`, `Completed`, `Failed`.
- Evidence sources: `RuntimeState`, `InstancePlan`, `StepAssignments`,
  `ExecutionObservations`, `UsageTelemetry`, `Pricing`, `RuntimeEvents`,
  `ArtifactLineage`, and `Subprocesses`.

Completeness warnings identify missing or truncated evidence. Treat them as contract
signals; do not infer completeness solely from the disposition.

## Errors And Time Semantics

- Invalid filters, cursors, time ranges, identifiers, or page bounds return `400` with
  error code `process.run_record_query_invalid`.
- A missing summary or graph returns `404` with
  `process.run_record_not_found`.
- The live `GET /api/processes/runs/{runId}` route uses the separate
  `process.run_not_found` error code.

`metrics.endedAtUtc` is the canonical terminal-event timestamp.
`recordUpdatedAtUtc` is later stage-maintenance time and must not be used as the business
completion timestamp or analytics watermark.
