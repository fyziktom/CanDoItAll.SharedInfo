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

## Use Plugins

`marketplace.json` catalogs repository plugins. Add the `codex` directory as a local
marketplace using the current Codex plugin workflow, then install the desired plugin.

The Components plugin requires sibling checkouts named `CanDoItAll.Mcp` and
`CanDoItAll.Components`. By default it derives their parent from this repository. Set
`CANDOITALL_REPOSITORIES_ROOT` when the repositories use another common parent.

## Provenance

- Development, bundle, API, Components, and C# architecture assets were mirrored from
  `CanDoItAll/codex`.
- Agent profiles were mirrored from `CanDoItAll/.codex/agents`.
- CFO skills were mirrored from the reusable pack in `CanDoItAll.Economy`.

The source repositories were not edited during consolidation.
