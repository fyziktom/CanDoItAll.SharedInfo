# Workflow Stable Identity And Retry Safety

Use this reference when a client must resolve workflows without display-name matching or
start a workflow safely across timeouts and concurrent retries.

## Resolve A Stable Workflow

Catalog items expose template provenance (`templateKey`, `templatePackKey`,
`templatePackVersion`, `sourceHash`) and partner identity (`externalNamespace`,
`externalKey`).

- Resolve a system template with
  `GET /api/workflows/definitions/by-template-key/{templateKey}`.
- Resolve a partner identity with
  `GET /api/workflows/definitions/by-external-key/{externalNamespace}/{externalKey}`.
- Filter the catalog with
  `GET /api/workflows/definitions?externalNamespace=...&externalKey=...`; supply both
  query values together.

Stable values are trimmed and lowercased. Namespace length is at most 100; key length is
at most 200. Values allow ASCII letters, digits, `-`, `_`, `.`, and `:`.

`WorkflowStableIdentityResolution.status` is `Resolved`, `NotFound`, `Ambiguous`, or
`Stale`. Only `Resolved` supplies one safe `workflowId` and `runnableVersionId`.
`Ambiguous` fails closed until duplicate materializations are repaired; `Stale` means the
single materialization has no active runnable version. Pin the returned version and do
not fall back to display-name matching.

## Start With Idempotency

Both public start routes accept `Idempotency-Key`:

- `POST /api/workflows/runs/start`;
- `POST /api/workflows/definitions/{workflowId}/runs/start`.

Use one stable key for one logical launch. The workspace-scoped fingerprint includes the
workflow selection/version, requested backend, and canonical JSON input. Object
properties are sorted for canonicalization; input must be a JSON object.

An identical concurrent or post-timeout retry returns the original run with
`replayed: true`, `created: false`, and the same `idempotencyKeyHash`. A new claim returns
`created: true`. Reusing a key with changed workflow, version, backend, or canonical
input returns `409` and does not start another run.

Read retry evidence with
`GET /api/workflows/runs/by-idempotency-key/{key}`. The response exposes the safe key
hash, request and canonical-input hashes, selected/resolved workflow and version,
backend, original run id, claim/run state, terminal flag, replay count/timestamps, and
completion timestamp. It never returns the raw key.

The current Web serializer encodes `idempotencyDisposition` numerically:
`NotRequested=0`, `EnforcedNewRun=1`, `ReplayedExistingRun=2`. Evidence
`claimState` is `Pending=0` or `Completed=1`.

## Error Handling

Runtime validation and authorization failures use `ApiErrorResponse`. Treat
`workflows.idempotency-key-conflict` as a terminal caller conflict, not a transient
retry. A missing lookup returns `404` with
`workflows.idempotency-key-not-found`; malformed keys return `400`.
