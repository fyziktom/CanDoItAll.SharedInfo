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
- When API authorization is enabled (`authorizationEnabled`), send `Authorization: Bearer <token>`
  with the exact LLM Chat scope.
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
2. Create a definition with `POST /api/llm-chats`. A new definition starts in `draft` (revision 1,
   concurrency token 0); activate it before creating conversations.
3. Use `GET /api/llm-chats/{definitionId}` for the safe read projection. Use the manage-scoped
   `/editor` resource when the system prompt and complete editable revision are required.
4. Preserve the returned numeric ETag. Update with `PUT /api/llm-chats/{definitionId}`. PUT
   replaces the whole configuration: an omitted or null optional member takes its empty or
   default meaning (no `tags` removes all tags, no `responseFormat` removes the response format).
   Read `/editor` and send every value back, with the concurrency token in the body or as a
   single strong `If-Match` value such as `"3"`, quotes included.
5. Activate, suspend, or archive through the typed lifecycle route; do not emulate state changes by
   rewriting the definition. Lifecycle routes need a JSON body even with `If-Match` (`{}` is
   enough), and archiving is final.

Exact members of `LlmChatDefinitionMutationApiRequest` are in the live schema. `thinkingEffort` is a
camel-case string such as `"low"`; a number is rejected. `systemPrompt` is required on every
write: an empty string means no prompt, and null is rejected. Invocation attempts report provider
kind and thinking effort as integers. Thinking effort is a typed provider/model capability; do not
put a duplicate effort value in free-form model parameters.

A conversation pins the definition revision current at creation. Later definition edits do not mutate
existing conversations.

## Shared providers and request history

Provider options list only enabled chat provider profiles, which may include profiles imported
from a shared-provider publication (they are not marked). Use the returned `providerProfileId`,
`model` and the model's `thinkingEffort.allowedEfforts` exactly. Never substitute an upstream
model name or silently switch profile. A disabled profile disappears from the options and fails
with 503 `llm-chat.provider-unavailable`. Direct compatible inference uses the
[shared-provider API skill](../candoitall-api-shared-providers/SKILL.md).

Simple Chat invocation history links to canonical conversation/operation evidence.
Usage and frozen prices are evidence, not estimates inferred from text. Caller/managed
credential identity is server-derived. Do not supply internal history context in HTTP
commands or treat history metadata scope as permission to read canonical chat content.

## Conversation Workflow

- Create through `POST /api/llm-chats/{definitionId}/conversations` with a title. HTTP creation always
  records API origin and is not idempotent; do not blindly retry an ambiguous response. The
  definition must be `active`. If the provider profile or model of its current revision is no
  longer usable, creation currently fails with HTTP 500 without Problem Details.
- List through `GET /api/llm-conversations` with bounded `take`, opaque `cursor`, and optional
  `definitionId`.
- Read through `GET /api/llm-conversations/{conversationId}` with bounded `messageTake` and opaque
  `messageCursor`. The public transcript excludes system messages.
- Rename with `PATCH .../title`, supplying both `expectedTranscriptRevision` and the expected resource
  concurrency token. Rename also increments `transcriptRevision`, so use the returned value for
  the next turn. A stale revision or an active turn currently returns HTTP 500 and nothing
  changes.
- Archive through `POST .../archive` with the expected resource concurrency token. Archive is
  irreversible, needs a JSON body, and returns 409 `llm-chat.active-turn-conflict` while a turn is
  active or unfinished.

Read the new ETag after each successful mutation. Branch on the 409 `code`. After
`llm-chat.definition-concurrency-conflict`, `llm-chat.storage-conflict` or
`llm-chat.transcript-revision-conflict`, read again and reapply your change; never hide a 409 with
an unconditional retry. `llm-chat.runtime-profile-changed` means the host switched its active
database profile: a read can be repeated, but read back before repeating a write. An identical
turn may be resent with the same `operationId`.

## Durable Turns

Send a turn with `POST /api/llm-conversations/{conversationId}/turns`:

```json
{
  "operationId": "00000000-0000-0000-0000-000000000001",
  "expectedTranscriptRevision": 1,
  "message": "Summarize the decision."
}
```

Send the conversation's current `transcriptRevision` as `expectedTranscriptRevision`, from the
create response, the conversation read or the previous turn's `resultingTranscriptRevision`. A
new conversation starts at 1 when its definition has a system prompt and at 0 otherwise.

Generate a new non-empty GUID for every turn; it is the idempotency key and becomes the operation
and turn identifier. Resending the same `operationId` with the same conversation,
`expectedTranscriptRevision` and `message` returns the recorded operation (202, `replayed: true`)
without calling the provider again. Different content under the same id returns 409
`llm-chat.operation-id-conflict`. After a lost response, resend the identical request; a new id
could duplicate the turn. After a `failed` or `cancelled` turn, read the conversation and send a
new turn with a new id.

Successful admission returns `202 Accepted`, a `Location` header, and the operation resource. The HTTP
request does not own provider execution. Follow the durable status resource or its event stream.

- `POST .../{operationId}/cancel` durably requests cancellation and signals a live local call when one
  exists. A client disconnect does not cancel the operation.
- `POST .../{operationId}/reconcile` settles only from durable transcript, invocation, dispatch, and
  lease evidence. It never redispatches ambiguous post-provider work.
- `POST .../{conversationId}/active-turns/{turnId}/abandon` is an explicit final recovery action for
  the exact turn whose operation is `recoveryRequired` (its `turnId` is the `operationId`), after
  reconcile left it there and no live execution owns it.

## Event Replay

`GET /api/llm-chat-operations/{operationId}/events` replays committed durable events and then follows
new updates until a terminal event. Send `Last-Event-ID` or the equivalent non-negative `after` query
cursor. If both are present they must match.

Event IDs are durable per-operation sequences. `stream.gap` means retained history no longer covers the
requested cursor; read the operation and conversation resources before trusting later events. Never put
a bearer token in an SSE query parameter.

An invalid or conflicting cursor returns 400 with the general `errors` envelope
(`llm-chat.stream-cursor-invalid`). `stream.gap` carries `snapshotUrl`, the operation status URL
to read. Delta text is provisional until `llm.operation.succeeded`.

## Authorization And Failures

- `api.llm-chats.read`: provider options, definitions, conversations, transcripts, operation status,
  and events.
- `api.llm-chats.manage`: definition and conversation mutation, editor reads, lifecycle
  transitions and reconciliation.
- `api.llm-chats.execute`: turn admission, cancellation and abandoning a `recoveryRequired` turn.

The broad `api` scope is not an LLM Chat super-scope. Handled failures use Problem Details
(`application/problem+json`) with a stable `code`; failures concerning a turn operation add
`operationId` and `retryable`. There are exceptions: the event-stream cursor error uses the
general `errors` envelope, a query value the framework cannot bind returns 400 without Problem
Details, and the HTTP 500 cases described above for rename and conversation creation have no
Problem Details body. Do not expose or log provider credentials, endpoints, system prompts, raw
provider exceptions, internal request fingerprints, or server filesystem paths.

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
| `GET` | `/api/llm-chats/provider-options` |
| `GET` | `/api/llm-chats/{definitionId}` |
| `PUT` | `/api/llm-chats/{definitionId}` |
| `POST` | `/api/llm-chats/{definitionId}/activate` |
| `POST` | `/api/llm-chats/{definitionId}/archive` |
| `POST` | `/api/llm-chats/{definitionId}/conversations` |
| `GET` | `/api/llm-chats/{definitionId}/editor` |
| `POST` | `/api/llm-chats/{definitionId}/suspend` |
<!-- api-docs-skills-parity:llm-chat-definition-routes:end -->

## Conversation Route Appendix

<!-- api-docs-skills-parity:llm-chat-conversation-routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/llm-conversations` |
| `GET` | `/api/llm-conversations/{conversationId}` |
| `POST` | `/api/llm-conversations/{conversationId}/active-turns/{turnId}/abandon` |
| `POST` | `/api/llm-conversations/{conversationId}/archive` |
| `PATCH` | `/api/llm-conversations/{conversationId}/title` |
| `POST` | `/api/llm-conversations/{conversationId}/turns` |
<!-- api-docs-skills-parity:llm-chat-conversation-routes:end -->

## Operation Route Appendix

<!-- api-docs-skills-parity:llm-chat-operation-routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/llm-chat-operations/{operationId}` |
| `POST` | `/api/llm-chat-operations/{operationId}/cancel` |
| `GET` | `/api/llm-chat-operations/{operationId}/events` |
| `POST` | `/api/llm-chat-operations/{operationId}/reconcile` |
<!-- api-docs-skills-parity:llm-chat-operation-routes:end -->
