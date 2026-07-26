# CanDoItAll Web API Contract Support

This non-discoverable support package contains the shared OpenAPI snapshot used by the
CanDoItAll API skills.

## Current Snapshot

- Artifact: [`references/candoitall-web.openapi.json`](references/candoitall-web.openapi.json)
- Provenance: [`manifest.json`](manifest.json)
- Source repository: `CanDoItAll`
- Source branch: `apis-improvements`
- Source commit: `75ea79252a3c3d442e7a404f619f167c4b3edfcf`
- Source state: committed and clean; `workingTreeClean: true`
- Document server: `http://localhost:5032/`
- Runtime endpoints: `/openapi/v1.json` and `/swagger/v1/swagger.json`
- OpenAPI version: `3.1.1`
- Paths: `229`
- Operations: `274`
- Component schemas: `342`
- SHA-256:
  `A5D9EE04B93A5913CB3AF7004B1F91F7F85A6639CF911F2BA2258316C778B51C`

The snapshot was captured from the clean source commit in the Development environment
with isolated runtime storage and in-memory infrastructure. Both runtime document
endpoints returned byte-identical content, and the result was byte-identical to the
earlier working-tree capture.

| Route family | Paths | Operations |
| --- | ---: | ---: |
| `/_dev` | 10 | 10 |
| `/api/access` | 2 | 2 |
| `/api/agent-recruiting` | 5 | 5 |
| `/api/agents` | 51 | 64 |
| `/api/cognitive-memory` | 6 | 22 |
| `/api/crm-hr` | 15 | 19 |
| `/api/plugins` | 18 | 20 |
| `/api/processes` | 9 | 9 |
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

This snapshot adds remote package import, external-key agent provisioning, portable JSON
Schema output schemas, stable workflow lookup, workflow launch idempotency evidence,
typed OpenAPI response/error schemas, and agent recruiting evidence. The four durable
process snapshot routes published by the prior `processes-snapshots` artifact are not
present on this branch; the Processes skill now fails closed unless a target host's live
contract reintroduces them.

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
