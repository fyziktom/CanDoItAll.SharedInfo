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
returns `409`; a failed expected hash/version precondition returns `412`.
Missing/invalid idempotency, external key, or replacement version fails with
`agent-package.idempotency-key-invalid`, `agent-package.external-key-invalid`, or
`agent-package.expected-version-required`.

The current OpenAPI operation publishes `Idempotency-Key` but does not mark the header
parameter as required even though runtime validation requires it. Treat the runtime rule
as authoritative and keep a golden negative test for a missing header.

## Stable External Provisioning

The external identity is workspace-local and consists of a namespace and key. Each part
is normalized to lowercase, is 1 through 100 characters, starts and ends with an ASCII
letter or digit, and otherwise allows letters, digits, `.`, `_`, and `-`.

1. Read `GET /api/agents/by-external-key/{externalNamespace}/{key}` and retain its `ETag`.
2. Send `PUT` to the same route with `AgentEditorModel`, a stable `Idempotency-Key`, and
   `If-Match` when updating an existing binding.
3. Read the resource back and compare `configurationVersion`.
4. Archive through `DELETE` with a new idempotency key and the current `If-Match`.

Identical concurrent retries resolve to one agent and return the original receipt with
`replayed: true`. Reusing a key for a changed command returns `409`; a stale
configuration version returns `412`. `DELETE` archives the binding and agent; it is not
an unguarded physical delete.

The current OpenAPI lists the request headers but does not publish the GET response's
`ETag` header and does not express every runtime-required header as `required: true`.
Capture raw response headers and verify missing/stale header behavior against the live
host before trusting generated client metadata alone.

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

Unsupported or excessive contracts fail before provider execution. The run preserves
the exact canonical schema, schema hash, and raw provider output. The structured result
returns parsed `data`, `rawOutput`, `schema`, `schemaHash`, `validationErrors`, and one
of `Valid`, `ProviderRefusal`, `MalformedJson`, or `SchemaValidationFailed`. Public
requests and responses never expose `System.Type` or runtime-only output metadata.

## Agent Recruiting Evidence

Use this order:

1. Create an interview for a candidate agent and its exact
   `candidateConfigurationVersion`.
2. Append repeatable attempts. Each attempt supplies exactly one typed target:
   `agent-execution-run`, `workflow-run`, or `process-run`, plus challenge/rubric
   versions and immutable input/output/schema hashes.
3. Append a human review for a specific attempt. When JWT is active,
   `reviewerActorId` must match the authenticated subject; the server binds the reviewer
   identity from the token.
4. Read the interview, then read candidate readiness.

Automated decisions are `Passed`, `Failed`, or `NeedsHumanReview`; human decisions are
`Approved` or `Rejected`. Missing, non-terminal, mismatched-agent, or incomplete target
evidence remains explicit. Readiness requires complete qualifying evidence plus human
authorization. `readyForProduction` never activates the agent:
`activatesAgent` remains false and separate activation authorization is required.

CRM-HR recruiting manages people/applications and remains a separate bounded context.
Do not copy CRM-HR application state into these agent execution-evidence resources.

## Errors And Security

All routes are under the authenticated `/api` group when authorization is enabled.
Expected `400`, `401`, `403`, `404`, `409`, and `412` responses use
`ApiErrorResponse.errors[]` with `code`, `message`, and `severity`. Preserve the code in
automation and do not retry a conflict with changed content.
