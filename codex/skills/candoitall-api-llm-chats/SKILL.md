---
name: candoitall-api-llm-chats
description: Use when managing ordinary CanDoItAll Simple Chat definitions, conversations, durable turns, replayable SSE, cancellation, or recovery through the HTTP API; use the agents API skill for agent chat sessions and governed agent runs.
---

# CanDoItAll LLM Chats API

Use this skill for provider-neutral ordinary conversations. Simple Chats share provider/model
infrastructure and usage accounting with AgentFramework, but they do not create agents, agent chat
sessions, tools, skills, MCP access, memory, or governed agent execution runs.

## Access And Contract

- Start the CanDoItAll web app and inspect Swagger UI at `/swagger`.
- Check `/api/access/status` before assuming bearer tokens are required.
- If JWT is active, send `Authorization: Bearer <token>` with the exact LLM Chat scope.
- Use the shared
  [OpenAPI snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  when its [provenance manifest](../_candoitall-api-shared/manifest.json) matches the target source.
- When the target differs, use its live `/openapi/v1.json` or
  `/swagger/v1/swagger.json` document.

The three route families have distinct responsibilities:

| Base path | Responsibility |
| --- | --- |
| `/api/llm-chats` | Definition catalog, provider/model options, lifecycle, and conversation creation |
| `/api/llm-conversations` | Conversation paging, transcript reads, rename/archive, turn admission, and exact active-turn recovery |
| `/api/llm-chat-operations` | Durable turn status, replayable events, cancellation, and evidence-based reconciliation |

## Definition Workflow

1. Read `GET /api/llm-chats/provider-options` before selecting a provider, model, or thinking effort.
2. Create a definition with `POST /api/llm-chats`.
3. Use `GET /api/llm-chats/{definitionId}` for the safe read projection. Use the manage-scoped
   `/editor` resource when the system prompt and complete editable revision are required.
4. Preserve the returned numeric ETag. Update with `PUT /api/llm-chats/{definitionId}` and send the
   expected concurrency token in the body or `If-Match` header.
5. Activate, suspend, or archive through the typed lifecycle route; do not emulate state changes by
   rewriting the definition.

`LlmChatDefinitionMutationApiRequest` contains `name`, `summary`, `avatarImageUrl`, `systemPrompt`,
`providerProfileId`, `model`, nullable `thinkingEffort`, `modelSettings`, `tags`, `revisionReason`,
optional `responseFormat`, and optional `expectedConcurrencyToken`. Thinking effort is a typed
provider/model capability; do not put a duplicate effort value in free-form model parameters.

A conversation pins the definition revision current at creation. Later definition edits do not mutate
existing conversations.

## Conversation Workflow

- Create through `POST /api/llm-chats/{definitionId}/conversations` with a title. HTTP creation always
  records API origin and is not idempotent; do not blindly retry an ambiguous response.
- List through `GET /api/llm-conversations` with bounded `take`, opaque `cursor`, and optional
  `definitionId`.
- Read through `GET /api/llm-conversations/{conversationId}` with bounded `messageTake` and opaque
  `messageCursor`. The public transcript excludes system messages.
- Rename with `PATCH .../title`, supplying both `expectedTranscriptRevision` and the expected resource
  concurrency token.
- Archive through `POST .../archive` with the expected resource concurrency token.

Read the new ETag after each successful mutation. A `409` is a concurrency decision for the caller;
never hide it with an unconditional retry.

## Durable Turns

Send a turn with `POST /api/llm-conversations/{conversationId}/turns`:

```json
{
  "operationId": "00000000-0000-0000-0000-000000000001",
  "expectedTranscriptRevision": 0,
  "message": "Summarize the decision."
}
```

Generate a non-empty UUID before the first attempt. The operation ID is the durable idempotency
identity: retry the same logical turn with the same ID and byte-equivalent semantics. Reusing it for a
changed turn returns `operation-id-conflict`; using a new ID after an ambiguous response can duplicate
the user's intent.

Successful admission returns `202 Accepted`, a `Location` header, and the operation resource. The HTTP
request does not own provider execution. Follow the durable status resource or its event stream.

- `POST .../{operationId}/cancel` durably requests cancellation and signals a live local call when one
  exists. A client disconnect does not cancel the operation.
- `POST .../{operationId}/reconcile` settles only from durable transcript, invocation, dispatch, and
  lease evidence. It never redispatches ambiguous post-provider work.
- `POST .../{conversationId}/active-turns/{turnId}/abandon` is an explicit final recovery action for
  the exact `RecoveryRequired` turn after its live owner has drained.

## Event Replay

`GET /api/llm-chat-operations/{operationId}/events` replays committed durable events and then follows
new updates until a terminal event. Send `Last-Event-ID` or the equivalent non-negative `after` query
cursor. If both are present they must match.

Event IDs are durable per-operation sequences. `stream.gap` means retained history no longer covers the
requested cursor; read the operation and conversation resources before trusting later events. Never put
a bearer token in an SSE query parameter.

## Authorization And Failures

- `api.llm-chats.read`: provider options, definitions, conversations, transcripts, operation status,
  and events.
- `api.llm-chats.manage`: definition/conversation mutation, editor reads, lifecycle transitions,
  reconciliation, and explicit abandon recovery.
- `api.llm-chats.execute`: turn admission and cancellation.

The broad `api` scope is not an LLM Chat super-scope. Failures use Problem Details with stable error
codes and retryability metadata. Do not expose or log provider credentials, endpoints, system prompts,
raw provider exceptions, internal request fingerprints, or server filesystem paths.

## Validation

- Read back every created or mutated definition/conversation and verify the returned ETag.
- After a turn, verify terminal operation state and the resulting transcript; transport success alone
  is not execution proof.
- For cancellation or recovery, verify the durable operation and the conversation's active-turn state.
- Use the live OpenAPI document for exact schemas, declared status codes, and enum values.

## Definition Route Appendix

<!-- api-docs-skills-parity:llm-chat-definition-routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/llm-chats` |
| `POST` | `/api/llm-chats` |
| `GET` | `/api/llm-chats/{definitionId:guid}` |
| `PUT` | `/api/llm-chats/{definitionId:guid}` |
| `POST` | `/api/llm-chats/{definitionId:guid}/activate` |
| `POST` | `/api/llm-chats/{definitionId:guid}/archive` |
| `POST` | `/api/llm-chats/{definitionId:guid}/conversations` |
| `GET` | `/api/llm-chats/{definitionId:guid}/editor` |
| `POST` | `/api/llm-chats/{definitionId:guid}/suspend` |
| `GET` | `/api/llm-chats/provider-options` |

<!-- api-docs-skills-parity:llm-chat-definition-routes:end -->

## Conversation Route Appendix

<!-- api-docs-skills-parity:llm-chat-conversation-routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/llm-conversations` |
| `GET` | `/api/llm-conversations/{conversationId:guid}` |
| `POST` | `/api/llm-conversations/{conversationId:guid}/active-turns/{turnId:guid}/abandon` |
| `POST` | `/api/llm-conversations/{conversationId:guid}/archive` |
| `PATCH` | `/api/llm-conversations/{conversationId:guid}/title` |
| `POST` | `/api/llm-conversations/{conversationId:guid}/turns` |

<!-- api-docs-skills-parity:llm-chat-conversation-routes:end -->

## Operation Route Appendix

<!-- api-docs-skills-parity:llm-chat-operation-routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/llm-chat-operations/{operationId:guid}` |
| `POST` | `/api/llm-chat-operations/{operationId:guid}/cancel` |
| `GET` | `/api/llm-chat-operations/{operationId:guid}/events` |
| `POST` | `/api/llm-chat-operations/{operationId:guid}/reconcile` |

<!-- api-docs-skills-parity:llm-chat-operation-routes:end -->
