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
| `-Version` | Optional NuGet package version override without editing committed project files |
| `-CreateRunDirectory` | Treat an explicit output path as a root and create a versioned, timestamped child |

It must fail with a non-zero exit when restore, build, tests required for packaging, or
packing fails. When `-Version` is supplied, the adapter must forward the override to every
restore, build, test, and pack operation that it runs, and it must not silently produce a
package with the committed default version. It must not publish packages. It must support
`-WhatIf` and make one `ShouldProcess` decision before creating output directories or
starting restore, build, test, or pack commands. It must require the repository
`global.json` and execute every `dotnet` command with the repository root as the working
directory. Absolute solution or project paths do not change SDK resolution; without this
working-directory boundary, a caller or the shared orchestrator can select another SDK.

When `-OutputDirectory` is omitted, the adapter must resolve the effective package
version and write to
`artifacts/packages/<version>_<yyyyMMdd-HHmmssfff>`. The millisecond timestamp prevents
one run from reusing stale packages from another. An explicitly supplied output
directory is exact unless `-CreateRunDirectory` is also supplied.

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

## Package Icon

Every public CanDoItAll NuGet package must include the approved square corporate favicon
at
[`templates/repository/docs/package-icon.png`](../../templates/repository/docs/package-icon.png)
by default. Copy it to `docs/package-icon.png` in the adopting repository and use the
copy-ready defaults in
[`templates/repository/dotnet/Directory.Build.targets`](../../templates/repository/dotnet/Directory.Build.targets).

- Declare `PackageIcon` as `package-icon.png` and embed the file at the package root.
- Treat a missing `docs/package-icon.png` as a packaging error. Do not silently omit the
  icon merely because the file was not copied during adoption.
- Use the 256x256 PNG corporate favicon for package and other compact square UI surfaces.
  It stays legible when clients scale it down and remains well below NuGet's 1 MB limit.
  NuGet recommends 128x128; retaining the official 256x256 master is a deliberate
  high-quality downsampling choice within the supported PNG and size contract.
- Do not use the stacked logo or another wordmark as a package icon; reserve wordmarks for
  larger README, website, presentation, and product surfaces where the text stays legible.
- Do not use the deprecated `PackageIconUrl` metadata.
- A deliberately product-specific icon may replace the corporate favicon when its owner
  maintains an equally polished square PNG and documents the branding decision.
- Validate the packed `.nuspec` `<icon>` value and prove the package contains the expected
  icon bytes.

## Package License

Public CanDoItAll packages use the unmodified [MIT License](licensing.md):

- set `PackageLicenseExpression` to `MIT`;
- do not set `PackageLicenseFile` for the family license;
- require `<license type="expression">MIT</license>` in the packed `.nuspec`;
- keep `PackageProjectUrl` on the shared website while `RepositoryUrl` continues to
  identify the package's canonical source repository;
- pack `THIRD-PARTY-NOTICES.md` when the package redistributes external material that
  requires retained copyright or license notices.

Start from
[`templates/repository/dotnet/Directory.Build.targets`](../../templates/repository/dotnet/Directory.Build.targets)
when centralizing license-expression, package-icon, and notice behavior.

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
The orchestrator accepts `-Version` and forwards it to every selected compatible adapter,
so coordinated proof or release builds do not require source edits.

## Artifact Rules

- A repository adapter defaults to
  `artifacts/packages/<version>_<yyyyMMdd-HHmmssfff>`.
- A coordinated SharedInfo run isolates repositories below its run output. When the
  caller supplies `-Version`, use that version in the coordinated run-folder name;
  otherwise use `committed-versions_<yyyyMMdd-HHmmssfff>` to state that repository-owned
  versions differ.
- Package and symbol files are generated and ignored.
- A repository decides its package IDs, versions, symbols, readme, and any deliberate
  package-specific project-page override. License and third-party notice metadata follow
  the shared licensing standard unless an owner-approved legal exception is documented.
- Publishing is a separate tool and requires explicit destination and authorization.
