# CanDoItAll Web API Contract Support

This non-discoverable support package contains the shared OpenAPI snapshot used by the
CanDoItAll API skills.

## Current Snapshot

- Artifact: [`references/candoitall-web.openapi.json`](references/candoitall-web.openapi.json)
- Provenance: [`manifest.json`](manifest.json)
- Source repository: `CanDoItAll`
- Source branch: `agents-loading-refactor`
- Baseline source commit: `6e866ab531808758c268bc460ce2c997f2ae8440`
- Source state: uncommitted working tree; `workingTreeClean: false`
- Document server: `http://localhost:5032/`
- Runtime endpoints: `/openapi/v1.json` and `/swagger/v1/swagger.json`
- OpenAPI version: `3.1.1`
- Paths: `234`
- Operations: `279`
- Component schemas: `347`
- SHA-256:
  `BD1F0B297956E4CEB176AA183FE283BB481D20CD686CAF075B52881BD7E92AEC`

The snapshot was captured from a rebuilt Development host on the canonical 5032 URL.
Both runtime document endpoints returned byte-identical 438,706-byte content. The
product source was not committed at capture time, so the baseline commit and a
working-tree status fingerprint are recorded in the manifest; this is deliberately
not represented as commit-clean provenance.

| Route family | Paths | Operations |
| --- | ---: | ---: |
| `/_dev` | 10 | 10 |
| `/api/access` | 2 | 2 |
| `/api/agent-recruiting` | 6 | 6 |
| `/api/agents` | 51 | 64 |
| `/api/cognitive-memory` | 6 | 22 |
| `/api/crm-hr` | 15 | 19 |
| `/api/plugins` | 18 | 20 |
| `/api/processes` | 13 | 13 |
| `/api/projects` | 7 | 10 |
| `/api/project-structure` | 55 | 56 |
| `/api/prompt-gallery` | 10 | 11 |
| `/api/workflows` | 36 | 41 |
| `/authorized-files` | 2 | 2 |
| `/managed-files` | 1 | 1 |
| `/storage` | 2 | 2 |

These families account for every path and operation in the document. The Development
document intentionally includes the `/_dev` surface. Static files, Blazor routes, and
other non-API application routes are not OpenAPI operations.

The manifest records complete Agents, Agent Recruiting, Processes, and Workflows
operation sets, including operation identifiers. Validation compares every set with the
generated document and its skill route appendix so these API and skill contracts cannot
drift silently.

The base-host Cognitive Memory surface is currently retired. Its documented routes
provide the contract response and `410 Gone` migration guidance; the former ingestion,
recall, and consolidation surface is not live in this source commit.

Relative to the preceding artifact, this snapshot adds typed
`AgentExecutionOperationId` and `ProjectStructureReadSource` schemas, candidate
interview listing and assessment schemas, and four durable process-record routes:
list, summary, graph, and analytics. The run operation identifier is durable
correlation metadata; the current contract does not publish an agent-activity polling
or SSE endpoint. Project Structure HTTP reads remain canonical: invocation-local
snapshots are available only to the in-process runtime tool and are rejected by the
HTTP boundary.

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
