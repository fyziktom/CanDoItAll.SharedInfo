# CanDoItAll Web API Contract Support

This non-discoverable support package contains the generated OpenAPI snapshot and shared
access guidance used by the CanDoItAll API skills.

## Current snapshot

- Artifact: [references/candoitall-web.openapi.json](references/candoitall-web.openapi.json)
- Provenance: [manifest.json](manifest.json)
- Source: CanDoItAll `demos-repairs`, commit `e09d18f9a99186740095fdf2817b0bc12464f07c`
- Source tree: `1cfd63991d9135157f00a50d571280db553e9d8b`; working tree clean
- Dependency pins: Components `a3fd4d22f2c4e0432cf389f194c6468b44ab7371` and FileTools
  `3a080ecd31068a77c1e1bd639f7a78e21c93db85`, both clean
- Capture: exact signed-source Release Docker publication, Development environment,
  InMemory synthetic state/credentials, LinuxHeadless profile and McpToolHost worker policy
- Exposure: main API, OpenAPI, Swagger, JWT, user authentication and HTTP management enabled
- Document server: `http://localhost:5032/` inside an isolated container with no network
  or published ports; existing operator and demo hosts were not reconfigured
- Runtime endpoints: `/openapi/v1.json` and `/swagger/v1/swagger.json`
- Captured UTC: 2026-10-07T19:48:11Z
- OpenAPI: `3.1.1`; **309 paths, 346 operations, 1,016 schemas**
- SHA-256: `0B1C79FC23E0F21D66CA55F406D3A9791BF190D575E031098C5CF2228B986FA5`

Both anonymous document requests returned byte-identical 3,927,847-byte content.
The artifact contains those unmodified bytes. The same publication was checked with
WindowsHeadless on free loopback port 5542; both Windows document routes agree and the
Linux/Windows documents differ only in `servers`. Its SHA-256 is
`5B16714F03CD40DF34FC0EF90444DA395FB02A2F8DEB0E33AA6E77446EA6A827`.
The manifest also identifies the image and its 13 live synthetic identity checks at port
5532, whose user login and account management remain disabled. It retains voice round-trip
proof with the earlier T07 commit explicitly identified; T08 leaves voice code unchanged. Port identity is not
source identity; the commit, configuration and dependency pins identify the contract.

| Route family | Paths | Operations |
| --- | ---: | ---: |
| /_dev | 10 | 10 |
| /api/access | 11 | 15 |
| /api/agent-recruiting | 6 | 6 |
| /api/agents | 65 | 78 |
| /api/crm-hr | 15 | 19 |
| /api/llm-chat-operations | 4 | 4 |
| /api/llm-chats | 8 | 10 |
| /api/llm-conversations | 6 | 6 |
| /api/memory-providers | 4 | 5 |
| /api/plugins | 18 | 20 |
| /api/processes | 20 | 20 |
| /api/project-structure | 58 | 59 |
| /api/projects | 11 | 14 |
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
Blazor pages and static assets are not API operations. Conditional account/session routes
and operation bearer requirements are present. A differently configured deployment may
expose fewer routes.

## Current API improvements

Compared with the previous September snapshot, this document adds four paths and four
operations and removes no operation. Two new public voice routes provide bounded audio
transcription and speech synthesis using existing workspace settings, execute authority,
native-provider capability checks and safe errors. See the
[voice client contract](../candoitall-api-agents/references/voice-api.md).
The snapshot also includes the existing `/api/agents/usage` summary route. Its schema
count changes from 997 to 1,016; regenerate clients against the new artifact.

The latest additive route resolves projects by an immutable external namespace/key pair,
with lifetime checks and explicit conflicts. Existing project editors may omit the new
fields without losing a stored identity. See the
[project identity contract](../candoitall-api-project-structure/references/project-external-identity.md).

The prior access/session, workspace-settings, workflow/process, stable provisioning and
request-history contracts remain included. Thirteen documented operation sets are
checked against the snapshot and skill appendices. The main host's Memory-provider API
remains experimental; it does not expose a native Cognitive Memory compatibility family.

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
