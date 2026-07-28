# Shared Codex Assets

This folder contains maintained Codex assets that are reusable across the CanDoItAll
repository family and, where their scope is generic, other software repositories.

## Layout

- `skills`: discoverable skill packages and non-discoverable shared support folders.
- `agents`: optional reusable custom-agent profiles.
- `architecture-review`: snippets and prompts for repository-local architecture reviews.
- `csharp-architecture`: detailed examples, checklists, and bundle templates used by the
  architecture skills.
- `plugins`: plugin source.
- `marketplace.json`: repository marketplace catalog.

Task bundles, proof output, runtime logs, and product application/agent templates are not
shared Codex assets and do not belong here.

## Install Skills

Preview:

```powershell
.\tools\install\codex\Install-CodexSkills.ps1 -WhatIf
```

Install missing skills:

```powershell
.\tools\install\codex\Install-CodexSkills.ps1
```

Refresh repository-managed skills intentionally:

```powershell
.\tools\install\codex\Install-CodexSkills.ps1 -Force
```

The installer leaves existing skill folders untouched unless `-Force` is supplied. Public
OpenAI or .NET skills are external dependencies and are not vendored or downloaded by
this repository.

## API Contract Support

The non-discoverable `_candoitall-api-shared` support package contains the generated
OpenAPI contract used by the CanDoItAll web API skills. Its
[`manifest.json`](skills/_candoitall-api-shared/manifest.json) records the source commit,
source working-tree state, runtime endpoints, content hash, document counts, complete
route-family coverage, and parity-checked operation sets.

The default installer includes underscore support packages. For an exact API-skill
install, name both the desired skill and `_candoitall-api-shared`:

```powershell
.\tools\install\codex\Install-CodexSkills.ps1 `
    -PackageName candoitall-api-agents,_candoitall-api-shared
```

Use the bundled snapshot when it matches the target source version. Otherwise, use the
running web host's `/openapi/v1.json` or `/swagger/v1/swagger.json` document.

For partner adapters built against the earlier API, start with the support package's
[migration matrix](skills/_candoitall-api-shared/references/partner-api-migration.md).
It maps each former workaround to the stable identity, idempotency, portable schema, or
canonical evidence contract that replaces it.

## Use Plugins

`marketplace.json` catalogs repository plugins. Add the `codex` directory as a local
marketplace using the current Codex plugin workflow, then install the desired plugin.

The Components plugin requires sibling checkouts named `CanDoItAll.Mcp` and
`CanDoItAll.Components`. By default it derives their parent from this repository. Set
`CANDOITALL_REPOSITORIES_ROOT` when the repositories use another common parent.

## Provenance

- Development, bundle, API, Components, and C# architecture assets were initially
  mirrored from `CanDoItAll/codex`; the obsolete skill and architecture mirrors were
  removed from that product repository after consolidation.
- Agent profiles were mirrored from `CanDoItAll/.codex/agents`.
- CFO skills were mirrored from the reusable pack in `CanDoItAll.Economy`.

CanDoItAll app-agent templates and execution evidence remain product-owned. The
CanDoItAll.Economy source remains unchanged pending a separately approved cleanup.
