# CanDoItAll.SharedInfo

The source of truth for conventions and cross-repository developer assets shared by the
CanDoItAll repository family.

This repository is deliberately separate from product source. Changes are prepared and
reviewed here first; adoption in sibling repositories is a later, explicit operation.

## What Lives Here

| Area | Purpose |
|---|---|
| [`docs/standards`](docs/standards) | Canonical repository, documentation, Git, .NET, tooling, NuGet, and Codex conventions |
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

See [`docs/architecture/source-of-truth.md`](docs/architecture/source-of-truth.md) for
ownership boundaries and [`docs/inventory/2026-07-24-baseline.md`](docs/inventory/2026-07-24-baseline.md)
for the initial consolidation evidence.
