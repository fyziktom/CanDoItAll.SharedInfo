# CanDoItAll Web API Contract Support

This non-discoverable support package contains the shared OpenAPI snapshot used by the
CanDoItAll API skills.

## Current Snapshot

- Artifact: [`references/candoitall-web.openapi.json`](references/candoitall-web.openapi.json)
- Provenance: [`manifest.json`](manifest.json)
- Source repository: `CanDoItAll`
- Source branch: `apis-sse`
- Baseline source commit: `563636f944e76e777356ae2a5fec4ad66c997fd2`
- Source state: uncommitted working tree; `workingTreeClean: false`
- Document server: `http://localhost:5032/`
- Runtime endpoints: `/openapi/v1.json` and `/swagger/v1/swagger.json`
- OpenAPI version: `3.1.1`
- Paths: `244`
- Operations: `274`
- Component schemas: `381`
- SHA-256:
  `77B03745B16C3E8B3EF490C4D5817083FABD20C9320CF1DF01E2107DF47C699F`

The snapshot was captured from a rebuilt Development host on the canonical 5032 URL.
Both runtime document endpoints returned byte-identical 488,398-byte content. The
product source was not committed at capture time, so the baseline commit and a
working-tree status fingerprint are recorded in the manifest; this is deliberately
not represented as commit-clean provenance.

| Route family | Paths | Operations |
| --- | ---: | ---: |
| `/_dev` | 10 | 10 |
| `/api/access` | 2 | 2 |
| `/api/agent-recruiting` | 6 | 6 |
| `/api/agents` | 59 | 72 |
| `/api/memory-providers` | 4 | 5 |
| `/api/crm-hr` | 15 | 19 |
| `/api/plugins` | 18 | 20 |
| `/api/processes` | 15 | 15 |
| `/api/projects` | 7 | 10 |
| `/api/project-structure` | 55 | 56 |
| `/api/prompt-gallery` | 10 | 11 |
| `/api/workflows` | 38 | 43 |
| `/authorized-files` | 2 | 2 |
| `/managed-files` | 1 | 1 |
| `/storage` | 2 | 2 |

These families account for every path and operation in the document. The Development
document intentionally includes the `/_dev` surface. Static files, Blazor routes, and
other non-API application routes are not OpenAPI operations.

The manifest records complete Agents, Agent Recruiting, Memory Providers, Processes,
and Workflows operation sets, including operation identifiers. Validation compares
every set with the generated document and its skill route appendix so these API and
skill contracts cannot drift silently.

The main host now exposes only the experimental, provider-neutral
`/api/memory-providers` surface for profile configuration, context queries, and
caller-owned operation status. Native Cognitive Memory belongs to the separate
`CanDoItAll.CognitiveMemory` repository, which remains WIP and unpublished; the main
host does not expose a `/api/cognitive-memory` compatibility family.

Relative to the preceding artifact, this snapshot adds bounded SSE contracts for
agent activity and same-request commands, provider completion status, workflow run
signals, and process run signals. It also adds bounded image attachment staging,
global agent approval readback, caller-supplied activity-operation correlation, and
configurable Swagger UI. Workflow and process streams support global or exact-run
subscriptions; their cursors are bounded and host-local, so canonical detail/history
routes remain the source of truth after a replay gap or process restart.

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
