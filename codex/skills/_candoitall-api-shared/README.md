# CanDoItAll Web API Contract Support

This non-discoverable support package contains the generated OpenAPI snapshot and shared
access guidance used by the CanDoItAll API skills.

## Current snapshot

- Artifact: [references/candoitall-web.openapi.json](references/candoitall-web.openapi.json)
- Provenance: [manifest.json](manifest.json)
- Source: CanDoItAll `demos-repairs`, commit `a59e3af7dcba28b7c0bf4a7450898d468a7d6fc3`
- Source tree: `e156b5248cc87f9ea9e91c090a19ab3ee048610f`; working tree clean
- Dependency pins: Components `a3fd4d22f2c4e0432cf389f194c6468b44ab7371` and FileTools
  `3a080ecd31068a77c1e1bd639f7a78e21c93db85`, both clean
- Capture: exact signed-source Release Docker publication, Development environment,
  InMemory synthetic state/credentials, LinuxHeadless profile and McpToolHost worker policy
- Exposure: main API, OpenAPI, Swagger, JWT, user authentication and HTTP management enabled
- Document server: `http://localhost:5032/` inside an isolated container with no network
  or published ports; existing operator and demo hosts were not reconfigured
- Runtime endpoints: `/openapi/v1.json` and `/swagger/v1/swagger.json`
- Captured UTC: 2026-10-07T19:08:54Z
- OpenAPI: `3.1.1`; **308 paths, 345 operations, 1,015 schemas**
- SHA-256: `9A3540D43D854E7AAE019E6D8122B27B85C476E2B90F9A58F211B3604C5079C1`

Both anonymous document requests returned byte-identical 3,923,256-byte content.
The artifact contains those unmodified bytes. The same publication was checked with
WindowsHeadless on free loopback port 5542; both Windows document routes agree and the
Linux/Windows documents differ only in `servers`. Its SHA-256 is
`73267766EE7505D20340FA0678AE7ADE36CFFFFEB11E11C09DCD005FDB7227C8`.
The manifest also identifies the image and the live voice-verified deployment at port
5532, whose user login and account management remain disabled. Port identity is not
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
Blazor pages and static assets are not API operations. Conditional account/session routes
and operation bearer requirements are present. A differently configured deployment may
expose fewer routes.

## Current API improvements

Compared with the previous September snapshot, this document adds three paths and three
operations and removes no operation. Two new public voice routes provide bounded audio
transcription and speech synthesis using existing workspace settings, execute authority,
native-provider capability checks and safe errors. See the
[voice client contract](../candoitall-api-agents/references/voice-api.md).
The snapshot also includes the existing `/api/agents/usage` summary route. Its schema
count changes from 997 to 1,015; regenerate clients against the new artifact.

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
