---
name: candoitall-api-agents
description: Use when managing CanDoItAll agents, SSE activity, provider completions, attachments, approvals, execution evidence, remote imports, stable external-key provisioning, portable JSON Schema output, or recruiting through the HTTP API.
---

# CanDoItAll Agents API

Use this skill when a task needs agent catalog, provider, chat, execution, approval, or diagnostics control through the CanDoItAll web API.

An agent chat session under `/api/agents` is a conversation thread with one technical agent
definition; every message in it starts its own governed agent execution run. For Simple Chat
conversations under `/api/llm-chats`, use
[`candoitall-api-llm-chats`](../candoitall-api-llm-chats/SKILL.md); do not substitute one chat contract
for the other.

## Access

- Start the CanDoItAll web app and inspect Swagger/OpenAPI at `/swagger`.
- Check `/api/access/status` before assuming bearer tokens are required.
- When API authorization is enabled, send `Authorization: Bearer <token>`. Most agent routes
  accept any valid token; recovery and cancellation reconciliation need the exact `api` scope,
  and recording a recruiting human review needs `agent-recruiting.review` (see
  [partner API contracts](references/partner-api-contracts.md)).

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
- To change an agent, read `GET /api/agents/{agentId}`, change only what you intend and send the
  whole form to `POST /api/agents` with `expectedUpdatedAtUtc` unchanged: it must equal the stored
  revision exactly, otherwise nothing is saved and the response is HTTP 400 `agents.request-invalid`
  (not 409); null skips the check. Unknown identifiers on `GET /api/agents/{agentId}` and the clone,
  convert-to-template and export routes fail with a generic HTTP 500 without the error envelope;
  list the agents before retrying.
- Stable partner provisioning: GET/PUT/DELETE
  `/api/agents/by-external-key/{externalNamespace}/{key}` with ETag,
  `Idempotency-Key`, and `If-Match` handling.
- Teams: `GET /api/agents/teams`, `GET /api/agents/teams/{teamId}`, `GET /api/agents/teams/{teamId}/editor`, `POST /api/agents/teams`, `PUT /api/agents/teams/{teamId}`, `DELETE /api/agents/teams/{teamId}`, `GET /api/agents/teams/{teamId}/agents`, `POST /api/agents/teams/{teamId}/members`, and `PUT /api/agents/teams/{teamId}/members`.
- Providers: `/api/agents/providers`, `/providers/{providerId}/editor`, create/delete/test/test-chat, SSE chat completion, and Ollama modelfile routes.
- Capabilities: `/api/agents/capabilities`, `/capabilities/{capabilityId}/editor`, create/delete, per-agent capability verification, tool setup tests, MCP setup tests, and access-policy previews.
- Workspace memory notes: `/api/agents/{agentId}/memory`, `POST /api/agents/memory` and
  `DELETE /api/agents/memory/{memoryId}`. They are simple title and content records, not memory
  providers (`/api/memory-providers`), and are not injected into agent runs.

## Shared providers and request evidence

Provider/model selection can include imported shared publications. Preserve returned
profile/model identities and capability/thinking constraints; an unavailable import
must not silently select a local provider. For direct shared-provider HTTP invocation,
use [shared providers](../candoitall-api-shared-providers/SKILL.md).

Caller and managed credential attribution are derived by the server. Do not place a
forged history/caller object in a command payload. Provider history counts
application-visible attempts and freezes usage/price evidence; canonical agent execution
content remains owned by the agent run. Metadata access does not grant content access,
and `api.provider-history.*` does not imply a new general history HTTP route.

## Chat And Execution

- Chat sessions: `/api/agents/{agentId}/chat-sessions`, rename, chat workspace, `/chat`, and `/chat/stream`.
- Execution runs: blocking JSON and same-request SSE start routes at `/api/agents/execution-runs` and `/api/agents/{agentId}/execution-runs`, plus list, detail, and agent-scoped/global evidence routes.
- Approvals: the run's approval list and blocking/SSE response commands under `/api/agents/execution-runs/{executionRunId}`.
- Attachments: upload a bounded image with `POST /api/agents/attachments/images`, then pass the returned `relativePath` in `attachmentPaths` or `inputAttachmentPaths`.
- Evidence: execution artifacts, checkpoints, tool receipts, execution log, runtime snapshot, and metrics routes.
- Recovery: `POST /api/agents/execution-runs/{executionRunId}/recover` resumes a run that has a
  recoverable tool-admission journal (runs admitted by the interactive chat interface or by
  governed process steps) under current authority, and never repeats a tool call whose effect is
  uncertain. Runs started through this HTTP API have no journal and are rejected with HTTP 400
  `tool-admission.legacy-run`; other recovery rules fail with 400 `tool-admission.*` codes. The
  owner re-authorizes every saved private result before disclosure, so a run whose original read
  targets are gone stays failed. A cancelled run first needs
  `POST /api/agents/execution-runs/{executionRunId}/reconcile-cancellation`, which records from
  owner receipts which tool effects took place (`AgentCancellationReconciliationApiResponse`;
  `hasUnknownEffects` true needs manual follow-up). Both routes need the exact `api` scope when
  API authorization is enabled, and neither creates a new grant or a new run.
- Provider mutations: `POST /api/agents/providers/mutations/verify` verifies an earlier create/update/delete attempt by its mutation attempt identity (`ProviderVerificationApiResponse`) instead of repeating it after an uncertain response.
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

Every agent command runs only while its request is open: closing the connection cancels the run
(stored as failed with outcome Cancelled) without undoing completed tool calls, and the id-less
`agent.command.*` frames are not replayable. After a dropped connection, read
`GET /api/agents/execution-runs/{executionRunId}` before sending the command again. Stream data
uses camel-case enum strings (for example `waitingOnTool`) where the JSON routes write integers.

For command/subscriber separation, send a caller-generated UUID as
`activityOperationId` on the corresponding blocking JSON chat, run-start, or approval
command. Start that request and keep it open without waiting for its response body, then
subscribe to:

`GET /api/agents/execution-operations/{operationId}/events/stream`

This agent execution operation stream returns only the canonical activity events. A transient
`404` can mean the command has not admitted the supplied operation yet; an unknown operation
also returns `404`. Do not silently replace the operation id. Duplicate, previously
evicted, and capacity-exhausted operation admission return `409`, `410`, and `503`
respectively.

Every valid agent chat, run, or approval command, whether blocking JSON or
same-request SSE, exposes the actual operation id in the
`X-CanDoItAll-Agent-Operation-Id` response header. This is true whether the caller
supplied the id or the server generated it. A caller that needs a concurrent
cross-request subscriber must still generate the id before starting the command.

Only the agent execution operation stream supports replay. Send either a non-negative
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
persisted approval details. The approval list does not return the proposed tool arguments
either. Read `GET /api/agents/execution-runs/{executionRunId}/approvals` (the agent-scoped form
returns 404 for an unknown run) for each approval's `status`, `decidedAtUtc` and
`decisionSourceKind`.

Read the approval list immediately before posting a decision; do not assume an older SSE
summary is still complete. New clients should send `decisions` with exactly one
`approvalId`/`approved` pair for every currently pending approval. Duplicate, unknown,
missing, or stale decision sets fail with HTTP 400 `agents.approval-decision-mismatch` on the
JSON route; the streaming route reports them in the stream as `agent.command.failed` with
`agents.command-failed`. The required legacy `approved` field remains a uniform decision only
when `decisions` is absent or empty.

Upload attachments as multipart form field `file` to
`POST /api/agents/attachments/images`. The staging boundary accepts PNG, JPEG, GIF,
or WebP images up to 10 MiB (10,485,760 bytes), requires a supplied content type to agree with
the file extension, normalizes the file name, and stores the file under the managed workspace.
A message or run can attach at most 8 images. Use only the returned `relativePath` in
`attachmentPaths` or `inputAttachmentPaths`; never send or persist a server absolute path.

## Operating Rules

- Prefer agent-scoped routes when you already know `agentId`; use global execution-run routes for cross-agent review.
- Use `/import-package` for remote clients; never send a server filesystem path or raw
  provider secret across environments.
- Resolve partner-managed agents by external key. Do not emulate identity with display
  names, and do not retry a changed payload under an existing idempotency key.
- For debugging, query run detail first, then fetch artifacts/checkpoints/receipts/log only for the run under review.
- Treat `activityOperationId` and the `X-CanDoItAll-Agent-Operation-Id` header value as
  correlation metadata only. Continue to use `executionRunId` for durable run lookups.
- SSE approval summaries and the approval list omit tool arguments; decide from `toolName`,
  `toolKind` and the run context.
- Use provider test routes before assigning a provider to production-like agents.
- Use capability verification to check that a capability is assigned exactly once to an agent and
  to publish its proof. HTTP 200 means the proof was published, not that it passed: read the
  agent's `capabilities[].proofStatus` in `GET /api/agents`. Verification never attaches a tool to
  a run.
- Use setup tests for tool and MCP capability definitions before enabling them for agents or
  process roles; they run the configured command or connect from the server host, so test only
  definitions you trust. Use access-preview to see which candidates a capability access policy
  would allow; it evaluates only the policy you send, not what a particular run receives. Agent
  teams neither grant nor restrict capabilities.
- Provider profiles include `isPrivateProvider`, `modelPrices`, `tags`, `purpose` (Chat or
  ImageGeneration), `supportsTools` and `modelThinkingEffortCapabilities`; a profile imported from
  a shared provider source also carries `featureConstraints` (structured output, vision, native
  tools, hosted MCP, service-managed history, compaction, parallel function tools). Read the live
  `ProviderProfile` schema for the exact members.
- Set an agent's reasoning effort with the typed `thinkingEffortOverride` member of the agent form
  (a JSON integer; null uses the provider default), not by editing `configurationJson`: the save
  writes it to `modelParameters.reasoningEffort` and rejects a level that the model's
  thinking-effort capability does not allow (HTTP 400 on `POST /api/agents`, 409 on the
  external-key `PUT`). Allowed levels differ per model; read the live `AgentReasoningEffortLevel`
  schema and the provider profile's `modelThinkingEffortCapabilities`. Temperature is not sent to
  defined OpenAI reasoning models such as `gpt-5` or `o3`.
- Use the versioned `json-schema` structured-output contract for portable clients. Treat
  `structuredOutput.validationStatus`, `validationErrors` and the parsed `data` as the evidence:
  any status other than `Valid` ends the run in state 6 Failed although the response is HTTP 200.
  The run keeps the raw provider output internally and returns no `rawOutput` member; do not rely
  on `responseText` alone.

## Canonical Runtime Contracts

- Only process automation starts process-step runs and sets their output contract. In `context`,
  never send source kind `process-step`, `processRunId` or `processStepId`, which mark the run as a
  governed process run with different validation, approval and tool rules, and never send
  `metadataJson` keys starting with `agent`, which the product reserves for its own run settings.
  The HTTP run-start operations enforce both: such a `context`, and `metadataJson` carrying
  `agentExternalTargetRootBindings` (which would bind folders on the server host), are rejected
  before any run with HTTP 400 `agents.request-invalid`. External folders are granted only in the
  agent's saved workspace tool settings.
  When reviewing process-driven runs, filter `GET /api/agents/execution-runs` by `processRunId`,
  `processStepId`, `schedulerRunId` and `messageId`.
- Provider usage is a ledger observation, not a chat estimate. The HTTP run-detail contract exposes `usageTotals`: observation counts, known/unknown usage counts, token and tool-call totals, known/unknown cost counts, and known cost. Raw internal provider-usage observation enums are not public API fields.
- Tool receipts and runtime snapshots are current-run evidence. Do not treat stale prior-run receipts, copied artifacts, or provider test-chat output as proof for a governed process step.
- When a process proof claims real automation dispatch, verify at least one execution run is
  bound to the claimed process run and step, has relevant tool receipts, and reports
  `usageTotals.observationCount > 0` when a provider response was produced. Judge each receipt by
  `effectState` (3 Committed, 2 NotCommitted, 1 None, 0 Unknown), not by the command's HTTP
  status; workspace file, workspace process and MCP receipts currently report 0 Unknown, and an
  unknown effect needs reconciliation, not a blind retry. A provider test route or detached chat
  session proves provider health only, not process execution.

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
| `POST` | `/api/agents/attachments/images` |
| `GET` | `/api/agents/bootstrap` |
| `GET` | `/api/agents/by-external-key/{externalNamespace}/{key}` |
| `PUT` | `/api/agents/by-external-key/{externalNamespace}/{key}` |
| `DELETE` | `/api/agents/by-external-key/{externalNamespace}/{key}` |
| `GET` | `/api/agents/capabilities` |
| `POST` | `/api/agents/capabilities` |
| `POST` | `/api/agents/capabilities/access-preview` |
| `POST` | `/api/agents/capabilities/setup-tests/mcp` |
| `POST` | `/api/agents/capabilities/setup-tests/tool` |
| `DELETE` | `/api/agents/capabilities/{capabilityId}` |
| `GET` | `/api/agents/capabilities/{capabilityId}/editor` |
| `GET` | `/api/agents/execution-operations/{operationId}/events/stream` |
| `GET` | `/api/agents/execution-runs` |
| `POST` | `/api/agents/execution-runs` |
| `POST` | `/api/agents/execution-runs/stream` |
| `GET` | `/api/agents/execution-runs/{executionRunId}` |
| `GET` | `/api/agents/execution-runs/{executionRunId}/approvals` |
| `GET` | `/api/agents/execution-runs/{executionRunId}/artifacts` |
| `GET` | `/api/agents/execution-runs/{executionRunId}/checkpoints` |
| `POST` | `/api/agents/execution-runs/{executionRunId}/pending-approvals` |
| `POST` | `/api/agents/execution-runs/{executionRunId}/pending-approvals/stream` |
| `POST` | `/api/agents/execution-runs/{executionRunId}/reconcile-cancellation` |
| `POST` | `/api/agents/execution-runs/{executionRunId}/recover` |
| `GET` | `/api/agents/execution-runs/{executionRunId}/tool-receipts` |
| `POST` | `/api/agents/import` |
| `POST` | `/api/agents/import-package` |
| `POST` | `/api/agents/memory` |
| `DELETE` | `/api/agents/memory/{memoryId}` |
| `GET` | `/api/agents/providers` |
| `POST` | `/api/agents/providers` |
| `POST` | `/api/agents/providers/mutations/verify` |
| `DELETE` | `/api/agents/providers/{providerId}` |
| `POST` | `/api/agents/providers/{providerId}/chat-completions/stream` |
| `GET` | `/api/agents/providers/{providerId}/editor` |
| `POST` | `/api/agents/providers/{providerId}/ollama-modelfile` |
| `POST` | `/api/agents/providers/{providerId}/test` |
| `POST` | `/api/agents/providers/{providerId}/test-chat` |
| `GET` | `/api/agents/teams` |
| `POST` | `/api/agents/teams` |
| `GET` | `/api/agents/teams/{teamId}` |
| `PUT` | `/api/agents/teams/{teamId}` |
| `DELETE` | `/api/agents/teams/{teamId}` |
| `GET` | `/api/agents/teams/{teamId}/agents` |
| `GET` | `/api/agents/teams/{teamId}/editor` |
| `PUT` | `/api/agents/teams/{teamId}/members` |
| `POST` | `/api/agents/teams/{teamId}/members` |
| `GET` | `/api/agents/{agentId}` |
| `DELETE` | `/api/agents/{agentId}` |
| `POST` | `/api/agents/{agentId}/capabilities/{capabilityId}/verify` |
| `POST` | `/api/agents/{agentId}/chat` |
| `GET` | `/api/agents/{agentId}/chat-sessions` |
| `POST` | `/api/agents/{agentId}/chat-sessions` |
| `POST` | `/api/agents/{agentId}/chat-sessions/{chatSessionId}/rename` |
| `GET` | `/api/agents/{agentId}/chat-workspace` |
| `POST` | `/api/agents/{agentId}/chat/stream` |
| `POST` | `/api/agents/{agentId}/clone` |
| `POST` | `/api/agents/{agentId}/convert-to-template` |
| `GET` | `/api/agents/{agentId}/execution-log` |
| `GET` | `/api/agents/{agentId}/execution-runs` |
| `POST` | `/api/agents/{agentId}/execution-runs` |
| `POST` | `/api/agents/{agentId}/execution-runs/stream` |
| `GET` | `/api/agents/{agentId}/execution-runs/{executionRunId}` |
| `GET` | `/api/agents/{agentId}/execution-runs/{executionRunId}/approvals` |
| `GET` | `/api/agents/{agentId}/execution-runs/{executionRunId}/artifacts` |
| `GET` | `/api/agents/{agentId}/execution-runs/{executionRunId}/checkpoints` |
| `GET` | `/api/agents/{agentId}/execution-runs/{executionRunId}/log` |
| `GET` | `/api/agents/{agentId}/execution-runs/{executionRunId}/metrics` |
| `GET` | `/api/agents/{agentId}/execution-runs/{executionRunId}/tool-receipts` |
| `GET` | `/api/agents/{agentId}/export` |
| `GET` | `/api/agents/{agentId}/memory` |
| `GET` | `/api/agents/{agentId}/metrics` |
| `GET` | `/api/agents/{agentId}/runtime-snapshot` |
<!-- api-docs-skills-parity:routes:end -->

## Agent Recruiting Route Appendix

<!-- api-docs-skills-parity:agent-recruiting-routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/agent-recruiting/candidates/{agentId}/readiness` |
| `GET` | `/api/agent-recruiting/candidates/{candidateAgentId}/interviews` |
| `POST` | `/api/agent-recruiting/interviews` |
| `GET` | `/api/agent-recruiting/interviews/{interviewId}` |
| `POST` | `/api/agent-recruiting/interviews/{interviewId}/attempts` |
| `POST` | `/api/agent-recruiting/interviews/{interviewId}/reviews` |
<!-- api-docs-skills-parity:agent-recruiting-routes:end -->
