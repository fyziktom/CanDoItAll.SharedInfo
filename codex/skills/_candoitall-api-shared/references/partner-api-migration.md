# Partner API Migration Matrix

Use this matrix when upgrading a partner adapter from the contract captured before
CanDoItAll commit `75ea79252a3c3d442e7a404f619f167c4b3edfcf`. Confirm every route
and schema against the target host's live OpenAPI document before changing production
traffic.

| Superseded integration behavior | Current contract | Required migration |
| --- | --- | --- |
| Send a server-local `packagePath` to `POST /api/agents/import` | `POST /api/agents/import-package` accepts a bounded multipart ZIP | Upload `package`, send import mode and stable external identity, require `Idempotency-Key`, and verify the receipt hashes and prerequisites |
| List agents and reject or select by display name | `GET`, `PUT`, and `DELETE /api/agents/by-external-key/{externalNamespace}/{key}` | Assign a workspace-local namespace/key, retain `ETag`, send `If-Match` on updates/archive, and use a distinct idempotency key per logical mutation |
| Pass runtime `.NET Type` metadata or request JSON only through prompt text | Agent execution accepts `AgentJsonSchemaOutputContract` | Send `kind: json-schema`, version, name, schema, and strictness; validate the returned status, canonical schema hash, parsed data, and raw output |
| Enumerate workflows and match an exact display name | Stable template/external-key lookup endpoints return `WorkflowStableIdentityResolution` | Require `status: Resolved`, persist `workflowId`, and pin `runnableVersionId`; fail closed for `NotFound`, `Ambiguous`, or `Stale` |
| Use a partner ledger as the only workflow retry guard | Both workflow start routes accept `Idempotency-Key` and expose lookup evidence | Reuse one key only for the identical workflow/version/backend/canonical input; treat changed-content `409` as terminal and query `/runs/by-idempotency-key/{key}` after an uncertain response |
| Store all AI-agent evaluation lineage only in a partner scorecard or CRM-HR feedback | `/api/agent-recruiting` owns typed interviews, attempts, reviews, comparison, and readiness | Create an interview for the exact candidate configuration, append typed terminal-run evidence and a human review, then read readiness; keep CRM-HR people/applications separate |
| Infer response or error bodies from prose | OpenAPI publishes typed success and `ApiErrorResponse` schemas | Regenerate the client, preserve `errors[].code`, and add negative tests for `400`, `401`, `403`, `404`, `409`, and `412` as applicable |

## Additive Delta (commit 160616c8, modules-decoupling)

The 2026-09-15 snapshot (289 paths, 321 operations, 518 schemas) removed or renamed
nothing relative to the 2026-08-31 snapshot (commit aadd9531). Adapters built against
the older contract keep working; the rows below are opportunities, not required
migrations.

| Superseded integration behavior | Current contract | Optional migration |
| --- | --- | --- |
| Re-launch a process when the launch response was lost | `GET /api/processes/launch/{admissionId}` returns the prepared-launch status | Persist the admission id from the launch routes and poll it instead of launching again |
| Re-run a retained agent run after a host restart or a cancelled tool call | `POST /api/agents/execution-runs/{executionRunId}/recover` and `POST /api/agents/execution-runs/{executionRunId}/reconcile-cancellation` | Recover the same run under current authority; treat a recovery denial as terminal rather than retrying with a new run, and read the typed cancellation reconciliation instead of inferring committed effects |
| Repeat a provider create/update/delete after an uncertain response | `POST /api/agents/providers/mutations/verify` | Verify the earlier mutation attempt by its identity before repeating it |
| Inspect storage placement recovery only through host logs | `/api/storage-placement-recovery` (context, pending intents, owner continuations, reconcile, cancelled-run receipts, external-termination verification, workflow asset continuation) | Read pending intents and continuations through the typed family; the reconcile routes are owner-scoped operator actions, not partner automation |
| Send Project Structure task and node inputs from the August schemas | `ProjectStructureTaskCreateRequest`, task/node update requests and `ProjectStructureNodeSummary` gained execution-state, expected-cost and deletion-disposition fields; `ProcessLaunchApiRequest`, `WorkflowRunStartApiResponse` and the provider editor models also grew | Regenerate the typed client; the added fields are optional on input and additive on output, so older clients keep working but do not observe the recorded execution state or the cost snapshot |

## Upgrade Gate

Before removing a workaround:

1. Pin the target host commit and OpenAPI SHA-256.
2. Regenerate the typed client and run contract tests.
3. Migrate one stable partner identity in an isolated workspace.
4. Exercise an identical replay and a changed-content conflict.
5. Capture raw provisioning response headers and verify ETag plus missing/stale
   header behavior; the current OpenAPI does not fully model those runtime requirements.
6. Read back the canonical resource, run, or recruiting evidence.
7. Verify a denied authorization or invalid-reference case.
8. Remove the old name/path/ledger fallback so the adapter fails closed instead of
   silently switching identity models.

Do not migrate the four durable process snapshot routes from the historical
`processes-snapshots` branch. They are absent from this contract unless a target host's
live OpenAPI document explicitly publishes them.
