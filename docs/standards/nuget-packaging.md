# NuGet Packaging Contract

## Repository Entry Point

A repository that produces NuGet packages must own:

```text
tools/deployment/nugets/Build-NuGets.ps1
```

The entry point must accept:

| Parameter | Required behavior |
|---|---|
| `-Configuration` | Build configuration; default `Release` |
| `-OutputDirectory` | Absolute or repository-relative package destination |
| `-NoRestore` | Skip restore only when the caller guarantees it already happened |

It must fail with a non-zero exit when restore, build, tests required for packaging, or
packing fails. It must not publish packages. It must support `-WhatIf` and make one
`ShouldProcess` decision before creating output directories or starting restore, build,
test, or pack commands.

Start from
[`templates/repository/tools/deployment/nugets/Build-NuGets.ps1`](../../templates/repository/tools/deployment/nugets/Build-NuGets.ps1)
and customize package selection inside the owning repository.

## Package Links And Repository Metadata

Publicly distributed CanDoItAll packages must distinguish the user-facing project
website from the source repository:

```xml
<PropertyGroup>
  <PackageProjectUrl>https://aicandoitall.com</PackageProjectUrl>
  <RepositoryUrl>${REPOSITORY_URL}</RepositoryUrl>
  <RepositoryType>git</RepositoryType>
  <PublishRepositoryUrl>true</PublishRepositoryUrl>
</PropertyGroup>
```

- Use `https://aicandoitall.com` as the default `PackageProjectUrl`. A package may use a
  more specific stable public product page when that page is intentionally owned and
  maintained.
- Keep `RepositoryUrl` pointed at the canonical source repository; do not replace it
  with the project website.
- Set `RepositoryType` and enable repository publishing so package provenance and
  SourceLink metadata remain available.
- Include the public project website in the package README when it materially helps
  consumers discover documentation or related products.
- Inspect at least one packed `.nuspec` during adoption to prove that `projectUrl` and
  repository metadata are distinct and correct.

## Central Orchestration

[`Invoke-CanDoItAllNuGetBuilds.ps1`](../../tools/deployment/nugets/Invoke-CanDoItAllNuGetBuilds.ps1)
discovers compatible entry points below a repositories root and gives each repository a
separate output folder.

The orchestrator reads the repository-relative entry point from
`contracts.nugetBuildEntryPoint` in
[`config/repositories.json`](../../config/repositories.json). Use `-ManifestPath` to test
or operate against another compatible manifest. Each adapter runs in an isolated
PowerShell process so a repository-owned `exit N` is captured as that repository's
failure instead of terminating the cross-repository run. Adapter standard output and
standard error are returned in `AdapterOutput` and `AdapterError`.

Missing entry points are reported as `NotCompatible`; they are not silently replaced by
guesses about legacy scripts. Use `-FailOnMissing` during a future standards-adoption gate.

## Artifact Rules

- Default output is `artifacts/packages/<repository>` in SharedInfo.
- Package and symbol files are generated and ignored.
- A repository decides its package IDs, versions, symbols, readme, license metadata, and
  any deliberate package-specific project-page override.
- Publishing is a separate tool and requires explicit destination and authorization.
