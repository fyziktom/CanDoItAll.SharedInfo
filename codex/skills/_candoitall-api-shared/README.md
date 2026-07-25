# CanDoItAll Web API Contract Support

This non-discoverable support package contains the shared OpenAPI snapshot used by the
CanDoItAll API skills.

## Current Snapshot

- Artifact: [`references/candoitall-web.openapi.json`](references/candoitall-web.openapi.json)
- Provenance: [`manifest.json`](manifest.json)
- Source repository: `CanDoItAll`
- Source branch: `processes-snapshots`
- Source commit: `065f31e0b527bcda2d499daf39e8a901e0231323`
- Document server: `http://localhost:5032/`
- Runtime endpoints: `/openapi/v1.json` and `/swagger/v1/swagger.json`
- OpenAPI version: `3.1.1`
- Paths: `223`
- Operations: `266`
- Component schemas: `258`
- SHA-256:
  `324A90A694B67FF341AE951FCEE6C5447B58D0E603268EF78250E7554C2C2118`

The snapshot was captured from a clean build of the source commit in the Development
environment. Both runtime document endpoints returned byte-identical content.

| Route family | Paths | Operations |
| --- | ---: | ---: |
| `/_dev` | 10 | 10 |
| `/api/access` | 2 | 2 |
| `/api/agents` | 49 | 60 |
| `/api/cognitive-memory` | 6 | 22 |
| `/api/crm-hr` | 15 | 19 |
| `/api/plugins` | 18 | 20 |
| `/api/processes` | 13 | 13 |
| `/api/projects` | 7 | 10 |
| `/api/project-structure` | 55 | 56 |
| `/api/prompt-gallery` | 10 | 11 |
| `/api/workflows` | 33 | 38 |
| `/authorized-files` | 2 | 2 |
| `/managed-files` | 1 | 1 |
| `/storage` | 2 | 2 |

These families account for every path and operation in the document. The Development
document intentionally includes the `/_dev` surface. Static files, Blazor routes, and
other non-API application routes are not OpenAPI operations.

The manifest also records the complete Processes operation set, including operation
identifiers. Validation compares that set with both the generated document and the
Processes skill route appendix so process API and skill changes cannot drift silently.

The base-host Cognitive Memory surface is currently retired. Its documented routes
provide the contract response and `410 Gone` migration guidance; the former ingestion,
recall, and consolidation surface is not live in this source commit.

This snapshot adds the durable process-run record list, summary, graph, and analytics
operations from the `processes-snapshots` branch. The current Minimal API metadata
describes their query parameters but does not publish their response schemas or
`400`/`404` responses. Use the Processes API skill's
[durable run-record reference](../candoitall-api-processes/references/durable-run-records.md)
for the source-backed response fields, bounds, status values, and error contract.

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
5. Run:

```powershell
.\tools\validation\Test-CanDoItAllWebOpenApi.ps1
.\tools\validation\Test-SharedInfo.ps1
```
