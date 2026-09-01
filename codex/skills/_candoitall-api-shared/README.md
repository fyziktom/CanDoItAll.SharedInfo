# CanDoItAll Web API Contract Support

This non-discoverable support package contains the shared OpenAPI snapshot used by the CanDoItAll API skills.

## Current Snapshot

- Artifact: [references/candoitall-web.openapi.json](references/candoitall-web.openapi.json)
- Provenance: [manifest.json](manifest.json)
- Source repository: CanDoItAll
- Source branch: providers-shared
- Baseline source commit: aadd953150e7f659e4060ced6505621c705ea61f
- Source state: committed provider/history repairs plus uncommitted finishing changes; workingTreeClean: false
- Document server: http://localhost:5032/
- Runtime endpoints: /openapi/v1.json and /swagger/v1/swagger.json
- OpenAPI version: 3.1.1
- Paths: 276
- Operations: 308
- Component schemas: 486
- SHA-256: 14FE4C527863FF84948ED96D3D7A3B16FD46D3E315E673E96EEF3911C3D2A52B

> Provenance limitation: the commit identifies the baseline. Product SB09 finishing proof records the uncommitted changes and identified Release host. The manifest records the capture-time working-tree fingerprint. No automatic commit was made.

Captured on 2026-08-31 from the rebuilt Release host at canonical port 5032. Both document endpoints returned byte-identical 963,289-byte content. The normal HTTP launch profile and existing runtime data were preserved.

| Route family | Paths | Operations |
| --- | ---: | ---: |
| /_dev | 10 | 10 |
| /api/access | 2 | 2 |
| /api/agent-recruiting | 6 | 6 |
| /api/agents | 59 | 72 |
| /api/crm-hr | 15 | 19 |
| /api/llm-conversations | 6 | 6 |
| /api/llm-chat-operations | 4 | 4 |
| /api/llm-chats | 8 | 10 |
| /api/memory-providers | 4 | 5 |
| /api/plugins | 18 | 20 |
| /api/processes | 15 | 15 |
| /api/project-structure | 58 | 59 |
| /api/projects | 10 | 13 |
| /api/prompt-gallery | 10 | 11 |
| /api/runtime | 2 | 2 |
| /api/shared-providers | 5 | 5 |
| /api/workflows | 39 | 44 |
| /authorized-files | 2 | 2 |
| /managed-files | 1 | 1 |
| /storage | 2 | 2 |

These families account for every path and operation. The Development document intentionally includes the /_dev surface. Blazor pages and static files are not API operations.

This capture adds the five shared-provider operations and current workflow route drift to the August 18 snapshot. Shared-provider request schemas, qualified component identities, identifiers and enum wire values reflect the generated contract. Provider-history browsing and provider source/publication management remain UI/application-service surfaces; no public history or source CRUD API is implied.

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

1. Generate the document by running a clean build of the main `CanDoItAll.Web` project
   on its canonical development URL, `http://localhost:5032`.
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
