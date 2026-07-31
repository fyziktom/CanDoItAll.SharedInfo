# .NET Repository Standard

## SDK

- The reviewed family baseline is .NET SDK `10.0.302`, which carries the .NET
  `10.0.10` runtime servicing baseline.
- Track `global.json` in every .NET repository.
- Pin `10.0.302` with `latestPatch` roll-forward and `allowPrerelease: false`.
- Update the family baseline through a reviewed SharedInfo change, then adopt it
  repository by repository.
- CI must install the SDK selected by the repository `global.json`; do not duplicate a
  floating `10.0.x` SDK selector in workflow configuration.
- Build and package automation must execute `dotnet` with the owning repository root as
  its working directory so SDK resolution cannot inherit another repository's policy.
- .NET Docker build stages pin `mcr.microsoft.com/dotnet/sdk:10.0.302`. Framework-dependent
  runtime stages independently pin `mcr.microsoft.com/dotnet/aspnet:10.0.10` or
  `mcr.microsoft.com/dotnet/runtime:10.0.10`, as appropriate.

The 2026-07-24 inventory records the superseded `10.0.200`/`10.0.301` state. Inventories
are historical evidence and do not override this normative baseline.

Copy [`templates/repository/dotnet/global.json.template`](../../templates/repository/dotnet/global.json.template)
during adoption. Change its SDK policy only through a reviewed family-baseline update.

## Shared Build Properties

`Directory.Build.props` should contain truly repository-wide behavior:

- nullable reference types and implicit usings;
- deterministic builds;
- CI build metadata;
- generated-output exclusions.

Keep product metadata, package versions, target frameworks, and component dependency
versions in the repository or projects that own them. Do not use the shared template as a
central package-version service.

## Solutions And Projects

- Prefer one canonical root `.slnx`.
- Keep production projects below `src`, tests below `tests`, samples below `samples`, and
  compiled engineering tools below `tools/<area>`.
- Use project references for source built together; use packages for released
  cross-repository dependencies.
- Do not depend on sibling source paths in shipping project files.

## Restore Sources

- Declare required package sources explicitly in `NuGet.config`.
- Use `<clear />` when deterministic source selection is required.
- Never store credentials in `NuGet.config`; use the supported credential provider or
  machine-level configuration.
- Treat a sibling local package feed as a developer convenience, not the only reproducible
  release source.

## Validation

At minimum, a repository should expose commands for:

```powershell
dotnet restore <solution>
dotnet build <solution> --configuration Release --no-restore
dotnet test <solution> --configuration Release --no-build
```

Repositories with slow or environment-dependent tests should document a fast pull-request
gate and the additional release gate separately.
