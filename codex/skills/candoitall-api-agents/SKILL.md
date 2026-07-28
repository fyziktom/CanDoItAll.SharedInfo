---
name: candoitall-api-agents
description: Use when managing CanDoItAll agents, remote package imports, stable external-key provisioning, portable JSON Schema output, AI-agent recruiting evidence, providers, capabilities, chat, execution runs, approvals, artifacts, logs, metrics, or runtime snapshots through the HTTP API.
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
- Providers: `/api/agents/providers`, `/providers/{providerId}/editor`, create/delete/test/test-chat, and Ollama modelfile routes.
- Capabilities: `/api/agents/capabilities`, `/capabilities/{capabilityId}/editor`, create/delete, per-agent capability verification, tool setup tests, MCP setup tests, and access-policy previews.
- Memory: `/api/agents/{agentId}/memory`, `POST /api/agents/memory`, and delete memory routes.

## Chat And Execution

- Chat sessions: `/api/agents/{agentId}/chat-sessions`, rename, chat workspace, and `/chat`.
- Execution runs: `POST /api/agents/execution-runs`, `POST /api/agents/{agentId}/execution-runs`, list routes, run detail routes, and agent-scoped/global evidence routes.
- Approvals: `/api/agents/execution-runs/{executionRunId}/pending-approvals` and run approval listing.
- Evidence: execution artifacts, checkpoints, tool receipts, execution log, runtime snapshot, and metrics routes.
- Recruiting evidence: create/read `/api/agent-recruiting/interviews`, list a
  candidate's interviews through
  `/api/agent-recruiting/candidates/{candidateAgentId}/interviews`, append typed
  attempts and human reviews, then read
  `/api/agent-recruiting/candidates/{agentId}/readiness`.

### Activity Correlation Boundary

New execution records can expose `initialActivityOperationId`. It is the durable
correlation identifier for the first typed in-process activity operation associated
with that run. It is not an idempotency key and does not authorize or expose the
activity stream.

The current HTTP contract has no agent-activity polling or SSE endpoint. The typed
activity stream is process-local and is consumed by the Blazor surfaces. External
clients must use execution-run detail, approvals, artifacts, checkpoints, receipts,
logs, runtime snapshots, and metrics for durable readback. Do not invent an
`/activity`, `/events`, or SSE route from the presence of
`initialActivityOperationId`.

## Operating Rules

- Prefer agent-scoped routes when you already know `agentId`; use global execution-run routes for cross-agent review.
- Use `/import-package` for remote clients; never send a server filesystem path or raw
  provider secret across environments.
- Resolve partner-managed agents by external key. Do not emulate identity with display
  names, and do not retry a changed payload under an existing idempotency key.
- For debugging, query run detail first, then fetch artifacts/checkpoints/receipts/log only for the run under review.
- Treat `initialActivityOperationId` as correlation metadata only. Continue to use
  `executionRunId` for durable run lookups.
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
- Provider usage is a ledger observation, not a chat estimate. Preserve `ProviderUsageObservationStatus`, `ProviderUsageSourcePhase`, token counts, pricing status, and execution/run identifiers when reviewing metrics or artifacts.
- Tool receipts and runtime snapshots are current-run evidence. Do not treat stale prior-run receipts, copied artifacts, or provider test-chat output as proof for a governed process step.
- When a process proof claims real automation dispatch, verify at least one execution run is bound to the claimed process run and step, has relevant tool receipts, and has provider usage observations when a provider response was produced. A provider test route or detached chat session proves provider health only, not process execution.

## Execution DTOs

`AgentExecutionRunStartApiRequest` fields:

- `prompt`
- `chatSessionId`
- `context`
- `autoApprovePendingToolCalls`
- `structuredOutput`
- `inputAttachmentPaths`

`AgentExecutionRunApiRequest` is the global-start shape. It requires `agentId` and
`prompt`, then uses the same `chatSessionId`, `context`,
`autoApprovePendingToolCalls`, `structuredOutput`, and `inputAttachmentPaths` fields as
the scoped request.

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

## Validation

- For created/updated agents, read back the agent editor/detail.
- For execution, verify run state, artifacts, receipts, and metrics instead of relying on a single status field.
- For provider changes, run provider health/test-chat when credentials and model availability are relevant.
- For capability changes, run tool/MCP setup tests or access-preview when the change affects executable tools, local/remote MCP servers, or role-level capability policies.

## Source Route Appendix

<!-- api-docs-skills-parity:routes:start -->

Agents API route appendix. Generated from Minimal API registrations; refresh from `src/App/CanDoItAll.Web/Api/AgentsApi.cs` when routes change.

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
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/approvals` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/artifacts` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/checkpoints` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/log` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/metrics` |
| `GET` | `/api/agents/{agentId:guid}/execution-runs/{executionRunId:guid}/tool-receipts` |
| `GET` | `/api/agents/{agentId:guid}/export` |
| `POST` | `/api/agents/{agentId:guid}/chat` |
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
| `GET` | `/api/agents/execution-runs` |
| `POST` | `/api/agents/execution-runs` |
| `GET` | `/api/agents/execution-runs/{executionRunId:guid}` |
| `GET` | `/api/agents/execution-runs/{executionRunId:guid}/artifacts` |
| `GET` | `/api/agents/execution-runs/{executionRunId:guid}/checkpoints` |
| `POST` | `/api/agents/execution-runs/{executionRunId:guid}/pending-approvals` |
| `GET` | `/api/agents/execution-runs/{executionRunId:guid}/tool-receipts` |
| `POST` | `/api/agents/import` |
| `POST` | `/api/agents/import-package` |
| `POST` | `/api/agents/memory` |
| `DELETE` | `/api/agents/memory/{memoryId:guid}` |
| `GET` | `/api/agents/providers` |
| `POST` | `/api/agents/providers` |
| `DELETE` | `/api/agents/providers/{providerId:guid}` |
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
