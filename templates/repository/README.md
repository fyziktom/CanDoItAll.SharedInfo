# ${REPOSITORY_NAME}

[![CI](${SOURCE_REPOSITORY_URL}/actions/workflows/${CI_WORKFLOW_FILE}/badge.svg?branch=main&event=push)](${SOURCE_REPOSITORY_URL}/actions/workflows/${CI_WORKFLOW_FILE})
[![NuGet version](https://img.shields.io/nuget/v/${PRIMARY_PACKAGE_ID}.svg?logo=nuget&label=NuGet)](https://www.nuget.org/packages/${PRIMARY_PACKAGE_ID})
[![NuGet downloads](https://img.shields.io/nuget/dt/${PRIMARY_PACKAGE_ID}.svg?logo=nuget&label=${PRIMARY_PACKAGE_BADGE_LABEL}%20downloads)](https://www.nuget.org/packages/${PRIMARY_PACKAGE_ID})
[![.NET ${DOTNET_MAJOR_VERSION}](https://img.shields.io/badge/.NET-${DOTNET_MAJOR_VERSION}.0-512BD4?logo=dotnet)](https://dotnet.microsoft.com/download/dotnet/${DOTNET_MAJOR_VERSION}.0)
[![License](https://img.shields.io/badge/license-MIT--derived%20with%20source%20link-blue.svg)](LICENSE)

Remove badge lines that do not apply; do not leave unresolved placeholders.

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

This repository uses the
[MIT-Derived License with Source Link Requirement](LICENSE). Redistributions of the
software or a substantial portion of it in source or binary form must include the link to
`${SOURCE_REPOSITORY_URL}` required by the license.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution policy.
