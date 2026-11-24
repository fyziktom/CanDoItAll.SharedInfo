# CanDoItAll Web API Contract Support

This support package contains the generated OpenAPI snapshot and common access guidance
for the API skills. Use the live document when a target host has a different version.

## Current snapshot

- [Unmodified OpenAPI bytes](references/candoitall-web.openapi.json) and [provenance](manifest.json).
- CanDoItAll `development`, clean commit `42f01bacf68c3a71451c3dca7e91e79c4ec6162a`.
- Source tree `c8d612f16ec13791b9df635586258316aff5c198`. The manifest records the dependency commits, archive hashes and image digest.
- All three source contexts are exact Git archives. The maintained Dockerfile build stage
  published with SDK 10.0.403 and runtime 10.0.14.
- Release LinuxHeadless and WindowsHeadless, Development, synthetic InMemory state, McpToolHost worker policy.
- API, OpenAPI, Swagger, JWT, user authentication and access management all enabled.
- Canonical `http://localhost:5032/` inside a network-none container, with no published ports.
- Both anonymous document routes agree byte for byte on each platform. The canonical capture was taken at `2026-11-24T13:29:09Z`.
- OpenAPI 3.1.1 contains **341 paths, 385 operations and 1,222 schemas**.
- The 4,805,513-byte export has SHA-256 `D23B1252EBAF7CB659E7AA87C4209A12A37C7345F0FAE4067E58593FE1BE4D94`.

Since the November 12 snapshot, eight new reads expose explicitly shared agents,
Simple Chats and workflows. Two new operations read and patch the signed-in
account's UI preferences. All 375 previous method/path pairs are present.
See [remote instances and shared templates](references/remote-instances.md),
[access and authentication](references/access-and-authentication.md) and the
[partner migration matrix](references/partner-api-migration.md).

The Linux host used an isolated SDK container. The Windows host served the same
portable Release publication on a separate loopback listener. Comparing the parsed
documents found one difference, the `servers` array containing each host's URL.

The validator checks 25 route families and all 17 documented operation sets
against the export and skill appendices. The snapshot includes Development
diagnostics and the account routes enabled by this host configuration.

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
