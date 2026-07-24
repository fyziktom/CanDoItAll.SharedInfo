# Docker Template

Copy the relevant files to the repository root, then replace every `sample` name and
application path with repository-owned values.

| Template | Destination | Purpose |
|---|---|---|
| `compose.yaml` | `compose.yaml` | Safe development baseline |
| `compose.override.yaml.example` | `compose.override.yaml.example` | Optional local source-mount example |
| `compose.production.yaml.example` | `compose.production.yaml` | Explicit production overlay starting point |
| `.env.example` | `.env.example` | Non-secret configuration contract |
| `.dockerignore` | `.dockerignore` | Root build-context exclusions |
| `Dockerfile.dotnet` | `src/<service>/Dockerfile` or root `Dockerfile.dotnet` | Multi-stage .NET application image |
| `../tools/validation/Test-Docker.ps1` | `tools/validation/Test-Docker.ps1` | Repository-owned validation/smoke entry point |

The Compose example assumes the application supports:

- `DB_PASSWORD_FILE=/run/secrets/db-password`;
- an executable readiness probe at `/app/healthcheck`;
- ASP.NET Core HTTP on container port `8080`.

Adapt those names to the application rather than copying an unsupported contract. An
image-native executable or app-provided probe is preferable to installing a general
shell or HTTP client only for healthchecks. Update the Compose `dockerfile` path if the
template is renamed or moved.

The production overlay intentionally removes the development host port. Attach the API
to a reviewed ingress/reverse-proxy network or add the one required ingress publication.
Set `PRODUCTION_API_IMAGE` separately from the development `API_IMAGE` so a local `.env`
cannot silently select a development image for production. Set
`PRODUCTION_POSTGRES_IMAGE` to a reviewed PostgreSQL version plus digest as well. The
overlay resets the local API build context so production pulls the immutable image.

Before adoption:

1. classify every volume and document authoritative-data recovery;
2. remove services and settings the repository does not own;
3. choose measured resource and shutdown limits;
4. validate the resolved base and production models;
5. build and smoke-test the exact image;
6. document every hardening exception required by a third-party image.

Validate an adopted production overlay explicitly:

```powershell
.\tools\validation\Test-Docker.ps1 `
    -ComposeFile compose.yaml,compose.production.yaml `
    -Production
```

See
[`docs/standards/docker.md`](../../../docs/standards/docker.md) for the normative
contract.
