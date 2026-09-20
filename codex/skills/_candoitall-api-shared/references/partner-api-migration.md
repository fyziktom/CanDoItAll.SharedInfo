# Partner API Migration Matrix

Use this matrix when upgrading a partner adapter from the contract captured before
CanDoItAll commit `75ea79252a3c3d442e7a404f619f167c4b3edfcf`. Confirm every route
and schema against the target host's live OpenAPI document before changing production
traffic.

| Superseded integration behavior | Current contract | Required migration |
| --- | --- | --- |
| Send a server-local `packagePath` to `POST /api/agents/import` | `POST /api/agents/import-package` accepts a bounded multipart ZIP | Upload `package`, send import mode and stable external identity, require `Idempotency-Key`, and verify the receipt hashes and prerequisites |
| List agents and reject or select by display name | `GET`, `PUT`, and `DELETE /api/agents/by-external-key/{externalNamespace}/{key}` | Assign a workspace-local namespace/key, retain `ETag`, send `If-Match` on updates/archive, and use a distinct idempotency key per logical mutation |
| Pass runtime `.NET Type` metadata or request JSON only through prompt text | Agent execution accepts `AgentJsonSchemaOutputContract` | Send `kind: json-schema`, version, name, schema, and strictness; validate the returned status, canonical schema hash, parsed data, and raw output |
| Enumerate workflows and match an exact display name | Stable template/external-key lookup endpoints return `WorkflowStableIdentityResolution` | Require `status: Resolved`, persist `workflowId`, and pin `runnableVersionId`; fail closed for `NotFound`, `Ambiguous`, or `Stale` |
| Use a partner ledger as the only workflow retry guard | Both workflow start routes accept `Idempotency-Key` and expose lookup evidence | Reuse one key only for the identical workflow/version/backend/canonical input; treat changed-content `409` as terminal and query `/runs/by-idempotency-key/{key}` after an uncertain response |
| Store all AI-agent evaluation lineage only in a partner scorecard or CRM-HR feedback | `/api/agent-recruiting` owns typed interviews, attempts, reviews, comparison, and readiness | Create an interview for the exact candidate configuration, append typed terminal-run evidence and a human review, then read readiness; keep CRM-HR people/applications separate |
| Infer response or error bodies from prose | OpenAPI publishes typed success and `ApiErrorResponse` schemas | Regenerate the client, preserve `errors[].code`, and add negative tests for `400`, `401`, `403`, `404`, `409`, and `412` as applicable |

## Additive Delta (commit 160616c8, modules-decoupling)

The 2026-09-15 snapshot (289 paths, 321 operations, 518 schemas) removed or renamed
nothing relative to the 2026-08-31 snapshot (commit aadd9531). Adapters built against
the older contract keep working; the rows below are opportunities, not required
migrations.

| Superseded integration behavior | Current contract | Optional migration |
| --- | --- | --- |
| Re-launch a process when the launch response was lost | `GET /api/processes/launch/{admissionId}` returns the prepared-launch status | Persist the admission id from the launch routes and poll it instead of launching again |
| Re-run a retained agent run after a host restart or a cancelled tool call | `POST /api/agents/execution-runs/{executionRunId}/recover` and `POST /api/agents/execution-runs/{executionRunId}/reconcile-cancellation` | Recover the same run under current authority; treat a recovery denial as terminal rather than retrying with a new run, and read the typed cancellation reconciliation instead of inferring committed effects |
| Repeat a provider create/update/delete after an uncertain response | `POST /api/agents/providers/mutations/verify` | Verify the earlier mutation attempt by its identity before repeating it |
| Inspect storage placement recovery only through host logs | `/api/storage-placement-recovery` (context, pending intents, owner continuations, reconcile, cancelled-run receipts, external-termination verification, workflow asset continuation) | Read pending intents and continuations through the typed family; the reconcile routes are owner-scoped operator actions, not partner automation |
| Send Project Structure task and node inputs from the August schemas | `ProjectStructureTaskCreateRequest`, task/node update requests and `ProjectStructureNodeSummary` gained execution-state, expected-cost and deletion-disposition fields; `ProcessLaunchApiRequest`, `WorkflowRunStartApiResponse` and the provider editor models also grew | Regenerate the typed client; the added fields are optional on input and additive on output, so older clients keep working but do not observe the recorded execution state or the cost snapshot |

## Required Migration: Project Structure Task Update (commit d0f3c41a and later)

`PUT /api/project-structure/projects/{projectId}/tasks/{taskId}` (operation of the Project
Structure family; the agent task update tool takes the same input with its own admission) now
binds `ProjectStructureTaskUpdateAgentInput`. The 2026-09-15 snapshot published
`ProjectStructureTaskDetailsUpdateRequest` for this route, whose task identifiers were
`{ "value": "<node id>" }` wrapper objects. The wrapper shape is not accepted: the framework rejects
it with HTTP 400 before the operation runs, without the Project Structure error envelope, and
nothing is written (product test
`ProjectStructureTaskUpdateRawJsonTests.The_superseded_identifier_wrapper_is_rejected_without_changing_the_task`).
No compatibility path exists; migrate the body.

| Superseded integration behavior | Current contract | Required migration |
| --- | --- | --- |
| Send `taskId`, `scheduleChange.taskId`, `scheduleChange.affectedTasks[].taskId` and `scheduleChange.criticalTaskIds[]` as `{ "value": "<node id>" }` objects (`GanttTaskScheduleChangeRequest`, `GanttTaskDateChange`) | Every task identifier is a plain JSON string equal to `nodes[].id` from the structure read. `scheduleChange` is `ProjectStructureTaskScheduleAgentChange` (`gesture`, `affectedTasks[]` of `ProjectStructureTaskDateAgentChange`, `criticalTaskIds`) and has no task identifier of its own | Send the node identifier string in the route and in `taskId` (compared ordinally; a difference is HTTP 400 `TaskRouteMismatch`) and in every affected-task entry |
| Build the current values from a cached copy or from the values you intend to write | Every `current*` member is an edit precondition checked against the stored task: HTTP 409 `ConcurrencyConflict` (estimate, execution state, cost basis or direct-assignment revision) or `StaleTask` (title, progress or previous interval) | Read first: call `POST .../structure/read` with `{ "includeMetadata": true }`, take title, progress, start and end from the task node and the estimate, execution, cost basis and direct-assignment revision from `workItem` in its `metadataJson` string; send unchanged current values and change only proposed values |
| Omit `currentCostBasis` or `expectedProjectAdmission` | `currentCostBasis` must be present (send `null` when the read returned none); a missing member is rejected with HTTP 400 without an envelope. `expectedProjectAdmission` is required by the route: missing or for another project is HTTP 409 `ProjectLifetimeRefreshRequired` | Copy `expectedProjectAdmission` unchanged from the same structure read; never construct one |
| Send enum tokens copied from `metadataJson` (`"manDays"`, `"notStarted"`) | The request expects JSON integers (`expectedEffortUnit` 0 Hours, 1 ManDays; execution `state` 0 Unknown to 4 Cancelled; cost-basis `resourceKind` and `source` integers) | Map the camel-case tokens of the read to the integers listed on each enum schema |
| Retry a 409 by refreshing only the preconditions | A 409 means the task, its assignments or the project changed after the read | Read again, decide whether the intended change still applies, then send a new body |

Runnable reference: `candoitall-api-project-structure/scripts/update-task.mjs` (Node.js 18+)
performs this read-modify-write with literal JSON against a synthetic project.

## Metadata Delta (documented contract, 2026-09-19)

Routes, methods, operation ids and runtime behavior are unchanged. The document now declares
what the handlers already return, so regenerated clients change shape:

| Superseded integration behavior | Current contract | Optional migration |
| --- | --- | --- |
| Treat most operations as returning an untyped `200` | 425 statuses and 187 response bodies are declared with their real types and error envelopes (`errors` array, Project Structure `error` object, Problem Details) | Regenerate the typed client and branch on the documented error codes |
| Group generated operations under one `CanDoItAll.Web` tag | 77 operations moved to their family tag (for example `Project Structure`, `Development diagnostics`, `Runtime`, `Files`) | Update client grouping or code generation settings that rely on tags |
| Parse LLM Chat errors as `application/json` | LLM Chat errors are declared as `application/problem+json`, as the host always sent them | Accept the problem media type in generated clients |
| Handle a declared status that never occurred | 13 unreachable declarations were removed, including recruiting review 409 (a review conflict currently fails with HTTP 500), LLM send-turn 504 (deadline failures are recorded on the asynchronous operation) and memory operation status 502/504 | Remove dead branches; keep generic 5xx handling |
| Read enum values from the schema list | Integer enums carry no value list; every enum schema and enum-typed member describes its values in text | Map values from the descriptions or the live document |

## Security Delta (commit b82ffc57, 2026-09-19)

These changes are included in the current snapshot. That security release preserved
routes, methods and operation identifiers and added the runtime routes' 401 declarations.

| Superseded integration behavior | Current contract | Required migration |
| --- | --- | --- |
| Share one `Idempotency-Key` between callers of a host, or read a start made by another caller with `GET /api/workflows/runs/by-idempotency-key/{key}` | A key belongs to the caller that first used it: the bearer token subject, or the local operator when authorization is disabled, under the current database profile's authorization scope | Use keys per caller. A key another caller holds returns `409 workflows.idempotency-key-conflict` on start and `404` on the lookup; a start never replays another caller's run |
| Read `run.origin` (the launch origin, with the launching caller's identity and authority) from `POST /api/workflows/runs/{runId}/cancel` or `GET /api/workflows/analytics` | Both withhold the launch origin: `origin` is always null. `POST /api/workflows/test-runs` still returns the origin of the caller's own preview run | Remove any dependency on `origin` from the cancellation and analytics responses; correlate runs by `runId` |
| Poll `GET /api/runtime/capabilities` or `GET /api/runtime/operations` without a token on a host with `Api:Authorization:Enabled` | Both require a bearer token issued by that host, like the rest of `/api`; without one they answer `401 api.authorization-required`. With authorization disabled they stay open | Send the bearer token, or use the anonymous `GET /health` for liveness |
| Send an agent run `context` that claims a process step (source kind `process-step`, `processRunId` or `processStepId`), or `metadataJson` carrying `agentExternalTargetRootBindings` | Every HTTP run start (`/api/agents/execution-runs`, `/api/agents/{agentId}/execution-runs` and their `/stream` variants) rejects both before any run with `400 agents.request-invalid` | Drop those context members. Process automation sets them in process; external folders are granted only in the agent's saved workspace tool settings |
| Read other callers' recorded request and response bodies from `POST /api/project-structure/analytics/query` | Bodies, warnings, internal error message and repository root are returned only for the caller's own calls; other callers' entries carry `{}`, `[]`, null and an empty string | Use the log for your own call evidence; read owner state through the structure read |
| Send an OAuth `returnPath` such as `/\host`, `//host` or one containing control characters to `POST /api/plugins/{pluginId}/oauth/start` | A return path must start with a single `/` that is not followed by `/` or `\` and must contain no control characters; any other value is replaced by `/plugins` | Send a plain relative path of this host, for example `/plugins?connection=gmail` |

## API Access Delta (commits 6aa1aa0dd and 32d296a92, 2026-09-20)

Read [authentication and capabilities](access-and-authentication.md) for the exposure
matrix, session lifecycle and scope map. Regenerate clients from the refreshed snapshot;
login and management routes appear only when their independent settings are enabled.

| Superseded integration behavior | Current contract | Required migration |
| --- | --- | --- |
| Issue HTTP tokens with broad `api` or `api.tokens.issue` | HTTP account/token management requires a registered configured-administrator session and enabled management | Log in as the configured administrator when administration was requested; use ordinary scoped credentials for business work |
| Treat any signed JWT as sufficient for Projects, Agents, Workflows, Processes, CRM/HR, Prompts, Plugins or runtime | Section read/write/execute policies apply; existing exact policies still apply | Select the required catalog capabilities independently; do not broaden grants after a 403 |
| Keep using an account token after editing its profile, grants, password or enabled state | Existing sessions become invalid at the next validation; active streams also revalidate | Log in again under current permissions; re-enabling never revives a session |
| Authenticate the OpenAPI document before Swagger can show Authorize | Documents and UI load anonymously when enabled; protected operations retain bearer requirements | Use HTTPS Swagger, paste a raw JWT into Authorize, and keep documentation exposure settings explicit |
| Scrape process definitions, roles or steps from UI/internal storage | Four read operations expose current catalog/editor projections under `/api/processes/definitions` | Select returned opaque definition keys; keep definition discovery separate from durable run evidence |
| Reimplement Settings' workflow-template creation | `GET /api/workflows/templates` and `POST /api/workflows/templates/{templateKey}/drafts` use the canonical application owner | Grant workflow read/write as needed, satisfy provider/model prerequisites and reconcile uncertain creation before retrying |
| Treat a successful settings write with failed read-back as a failed mutation | Workspace `PUT` can return success with `X-CanDoItAll-Read-Back: pending` and the saved snapshot | Refresh with `GET /api/settings/workspace`; do not repeat the committed write |
| Parse framework/API failures as HTML or suppress service faults with empty data | API transport failures return safe JSON with explicit status; domain envelopes remain distinct | Branch on status and the operation's documented JSON envelope; preserve 500/503 failures |

## Upgrade Gate

Before removing a workaround:

1. Pin the target host commit and OpenAPI SHA-256.
2. Regenerate the typed client and run contract tests.
3. Migrate one stable partner identity in an isolated workspace.
4. Exercise an identical replay and a changed-content conflict.
5. Capture raw provisioning response headers and verify ETag plus missing/stale
   header behavior; the current OpenAPI does not fully model those runtime requirements.
6. Read back the canonical resource, run, or recruiting evidence.
7. Verify a denied authorization or invalid-reference case.
8. Remove the old name/path/ledger fallback so the adapter fails closed instead of
   silently switching identity models.

Do not migrate the four durable process snapshot routes from the historical
`processes-snapshots` branch. They are absent from this contract unless a target host's
live OpenAPI document explicitly publishes them.
