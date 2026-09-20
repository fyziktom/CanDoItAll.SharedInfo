---
name: candoitall-api-memory-providers
description: Use when listing, reading, configuring, querying, or polling experimental CanDoItAll Memory provider integrations through the /api/memory-providers HTTP API, including credential-reference safety, strict transport validation, synchronous and asynchronous queries, and caller-owned operation status.
---

# CanDoItAll Memory Providers API

Use this skill for provider-neutral Memory integration in the main CanDoItAll host.
The API is work in progress and experimental.

## Ownership And Maturity

- Treat `/api/memory-providers` as the main host's provider profile, query, and
  operation-status surface.
- Do not infer or call `/api/cognitive-memory` routes on the main host. Native Cognitive
  Memory is owned by the separate `CanDoItAll.CognitiveMemory` repository.
- Treat the standalone Cognitive Memory product as WIP and unpublished until its own
  repository states otherwise. Discover its native service contract independently.
- Use the `NativeRemote` driver only as an explicitly configured provider adapter. It
  does not move native Cognitive Memory ownership back into the main host.

## Access And Contract Source

- Inspect Swagger/OpenAPI at `/swagger` or `/openapi/v1.json`.
- Check `GET /api/access/status` before assuming bearer tokens are required.
- When authorization is enabled, send the configured bearer token. Its subject is the
  durable requester identity for query and status ownership.
- Authorization accepts the umbrella `api` scope or the granular
  `api.memory-providers.read`, `api.memory-providers.write`, and
  `api.memory-providers.query` scopes. Read covers profile/status `GET` operations,
  write covers profile `PUT`, and query covers the query `POST`.
- Follow [authentication and capability rules](../_candoitall-api-shared/references/access-and-authentication.md)
  for login, administrator-only HTTP token issuance, HTTPS and Swagger authorization.
- Use the shared
  [OpenAPI snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  for exact schemas when it matches the target source version.
- Check the snapshot's [provenance manifest](../_candoitall-api-shared/manifest.json)
  before relying on it. Prefer the target host's live OpenAPI document when versions
  differ.

## Profile Workflow

1. List profiles with `GET /api/memory-providers`.
2. Read the exact profile with `GET /api/memory-providers/{providerId}`.
3. Create or replace it with `PUT /api/memory-providers/{providerId}`. PUT is
   last-write-wins and does not contact the provider. It also turns off the ingestion,
   feedback and event capabilities, which this API cannot configure.
4. Read it back and verify the effective capabilities, interaction support, limits, and
   sanitized transport configuration.

The request body rejects unknown JSON properties. Send `driverKind`, `fallbackBehavior` and
the query `mode` as the exact PascalCase tokens of the live schema; do not invent string
aliases.
`providerKind` is a lowercase dotted token such as `memory.mock`. `providerId` is the
caller-chosen permanent route key, at most 256 characters.

### Transport And Credential Rules

- Send every request member, using null for the unused transport and for `selectionTags`
  when there are no tags.
- `Http` and `NativeRemote` require `http` configuration and reject `mcp`.
- `Mcp` requires `mcp` configuration and rejects `http`.
- `Mock` rejects both transport blocks.
- `Http`, `NativeRemote` and `Mock` support synchronous queries only; `Mcp` supports all
  three capabilities. Asynchronous queries require operation status. An MCP profile needs
  `contextQueryTool` for queries and also `operationStatusTool` for asynchronous queries or
  operation status.
- `InProcessMigration` is not accepted through the external provider API.
- Use HTTPS for remote HTTP endpoints or loopback HTTP for local development. Use safe
  rooted relative query and health paths.
- Supply only credential references:
  `http.apiKeyEnvironmentVariable` or
  `mcp.authHeaderEnvironmentVariable`.
- Never put an API key, bearer token, password, embedded URI credential, or other secret
  value in a provider request.
- Configure only executable query/status capability flags. Provider UI capability data
  in responses is informational and is not writable through this API.

The server validates the discriminator and its matching transport as one unit. Do not
send extra transport blocks in the hope that an inactive block will be ignored.

## Query And Status Workflow

1. Send `POST /api/memory-providers/{providerId}/queries` with a non-empty `query` and
   `mode` of `Synchronous` or `Asynchronous`.
2. Inspect the returned handler `status`, selection result, diagnostic, operation,
   context pack, and accepted-operation metadata. Do not assume every `2xx` contains a
   completed context pack. The HTTP status follows `status`. Responses 403, 404, 409, 502
   and 504 carry the query response body, not `errors`: branch on `status` and
   `driverDispatchAttempted`. Only the 400 `memory-provider.request-invalid` and the 403
   `memory-provider.identity-missing` (a token without a subject) use `errors`; a body the
   framework cannot bind returns 400 without it. Every call creates a new operation, so
   retry a 502 or 504 only as a new query.
3. For an accepted asynchronous operation, poll
   `GET /api/memory-providers/operations/{operationId}` with
   `acceptedOperation.operationId`. `statusPath` holds the same identifier as text and is
   not an address. Wait at least `pollAfterSeconds` between reads, and stop when
   `expiresAtUtc` passes.
4. Stop when `operation.status` is `Completed`, `Failed`, `TimedOut`, `Cancelled`,
   `Expired` or `Forgotten`. The status read returns only the ledger record, never a
   context pack. The record advances only while the host's memory background workers run,
   so it can stay `Accepted` or `Running`.

Query dispatch is pinned to the provider id in the route. Operation status is visible
only to the same API requester that created the operation. A different authenticated
subject receives `403`; with local authorization disabled, the explicit local API
identity owns locally created operations.

## Deliberate Omissions

Do not expect provider ingestion, feedback, event acknowledgement, cancellation, or
native Cognitive Memory management routes in this basic API. Do not bypass the provider
catalog or operation ledger by calling provider-specific infrastructure directly.

## Validation

1. Confirm the live OpenAPI document contains the five operations below and no
   `/api/cognitive-memory` family.
2. Save and read back one non-secret provider profile.
3. Verify a mismatched or extra transport block returns `400`.
4. Verify a raw credential property is rejected as an unknown property.
5. Run a query through the explicitly selected provider.
6. For an asynchronous result, verify status succeeds for the creating requester and
   is denied for a different requester.

## Source Route Appendix

<!-- api-docs-skills-parity:routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/memory-providers` |
| `GET` | `/api/memory-providers/operations/{operationId}` |
| `GET` | `/api/memory-providers/{providerId}` |
| `PUT` | `/api/memory-providers/{providerId}` |
| `POST` | `/api/memory-providers/{providerId}/queries` |
<!-- api-docs-skills-parity:routes:end -->
