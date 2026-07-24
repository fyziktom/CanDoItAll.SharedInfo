# CanDoItAll.SharedInfo

[![License](https://img.shields.io/badge/license-MIT--derived%20with%20source%20link-blue.svg)](LICENSE)

The source of truth for conventions and cross-repository developer assets shared by the
CanDoItAll repository family.

This repository is deliberately separate from product source. Changes are prepared and
reviewed here first; adoption in sibling repositories is a later, explicit operation.

## What Lives Here

| Area | Purpose |
|---|---|
| [`docs/standards`](docs/standards) | Canonical repository, documentation, licensing, Git, .NET, Docker, tooling, NuGet, and Codex conventions |
| [`docs/inventory`](docs/inventory) | Evidence-backed snapshots of the repository family |
| [`templates/repository`](templates/repository) | Copy-ready starting points for repository-owned files |
| [`tools`](tools) | Cross-repository discovery, installation, packaging orchestration, and validation |
| [`config/repositories.json`](config/repositories.json) | Machine-readable repository catalog and shared entry-point contracts |
| [`codex/skills`](codex/skills) | Maintained reusable Codex skills |
| [`codex/agents`](codex/agents) | Optional reusable Codex agent profiles |
| [`codex/plugins`](codex/plugins) | Maintained Codex plugin sources |
| [`codex/marketplace.json`](codex/marketplace.json) | Repository marketplace catalog for the shared plugins |

## Operating Model

1. Record a convention in `docs/standards`.
2. Provide a template when repositories need a concrete file.
3. Put executable cross-repository behavior in the appropriate `tools/<area>` folder.
4. Validate this repository.
5. Review the proposed standard.
6. Update sibling repositories only in a separately authorized adoption phase.

Repository-specific implementation remains in the repository that owns it. For example,
each NuGet-producing repository owns
`tools/deployment/nugets/Build-NuGets.ps1`; this repository owns the compatible template
and the orchestrator that calls all such entry points.

## Quick Checks

Inspect the current sibling-repository state without changing it:

```powershell
.\tools\inventory\Get-CanDoItAllRepositoryInventory.ps1
```

Preview a coordinated NuGet build:

```powershell
.\tools\deployment\nugets\Invoke-CanDoItAllNuGetBuilds.ps1 -WhatIf
```

Validate this repository:

```powershell
.\tools\validation\Test-SharedInfo.ps1
```

Preview installation of the maintained Codex skills:

```powershell
.\tools\install\codex\Install-CodexSkills.ps1 -WhatIf
```

Preview one exact package without touching unrelated installed skills:

```powershell
.\tools\install\codex\Install-CodexSkills.ps1 `
    -PackageName apply-candoitall-shared-standards `
    -WhatIf
```

Validate a repository's Docker/Compose baseline without starting containers:

```powershell
.\tools\validation\Test-DockerConventions.ps1 -RepositoryPath ..\CanDoItAll.Ledger
```

See [`docs/architecture/source-of-truth.md`](docs/architecture/source-of-truth.md) for
ownership boundaries and [`docs/inventory/2026-07-24-baseline.md`](docs/inventory/2026-07-24-baseline.md)
for the initial consolidation evidence. The
[`Docker baseline`](docs/inventory/2026-07-24-docker-baseline.md) records current
container usage and adoption dependencies.

## License

SharedInfo uses the
[MIT-Derived License with Source Link Requirement](LICENSE). Redistributions of the
software or a substantial portion of it in source or binary form must include the
required link to this source repository.
