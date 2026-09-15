# CanDoItAll Web API Contract Support

This non-discoverable support package contains the shared OpenAPI snapshot used by the CanDoItAll API skills.

## Current Snapshot

- Artifact: [references/candoitall-web.openapi.json](references/candoitall-web.openapi.json)
- Provenance: [manifest.json](manifest.json)
- Source repository: CanDoItAll
- Source branch: modules-decoupling (pre-merge branch contract; not yet integrated into components-decoupling, development or main)
- Source commit: 160616c8256594257d00612b4e7dbadd567c024e (signed closure head of the module-decoupling refactor)
- Source state: clean working tree; workingTreeClean: true
- Dependency pins: CanDoItAll.Components 7b618cdac5570e806832e3f5ff65ddf1439eb868 (tree 35a4d090, identical to the repaired worktree 780e9a30 that built the candidate), CanDoItAll.FileTools 498b36825bd5a5222429972af120b04becf4b3f6
- Capture host: the audited candidate publication `C:/mdo-qa-160616c8` (app manifest SHA-256 5424d906…, Web assembly SHA-256 73506915…) started as an isolated Development host with the InMemory database provider and private workspace/control-plane roots, bound to the canonical localhost:5032 while that port was free; the operator's Production hosts were not used and no development-only endpoint was enabled on them
- Document server: http://localhost:5032/
- Runtime endpoints: /openapi/v1.json and /swagger/v1/swagger.json
- OpenAPI version: 3.1.1
- Paths: 289
- Operations: 321
- Component schemas: 518
- SHA-256: 4A72044B333CA60F18139F5256910087E258D6488C5D3A395F50D68BFE0EF355

> Port identity is not source identity. The document's server URL is the capture host's loopback address, not the identity of the source; the manifest's commit, dependency pins and capture note identify the contract. A first capture of the same publication on the free loopback port 127.0.0.1:58992 produced the same document except for the servers entry (SHA-256 C419F169…); the canonical-port capture is the published artifact because the validator pins the canonical server URL.

Captured on 2026-09-15 (14:37 UTC). Both document endpoints returned byte-identical 1,053,750-byte content.

| Route family | Paths | Operations |
| --- | ---: | ---: |
| /_dev | 10 | 10 |
| /api/access | 2 | 2 |
| /api/agent-recruiting | 6 | 6 |
| /api/agents | 62 | 75 |
| /api/crm-hr | 15 | 19 |
| /api/llm-chat-operations | 4 | 4 |
| /api/llm-chats | 8 | 10 |
| /api/llm-conversations | 6 | 6 |
| /api/memory-providers | 4 | 5 |
| /api/plugins | 18 | 20 |
| /api/processes | 16 | 16 |
| /api/project-structure | 58 | 59 |
| /api/projects | 10 | 13 |
| /api/prompt-gallery | 10 | 11 |
| /api/runtime | 2 | 2 |
| /api/shared-providers | 5 | 5 |
| /api/storage-placement-recovery | 9 | 9 |
| /api/workflows | 39 | 44 |
| /authorized-files | 2 | 2 |
| /managed-files | 1 | 1 |
| /storage | 2 | 2 |

These families account for every path and operation. The Development document intentionally includes the /_dev surface. Blazor pages and static files are not API operations. Production hosts with `Api:Authorization:Enabled` require a bearer token on the two document endpoints as well; the isolated capture host used the default configuration without authorization.

Delta from the 2026-08-31 snapshot (commit aadd9531, 276 paths / 308 operations / 486 schemas): additive only. No route, method or operation id was removed or renamed. Added operations: `POST /api/agents/execution-runs/{executionRunId}/recover` (supported same-run recovery of a retained run under current authority), `POST /api/agents/execution-runs/{executionRunId}/reconcile-cancellation` (typed reconciliation of a cancelled run's tool effects), `POST /api/agents/providers/mutations/verify` (idempotent provider-mutation verification), `GET /api/processes/launch/{admissionId}` (prepared-launch status by admission id) and the nine-operation `/api/storage-placement-recovery` family (context, pending intents, pending owner continuations, intent detail and owner continuation, reconcile, reconcile cancelled run receipts, verify external termination, continue workflow asset). Thirty-two schemas were added (agent cancellation and committed-effect responses, tool effect/outcome/dispatch enums, provider mutation and verification responses, storage placement recovery commands and intents, `ProjectWriteAdmission`, `ProjectProcessAssetReceipt`, `WorkflowLaunchObservation`) and fifteen existing schemas gained fields, chiefly the Project Structure task and node inputs (execution-state and expected-cost snapshots, deletion dispositions), `ProjectStructureReadResponse`, `ProcessLaunchApiRequest`, `WorkflowRunStartApiResponse` and the provider editor models. Twenty operations changed only through those schemas; their routes, methods and operation ids are unchanged.

Complete documented operation sets cover Agents, Agent Recruiting, Memory Providers, Processes, Projects, Project Structure, Workflows, Shared Providers, LLM Chat Definitions, Conversations and Operations. Validation compares every recorded set and skill route appendix against this single generated document.

The main host exposes the experimental provider-neutral /api/memory-providers surface. Native Cognitive Memory remains separate; no /api/cognitive-memory compatibility family is exposed. Simple Chats remain distinct from governed agent chat sessions and execution runs.

Use the [partner API migration matrix](references/partner-api-migration.md) for integrations using superseded workarounds.

## Usage

Use the snapshot for exact routes, operation identifiers, parameters, and published
request/response schemas when working against the source commit recorded in the
manifest. When the target host differs, its live `/openapi/v1.json` or
`/swagger/v1/swagger.json` document is authoritative.

The normal skills installer includes this underscore support package. When installing an
exact API-skill subset with `-PackageName`, include `_candoitall-api-shared`.

## Refresh

1. Generate the document by running a clean build (or the audited publication) of the
   main `CanDoItAll.Web` project as a Development host on the canonical URL,
   `http://localhost:5032`. When that port belongs to a protected operator host, start
   an isolated Development capture host of the same build on a free loopback port
   instead (InMemory database, private workspace and control-plane roots) and record
   the actual capture URL; never enable development endpoints on the operator's
   Production host, and never capture from an unrelated older host merely because it
   owns port 5032. The validator pins the canonical server URL, so a capture on another
   port must be repeated on `localhost:5032` once it is free, or the validator's server
   rule must be updated together with the manifest in the same reviewed change.
2. Capture `/openapi/v1.json` and `/swagger/v1/swagger.json` and verify they are identical.
3. Replace the artifact and update all provenance, hash, version, and count fields in
   `manifest.json`.
4. Update API-skill route guidance when the runtime contract changed.
5. If publication is authorized before the product changes are committed, record
   `workingTreeClean: false`, the baseline commit, a working-tree status fingerprint,
   and a prominent limitation note. Do not claim commit-clean provenance.
6. Run:

```powershell
.\tools\validation\Test-CanDoItAllWebOpenApi.ps1
.\tools\validation\Test-SharedInfo.ps1
```
