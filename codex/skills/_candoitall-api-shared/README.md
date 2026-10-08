# CanDoItAll Web API Contract Support

This support package contains the generated OpenAPI snapshot and common access guidance
for the API skills. Use the live document when a target host has a different version.

## Current snapshot

- [Unmodified OpenAPI bytes](references/candoitall-web.openapi.json) and [provenance](manifest.json).
- CanDoItAll `demos-repairs`, clean signed commit `16eb94433945e20259ad3cfc3d57751224a8f548`.
- Source tree `38b01d3ef29b36b036de9dae44cdfe6c28ff539e`; dependency commits and image digest are in the manifest.
- Release LinuxHeadless, Development, InMemory invented state, McpToolHost worker policy.
- API, OpenAPI, Swagger, JWT, user authentication and access management all enabled.
- Canonical `http://localhost:5032/` inside a network-none container, with no published ports.
- Both anonymous document routes agree byte for byte; capture UTC `2026-10-08T07:53:02+00:00`.
- OpenAPI 3.1.1: **310 paths, 347 operations, 1019 schemas**.
- SHA-256 `6095DC7E69890DA6FD20662CC55320B87525D565F96E240E39622BE120E71C25`; 3,936,325 bytes.

This revision adds bounded PDF staging at `POST /api/workflows/attachments/documents`.
See the [workflow document contract](../candoitall-api-workflows/references/document-attachments.md).
Voice, immutable project identity, initial schedules and import identity remain included;
their historical live proofs retain their own source commits in the manifest. The current
capture is Linux-only; the previous Windows comparison is explicitly historical.

Route-family counts and all thirteen documented operation sets are validated against the
snapshot and skill appendices. Development diagnostics are included; application pages
and static files are not API operations. Conditional account routes depend on host flags.

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
