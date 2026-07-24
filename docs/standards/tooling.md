# Shared Tooling Standard

## Placement

Cross-repository coordination lives here. Product behavior stays in the product
repository.

```text
tools/
  deployment/
    nugets/
  install/
    codex/
    repositories/
  inventory/
  validation/
```

Do not place unrelated scripts directly under `tools`.

## Script Contract

PowerShell is the baseline orchestration language because the current repository family is
developed primarily on Windows. Shared scripts must:

- use `[CmdletBinding()]`;
- declare parameters instead of editing constants;
- set `$ErrorActionPreference = 'Stop'`;
- derive paths from `$PSScriptRoot`, a manifest, or a parameter;
- reject paths outside the intended root before recursive mutation;
- use `SupportsShouldProcess` for mutating operations;
- return useful objects as well as readable status;
- preserve the exit code of external tools;
- avoid machine-specific paths and secrets.

Use lower-case directory names and approved PowerShell verbs in file names.

## Cross-Repository Pattern

SharedInfo defines a stable relative entry point and orchestrator. Each repository provides
an adapter at that path:

```text
SharedInfo:
  tools/deployment/nugets/Invoke-CanDoItAllNuGetBuilds.ps1

Each package repository:
  tools/deployment/nugets/Build-NuGets.ps1
```

The adapter owns package selection and any repository-specific preparation. The
orchestrator owns discovery, selection, output isolation, failure aggregation, and
reporting.

## Safety

- Inspection is the default.
- Clone helpers skip existing directories.
- Install helpers do not overwrite existing Codex assets without `-Force`.
- Orchestrators support `-WhatIf` and do not publish by default.
- A build/package tool may create local artifacts; a publish tool must be a distinct,
  explicit action.
