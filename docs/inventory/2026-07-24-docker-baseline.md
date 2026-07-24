# Docker Baseline — 2026-07-24

## Purpose And Scope

This is a read-only snapshot of Docker usage across the sibling `CanDoItAll*`
repositories. It records evidence for the shared standard; it is not itself normative and
does not authorize changes in product repositories.

The survey found:

- 6 Compose manifests;
- 8 Dockerfiles;
- 4 `.dockerignore` files;
- 1 environment example;
- no repository-owned Docker lifecycle/validation entry points;
- no Testcontainers packages.

Every discovered Compose model passed `docker compose config --quiet`, including the
tested overlay combinations. That proves model resolution only: it did not reveal missing
Dockerfiles, broad exposure, weak readiness, or fragile persistence.

## Repository Matrix

| Repository | Current Docker footprint | Evidence relevant to adoption |
|---|---|---|
| `CanDoItAll` | PostgreSQL and Qdrant in root `docker-compose.yml` | Named volumes and healthchecks are present. Fixed `container_name` values, hard-coded local credentials, and host-wide port bindings prevent safe project isolation. Documentation describes a loopback PostgreSQL endpoint that the actual binding does not enforce. |
| `CanDoItAll.AgentFramework.Rag` | README-only Qdrant `docker run` guidance | The unpinned command duplicates infrastructure also owned by the main stack and has no shared persistence/readiness contract. |
| `CanDoItAll.Components` | `.dockerignore` used as an additional build context | Cross-repository build contexts need the same secret, generated-output, bundle, and proof exclusions as the primary context. |
| `CanDoItAll.Economy` | Base Compose file plus demo and VPS overlays | Named PostgreSQL/data-protection volumes and loopback ports are good. All three referenced Dockerfiles are absent, `.env` is recommended but not ignored, most long-running services lack healthchecks, and VPS key material is injected through environment values. |
| `CanDoItAll.IPFS` | Two Dockerfiles and a two-service Compose stack | Explicit project name, named volumes, healthchecks, and non-root .NET runtimes are good. Host ports bind all interfaces and the build context does not exclude the repository's `bundles` evidence tree. |
| `CanDoItAll.Ledger` | Six Dockerfiles and a six-service demo stack | PostgreSQL, data-protection keys, and demo keys are repository bind mounts; the PostgreSQL healthcheck compensates with a ten-minute Windows crash-recovery start period. All ports are broadly published, most dependencies wait only for process start, and only PostgreSQL is healthchecked. |
| `CanDoItAll.Mcp` | Remote network/volume/Compose operations in SshOps | Deployment accepts one Compose file per operation and rollback assumes `<stack>/docker-compose.yml`. That conflicts with canonical `compose.yaml` plus overlays and must be resolved before family-wide filename adoption. |
| Remaining siblings | No Docker assets | No adoption is required until they own a container image or runtime dependency. |

## Cross-Repository Findings

The highest-value shared controls are:

1. project-scoped names with no `container_name`;
2. loopback-only development publications and internal data-service ports;
3. named volumes for engine data, with explicit backup/restore ownership;
4. service-DNS networking and deliberate cross-stack external networks;
5. healthchecks plus readiness-aware dependencies and runtime reconnect behavior;
6. ignored local configuration, placeholder env examples, and externally sourced
   production secrets;
7. versioned images, non-root multi-stage application images, and complete build-context
   ignores;
8. bounded resources/logs and separate destructive reset operations;
9. validation of referenced files, builds, health, persistence, and smoke behavior in
   addition to Compose resolution.

## Adoption Dependencies

Before changing product repositories:

- update SshOps to carry the selected Compose filename and ordered overlay set through
  apply, status, logs, teardown, wait, and rollback;
- decide whether Qdrant belongs to the main stack, the RAG repository, or an explicitly
  shared external stack;
- restore or remove Economy's missing Dockerfile references;
- define a migration/backup path before moving Ledger's repository-bound data to named
  volumes;
- preserve current working runtime behavior while correcting exposure, readiness, and
  secret delivery one repository at a time.

No sibling repository was changed during this inventory.
