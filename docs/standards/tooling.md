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

## Reviewed Source Baseline Gates

Repositories that own `portability-static` or an equivalent source-fingerprint gate must
include it in CI/test repairs and changes to protected source, build/configuration, or
validation tooling. Check the complete proposed change, including supporting production
edits, shared test fixtures, and merged changes. A request to run only affected tests or
leave the full suite to CI does not waive this static gate.

The owning repository defines the commands, protected paths, patterns, and baseline.
Agents read its testing guide and current CI workflow; SharedInfo owns the review
process, not a copy of each product's scanner or allowances:

1. Run the gate's tooling checks and generate a fresh, complete scan with the same
   policy as CI. Use a unique ignored artifact or temporary output path. Confirm the
   scan is not truncated and account for new protected files that a tracked-only scan
   would omit.
2. Run enforcement without writing. Inspect every added and stale finding against
   source and the diff. Fingerprints can change after a signature, dependency version,
   or shell-step edit without introducing a portability defect.
3. Repair genuine defects first and regenerate the scan after any source edit. When
   remaining deltas are intentional and reviewed, explicitly refresh the baseline from
   that complete scan using the owning tool (for example, `--write-baseline`).
4. Inspect the baseline diff, keep it in the same change as its source, and rerun
   enforcement without the write flag. Leave the baseline unchanged if there is no
   delta. Report the gate result alongside focused test results.

Never accept an unexplained finding, use a partial/stale scan to refresh a baseline,
weaken scanner coverage to obtain a pass, or treat added/stale allowances as CI-only
work. If the gate cannot run, report the missing proof rather than claiming closure.

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

The same boundary applies to Docker validation:

```text
SharedInfo:
  tools/validation/Test-DockerConventions.ps1

Each Docker-owning repository:
  tools/validation/Test-Docker.ps1
```

The shared validator owns portable policy checks. The local entry point selects the
repository's Compose overlays, Dockerfiles, build contexts, required services, smoke
tests, and documented exceptions.

## Safety

- Inspection is the default.
- Clone helpers skip existing directories.
- Install helpers do not overwrite existing Codex assets without `-Force`.
- Orchestrators support `-WhatIf` and do not publish by default.
- A build/package tool may create local artifacts; a publish tool must be a distinct,
  explicit action.
