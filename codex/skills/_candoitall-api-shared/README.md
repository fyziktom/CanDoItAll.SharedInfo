# CanDoItAll Web API Contract Support

This support package contains the generated OpenAPI snapshot and common access guidance
for the API skills. Use the live document when a target host has a different version.

## Current snapshot

- [Unmodified OpenAPI bytes](references/candoitall-web.openapi.json) and [provenance](manifest.json).
- CanDoItAll `development`, clean commit `a74a8aa4d40d09be5537de82ac2fb2c87cc9f8b2`.
- Source tree `43d49f7c27a48a6e8dc7481e52fc249f8ec7f1d9`; dependency commits and image digest are in the manifest.
- All three source contexts are exact Git archives; the maintained Dockerfile build stage
  published with SDK 10.0.403 and runtime 10.0.14.
- Release LinuxHeadless, Development, InMemory invented state, McpToolHost worker policy.
- API, OpenAPI, Swagger, JWT, user authentication and access management all enabled.
- Canonical `http://localhost:5032/` inside a network-none container, with no published ports.
- Both anonymous document routes agree byte for byte; capture UTC `2026-11-12T11:10:22Z`.
- OpenAPI 3.1.1: **332 paths, 375 operations, 1205 schemas**.
- SHA-256 `88D7A7C4101FBAB0900945BE932E120D147BB0E9AF14882B90336892745B4315`; 4,743,574 bytes.

This revision adds 28 operations for conditional project editing and lifecycle changes,
Structure refresh feeds, decision policies, planning review, saved receipts, root process
cancellation and CRM business stewardship. See [conditional operations and recovery](references/conditional-operations.md)
and the [partner migration matrix](references/partner-api-migration.md). Refresh-safe
floating chat execution is documented separately in [interactive chat lifetime](../candoitall-api-agents/references/interactive-chat-lifetime.md);
it does not change HTTP request lifetimes.

The current capture ran the Release publication inside the isolated Linux SDK image.
The final runtime-image package download stalled and was cancelled. The installed manager
rejected the synthetic bootstrap password-hash environment setting before starting the
Windows comparison, so current cross-platform equivalence is unverified. Earlier voice,
project identity, schedule, import, PDF staging and Windows proofs retain their historical
source commits in the manifest.

Route-family counts and all fourteen documented operation sets are validated against the
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
