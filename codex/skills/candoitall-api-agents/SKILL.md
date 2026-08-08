---
name: candoitall-api-agents
description: Use when managing CanDoItAll agents, SSE activity, provider completions, attachments, approvals, execution evidence, remote imports, stable external-key provisioning, portable JSON Schema output, or recruiting through the HTTP API.
---

# CanDoItAll Agents API

Use this skill when a task needs agent catalog, provider, chat, execution, approval, or diagnostics control through the CanDoItAll web API.

## Access

- Start the CanDoItAll web app and inspect Swagger/OpenAPI at `/swagger`.
- Check `/api/access/status` before assuming bearer tokens are required.
- If JWT is active, send `Authorization: Bearer <token>`.

## Contract Source

- Use the shared
  [OpenAPI snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  for exact schemas when it matches the target source version.
- Check the snapshot's [provenance manifest](../_candoitall-api-shared/manifest.json)
  before relying on it.
- When the target host differs, use its live `/openapi/v1.json` or
  `/swagger/v1/swagger.json` document.
- Read [partner API contracts](references/partner-api-contracts.md) before remote package
  import, external-key provisioning, portable JSON Schema execution, or agent recruiting
  evidence work.
- Read the shared
  [partner API migration matrix](../_candoitall-api-shared/references/partner-api-migration.md)
  when replacing server-local imports, name-based provisioning, runtime-type output
  contracts, or partner-owned recruiting linkage.

## Catalog And Configuration

- Agents: `GET /api/agents`, `GET /api/agents/bootstrap`, `GET /api/agents/{agentId}`, `POST /api/agents`, `DELETE /api/agents/{agentId}`, clone, convert-to-template, export, legacy server-path import, and remote-safe multipart package import.
- Stable partner provisioning: GET/PUT/DELETE
  `/api/agents/by-external-key/{externalNamespace}/{key}` with ETag,
  `Idempotency-Key`, and `If-Match` handling.
- Teams: `GET /api/agents/teams`, `GET /api/agents/teams/{teamId}`, `GET /api/agents/teams/{teamId}/editor`, `POST /api/agents/teams`, `PUT /api/agents/teams/{teamId}`, `DELETE /api/agents/teams/{teamId}`, `GET /api/agents/teams/{teamId}/agents`, `POST /api/agents/teams/{teamId}/members`, and `PUT /api/agents/teams/{teamId}/members`.
- Providers: `/api/agents/providers`, `/providers/{providerId}/editor`, create/delete/test/test-chat, SSE chat completion, and Ollama modelfile routes.
- Capabilities: `/api/agents/capabilities`, `/capabilities/{capabilityId}/editor`, create/delete, per-agent capability verification, tool setup tests, MCP setup tests, and access-policy previews.
- Memory: `/api/agents/{agentId}/memory`, `POST /api/agents/memory`, and delete memory routes.

## Chat And Execution

- Chat sessions: `/api/agents/{agentId}/chat-sessions`, rename, chat workspace, `/chat`, and `/chat/stream`.
- Execution runs: blocking JSON and same-request SSE start routes at `/api/agents/execution-runs` and `/api/agents/{agentId}/execution-runs`, plus list, detail, and agent-scoped/global evidence routes.
- Approvals: global approval listing and blocking/SSE response commands under `/api/agents/execution-runs/{executionRunId}`.
- Attachments: upload a bounded image with `POST /api/agents/attachments/images`, then pass the returned `relativePath` in `attachmentPaths` or `inputAttachmentPaths`.
- Evidence: execution artifacts, checkpoints, tool receipts, execution log, runtime snapshot, and metrics routes.
- Recruiting evidence: create/read `/api/agent-recruiting/interviews`, list a
  candidate's interviews through
  `/api/agent-recruiting/candidates/{candidateAgentId}/interviews`, append typed
  attempts and human reviews, then read
  `/api/agent-recruiting/candidates/{agentId}/readiness`.

### Agent SSE And Activity Correlation

Prefer a same-request SSE command when one HTTP request can own both the command and
its live response:

- `POST /api/agents/{agentId}/chat/stream`
- `POST /api/agents/execution-runs/stream`
- `POST /api/agents/{agentId}/execution-runs/stream`
- `POST /api/agents/execution-runs/{executionRunId}/pending-approvals/stream`

These POST routes start at the beginning of their newly admitted activity operation.
They emit numbered canonical activity frames, an id-less safe
`agent.approval.required` frame when approvals remain, and an id-less
`agent.command.completed` or `agent.command.failed` frame. An id-less command frame
must not advance the canonical activity replay cursor.

For command/subscriber separation, send a caller-generated UUID as
`activityOperationId` on the corresponding blocking JSON chat, run-start, or approval
command. Start that request without waiting for its response body, then subscribe to:

`GET /api/agents/execution-operations/{operationId}/events/stream`

The operation GET returns only the canonical activity stream. A transient `404` can
mean the command has not admitted the supplied operation yet; an unknown operation
also returns `404`. Do not silently replace the operation id. Duplicate, previously
evicted, and capacity-exhausted operation admission return `409`, `410`, and `503`
respectively.

Every valid agent chat, run, or approval command, whether blocking JSON or
same-request SSE, exposes the actual operation id in the
`X-CanDoItAll-Agent-Operation-Id` response header. This is true whether the caller
supplied the id or the server generated it. A caller that needs a concurrent
cross-request subscriber must still generate the id before starting the command.

Only the operation GET supports replay. Send either a non-negative
`Last-Event-ID` header or equivalent `after` query parameter; if both are present they
must be equal. An invalid or conflicting cursor returns HTTP `400` with
`sse.cursor-invalid`. `stream.gap` reports `requestedFromInclusive` and
`availableFromInclusive`; `stream.evicted` reports that the operation partition is no
longer available. In either case, query durable execution-run detail and evidence
routes before relying on later notifications.

Agent activity retention and operation identity are bounded, host-local, and scoped
to the current database profile, profile generation, and workspace. A profile switch
cancels active readers. Reconnect against the active profile and rebuild state from
durable run APIs; do not carry an operation cursor across a profile switch or process
restart.

An activity operation id is correlation, not an idempotency key or authorization
credential. API authorization still gates every route.

This is local/basic fan-out, not a high-volume event broker. Use one external
subscriber per operation where practical, and do not route token-rate or
thousands-of-subscriber workloads through the in-process activity stream.

`POST /api/agents/providers/{providerId}/chat-completions/stream` resolves the
provider profile before starting SSE. An unknown profile returns normal HTTP `404`
with `providers.not-found` and no SSE frames. For a known profile it emits accepted,
starts the provider invocation, emits running only after that invocation starts, and
then emits completed or failed. A synchronous start failure therefore emits accepted
and failed without running. The completed event contains the full response. The
provider driver contract does not currently expose token deltas, so do not interpret
this route as token streaming. This is a same-request status stream, not a separately
resumable operation stream.

### Safe Approvals And Attachments

`agent.approval.required` contains only `approvalId`, `toolName`, `toolKind`, and
`requestedAtUtc` for each pending approval. It deliberately omits tool arguments and
persisted approval details. Read the scoped or global run approval endpoint when the
authorized client needs the canonical record.

Read the approval list immediately before posting a decision; do not assume an older SSE
summary is still complete. New clients should send `decisions` with exactly one
`approvalId`/`approved` pair for every currently pending approval. Duplicate, unknown,
missing, or stale decision sets fail with `agents.approval-decision-mismatch`. The required
legacy `approved` field remains a uniform decision only when `decisions` is absent or empty.

Upload attachments as multipart form field `file` to
`POST /api/agents/attachments/images`. The staging boundary accepts PNG, JPEG, GIF,
or WebP images up to 10 MB, requires a supplied content type to agree with the file
extension, normalizes the file name, and stores the file under the managed workspace.
Use only the returned `relativePath` in `attachmentPaths` or
`inputAttachmentPaths`; never send or persist a server absolute path.

## Operating Rules

- Prefer agent-scoped routes when you already know `agentId`; use global execution-run routes for cross-agent review.
- Use `/import-package` for remote clients; never send a server filesystem path or raw
  provider secret across environments.
- Resolve partner-managed agents by external key. Do not emulate identity with display
  names, and do not retry a changed payload under an existing idempotency key.
- For debugging, query run detail first, then fetch artifacts/checkpoints/receipts/log only for the run under review.
- Treat `activityOperationId` and `initialActivityOperationId` as correlation metadata
  only. Continue to use `executionRunId` for durable run lookups.
- SSE approval summaries omit raw tool arguments. Read the run approval endpoint when
  the full persisted approval record is required.
- Use provider test routes before assigning a provider to production-like agents.
- Use capability verification before assuming a tool or skill is assigned to an agent.
- Use setup tests for external tool and MCP capability descriptors before enabling them for agents or process roles. Use access-preview when a process, team, or role policy might deny required skill/tool/MCP capabilities.
- Provider profiles include `isPrivateProvider`, `modelPrices`, and `tags`. Provider capabilities include structured output, hosted tools, hosted/local MCP, image generation, vision, compaction, native code/file/web search, and approval support.
- For OpenAI-like Responses models beginning with `gpt-5`, `o1`, `o3`, or `o4`, temperature is omitted and `modelParameters.reasoningEffort` can be set to `none`, `low`, `medium`, `high`, or `extraHigh`.
- Use the versioned `json-schema` structured-output DTO for portable clients. Treat its
  validation status and preserved raw output as evidence; do not validate only
  `responseText`.

## Canonical Runtime Contracts

- Process-driven agent runs should use the canonical structured output contract key for process-step outcomes and preserve `processRunId`, `processStepId`, `schedulerRunId`, and `messageId` filters when reviewing execution runs.
- Provider usage is a ledger observation, not a chat estimate. The HTTP run-detail contract exposes `usageTotals`: observation counts, known/unknown usage counts, token and tool-call totals, known/unknown cost counts, and known cost. Raw internal provider-usage observation enums are not public API fields.
- Tool receipts and runtime snapshots are current-run evidence. Do not treat stale prior-run receipts, copied artifacts, or provider test-chat output as proof for a governed process step.
- When a process proof claims real automation dispatch, verify at least one execution run is bound to the claimed process run and step, has relevant tool receipts, and reports `usageTotals.observationCount > 0` when a provider response was produced. A provider test route or detached chat session proves provider health only, not process execution.

## Execution DTOs

`AgentChatApiRequest` accepts `chatSessionId`, `prompt`, `attachmentPaths`, and the
optional caller-generated `activityOperationId`.

`PendingApprovalApiRequest` accepts `approved`,
`autoApprovePendingToolCalls`, and an optional continuation
`activityOperationId`. Its optional `decisions` collection contains
`PendingApprovalDecisionApiRequest` values with `approvalId` and `approved`. A non-empty
collection takes precedence over the legacy uniform `approved` value and must match the
run's freshly read pending approval set exactly.

`AgentExecutionRunStartApiRequest` fields:

- `prompt`
- `chatSessionId`
- `context`
- `autoApprovePendingToolCalls`
- `structuredOutput`
- `inputAttachmentPaths`
- `activityOperationId`

`AgentExecutionRunApiRequest` is the global-start shape. It requires `agentId` and
`prompt`, then uses the same `chatSessionId`, `context`,
`autoApprovePendingToolCalls`, `structuredOutput`, `inputAttachmentPaths`, and
`activityOperationId` fields as the scoped request.

`AgentExecutionRunApiQuery` fields:

- `agentId`
- `chatSessionId`
- `correlationId`
- `sourceKind`
- `sourceId`
- `take`
- `processRunId`
- `processStepId`
- `schedulerRunId`
- `messageId`
- `state`
- `outcome`
- `approvalStatus`
- `createdFromUtc`
- `createdToUtc`
- `updatedFromUtc`
- `updatedToUtc`

`GET /api/agents/execution-runs/{executionRunId}` returns the transport-owned
`AgentExecutionRunDetailApiResponse`. Use its `run`, `chatSession`, `executionLog`,
`metrics`, `approvals`, `artifacts`, `checkpoints`, `toolReceipts`, and `usageTotals`
properties. Do not generate clients against removed internal persistence record schemas.

## Validation

- For created/updated agents, read back the agent editor/detail.
- For execution, verify run state, artifacts, receipts, and metrics instead of relying on a single status field.
- For provider changes, run provider health/test-chat when credentials and model availability are relevant.
- For capability changes, run tool/MCP setup tests or access-preview when the change affects executable tools, local/remote MCP servers, or role-level capability policies.

## Source Route Appendix

<!-- api-docs-skills-parity:routes:start -->

Agents API route appendix. Generated from Minimal API registrations; refresh from
`AgentsApi.cs`, `AgentEventsApi.cs`, `AgentProviderEventsApi.cs`, and
`AgentAttachmentsApi.cs` when routes change.

| Method | Route |
| --- | --- |
| `GET` | `/api/agents` |
| `POST` | `/api/agents` |
| `DELETE` | `/api/agents/{agentId:guid}` |
| `GET` | `/api/agents/{agentId:guid}` |
| `POST` | `/api/agents/{agentId:guid}/capabilities/{capabilityId:guid}/verify` |
| `POST` | `/api/agents/{agentId:guid}/clone` |
| `POST` | `/api/agents/{agentId:guid}/convert-to-template` |
| `GET` | `/api/agents/{agentId:guid}/execution-log` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs` |
| `POST` | `/api/agents/{agentId:guid}/execution-runs` |
| `POST` | `/api/agents/{agentId:guid}/execution-runs/stream` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/approvals` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/artifacts` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/checkpoints` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/log` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/metrics` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/tool-receipts` |
| `GET` | `/api/agents/{agentId:guid}/export` |
| `POST` | `/api/agents/{agentId:guid}/chat` |
| `POST` | `/api/agents/{agentId:guid}/chat/stream` |
| `GET` | `/api/agents/{agentId:guid}/chat-sessions` |
| `POST` | `/api/agents/{agentId:guid}/chat-sessions` |
| `POST` | `/api/agents/{agentId:guid}/chat-sessions/{chatSessionId:guid}/rename` |
| `GET` | `/api/agents/{agentId:guid}/chat-workspace` |
| `GET` | `/api/agents/{agentId:guid}/memory` |
| `GET` | `/api/agents/{agentId:guid}/metrics` |
| `GET` | `/api/agents/{agentId:guid}/runtime-snapshot` |
| `GET` | `/api/agents/bootstrap` |
| `GET` | `/api/agents/by-external-key/{externalNamespace}/{key}` |
| `PUT` | `/api/agents/by-external-key/{externalNamespace}/{key}` |
| `DELETE` | `/api/agents/by-external-key/{externalNamespace}/{key}` |
| `GET` | `/api/agents/capabilities` |
| `POST` | `/api/agents/capabilities` |
| `DELETE` | `/api/agents/capabilities/{capabilityId:guid}` |
| `GET` | `/api/agents/capabilities/{capabilityId:guid}/editor` |
| `POST` | `/api/agents/capabilities/access-preview` |
| `POST` | `/api/agents/capabilities/setup-tests/mcp` |
| `POST` | `/api/agents/capabilities/setup-tests/tool` |
| `POST` | `/api/agents/attachments/images` |
| `GET` | `/api/agents/execution-operations/{operationId:guid}/events/stream` |
| `GET` | `/api/agents/execution-runs` |
| `POST` | `/api/agents/execution-runs` |
| `POST` | `/api/agents/execution-runs/stream` |
| `GET` | `/api/agents/execution-runs/{executionRunId:guid}` |
| `GET` | `/api/agents/execution-runs/{executionRunId:guid}/approvals` |
| `GET` | `/api/agents/execution-runs/{executionRunId:guid}/artifacts` |
| `GET` | `/api/agents/execution-runs/{executionRunId:guid}/checkpoints` |
| `POST` | `/api/agents/execution-runs/{executionRunId:guid}/pending-approvals` |
| `POST` | `/api/agents/execution-runs/{executionRunId:guid}/pending-approvals/stream` |
| `GET` | `/api/agents/execution-runs/{executionRunId:guid}/tool-receipts` |
| `POST` | `/api/agents/import` |
| `POST` | `/api/agents/import-package` |
| `POST` | `/api/agents/memory` |
| `DELETE` | `/api/agents/memory/{memoryId:guid}` |
| `GET` | `/api/agents/providers` |
| `POST` | `/api/agents/providers` |
| `DELETE` | `/api/agents/providers/{providerId:guid}` |
| `POST` | `/api/agents/providers/{providerId:guid}/chat-completions/stream` |
| `GET` | `/api/agents/providers/{providerId:guid}/editor` |
| `POST` | `/api/agents/providers/{providerId:guid}/ollama-modelfile` |
| `POST` | `/api/agents/providers/{providerId:guid}/test` |
| `POST` | `/api/agents/providers/{providerId:guid}/test-chat` |
| `GET` | `/api/agents/teams` |
| `POST` | `/api/agents/teams` |
| `DELETE` | `/api/agents/teams/{teamId:guid}` |
| `GET` | `/api/agents/teams/{teamId:guid}` |
| `PUT` | `/api/agents/teams/{teamId:guid}` |
| `GET` | `/api/agents/teams/{teamId:guid}/agents` |
| `GET` | `/api/agents/teams/{teamId:guid}/editor` |
| `POST` | `/api/agents/teams/{teamId:guid}/members` |
| `PUT` | `/api/agents/teams/{teamId:guid}/members` |

<!-- api-docs-skills-parity:routes:end -->

## Agent Recruiting Route Appendix

<!-- api-docs-skills-parity:agent-recruiting-routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/agent-recruiting/candidates/{candidateAgentId:guid}/interviews` |
| `GET` | `/api/agent-recruiting/candidates/{agentId:guid}/readiness` |
| `POST` | `/api/agent-recruiting/interviews` |
| `GET` | `/api/agent-recruiting/interviews/{interviewId:guid}` |
| `POST` | `/api/agent-recruiting/interviews/{interviewId:guid}/attempts` |
| `POST` | `/api/agent-recruiting/interviews/{interviewId:guid}/reviews` |

<!-- api-docs-skills-parity:agent-recruiting-routes:end -->
