# ${REPOSITORY_NAME}

${ONE_SENTENCE_PURPOSE}

## Ownership

This repository owns:

- ${OWNED_CAPABILITY}

This repository does not own:

- ${EXCLUDED_CAPABILITY_AND_OWNER}

## Projects And Packages

| Project or package | Purpose |
|---|---|
| `${PROJECT_PATH}` | ${PROJECT_PURPOSE} |

## Requirements

- .NET SDK pinned by `global.json`
- ${OTHER_REQUIREMENT}

## Build And Test

Run from the repository root:

```powershell
dotnet restore ${SOLUTION_FILE}
dotnet build ${SOLUTION_FILE} --configuration Release --no-restore
dotnet test ${SOLUTION_FILE} --configuration Release --no-build
```

## Run

```powershell
${SMALLEST_USEFUL_RUN_COMMAND}
```

## Containers

Remove this section when the repository owns no Docker assets.

```powershell
Copy-Item .env.example .env
docker compose config --quiet
docker compose up -d --wait --wait-timeout 120
docker compose down
```

Document which services publish host ports, which volumes are authoritative, how secrets
are supplied, and where backup/restore procedures live. Normal teardown must preserve
volumes.

## Documentation

- [Architecture](docs/${ARCHITECTURE_DOCUMENT})
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)

## Packaging

Describe package ownership and use the compatible
`tools/deployment/nugets/Build-NuGets.ps1` entry point when this repository produces
NuGet packages.

## License And Contributions

State the repository's license and contribution policy. Do not assume that every
CanDoItAll repository uses the same policy.
