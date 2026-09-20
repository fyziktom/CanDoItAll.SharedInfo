---
name: candoitall-api-workflows
description: Use when resolving CanDoItAll workflows by stable identity, launching idempotently, or managing definitions, lifecycle, runtime runs, SSE signals, requests, artifacts, events, executors, and analytics through the HTTP API.
---

# CanDoItAll Workflows API

Use this skill when a task needs workflow authoring, lifecycle control, runtime observation, human/external request response, or workflow analytics through the CanDoItAll web API.

## Access

- Start the CanDoItAll web app and inspect Swagger/OpenAPI at `/swagger` or `/openapi/v1.json`.
- Check `/api/access/status` before assuming bearer tokens are required.
- When API authorization is enabled, create a token from Settings -> API Access, or with
  `POST /api/access/tokens` using a token that has the exact `api.tokens.issue` scope, then send
  `Authorization: Bearer <token>`.
- Do not add or reinstall a workflow-specific MCP server; workflow control is through the HTTP API.

## Contract Source

- Use the shared
  [OpenAPI snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  for exact schemas when it matches the target source version.
- Check the snapshot's [provenance manifest](../_candoitall-api-shared/manifest.json)
  before relying on it.
- When the target host differs, use its live `/openapi/v1.json` or
  `/swagger/v1/swagger.json` document.
- Read [stable identity and idempotency](references/stable-identity-and-idempotency.md)
  before resolving partner workflows or implementing retry-safe launch.
- Read the shared
  [partner API migration matrix](../_candoitall-api-shared/references/partner-api-migration.md)
  when removing display-name lookup or a partner-side run-submission ledger.

## Definition And Authoring Work

- Contract discovery: `GET /api/workflows/contract`.
- Settings: `GET /api/workflows/settings`, `POST /api/workflows/settings`.
- Runtime and executor catalogs: `GET /api/workflows/runtime-backends`, `GET /api/workflows/executor-catalog`.
- Definitions: `GET /api/workflows/definitions`, stable template/external-key lookup,
  `GET /api/workflows/definitions/{workflowId}`,
  `GET /api/workflows/definitions/{workflowId}/versions/{versionId}`,
  `POST /api/workflows/definitions`, and `DELETE /api/workflows/definitions/{workflowId}`.
- Lifecycle: `POST /api/workflows/definitions/{workflowId}/publish`, `/suspend`, and `/archive`; pass `expectedVersionId` as a query parameter when coordinating concurrent edits.
- Import/export: `GET /api/workflows/definitions/{workflowId}/export`, `POST /api/workflows/definitions/import`.
- Validation: `POST /api/workflows/definitions/{workflowId}/validate` for saved definitions and `POST /api/workflows/validate` for drafts.
- LLM call components and providers: `GET /api/workflows/provider-options`, `GET /api/workflows/components`, `GET /api/workflows/components/{componentId}`, `POST /api/workflows/components`, `DELETE /api/workflows/components/{componentId}`. Reusable prompt content is canonical in `/api/prompt-gallery`; workflow components retain provider/model/runtime settings plus an immutable Gallery item/version reference and prompt snapshot.

## Runtime Work

- Test runs: `POST /api/workflows/test-runs` validates a draft or exact version or, without
  `validateOnly`, creates a real preview run that executes its nodes, including executors with
  external effects, except the nodes replaced by `previewSimulationPlan`. It has no idempotency
  key, and its result contains stored run records of your own preview run (event payloads,
  artifact storage paths, raw request and response JSON, launch origin); use it only from trusted
  authoring clients.
- Start runs: `POST /api/workflows/runs/start` or
  `POST /api/workflows/definitions/{workflowId}/runs/start`. The request waits until the run
  stops, and closing the connection cancels the run, so keep it open. Send an `Idempotency-Key`
  (1 to 256 characters). A key belongs to the caller that first used it (the bearer token
  subject, or the local operator when API authorization is disabled) in the current database
  profile: your replay returns your original run, which an earlier disconnect may have cancelled,
  and another caller's request with the same key is rejected with HTTP 409 and never replays your
  run. A failed or cancelled run is still HTTP 200; check `run.state`.
- Retry evidence: `GET /api/workflows/runs/by-idempotency-key/{key}` returns the original run
  identifier (`originalRunId`), its current state and safe hashes without exposing the raw key.
  It finds only keys recorded by the same caller; a key another caller holds reads as 404. After
  a 404 you may send the start with that key: if another caller holds it, that start is rejected
  with HTTP 409 and nothing runs.
- Observe runs: `GET /api/workflows/runs`, `GET /api/workflows/runs/page`, `GET /api/workflows/runs/{runId}`, `GET /api/workflows/runs/{runId}/detail`.
- Cancel runs: `POST /api/workflows/runs/{runId}/cancel`; branch on `outcome`
  (200 CancellationRequested, 404 NotFound, 409 AlreadyTerminal, NotActive or
  TransitionRejected, 422 BackendNotCancellable) and read the run again. The body's `run` is the
  stored run record, not the safe projection, and its `origin` is always null: the HTTP API
  withholds the launch origin because the run can belong to another caller.
- Events, checkpoints, and artifacts: `GET /api/workflows/runs/{runId}/events`, `GET /api/workflows/runs/{runId}/events/page`, `GET /api/workflows/runs/{runId}/checkpoints`, and `GET /api/workflows/runs/{runId}/artifacts`.
- Live lifecycle signals: `GET /api/workflows/events/stream` for all runs or `GET /api/workflows/runs/{runId}/events/stream` for one run.
- Artifact content: `GET /api/workflows/runs/{runId}/artifacts/{artifactId}/content`.
- Human or external input: `GET /api/workflows/runs/{runId}/pending-requests`, `POST /api/workflows/external-requests/{requestId}/response`.
- Analytics: `GET /api/workflows/analytics`; run entries are stored run records with the backend
  run identifier but without the launch origin (always null, for the same reason as cancellation),
  and `take` outside 1 to 500 is rejected with HTTP 400.

### Durable human/external responses

Read the current pending request or run-detail projection first. It supplies the request
version, safe prompt and bounded response contract; `schemaAvailable:false` means the
public schema was deliberately omitted, not that arbitrary input is accepted.

Submit `POST /api/workflows/external-requests/{requestId}/response` with one
`Idempotency-Key` header and a body containing `expectedRequestVersion` and `response`.
The response is a JSON value, not a string containing encoded JSON. Preserve the key and
same semantics after an ambiguous result; do not create a second logical response.

Read accepted-operation status at
`GET /api/workflows/external-response-operations/{operationId}`. Reading never continues an
attempt: when it stays Resuming or reports a retryable failure, resend the original submission
with the same `Idempotency-Key`.
The exact `api.workflows.respond` authority, authenticated actor, current profile and
persisted workspace scope apply. Disabling global API authentication does not create an
anonymous response actor. Responses expose allowlisted status, never raw request/response
JSON, checkpoint material, leases or authorization internals.

Completed/waiting-again/denied results use 200; active resumption uses 202. Handle
400/401/403/404/409/410/422 explicitly; 503 is retryable infrastructure failure and 500 is
a redacted terminal failure. This response boundary does not use 502.

Provider invocations retain canonical workflow ownership and server-derived caller
attribution. History metadata permission does not grant canonical content access.
Shared provider choices keep publication/model identity and capability constraints;
see [shared providers](../candoitall-api-shared-providers/SKILL.md) for direct invocation.

### Workflow SSE Contract

Use `GET /api/workflows/events/stream` for fleet-level workflow signals or
`GET /api/workflows/runs/{runId}/events/stream` for one exact run. Both emit
`workflow.run.changed` with a signal-only envelope containing `eventId`, `runId`,
`category`, `kind`, optional `nodeId`, `occurredAtUtc`, `isTerminal`, and
`needsAttention`. Message and payload JSON remain available only from the canonical
run, event, artifact, checkpoint, and pending-request query routes.

Resume with either a non-negative `Last-Event-ID` header or equivalent `after` query
parameter. If both are supplied, they must be equal. The SSE `id` is a host-local API
cursor, not the workflow `eventId` and not a durable event-store position. An invalid
or conflicting cursor returns HTTP `400` with `sse.cursor-invalid`.

When the cursor falls outside the bounded replay window or is ahead of the current
host stream, the server emits `stream.gap`. Its payload includes `reason`,
`requestedAfterSequence`, `firstAvailableSequence`, `lastAvailableSequence`, and
`resumeAfterSequence`. The connection continues from `resumeAfterSequence` and sends
any retained matching notifications, but the client must first reload canonical run
detail/events because the missing notifications cannot be reconstructed from SSE.

Workflow SSE order is publication-arrival order at this host, not canonical event-store
order. Use `eventId` and persisted workflow events when ordering or completeness
matters.

The stream is pinned to the active database profile and runtime generation. A profile
switch cancels existing subscriptions. Reconnect against the new profile and rebuild
state from durable APIs; do not reuse an SSE cursor across a profile switch or process
restart.

This implementation is intentionally limited to local/basic fan-out. Global and
run-specific subscriptions share one profile-global replay buffer and wake-up path,
and run filters are applied while reading bounded batches. It is not a claim of
token-rate or thousands-of-subscribers scalability.

## Runtime DTOs

`WorkflowRunStartApiRequest` fields:

- `workflowId`
- `versionId`
- `inputJson` (a string that contains a JSON object, not a nested JSON object)
- `requestedBackend`

The public DTO rejects additional properties (HTTP 400 from the framework, without an error
envelope). It does not accept internal process-run or assignment lineage fields; governed
process launches must originate through the process orchestration boundary that owns that
lineage.

`WorkflowRunListApiQuery` fields:

- `workflowId`
- `state`
- `backend`
- `search`
- `take`
- `pageIndex`
- `pageSize`

`WorkflowEventListApiQuery` fields:

- `pageIndex`
- `pageSize`

`WorkflowAnalyticsApiQuery` fields:

- `workflowId`
- `state`
- `backend`
- `search`
- `take`

## Operating Rules

- Validate a draft or saved definition before publishing or running it.
- Resolve integrations by template/external identity, require `Resolved`, and pin
  `runnableVersionId`; never use mutable display names as integration identity.
- Reuse an idempotency key only for the identical workflow, version choice, backend and
  canonical input. A key belongs to the caller that first used it, so `409`
  `workflows.idempotency-key-conflict` means either a changed request or a key another caller
  already holds; use a new key, and keep keys unique to your client to avoid the second case.
- Read `GET /api/workflows/contract` before building clients or smoke tests; use OpenAPI for full schema detail.
- Prefer explicit lifecycle endpoints over resubmitting a full definition only to change status.
- Use import/export envelopes for portable workflow definition movement; do not hand-copy internal persistence records.
- Search and version reusable instructions through the Prompt Gallery API. Treat the LLM call
  component endpoints as reusable model-call settings, not a second prompt library. Saving a
  component keeps its instructions in the Prompt Gallery and, as a side effect, can create a new
  prompt or a new prompt version.
- Send `expectedVersionId` (a query parameter on publish, suspend and archive; a body member on
  `POST /api/workflows/definitions`) when another agent or UI may be editing the same definition.
  A stale value is rejected with HTTP 400 `workflows.request-invalid`, not 409; read the
  definition again. Every save, import and status change stores a new `versionId`.
- For long or active runs, prefer paged run and event routes before fetching full run detail.
- Treat workflow SSE as a bounded, host-local signal stream. On `stream.gap`, query
  persisted run detail/events before trusting subsequent notifications.
- SSE omits workflow message and payload JSON. Use the existing detail, event,
  artifact, checkpoint, and pending-request routes for canonical data.
- After responding to a pending external request, read back `/runs/{runId}/detail` and `/events` to confirm the state transition.
- Treat `DurableTask` and `AzureFunctions` backends as configured capabilities; do not silently fall back to `InProcess` when a requested backend is missing.

## Executor Side-Effect Contracts

- Executor catalog entries expose `WorkflowExecutorSideEffectDescriptor`: `kind`
  (0 None, 1 WorkspaceRead, 2 WorkspaceWrite, 3 ExternalRead, 4 ExternalWrite),
  `externalMutationKind` (0 None, 1 ProcessedMarker) and `allowsIdempotentRetry`. Treat them as
  workflow governance data, not UI hints.
- Email mark-processed executors must distinguish preview from commit with `sideEffectMode`, `dryRun`, `committed`, `idempotencyRecord`, `processedMarker`, and `externalSideEffectReceipt`.
- Do not retry an external-write executor unless its `allowsIdempotentRetry` is true. Preserve `idempotencyKey` and provider-scoped key prefixes when reviewing workflow output or scheduler replay behavior.
- For governed process workflow runs, use the process orchestration API so internal
  lineage remains tied to the owning process run; do not add internal lineage properties
  to the public workflow start body.

## Validation

- Use Swagger/OpenAPI to confirm route shape before writing client code.
- Use `GET /api/workflows/contract` as the quick route and boundary check for operator automation.
- After saving, importing, or changing lifecycle status, read back the specific definition id and version id.
- After starting, cancelling, or responding to a run, read back the run detail plus events.
- For artifacts, verify the metadata and read
  `GET /api/workflows/runs/{runId}/artifacts/{artifactId}/content` when content matters; the run
  detail and artifact list never expose storage paths.

## Source Route Appendix

<!-- api-docs-skills-parity:routes:start -->

Workflows API route appendix. Generated from Minimal API registrations; refresh from
`WorkflowsApi.cs` and `WorkflowRunEventsApi.cs` when routes change.

| Method | Route |
| --- | --- |
| `GET` | `/api/workflows/analytics` |
| `GET` | `/api/workflows/components` |
| `POST` | `/api/workflows/components` |
| `GET` | `/api/workflows/components/{componentId}` |
| `DELETE` | `/api/workflows/components/{componentId}` |
| `GET` | `/api/workflows/contract` |
| `GET` | `/api/workflows/definitions` |
| `POST` | `/api/workflows/definitions` |
| `GET` | `/api/workflows/definitions/by-external-key/{externalNamespace}/{externalKey}` |
| `GET` | `/api/workflows/definitions/by-template-key/{templateKey}` |
| `POST` | `/api/workflows/definitions/import` |
| `GET` | `/api/workflows/definitions/{workflowId}` |
| `DELETE` | `/api/workflows/definitions/{workflowId}` |
| `POST` | `/api/workflows/definitions/{workflowId}/archive` |
| `GET` | `/api/workflows/definitions/{workflowId}/export` |
| `POST` | `/api/workflows/definitions/{workflowId}/publish` |
| `POST` | `/api/workflows/definitions/{workflowId}/runs/start` |
| `POST` | `/api/workflows/definitions/{workflowId}/suspend` |
| `POST` | `/api/workflows/definitions/{workflowId}/validate` |
| `GET` | `/api/workflows/definitions/{workflowId}/versions/{versionId}` |
| `GET` | `/api/workflows/events/stream` |
| `GET` | `/api/workflows/executor-catalog` |
| `POST` | `/api/workflows/external-requests/{requestId}/response` |
| `GET` | `/api/workflows/external-response-operations/{operationId}` |
| `GET` | `/api/workflows/provider-options` |
| `GET` | `/api/workflows/runs` |
| `GET` | `/api/workflows/runs/by-idempotency-key/{key}` |
| `GET` | `/api/workflows/runs/page` |
| `POST` | `/api/workflows/runs/start` |
| `GET` | `/api/workflows/runs/{runId}` |
| `GET` | `/api/workflows/runs/{runId}/artifacts` |
| `GET` | `/api/workflows/runs/{runId}/artifacts/{artifactId}/content` |
| `POST` | `/api/workflows/runs/{runId}/cancel` |
| `GET` | `/api/workflows/runs/{runId}/checkpoints` |
| `GET` | `/api/workflows/runs/{runId}/detail` |
| `GET` | `/api/workflows/runs/{runId}/events` |
| `GET` | `/api/workflows/runs/{runId}/events/page` |
| `GET` | `/api/workflows/runs/{runId}/events/stream` |
| `GET` | `/api/workflows/runs/{runId}/pending-requests` |
| `GET` | `/api/workflows/runtime-backends` |
| `GET` | `/api/workflows/settings` |
| `POST` | `/api/workflows/settings` |
| `POST` | `/api/workflows/test-runs` |
| `POST` | `/api/workflows/validate` |
<!-- api-docs-skills-parity:routes:end -->
