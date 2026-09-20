# CanDoItAll Web API Contract Support

This non-discoverable support package contains the generated OpenAPI snapshot and shared
access guidance used by the CanDoItAll API skills.

## Current snapshot

- Artifact: [references/candoitall-web.openapi.json](references/candoitall-web.openapi.json)
- Provenance: [manifest.json](manifest.json)
- Source: CanDoItAll `development`, commit `32d296a92ce26c66bd539061fd2a8e3fe10cbaea`
- Source tree: `203460f864ae4b2e65b3377ebb5fcdb4eb863ce4`; working tree clean
- Dependency pins: Components `ff5289746573a6dd6456754a7764844627ddd49f` and FileTools `3a080ecd31068a77c1e1bd639f7a78e21c93db85`, both clean
- Capture: clean Release Docker publication, Development environment, InMemory database,
  private temporary roots and synthetic credentials, LinuxHeadless profile, McpToolHost worker policy
- Exposure: main API, OpenAPI, Swagger, JWT, user authentication and HTTP management enabled
- Document server: `http://localhost:5032/` inside an isolated container with no external network;
  the workstation's existing operator hosts and publisher/client test pair were not changed
- Runtime endpoints: `/openapi/v1.json` and `/swagger/v1/swagger.json`
- Captured UTC: `2026-09-20T19:13:26.683676Z`
- OpenAPI: `3.1.1`; **305 paths, 342 operations, 997 schemas**
- SHA-256: `C7DA97AC7C0EA73CBEF1AAE47E6E03A6CF24C550CAFA2C893A1E6DA06C501A3A`

Both anonymous document requests returned byte-identical 3,881,813-byte content. The same
publication was checked on a free Windows loopback port with the WindowsHeadless profile;
the document differs only in `servers`. The manifest records that comparison's hash and
capture address. Port identity is not source identity; the commit and dependency pins
identify the published contract.

| Route family | Paths | Operations |
| --- | ---: | ---: |
| /_dev | 10 | 10 |
| /api/access | 11 | 15 |
| /api/agent-recruiting | 6 | 6 |
| /api/agents | 62 | 75 |
| /api/crm-hr | 15 | 19 |
| /api/llm-chat-operations | 4 | 4 |
| /api/llm-chats | 8 | 10 |
| /api/llm-conversations | 6 | 6 |
| /api/memory-providers | 4 | 5 |
| /api/plugins | 18 | 20 |
| /api/processes | 20 | 20 |
| /api/project-structure | 58 | 59 |
| /api/projects | 10 | 13 |
| /api/prompt-gallery | 10 | 11 |
| /api/runtime | 2 | 2 |
| /api/settings/workspace | 1 | 2 |
| /api/shared-providers | 5 | 5 |
| /api/storage-placement-recovery | 9 | 9 |
| /api/workflows | 41 | 46 |
| /authorized-files | 2 | 2 |
| /managed-files | 1 | 1 |
| /storage | 2 | 2 |

These families account for every path and operation. Development diagnostics are included;
Blazor pages and static assets are not API operations. The capture enables conditional
account/session routes and includes the HTTP bearer/JWT scheme with operation security
requirements. A differently configured deployment may expose fewer routes.

## Current API improvements

Compared with the previous snapshot at `3fb71dd5`, this contract adds 16 paths and 21
operations, removes or renames no operation, and includes the current security behavior.
The previous snapshot had 865 schemas; the current document has 997. The changes cover:

- user login, self-session reads/logout, account lifecycle, capability discovery and
  administrator-only machine/session registration management;
- section-level read/write/execute capabilities while retaining existing exact policies;
- process-definition catalog/detail/role/step reads;
- workflow-template discovery and draft creation;
- workspace business settings with explicit committed-write/read-back handling;
- safe API errors, current stream revalidation, and anonymous Swagger/OpenAPI discovery.

The security changes from `b82ffc57` are included: caller-owned workflow idempotency,
withheld launch origin, protected runtime reads, bounded external agent context and
caller-filtered analytics. Use the
[partner migration matrix](references/partner-api-migration.md) for the client changes.

Thirteen documented operation sets are checked against the snapshot and skill appendices,
including API Access and Workspace Settings. The main host's Memory-provider API remains
experimental; it does not expose a native Cognitive Memory compatibility family.

## Access and usage

Read [access, sessions and capabilities](references/access-and-authentication.md) before
choosing credentials or interpreting disabled surfaces. OpenAPI documents and Swagger UI
are anonymous when enabled. `Api:SwaggerUiEnabled=false` disables only the UI;
`Api:OpenApiEnabled=false` disables both documents and UI. Use HTTPS Swagger **Authorize**
with a raw JWT to invoke protected operations. API capability checks still apply.

Use the snapshot when the target matches the recorded commit and exposure configuration.
Otherwise its live document is authoritative. Never infer HTTP administration from `api`,
legacy `api.tokens.issue`, a claimed role or an administrator-looking subject.

The installer includes underscore support packages by default. For an exact API-skill
subset, include `_candoitall-api-shared` with the desired skill packages.

## Refresh

1. Build the intended clean product commit and record dependency pins. Use a Release
   publication (`UseAppHost=false`), not development build output with machine-specific
   static-asset paths.
2. Start an isolated Development capture host on canonical `http://localhost:5032` with
   the exposure settings above, private temporary state and synthetic credentials. Use
   the supported headless profile for the current OS and `CanDoItAllMcpLaneKind=McpToolHost`.
   If the workstation port is occupied, use a network-none container with that URL in its
   own namespace; disposable readers can join that namespace. Do not change operator hosts
   or relabel a capture from another port.
3. Fetch both document routes anonymously and compare their bytes. Check the same
   publication on a free Windows loopback port; allow only the `servers` difference.
4. Replace the generated artifact. Update source/configuration provenance, hashes, counts,
   route families, documented operation sets, related skill appendices and migration guidance.
   Never include passwords, hashes, signing keys, JWTs or private instance data.
5. If the user authorized publishing before commit, record the baseline commit and branch,
   `workingTreeClean: false`, a status fingerprint and a prominent limitation note.
6. Run the OpenAPI validator, SharedInfo validator and the current Codex skill validator
   for changed skills. Preview an exact package installation before refreshing installed copies.

```powershell
.\tools\validation\Test-CanDoItAllWebOpenApi.ps1
.\tools\validation\Test-SharedInfo.ps1
```
