---
name: candoitall-api-project-structure
description: Use when creating, reading, editing, running, or reviewing CanDoItAll projects and project-structure nodes through the HTTP API instead of the removed ProjectStructure MCP server.
---

# CanDoItAll Project Structure API

Use this skill when a task needs project, hierarchy, project-structure, dependency, asset, lease, or control of process and workflow runs started from project nodes through the CanDoItAll web API.

## Access

- Start the CanDoItAll web app and use Swagger/OpenAPI from the running host, usually `http://localhost:5032/swagger` or `https://localhost:7271/swagger`.
- Use `/api/access/status` to check whether API authorization is enabled.
- When API authorization is enabled, create a token from Settings -> API Access, or with
  `POST /api/access/tokens` using a token that has the exact `api.tokens.issue` scope, then send
  `Authorization: Bearer <token>`. Every `/api/project-structure` operation, including reads,
  needs the `api` or `api.project-structure.write` scope; `/api/projects` accepts any valid token.
- Do not reinstall or use `candoitall_projectstructure`; that MCP server has been removed.

## Contract Source

- Use the shared
  [OpenAPI snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  for exact schemas when it matches the target source version.
- Check the snapshot's [provenance manifest](../_candoitall-api-shared/manifest.json)
  before relying on it.
- When the target host differs, use its live `/openapi/v1.json` or
  `/swagger/v1/swagger.json` document.

## Primary Routes

- Project records: `GET /api/projects`, `POST /api/projects`, `GET /api/projects/access-list`, `GET /api/projects/hierarchy-links`, `GET /api/projects/{projectId}`, `DELETE /api/projects/{projectId}`, `GET /api/projects/{projectId}/hierarchy`, `POST /api/projects/{parentProjectId}/subprojects/{childProjectId}`, `DELETE /api/projects/{parentProjectId}/subprojects/{childProjectId}`, and `POST /api/projects/{childProjectId}/reconnect-subproject`.
- Project hierarchy: `/api/projects/{projectId}/hierarchy`.
- Planning and tasks: `/api/project-structure/projects/{projectId}/plan/summary`,
  `/tasks`, `/tasks/{taskId}`, and `/tasks/{taskId}/resource`.
- Project structure read and focused mutations: `/api/project-structure/projects/{projectId}/structure/read`, `/nodes`, `/nodes/copy`, `/nodes/{nodeId}`, `/nodes/{nodeId}/type`, `/nodes/{nodeId}/metadata`, `/nodes/statuses`, `/nodes/{nodeId}/status`, `/nodes/progress`, `/nodes/{nodeId}/progress`, `/nodes/markers`, `/nodes/{nodeId}/markers`, `/nodes/priorities`, `/nodes/{nodeId}/priority`, `/nodes/move`, `/nodes/recompose`, `/nodes/{nodeId}/reparent`, `/nodes/reparent`, `/nodes/move-to-new-subproject`, `/nodes/{nodeId}/move-descendants-to-project`, `/nodes/{nodeId}/command`, `/nodes/{nodeId}/delete`, and `/nodes/delete`.
- Dependency and link control: `/links`, `/links/unlink`, `/dependencies/link`, `/dependencies/unlink`, `/dependencies/query`.
- Assets: `/assets`, `/assets/{nodeId}`, `/assets/{nodeId}/content`, `/assets/{nodeId}/revisions`.
- Process nodes: `/nodes/{nodeId}/process-definition` and `/nodes/{nodeId}/process/start`.
- Workflow nodes: `/nodes/{nodeId}/workflow-add-options`, `/nodes/{nodeId}/workflow-definition`, `/nodes/{nodeId}/workflow/start`, `/nodes/{nodeId}/workflow/status`.
- Coordination and review: `/approvals/request`, `/checklists/query`, `/leases/acquire`, `/leases/renew`, `/leases/current`, `/leases/release`, `/knowledge/query`, `/analytics/query`.
- Deletion recovery: global pending cleanup and completion-notice lists under
  `/api/projects`, retry by project/participant/recovery id, plus project-scoped readback
  under `/api/project-structure/projects/{projectId}/deletion-cleanups` and
  `/deletion-completion-notices`. Finish a pending node cleanup by calling
  `/nodes/{rootNodeId}/delete` again with its `durableMutationId` and the same
  `managedStorageDisposition`.

## Direct Tool Boundary

The internal project-structure runtime tool surface is exposed through `ProjectStructureAgentRuntimeToolProvider`; the tools an invocation receives depend on its project access. It broadly mirrors the 58-path, 59-operation `/api/project-structure` HTTP surface and adds the repo-branch lease helper `project_structure_repo_branch_lease_acquire`, which is a runtime tool and not an HTTP route. Direct runtime tools include node create (`project_structure_node_create`), single and batch node delete (`project_structure_node_delete`, `project_structure_nodes_delete`), focused node updates, generic links, asset create/content (`project_structure_asset_create`, `project_structure_asset_content_get`), lease renew, process/workflow node operations, and read/write/import/lease tools. These tools are classified by `AgentToolInvocationPolicy`; destructive and mutating tools still require project-structure write access and the normal approval path.

A runtime tool that is missing or denied in an agent invocation is not an instruction to use the HTTP API instead. Report the missing or denied tool name as a runtime or authorization issue. An operator or a separately authorized client may call the HTTP routes with its own bearer token and scopes, but HTTP authority is not an agent capability grant and never extends a tool the runtime denied. Do not reinstall or infer a removed ProjectStructure MCP server.

### Structure Read Source

`ProjectStructureReadRequest.source` is shared with the internal
`project_structure_read` runtime tool, but the two transports have different
eligible sources:

- For `POST /api/project-structure/projects/{projectId}/structure/read`,
  `ContextDefault` is normalized to `CanonicalCurrent`, and
  `CanonicalCurrent` reads the canonical application service.
- `InvocationSnapshot` is bound to an active in-process agent invocation and is not
  available through HTTP. The route fails closed with HTTP 400 and
  `ProjectStructureReadSourceUnavailable`; it never silently substitutes a database
  read.
- An undefined source value fails with HTTP 400 and
  `ProjectStructureReadSourceInvalid`.
- The internal runtime tool may use `InvocationSnapshot` only when the invocation
  carries an eligible, fresh, covered Project Structure snapshot. Its tool response
  reports the effective source. There is no silent snapshot-to-canonical fallback.

HTTP clients should send `CanonicalCurrent` explicitly when they want to make the
data source unambiguous. In HTTP request bodies `source` is a JSON integer:
`ContextDefault` is `0`, `InvocationSnapshot` `1` and `CanonicalCurrent` `2`.

## Canonical Tasks

Tasks created with `POST /api/project-structure/projects/{projectId}/tasks` are canonical
tasks. The generic node routes reject them; change a task only through the task routes.
The task routes take the project write admission from a structure read; they take no
lease token.

- **Create:** read the structure, send its `expectedProjectAdmission` with the create body,
  and keep the returned `taskNodeId`. Creation is not idempotent: after an unclear failure read
  the structure before retrying.
- **Update** (`PUT /api/project-structure/projects/{projectId}/tasks/{taskId}`) is a
  read-modify-write:
  1. Call `POST .../structure/read` with `{ "includeMetadata": true }` and keep
     `expectedProjectAdmission`.
  2. From the task node copy `id`, `title`, `progressPercent`, `startUtc` and `endUtc`.
     Parse its `metadataJson` string and take, under `workItem`, `expectedEffortHours`,
     `expectedEffortUnit`, `expectedCostAmount`, `expectedCostCurrencyCode`,
     `executionState`, `actualStartedAtUtc`, `actualEndedAtUtc`, `expectedCostBasis` and
     `directAssignmentRevision`. A missing member is null; a missing revision is 0.
  3. `metadataJson` writes enums as camel-case text, but the update body expects JSON
     integers. Execution state: `unknown` 0, `notStarted` 1, `started` 2, `completed` 3,
     `cancelled` 4. Effort unit: `hours` 0, `manDays` 1. Resource kind: `person` 0,
     `agent` 1, `workflow` 2, `process` 3. Cost source: `unknown` 0, `crmWorkforceRate` 1,
     `agentRunHistory` 2, `workflowRunHistory` 3, `processRunHistory` 4. Schedule gesture:
     `Move` 0, `ResizeStart` 1, `ResizeEnd` 2, `SetInterval` 3.
  4. Send `taskId` as the same plain string as the route, never as an object with a `value`
     member. Copy every `current*` member unchanged from the read and set each
     `proposed*` member to its current value except what you change. The exception is
     progress: `proposedProgressPercent` accepts only 0 through 100, so every update of an
     untracked task (current -1) starts tracking its progress; send 0 or the value you want. Keep
     `scheduleChange` null unless you move the task, and `assigneeChanged` false unless
     you set (`proposedAssignee` object) or clear (`proposedAssignee` null) the direct
     person or agent assignee. Always send `currentCostBasis`, as null when the read had
     none, and the read's `expectedProjectAdmission`.
  5. Read the structure again. The success body only lists the changed tasks, each as an
     object whose `value` is the task's node id.
- **Values:** `expectedEffortHours` stays in hours even when the unit is man-days.
  Current progress accepts -1 (untracked) or 0 through 100; proposed progress only 0
  through 100. A cost amount needs a currency that normalizes to three letters.
- **Failures** use the Project Structure `error` envelope. HTTP 409 `StaleTask`,
  `ConcurrencyConflict`, `AssignmentConflict`, `ProjectStructureConcurrentMutation` or
  `ProjectLifetimeRefreshRequired`: read again and reapply the intended change
  deliberately; never resend the old body with refreshed preconditions only. HTTP 400 codes
  (for example `TaskRouteMismatch`, `TaskUpdateRequestInvalid`, `InvalidRequest`,
  `InvalidSchedule`): fix the request. HTTP 404 (`WorkItemNotFound`, `TaskNotFound` or
  `ProjectNotFound`): the task or project is not there. HTTP 500
  `AssignmentCompensationFailed`: read the project before another change. Branch on
  `error.errorCode`; the live document lists every code. A body the framework
  cannot bind (malformed JSON, text for an integer enum, or a missing `currentCostBasis`)
  gets HTTP 400 without an envelope.
- **Resources:** attach a workflow (at its exact version) or process definition with
  `POST .../tasks/{taskId}/resource`, not as a direct assignee; send the task's execution state
  from `metadataJson` as `currentExecution` and the read's `expectedProjectAdmission`. HTTP 409
  `TaskResourceAttachmentPricingConflict` means the attachment was rolled back.
- **Runnable example:** [`scripts/update-task.mjs`](scripts/update-task.mjs) performs this
  read-modify-write with plain JSON (Node.js 18 or later). `--demo` first creates a
  synthetic project and task; set `CANDOITALL_API_TOKEN` when the host requires a bearer
  token.

## Operating Rules

- Prefer focused endpoints over fetching or sending entire graphs.
- Use `CanonicalCurrent` for HTTP structure reads. Do not request
  `InvocationSnapshot` outside the internal agent runtime.
- Generic structure mutations take an optional `leaseToken`: acquire a project lease with
  `POST /api/project-structure/leases/acquire` when you make several related changes or
  coordinate with other writers, and release it when done. Without a token each mutation takes a
  short project lease itself and fails with HTTP 409 `LeaseConflict` while another identity holds
  one. The task routes take no token; task creation and resource attachment can fail the same
  way. A lease is neither an authorization nor a project write admission: task writes and node
  deletions also need the `expectedProjectAdmission` from the latest structure read. Project-node
  and repo-branch leases only coordinate callers that check them.
- Copy nodes with `sourceNodeIds`, `destinationParentNodeId`, and the applicable lease token; read back the copied subtree rather than assuming source ids were reused.
- Preserve current-run lineage in nodes and assets that mirror process evidence: process run id, step run id, execution run id, workflow run id, source artifact path, source content hash, route/viewport for screenshots, and storage receipt ids when present.
- For typed project blocks, keep `objectType` as `ProjectBlock` and use lowercase `objectSubtype` values such as `feature`, `architecture`, `implementation`, `testing`, `delivery`, `research`, `risk`, `deployment`, `operations`, `repos`, or `dockers`.
- Mermaid diagrams are `File` asset nodes with `objectSubtype` `mermaid`: create them with
  `POST /api/project-structure/projects/{projectId}/assets`, with the Mermaid source as the asset
  content, never in notes. Generic node creation rejects File nodes and `mermaid` subtypes
  (HTTP 400 `ManagedAssetCreationRequired`); store changed content as a revision with
  `/assets/{nodeId}/revisions`, which adds a new asset node linked to the original.
- Other generated files are also `File` nodes with an appropriate subtype, created through the
  asset route, not invented project block enum names.
- Write approval blockers into the graph with `/approvals/request` instead of leaving them only in chat.
- Deleting projected `process-run:*` nodes hides the process-run branch from that project structure; it does not delete the backing process history.
- Project deletion can return `409 projects.delete-cleanup-pending` after the project commit when participant cleanup remains. List pending cleanup, honor `canRetryNow` and `retryAvailableAtUtc`, retry only the exact participant/recovery id, and retain completion warnings as operator evidence.
- `PUT /api/project-structure/projects/{projectId}` replaces every project value (an omitted
  `status` becomes Draft, an omitted `targetDateUtc` is cleared) and removes the project's phases
  and option selections, which the request cannot carry; read the project first and use it only
  when that loss is intended.
- After mutations, read back only the affected nodes or links with the structure read
  (`nodeIds`, `includeLinks`). `POST /api/project-structure/analytics/query` is a log of every
  caller's recent calls, not proof of stored state. Over HTTP it returns the recorded request and
  response bodies, warnings, error message and repository root only for your own calls, the same
  bearer token subject (or `local-api-operator` without authorization); entries of other callers
  and of in-process agent tools come back with `{}` bodies, `[]` warnings, a null error message
  and an empty repository root. Your own bodies can contain notes, file content and lease tokens:
  treat the response as sensitive.
- Start a node workflow with a new `intentId` per launch and repeat the same `intentId` to retry;
  `/process/start` has no idempotency key, so look for the run before retrying. Use
  `/nodes/{nodeId}/workflow/status` after starting node-linked workflows. Do not infer workflow
  completion from process or project node state alone.
- Use `/assets/{nodeId}/content` when the actual file bytes matter; metadata alone is not content proof.

## Validation

- Use Swagger to confirm the route shape before writing client code.
- For node mutations, read back the specific node id and relevant links/dependencies.
- For assets, verify both metadata and `/content` when content matters.

## Source Route Appendix

<!-- api-docs-skills-parity:routes:start -->

Project Structure routes mirrored by the shared OpenAPI snapshot.

| Method | Route |
| --- | --- |
| `POST` | `/api/project-structure/analytics/query` |
| `POST` | `/api/project-structure/imports` |
| `POST` | `/api/project-structure/knowledge/query` |
| `POST` | `/api/project-structure/leases/acquire` |
| `GET` | `/api/project-structure/leases/current` |
| `POST` | `/api/project-structure/leases/release` |
| `POST` | `/api/project-structure/leases/renew` |
| `GET` | `/api/project-structure/node-catalog` |
| `GET` | `/api/project-structure/projects` |
| `POST` | `/api/project-structure/projects` |
| `POST` | `/api/project-structure/projects/{parentProjectId}/subprojects` |
| `PUT` | `/api/project-structure/projects/{projectId}` |
| `POST` | `/api/project-structure/projects/{projectId}/approvals/request` |
| `POST` | `/api/project-structure/projects/{projectId}/assets` |
| `GET` | `/api/project-structure/projects/{projectId}/assets/{nodeId}` |
| `GET` | `/api/project-structure/projects/{projectId}/assets/{nodeId}/content` |
| `POST` | `/api/project-structure/projects/{projectId}/assets/{nodeId}/revisions` |
| `POST` | `/api/project-structure/projects/{projectId}/checklists/query` |
| `GET` | `/api/project-structure/projects/{projectId}/deletion-cleanups` |
| `GET` | `/api/project-structure/projects/{projectId}/deletion-completion-notices` |
| `POST` | `/api/project-structure/projects/{projectId}/dependencies/link` |
| `POST` | `/api/project-structure/projects/{projectId}/dependencies/query` |
| `POST` | `/api/project-structure/projects/{projectId}/dependencies/unlink` |
| `GET` | `/api/project-structure/projects/{projectId}/hierarchy` |
| `POST` | `/api/project-structure/projects/{projectId}/links` |
| `POST` | `/api/project-structure/projects/{projectId}/links/unlink` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/copy` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/delete` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/markers` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/move` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/move-to-new-subproject` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/priorities` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/progress` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/recompose` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/reparent` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/statuses` |
| `PUT` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/command` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/delete` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/markers` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/metadata` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/move-descendants-to-project` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/priority` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/process-definition` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/process/start` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/progress` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/reparent` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/status` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/type` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/workflow-add-options` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/workflow-definition` |
| `POST` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/workflow/start` |
| `GET` | `/api/project-structure/projects/{projectId}/nodes/{nodeId}/workflow/status` |
| `POST` | `/api/project-structure/projects/{projectId}/plan/summary` |
| `POST` | `/api/project-structure/projects/{projectId}/structure/read` |
| `POST` | `/api/project-structure/projects/{projectId}/tasks` |
| `PUT` | `/api/project-structure/projects/{projectId}/tasks/{taskId}` |
| `POST` | `/api/project-structure/projects/{projectId}/tasks/{taskId}/resource` |
<!-- api-docs-skills-parity:routes:end -->

## Projects Route Appendix

<!-- api-docs-skills-parity:projects-routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/projects` |
| `POST` | `/api/projects` |
| `GET` | `/api/projects/access-list` |
| `GET` | `/api/projects/deletion-cleanups` |
| `GET` | `/api/projects/deletion-completion-notices` |
| `GET` | `/api/projects/hierarchy-links` |
| `POST` | `/api/projects/{childProjectId}/reconnect-subproject` |
| `POST` | `/api/projects/{parentProjectId}/subprojects/{childProjectId}` |
| `DELETE` | `/api/projects/{parentProjectId}/subprojects/{childProjectId}` |
| `GET` | `/api/projects/{projectId}` |
| `DELETE` | `/api/projects/{projectId}` |
| `POST` | `/api/projects/{projectId}/deletion-cleanups/{participantId}/{recoveryId}/retry` |
| `GET` | `/api/projects/{projectId}/hierarchy` |
<!-- api-docs-skills-parity:projects-routes:end -->
