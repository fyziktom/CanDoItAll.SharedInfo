# Durable Process Run Records API

Use with the target build's OpenAPI document, which fully describes `ListProcessRunRecords`,
`GetProcessRunRecordSummary`, `GetProcessRunRecordGraph` and `GetProcessRunRecordAnalytics`.
This page keeps only the rules a client needs to choose and interpret them.

## Choose The Right Read Surface

| Need | Endpoint | Data model |
| --- | --- | --- |
| Active and recently active runs | `GET /api/processes/live` | Live runtime projection |
| Deep live state for one run | `GET /api/processes/runs/{runId}` | Live runtime projection |
| Recent runtime timeline | `GET /api/processes/runs/{runId}/history` | Live runtime projection |
| Ended-run list or dashboard | `GET /api/processes/runs` | Durable ended-run record |
| Bounded hard facts and manager narrative | `GET /api/processes/runs/{runId}/summary` | Durable ended-run record |
| Step dependency graph | `GET /api/processes/runs/{runId}/graph` | Durable ended-run record |
| Aggregated ended-run metrics | `GET /api/processes/runs/analytics` | Durable ended-run records |

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
| `disposition` | Optional, case-insensitive `Succeeded`, `Failed`, `Cancelled` or `Blocked` (`Escalated` is accepted but not currently produced) |
| `participantId` | Optional trimmed identifier, 1..256 characters |
| `fromUtc` | Optional inclusive lower bound of the run's end time |
| `toUtc` | Optional exclusive upper bound of the run's end time |
| `take` | Default `50`; must be `1..200` |
| `cursor` | Opaque cursor returned as `nextCursor`; pass it back unchanged |

When both times are supplied, `fromUtc` must be earlier than `toUtc`. Do not decode,
edit, or convert the cursor to an offset. The cursor does not carry the filters: send the
same filters with every `cursor`. `projectId`, `definitionId` and `participantId` match
only records whose facts are assembled (`factsStatus` `Completed`); `rootRunId`,
`disposition`, `fromUtc` and `toUtc` apply as soon as a record exists.

The response has `records` and `nextCursor`; the live schema lists the members of each
compact record. The compact list deliberately omits hard-fact collections, manager
narrative text, worker leases, last-error classes, and diagnostic references. Follow the
summary route only for a selected run.

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

The response contains `summary`, optional `facts`, and optional `narrative`. `facts` stays
null until `summary.factsStatus` is `Completed`, and `narrative` until
`summary.narrativeStatus` is `Completed`; a missing or failed narrative does not invalidate
available facts. Check `summary.completeness`, `summary.evidence` and
`completenessWarnings` before relying on totals.

Facts cover the run and every child run it launched. Identifier arrays are capped at 200
in the HTTP response even when their accompanying count is larger, so use the count, not
the array length. The summary lists at most 32 participants; the facts list up to 200.

The narrative is a model-written interpretation of the hard facts, which remain the
evidence. Per-step generated result-summary text is intentionally not persisted in durable
hard facts or exposed by this API because it is unclassified model output. Raw
runtime-event names, payloads, actors, payload hashes, worker leases, and restricted
diagnostic references are also outside this contract.

## Read A Dependency Graph

```http
GET /api/processes/runs/{runId}/graph?stepOffset=0&stepTake=100
```

`stepOffset` defaults to `0`; `stepTake` defaults to `100` and must be `1..200`.

The response contains the same durable `summary`, one page of step `nodes`, dependency
`edges`, up to 200 subprocess run identifiers, and `nodePage` with the total count and
`hasMore`. The graph is empty while the facts are not assembled.

Edges are emitted only when both endpoints are present on the returned node page. A
page-local graph must not be interpreted as the complete run graph.

## Read Analytics

```http
GET /api/processes/runs/analytics?projectId={projectId}&definitionId={definitionId}&rootRunId={rootRunId}&participantId={participantId}&fromUtc=2026-07-01T00:00:00Z&toUtc=2026-08-01T00:00:00Z
```

The identity and participant filters follow the list-route rules. `toUtc` defaults to
the current UTC time and `fromUtc` defaults to 30 days before it. The range must be
strictly increasing and cannot exceed 366 days. There is no disposition filter; the
response breaks the matching records down by disposition.

`matchingRunCount` includes every current ended-run record matching the filters.
Facts-derived metric totals use `factsAvailableRunCount` as their denominator.
Disposition counts use all matching records, including records whose facts are not
available.

A parent record's totals include its child runs, which are also counted as their own
records, so sums over a window containing both double-count the child runs. Filtering by
`rootRunId` still returns both kinds of record. For exact figures of one run tree, read
the root run's own record, whose totals already include its child runs.

`dataThroughUtc` is the latest included end time and `sourceGlobalSequenceWatermark` is
the largest included source sequence. Worker claims, narrative retries, and other record
maintenance do not advance those source watermarks.

## Status And Evidence Values

- Disposition: `Succeeded`, `Failed`, `Cancelled`, `Blocked` (`Escalated` is accepted but
  not currently produced).
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
  `process.run_record_not_found`: the run does not exist, has not ended, its end has not
  been processed yet, or it was reactivated and is running again.
- The live `GET /api/processes/runs/{runId}` route uses the separate
  `process.run_not_found` error code.

`metrics.endedAtUtc` is the canonical time of the event that ended the run.
`recordUpdatedAtUtc` is later stage-maintenance time and must not be used as the business
completion timestamp or analytics watermark.
