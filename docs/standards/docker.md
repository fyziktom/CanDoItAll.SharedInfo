# Docker And Compose Standard

## Scope

This standard applies when a CanDoItAll repository builds a container image or uses
Docker Compose for an application, database, queue, vector store, RAG service, model
cache, or other development/production dependency.

The words **must**, **should**, and **may** describe required defaults, recommended
defaults, and optional choices. A repository may use a different approach when the
runtime requires it, but it must document the reason, owner, and validation of the
exception beside the local Docker assets.

Start new Compose assets from
[`templates/repository/docker`](../../templates/repository/docker). Product repositories
own their resulting Dockerfiles, Compose files, operational scripts, secrets integration,
and data.

## Repository Contract

Use this layout when the concern exists:

```text
<repository>/
  compose.yaml
  compose.override.yaml.example    # copy to ignored compose.override.yaml when needed
  compose.production.yaml          # only when single-host Compose is a deployment target
  .env.example
  .dockerignore                    # at each build-context root
  src/<service>/Dockerfile         # application-owned image
  docs/operations/
    containers.md
    backup-and-restore.md           # when durable container data exists
  tools/
    dev/
      Start-Containers.ps1          # optional repository-owned convenience entry point
      Stop-Containers.ps1
    validation/
      Test-Docker.ps1               # repository-owned validation entry point
```

- Use the Compose v2 command `docker compose`.
- Use `compose.yaml` as the canonical file name.
- Do not add the obsolete top-level `version` property.
- Keep the base service graph reusable and do not set an application environment identity
  there. Safe local defaults such as loopback publications and bounded workstation
  resources may remain in the base. Put an explicit Development identity, source mounts,
  and other automatically loaded local-only changes in `compose.override.yaml`; commit
  only a safe example when each developer needs different values.
- Put production changes in an explicit `compose.production.yaml` overlay. Invoke it with
  both files so the selected model is visible in the command.
- Use profiles for optional capabilities such as `debug`, `admin`, `observability`,
  `backup`, or `gpu`. Core services must not require a profile. Profiles are not a
  substitute for a production overlay.

Inspect the resolved model before running it:

```powershell
docker compose config --quiet
docker compose config --environment
docker compose -f compose.yaml -f compose.production.yaml config --quiet
```

Do not print a fully rendered configuration to public logs when interpolated values could
contain secrets.

## Naming And Isolation

Use lower-case kebab-case names.

| Concern | Pattern | Example |
|---|---|---|
| Default Compose project | `candoitall-<repository-slug>` | `candoitall-ledger` |
| Concurrent developer or branch | `candoitall-<slug>-dev-<short-id>` | `candoitall-ledger-dev-tom` |
| CI project | `candoitall-<slug>-ci-<run-id>` | `candoitall-ledger-ci-4812` |
| Production project | `candoitall-<slug>-prod` | `candoitall-ledger-prod` |
| Service key | role, not repository name | `api`, `worker`, `db`, `vector-db` |
| Local image | `candoitall-<slug>-<service>:dev` | `candoitall-ledger-api:dev` |
| Volume key | role plus data purpose | `db-data`, `rag-index`, `model-cache` |
| Network key | trust boundary | `frontend`, `backend` |

Set a predictable default using the top-level `name`. Override it with `-p` or
`COMPOSE_PROJECT_NAME` for concurrent worktrees, CI jobs, and shared hosts.

Do not set `container_name`. Compose-generated names include the project, preserve
isolation, and allow a service to scale. Do not connect by container IP address; use the
service key and container port through Compose DNS.

Let Compose scope volume and network names. Set an explicit resource `name` only for an
intentionally shared or externally managed resource, and document its lifecycle and
collision boundary.

## Images And Dockerfiles

Application-owned images must:

- use trusted Docker Official, Verified Publisher, or vendor-maintained base images;
- use explicit version tags and never committed `latest` or an unqualified image;
- use multi-stage builds so SDKs, source, test tools, and package caches stay out of the
  runtime image;
- make the restore layer complete: when practical, copy every dependency-defining file
  and referenced project manifest before frequently changing source; otherwise copy the
  complete source graph before restore and optimize only after a correct build exists;
- use a `.dockerignore` at the build-context root;
- use JSON/exec form for `ENTRYPOINT` and `CMD`;
- run as a non-root user;
- write logs to stdout/stderr;
- carry useful OCI labels for source, revision, version, creation time, vendor, license,
  and documentation when published.

Do not pass build credentials through Dockerfile `ARG` or `ENV`. Use BuildKit secret or
SSH mounts. Use cache mounts for package caches where they materially reduce build time.

Development may use an explicit mutable tag such as `:dev`. Shared environments must use
immutable tags; production should pin the readable version to an image digest. Pair
digest pinning with an update process because a fixed digest does not receive security
fixes automatically. Tag owned release images with a release version and a commit-derived
tag, then deploy the verified digest.

CI should rebuild regularly and pull refreshed base images:

```powershell
docker build --check --file src/MyService/Dockerfile .
docker build --pull --file src/MyService/Dockerfile --tag candoitall-sample-api:dev .
```

Third-party images must follow the vendor's supported user, filesystem, and upgrade
model. Do not blindly impose an application-image hardening setting on a database or
vector-store image.

## Configuration And Secrets

Keep these concepts separate:

- `.env` supplies Compose interpolation and command defaults.
- `env_file` injects values into a container.
- Compose `configs` mount non-sensitive configuration.
- Compose `secrets` grant a service a specific read-only runtime secret.

Neither `.env` nor service environment variables are a secret store. Commit only
`.env.example` with non-sensitive defaults and obvious placeholders. Ignore `.env`,
`.env.*`, secret files, private keys, local certificates, and generated credentials.

Use `${VARIABLE:?explanation}` for required production configuration so resolution fails
before containers start. Prefer one source for each setting and document exceptions
because shell, CLI, `.env`, `environment`, `env_file`, and image `ENV` values have
different precedence.

Grant each secret only to services that use it. Production secrets must come from the
deployment platform or approved secret manager. Compose secrets are a delivery boundary,
not a claim that the source is encrypted. Never commit credentials in a Dockerfile,
Compose value, image layer, or CI output.

Applications should support a documented `*_FILE` convention or another explicit
file-based configuration mechanism when Compose mounts secrets under `/run/secrets`.

## Storage And Data Lifecycle

Classify every persistent mount before selecting its storage:

| Data class | Examples | Default storage | Recovery requirement |
|---|---|---|---|
| Authoritative durable | database, uploads, source corpus | named or external volume | backup and tested restore required |
| Derived durable | vector index, embeddings | named volume | define rebuild time and RTO; back up when needed |
| Rebuildable cache | model or package cache | named volume | normally no backup |
| Ephemeral | temporary work, sockets | `tmpfs` or container layer | no backup |

- Use named volumes for databases and service-generated persistent data.
- Do not use anonymous volumes for data that must be found and reused.
- Use bind mounts for local source, deliberate host exchange, or mounted configuration.
  Prefer long syntax, `read_only: true`, and `bind.create_host_path: false`.
- Do not bind-mount database engine data to a Windows project folder. Use a Docker-managed
  named volume to avoid host-filesystem semantics, poor performance, and fragile
  crash-recovery behavior.
- Do not use source-code bind mounts in production.
- Do not manipulate Docker's internal volume storage directory directly.
- Use `external: true` when production data has a lifecycle independent of the Compose
  application.

Normal stop and reset commands must preserve volumes:

```powershell
docker compose down
```

`docker compose down --volumes` is destructive. It must live in a separately named reset
operation, require an explicit target/project, and display which durable data will be
lost. It must never be part of the normal stop path.

For each authoritative volume, document:

- owner and data class;
- engine and schema/migration version;
- backup mechanism, frequency, retention, and encryption;
- restore command and validation;
- recovery point and recovery time objectives;
- major-version upgrade and rollback procedure.

Use database-native backup tooling for a live database. Quiesce writes before raw
file-level backup. Restore into a new empty volume, validate it, and then cut over rather
than overwriting the only known-good copy. Test restores on a schedule.

## Networks And Ports

The implicit project network is enough for a simple trusted stack. Use explicit
`frontend` and `backend` networks when a stack contains a data service or a meaningful
trust boundary. Put databases, caches, queues, RAG stores, and vector stores only on the
backend network; use `internal: true` when those services do not need outbound access.

- Use service DNS names and container ports between containers.
- Do not use legacy `links`.
- Publish only ports needed by a host user or ingress component.
- Do not publish database, cache, queue, RAG, or vector-store ports merely for
  container-to-container access.
- Bind local administrative and data ports to loopback, for example
  `127.0.0.1:5432:5432`.
- An omitted host address binds on all interfaces and requires an explicit documented
  reason.
- Production normally publishes only an ingress/reverse-proxy port.
- Do not use host networking, host PID namespace, host devices, or an external network
  without a reviewed requirement.

## Readiness And Dependencies

Give every long-running service a meaningful healthcheck when the image contains or can
provide a reliable readiness probe.

- Probe the service from inside its container with a native client or dedicated
  lightweight command.
- Test the service's ability to serve requests, not unrelated downstream dependencies.
- Tune `start_period`, `interval`, `timeout`, and `retries` from observed startup
  behavior.
- Use long-form `depends_on` with `service_healthy` for required infrastructure and
  `service_completed_successfully` for deliberate one-shot initialization or migration
  jobs.
- Do not treat short-form `depends_on` as readiness.
- Applications must still reconnect with bounded backoff because startup ordering does
  not handle later dependency failures.
- Remember that an unhealthy status does not itself restart a running process.

CI and smoke tests should wait for health:

```powershell
docker compose -p candoitall-sample-ci-4812 up -d --wait --wait-timeout 120
docker compose -p candoitall-sample-ci-4812 ps --all
docker compose -p candoitall-sample-ci-4812 down --volumes --remove-orphans
```

CI/smoke projects must use a unique, explicitly disposable project name and must never
attach production external data. Their teardown may remove project-scoped volumes so
repeated validation does not leak storage. This is distinct from normal developer or
production teardown, which preserves volumes.

## Runtime Safety, Resources, And Logs

Application-owned services should default to:

- a non-root image user;
- `read_only: true`;
- explicit named volumes or `tmpfs` for required writable paths;
- `cap_drop: [ALL]`, adding back only proven capabilities;
- `security_opt: [no-new-privileges:true]`;
- no privileged mode, Docker socket/API, host namespace, or host device.

Use `init: true` only when the entry point does not reap child processes correctly.
Applications should run directly as PID 1 and handle termination signals.

Containers have no resource limit by default. Add configurable workstation guardrails
for memory-, CPU-, or PID-intensive databases, models, and RAG workloads. Derive
production `mem_limit`, `mem_reservation`, `cpus`, and `pids_limit` values from measured
load. Use `deploy.resources` only when the selected deployment platform implements the
Compose Deploy Specification.

Use bounded logging. For ordinary Docker Engine development and single-host use, prefer
the `local` logging driver or explicitly rotate `json-file`; the unbounded default can
consume the host disk. Production services should send structured stdout/stderr logs to
the selected centralized backend with bounded local buffering.

Development should normally use `restart: "no"` so failures remain visible. A production
single-host service may use a documented `unless-stopped` or `always` policy. One-shot
jobs use `"no"` or a bounded `on-failure:<count>`.

Set `stop_grace_period` from measured drain and flush time. Test graceful stop, forced
stop recovery, dependency restart, and host/daemon restart behavior.

## Validation Contract

Every Docker-owning repository should expose
`tools/validation/Test-Docker.ps1`. It must validate the repository's actual file set and
return a nonzero exit code on failure. At minimum, CI must run:

```powershell
docker compose config --quiet
docker compose -f compose.yaml -f compose.production.yaml config --quiet
docker build --check --file <Dockerfile> <context>
docker build --pull --file <Dockerfile> <context>
docker compose -p <unique-ci-project> up -d --wait --wait-timeout 120
# repository smoke or integration tests
docker compose -p <unique-ci-project> down --volumes --remove-orphans
```

Policy validation must reject:

- `container_name`;
- obsolete top-level `version`;
- `latest` or unversioned committed images;
- production source bind mounts;
- production privileged/host-network/Docker-socket access;
- secret-like committed values;
- anonymous persistent mounts;
- destructive `down --volumes` in ordinary stop scripts;
- undocumented explicit volume/network names.

Policy validation should flag all-interface port publishing, missing healthchecks for
readiness dependencies, mutable production image references, and local bind-mounted
engine data for explicit review.

SharedInfo provides
[`Test-DockerConventions.ps1`](../../tools/validation/Test-DockerConventions.ps1) for the
portable baseline. It rejects unambiguous naming, image, committed-secret, anonymous
volume, host-control, and destructive-stop violations; it validates every enabled
profile, referenced Dockerfile, and build-context ignore. With `-Production`, it also
rejects local build contexts, source bind mounts, and images without a sha256 digest.
Use `-WarningsAsErrors` for the reviewed CI baseline.

Portable validation cannot infer whether every explicit resource name has a documented
owner, whether a mounted production secret came from the approved provider, or whether a
product-specific bind mount is source code under an unusual path. The repository-owned
entry point must validate those remaining rules and encode reviewed exceptions.

## Development And Production Defaults

| Concern | Development | Production |
|---|---|---|
| Images | local build or explicit `:dev` | registry image pinned to digest |
| Code | optional bind mount or Compose Watch | code baked into image |
| Ports | loopback-only convenience ports | ingress-only exposure |
| Data | named volumes; explicit disposable reset | external or managed durable volumes |
| Secrets | ignored local source delivered as a secret | platform or secret-manager source |
| Restart | `"no"` | documented platform policy |
| Resources | workstation guardrails | measured limits and reservations |
| Logs | stdout/stderr with local rotation | centralized collection and retention |
| Optional tools | profiles | disabled unless explicitly approved |
| Hardening | production-like where practical | required with tested exceptions |

## Primary References

- [Docker build best practices](https://docs.docker.com/build/building/best-practices/)
- [Docker build secrets](https://docs.docker.com/build/building/secrets/)
- [Compose application model](https://docs.docker.com/compose/intro/compose-application-model/)
- [Compose project names](https://docs.docker.com/compose/how-tos/project-name/)
- [Compose production guidance](https://docs.docker.com/compose/how-tos/production/)
- [Compose startup order](https://docs.docker.com/compose/how-tos/startup-order/)
- [Compose networking](https://docs.docker.com/compose/how-tos/networking/)
- [Compose secrets](https://docs.docker.com/reference/compose-file/secrets/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker resource constraints](https://docs.docker.com/engine/containers/resource_constraints/)
- [Docker logging configuration](https://docs.docker.com/engine/logging/configure/)
- [Docker Engine security](https://docs.docker.com/engine/security/)
- [OCI image annotations](https://specs.opencontainers.org/image-spec/annotations/)
- [.NET container images](https://learn.microsoft.com/dotnet/core/docker/container-images)
