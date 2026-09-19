# CanDoItAll Web API Contract Support

This non-discoverable support package contains the shared OpenAPI snapshot used by the CanDoItAll API skills.

## Current Snapshot

- Artifact: [references/candoitall-web.openapi.json](references/candoitall-web.openapi.json)
- Provenance: [manifest.json](manifest.json)
- Source repository: CanDoItAll
- Source branch: development
- Source commit: 3fb71dd583f67f83efdda5f6076b522108eacff0 (signed; tree 9a9176f21a12c6e38022833bcc7463b0ac9238f6)
- Source state: the clean tree of that commit; workingTreeClean: true
- Dependency pins: CanDoItAll.Components ff5289746573a6dd6456754a7764844627ddd49f, CanDoItAll.FileTools 3a080ecd31068a77c1e1bd639f7a78e21c93db85 (both clean checkouts)
- Capture host: a clean Release publication of that tree (exported with `git checkout-index`, `UseAppHost=false`) started as an isolated Development host with the InMemory database provider, private workspace and control-plane roots and the Linux headless runtime profile, inside a container whose only network is its own loopback, bound to `http://localhost:5032` of that network namespace; the operator's host that owns localhost:5032 on Windows was not touched and no development-only endpoint was enabled on it
- Document server: http://localhost:5032/
- Runtime endpoints: /openapi/v1.json and /swagger/v1/swagger.json
- OpenAPI version: 3.1.1
- Paths: 289
- Operations: 321
- Component schemas: 865
- SHA-256: 95C566D15F21C036610DA2F37D174DB7A88FE095414A866DD58B276E8A806006

> Port identity is not source identity. The document's server URL is the capture host's loopback address, not the identity of the source; the manifest's commit, dependency pins and capture note identify the contract. A Windows capture of the same publication on the free loopback port 51813 produced the same document except for the servers entry (SHA-256 D31B41AA…); the container capture is the published artifact because its host genuinely served the canonical URL that the validator pins.

Captured on 2026-09-19 (17:41 UTC). Both document endpoints returned byte-identical 3,636,957-byte content.

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

Every operation, parameter, request body, response, component schema and property carries a description written from the owning code: 9,126 of 9,126 describable items under the rules of the product's coverage gate, including the enum values at every enum-typed member. The descriptions state identity sources, units, null, omitted and default meaning, preconditions, retry and idempotency rules, error codes and authority; the SharedInfo standard `docs/standards/api-documentation.md` and glossary `docs/architecture/candoitall-api-domain-glossary.md` govern their wording.

Delta from the 2026-09-15 snapshot (commit 160616c8, 289 paths / 321 operations / 518 schemas): no route, method or operation id was added, removed or renamed, and no runtime behavior changed. One request contract differs: `PUT /api/project-structure/projects/{projectId}/tasks/{taskId}` now binds `ProjectStructureTaskUpdateAgentInput` with plain string task identifiers, replacing `ProjectStructureTaskDetailsUpdateRequest`, `GanttTaskScheduleChangeRequest` and `GanttTaskDateChange` (see the partner migration matrix). The rest is metadata that now matches the runtime: 425 response statuses and 187 response bodies were declared with the types and envelopes the handlers write; 77 operations moved from the application-name tag to their family tag; the LLM Chat error responses changed media type from `application/json` to `application/problem+json` (50 responses); the non-streaming shared-provider inference responses gained their `application/json` body (2); 13 declared statuses that no code path produces were removed (recruiting review 409, pending-approval stream 404, reconcile-cancellation 500, provider save 500 and 503, provider delete and test 503, LLM provider-options 500, LLM send-turn 504, memory operation status 502 and 504, and the implicit 200 of the plugin OAuth callback, now 302, and of `/managed-files`, now 410); two error responses now reference the schema actually written (provider mutation verification 400, LLM operation event stream 400); the duplicated `agentId` path parameter of `GET /api/agents/{agentId}/execution-runs` was removed; the `default` of the shared `PluginGrantRiskKind`, `PluginGrantScopeKind` and `ProjectStatus` enum components was dropped because their uses disagree (each use states its default). 350 schemas were added, chiefly the newly declared response types.

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
   `http://localhost:5032`. When that port belongs to a protected operator host, run an
   isolated Development capture host of the same publication (`UseAppHost=false`,
   InMemory database, private workspace and control-plane roots, Linux headless runtime
   profile) in a container started with `--network none` and
   `ASPNETCORE_URLS=http://localhost:5032`, and fetch both document paths from a second
   container that joins its network namespace (`--network container:<name>`). A plain
   build output does not start in a container (its development static-asset manifest
   holds Windows paths); use a publication. Also capture the same publication on a free
   loopback port of the workstation and confirm that the two documents differ only in
   the servers entry. Never enable development endpoints on the operator's Production
   host, and never capture from an unrelated older host merely because it owns port
   5032. The validator pins the canonical server URL; do not relabel a capture from
   another port.
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
