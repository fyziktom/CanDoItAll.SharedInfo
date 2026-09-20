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
  `GET /api/workflows/definitions?externalNamespace=partner-erp&externalKey=invoice-approval`;
  supply both query values together.

Stable values are trimmed and lowercased. Namespace length is at most 100; key length is
at most 200. Values allow ASCII letters, digits, `-`, `_`, `.`, and `:`.

`WorkflowStableIdentityResolution.status` is `Resolved`, `NotFound`, `Ambiguous`, or
`Stale`; every status is returned with HTTP 200. Only `Resolved` supplies a
`runnableVersionId`. `Stale` names the single matching `workflowId`, which has no active
runnable version; `NotFound` and `Ambiguous` return a null `workflowId`, and `Ambiguous` fails
closed until duplicate materializations are repaired. Pin the returned version and do
not fall back to display-name matching.

## Start With Idempotency

Both public start routes accept `Idempotency-Key`:

- `POST /api/workflows/runs/start`;
- `POST /api/workflows/definitions/{workflowId}/runs/start`.

Use one stable key for one logical launch. A key belongs to the caller that first used it: the
bearer token subject, or the local operator when API authorization is disabled, under the
authorization scope of the current database profile. Another caller sending the same key is
rejected with `409` and never receives the first caller's run, so a key is never a way to read
someone else's launch. Keep keys unique to your client anyway, because a collision costs you a
`409`. The request fingerprint covers the version choice, requested backend, canonical JSON input
and the caller's authorization context: a key reused from another workspace scope conflicts.
Object properties are sorted for canonicalization; input must be a JSON object.

An identical concurrent or post-timeout retry returns the original run with `replayed: true`,
`created: false` and `idempotencyDisposition` 2 ReplayedExistingRun; a concurrent duplicate
waits for the first request. In a replay, `run` shows the state recorded when the original start
returned, so read `GET /api/workflows/runs/{runId}` for the current state. A new claim returns
`created: true`. Closing the start request's connection cancels the run, and a retry then
returns the cancelled run. The key hash appears only in the by-key evidence. Reusing a key with
changed workflow, version, backend, or canonical input returns `409` and does not start another
run.

Read retry evidence with
`GET /api/workflows/runs/by-idempotency-key/{key}`. The response exposes the safe key
hash, request and canonical-input hashes, selected/resolved workflow and version,
backend, original run id, claim/run state, terminal flag, replay count/timestamps, and
completion timestamp. It never returns the raw key, and it finds only the keys of the
calling caller: a key another caller holds reads as `404`.

The current Web serializer encodes `idempotencyDisposition` numerically:
`NotRequested=0`, `EnforcedNewRun=1`, `ReplayedExistingRun=2`. Evidence
`claimState` is `Pending=0` or `Completed=1`.

## Error Handling

Runtime validation and authorization failures use `ApiErrorResponse`. Treat
`workflows.idempotency-key-conflict` as a terminal caller conflict, not a transient
retry. A missing lookup returns `404` with
`workflows.idempotency-key-not-found`; malformed keys return `400`. When the original start
failed before admitting a run, its key is released: the lookup returns 404 and the key can be
used again.
