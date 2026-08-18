# CanDoItAll Web API Contract Support

This non-discoverable support package contains the shared OpenAPI snapshot used by the
CanDoItAll API skills.

## Current Snapshot

- Artifact: [`references/candoitall-web.openapi.json`](references/candoitall-web.openapi.json)
- Provenance: [`manifest.json`](manifest.json)
- Source repository: `CanDoItAll`
- Source branch: `simple-chats`
- Baseline source commit: `827fa425c30404ab910a363962d00fd1479f87c1`
- Source state: uncommitted merge-preparation tree; `workingTreeClean: false`
- Document server: `http://localhost:5032/`
- Runtime endpoints: `/openapi/v1.json` and `/swagger/v1/swagger.json`
- OpenAPI version: `3.1.1`
- Paths: `270`
- Operations: `302`
- Component schemas: `467`
- SHA-256:
  `376E5EA35D4C5FF99FEDC32012E67F18033F54245C10CE0C054FF0FAE997B797`

> **Provenance limitation:** this is a merge-preparation capture from an uncommitted product
> working tree. The commit above is the baseline, not a commit-clean artifact identity. Use the
> manifest's working-tree status fingerprint to verify the exact source state until the product changes
> are committed and the snapshot is recaptured.

The snapshot was captured from a Debug build because pre-existing `CanDoItAll.Web` processes locked the
normal Release output. Repository-local runtime roots and the configured Development PostgreSQL profile
served the canonical 5032 URL. Both runtime document endpoints returned byte-identical 817,035-byte
content. An earlier clean Release baseline build passed before the Swagger description edits.

| Route family | Paths | Operations |
| --- | ---: | ---: |
| `/_dev` | 10 | 10 |
| `/api/access` | 2 | 2 |
| `/api/agent-recruiting` | 6 | 6 |
| `/api/agents` | 59 | 72 |
| `/api/llm-chats` | 8 | 10 |
| `/api/llm-conversations` | 6 | 6 |
| `/api/llm-chat-operations` | 4 | 4 |
| `/api/memory-providers` | 4 | 5 |
| `/api/crm-hr` | 15 | 19 |
| `/api/plugins` | 18 | 20 |
| `/api/processes` | 15 | 15 |
| `/api/projects` | 10 | 13 |
| `/api/project-structure` | 58 | 59 |
| `/api/prompt-gallery` | 10 | 11 |
| `/api/runtime` | 2 | 2 |
| `/api/workflows` | 38 | 43 |
| `/authorized-files` | 2 | 2 |
| `/managed-files` | 1 | 1 |
| `/storage` | 2 | 2 |

These families account for every path and operation in the document. The Development
document intentionally includes the `/_dev` surface. Static files, Blazor routes, and
other non-API application routes are not OpenAPI operations.

The manifest records complete LLM Chat Definitions, Conversations, and Operations sets alongside
Agents, Agent Recruiting, Memory Providers, Processes, Projects, Project Structure, and Workflows,
including operation identifiers. Validation compares every set with the generated document and its
skill route appendix so these API and skill contracts cannot drift silently.

The main host now exposes only the experimental, provider-neutral
`/api/memory-providers` surface for profile configuration, context queries, and
caller-owned operation status. Native Cognitive Memory belongs to the separate
`CanDoItAll.CognitiveMemory` repository, which remains WIP and unpublished; the main
host does not expose a `/api/cognitive-memory` compatibility family.

Relative to the preceding artifact, this snapshot adds the complete provider-neutral Simple Chats API:
definition lifecycle and editor contracts, conversation and transcript paging, retry-safe durable turn
admission, operation status, replayable SSE, cancellation, reconciliation, and exact abandon recovery.
Every Simple Chats operation now publishes a non-empty Swagger description. The snapshot also adds the
runtime capability and bounded operation-readiness routes. Simple Chats remain distinct from governed
agent chat sessions and agent execution runs.

Use the [partner API migration matrix](references/partner-api-migration.md) when upgrading
an integration that still uses the superseded partner-side workarounds.

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
