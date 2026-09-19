# Agent Partner API Contracts

Use this reference for remote package import, stable external provisioning, portable JSON
Schema output, and agent recruiting evidence. Confirm exact schemas against the shared
OpenAPI snapshot or the target host.

## Remote Package Import

Send `POST /api/agents/import-package` as `multipart/form-data`:

- `package`: required non-empty agent ZIP package, at most 32 MiB;
- `mode`: `create`, `replace-exact-version`, or `clone`;
- `externalKey`: required stable partner key; after normalization it must satisfy the
  1-through-100-character external-identity rule;
- `externalNamespace`: optional; defaults to `package-import`;
- `expectedPackageSha256`: optional lowercase or uppercase SHA-256;
- `expectedAgentVersion`: required for `replace-exact-version`; omit it for other modes;
- `Idempotency-Key`: required for every import and at most 200 characters.

The archive reader bounds expanded content to 128 MiB, entry count to 64, and the
manifest to 8 MiB. It rejects traversal, absolute paths, links, executable content,
invalid schema or hashes, and secret-bearing provider material before mutation. Provider
and capability prerequisites are reported rather than guessed.

`201` means a create/clone was applied. `200` means an exact-version replacement or an
idempotent replay. The `AgentPackageImportReceipt` returns `agentId`, mode, normalized
external identity, package/configuration hashes, package/imported versions, unresolved
prerequisites, warnings, and `replayed`. A changed request under the same idempotency key
returns `409` (`agent-package.idempotency-conflict`); a stale `expectedAgentVersion` returns
`412` (`agent-package.version-conflict`), while a package that does not match
`expectedPackageSha256` is rejected with `400` (`agent-package.hash-mismatch`).
Missing/invalid idempotency, external key, external identity format, or replacement version
fails with `agent-package.idempotency-key-invalid`, `agent-package.external-key-invalid`,
`agent-package.external-identity-invalid`, or `agent-package.expected-version-required`.

The current OpenAPI operation publishes `Idempotency-Key` but does not mark the header
parameter as required even though runtime validation requires it. Treat the runtime rule
as authoritative and keep a golden negative test for a missing header.

## Stable External Provisioning

The external identity is workspace-local and consists of a namespace and key. Each part
is normalized to lowercase, is 1 through 100 characters, starts and ends with an ASCII
letter or digit, and otherwise allows letters, digits, `.`, `_`, and `-`.

1. Read `GET /api/agents/by-external-key/{externalNamespace}/{key}` and retain its `ETag`.
2. Send `PUT` to the same route with the complete `AgentEditorModel` (`id` and
   `expectedUpdatedAtUtc` null, no secret references, `selectedCapabilityIds` and `tags`
   present; the operation description lists every rule), a stable `Idempotency-Key`, and
   `If-Match` when updating an existing binding.
3. Read the resource back and compare `configurationVersion`.
4. Archive through `DELETE` with a new idempotency key and the current `If-Match`.

Identical concurrent retries resolve to one agent and return the original receipt with
`replayed: true`. Reusing a key for a changed command returns `409`; a stale
configuration version returns `412`. `DELETE` archives only the agent; the binding is kept, so
`GET` on the same route still resolves it with `isArchived: true`. It is not a physical delete.

The OpenAPI document describes the `ETag` response header and the header rules in prose, but
declares no response-header object and does not mark `Idempotency-Key` or `If-Match` as
`required: true`, so generated clients do not enforce them. Capture raw response headers and
keep golden negative tests for missing and stale headers.

## Portable JSON Schema Output

Both agent execution start routes accept this `structuredOutput` shape:

```json
{
  "kind": "json-schema",
  "version": "1.0",
  "name": "crm_note_classification",
  "schema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "classification": { "type": "string" }
    },
    "required": ["classification"]
  },
  "strict": true
}
```

The name starts with an ASCII letter and is at most 64 letters, digits, `_`, or `-`.
Schemas are limited to 64 KiB, 16 nested schema levels, 512 schema nodes, and 128
properties per object. The top level must be an object. Strict object schemas set
`additionalProperties: false` and list every property in `required`; represent an
optional value with a type that includes `null`.

Unsupported or excessive contracts fail before provider execution: the JSON start routes return
HTTP 400 with a code starting with `agents.structured-output-`, and on the streaming start routes
an invalid contract arrives in the stream as `agent.command.failed` with `agents.command-failed`.
The run keeps the canonical schema, its hash and the raw provider output internally, but the run
result's `structuredOutput` returns only the parsed `data` (null for malformed, oversized or
refused answers), `validationStatus` (`Valid`, `ProviderRefusal`, `MalformedJson` or
`SchemaValidationFailed`; streams write camel-case text such as `schemaValidationFailed`) and at
most 20 `validationErrors`. Any status other than `Valid` ends the run in state 6 Failed with
HTTP 200. Public requests and responses never expose `System.Type` or runtime-only output
metadata.

## Agent Recruiting Evidence

Use this order:

1. Read `GET /api/agent-recruiting/candidates/{agentId}/readiness` and create an interview with
   its `currentConfigurationVersion` as `candidateConfigurationVersion` (a different version is
   rejected with 409 `agent-recruiting.candidate-version-conflict`). Evidence stops counting
   when the agent's configuration changes.
2. Append repeatable attempts. Each attempt supplies exactly one typed target:
   `agent-execution-run`, `workflow-run`, or `process-run`, plus challenge/rubric
   versions and immutable input/output/schema hashes. Append an attempt only after the target
   run has finished. When you send a `structuredOutputContractKey`,
   `structuredOutputValidationStatus` must be `succeeded`; the agent run's `Valid` leaves the
   attempt incomplete.
3. Append a human review for a specific attempt. This always needs an authenticated reviewer
   whose bearer token includes the `agent-recruiting.review` scope (the `api` scope alone is
   not enough); with API authorization disabled it always fails with 401
   `agent-recruiting.reviewer-authorization-required`. The server stores the token subject as
   the reviewer, and a non-blank `reviewerActorId` must equal it. An approval qualifies for
   readiness only with both `authorizationReference` and `authorizationEvidenceHash`.
4. Read the interview, then read candidate readiness.

Automated decisions are `Passed`, `Failed`, or `NeedsHumanReview`; human decisions are
`Approved` or `Rejected`. Missing hashes, a missing automated evaluation or a target run that
has not finished leave the attempt stored as `Incomplete`, with `missingEvidence` naming what is
missing; append a new attempt to replace it. An unknown target run
(404 `agent-recruiting.target-not-found`) or a run in which the candidate did not take part
(409 `agent-recruiting.target-candidate-conflict`) is rejected and nothing is appended. Readiness
requires complete qualifying evidence plus human authorization. `readyForProduction` never
activates the agent: `activatesAgent` remains false and separate activation authorization is
required.

CRM-HR recruiting manages people/applications and remains a separate bounded context.
Do not copy CRM-HR application state into these agent execution-evidence resources.

## Errors And Security

All routes are under the authenticated `/api` group when authorization is enabled.
Expected `400`, `401`, `403`, `404`, `409`, and `412` responses use
`ApiErrorResponse.errors[]` with `code`, `message`, and `severity`. Preserve the code in
automation and do not retry a conflict with changed content.
