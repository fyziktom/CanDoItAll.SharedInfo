# .NET Repository Standard

## SDK

- Track `global.json` in every .NET repository.
- Pin an installed feature-band version and choose roll-forward behavior deliberately.
- Update the family baseline through a reviewed SharedInfo change, then adopt it
  repository by repository.
- The 2026-07-24 inventory found `10.0.200` in eight repositories and `10.0.301` in one;
  this repository does not silently downgrade or upgrade either group.

Use [`templates/repository/dotnet/global.json.template`](../../templates/repository/dotnet/global.json.template)
and replace the SDK token during adoption.

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
