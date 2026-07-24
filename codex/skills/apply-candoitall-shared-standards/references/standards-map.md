# SharedInfo Standards Map

## Invariants

Apply these even before loading a task-specific document:

- SharedInfo owns shared conventions, templates, cross-repository orchestration, and
  reusable Codex packages.
- Each product repository owns its source, configuration, data, secrets, release logic,
  repository-specific entry points, and documented exceptions.
- Keep siblings read-only unless the user authorizes an adoption or migration.
- Keep the repository root for high-level entry points and policy; use `src`, `tests`,
  `docs`, `samples`, and purpose-specific `tools/<area>` folders.
- Derive executable paths from the current script, repository, manifest, or parameter.
  Never hard-code a developer profile or repositories directory.
- Give mutating PowerShell tools `SupportsShouldProcess`/`-WhatIf` where practical and
  validate exact recursive targets.
- Do not commit secrets, local overrides, generated output, Codex runtime state, browser
  artifacts, task proof, or logs.
- Maintained CanDoItAll repositories use the MIT-derived license with the fixed
  `https://aicandoitall.com` website-link requirement and display applicable CI,
  user-facing package, .NET, and license badges.
- Public CanDoItAll NuGet packages use `https://aicandoitall.com` as the default
  `PackageProjectUrl`; keep `RepositoryUrl` pointed at the canonical source repository.
- NuGet packages embed the repository `LICENSE` through `PackageLicenseFile`; do not
  mislabel the added website-link condition as the unmodified SPDX `MIT` expression.
- Select NuGet badges from the one or two packages users are most expected to install.
  Prefer user-facing entry packages over Abstractions, Core, or provider packages.
- When a shared contract changes, update its standard, copy-ready template, tooling, and
  validation together.

## Routing Table

Paths are relative to the resolved `CanDoItAll.SharedInfo` root.

| Task concern | Read | Then inspect or run |
|---|---|---|
| Ownership or source-of-truth decision | `docs/architecture/source-of-truth.md` | target repository ownership docs |
| Root folders and names | `docs/standards/repository-layout.md` | `templates/repository` |
| README, contributing, security, durable docs | `docs/standards/documentation.md` | matching root templates |
| License text, website link, badge, or package license metadata | `docs/standards/licensing.md` | `templates/repository/LICENSE`; README and .NET targets templates |
| Git attributes, ignores, local/generated state | `docs/standards/git.md` | `.gitignore`, `.gitattributes` templates |
| SDK pinning, MSBuild defaults, solution layout | `docs/standards/dotnet.md` | `templates/repository/dotnet` |
| Dockerfile, Compose, ports, networks, volumes, secrets, health, runtime | `docs/standards/docker.md` | `templates/repository/docker`; `tools/validation/Test-DockerConventions.ps1` |
| PowerShell or cross-repository automation | `docs/standards/tooling.md` | `tools/<area>` and local adapter contract |
| NuGet build/package coordination | `docs/standards/nuget-packaging.md` | NuGet tool template and orchestrator |
| Reusable Codex skills, agents, plugins | `docs/standards/codex.md` | `codex`, package validator, installer |
| Current family evidence | latest relevant file in `docs/inventory` | confirm target state; inventory is not normative |

## Docker Quick Baseline

For Docker work, confirm at least:

- canonical `compose.yaml`, no obsolete `version`, predictable top-level project name,
  and no `container_name`;
- role-based service names and service-DNS connections;
- loopback-only development publications and no unnecessary database/vector-store host
  ports;
- named volumes for engine data, explicit data classes, and tested recovery for
  authoritative state;
- ignored local configuration, explicit Compose secret grants, and external production
  secret sources;
- versioned images, multi-stage application Dockerfiles, non-root runtime, and a complete
  `.dockerignore`;
- meaningful healthchecks, readiness-aware dependencies, application retry, graceful
  shutdown, bounded resources, and rotated logs;
- normal teardown preserves volumes; destructive reset is separately named and explicit;
- `docker compose config` plus referenced-file, build, health, persistence, and smoke
  validation.

Read the full Docker standard before creating or changing Docker assets; this summary is
only a trigger checklist.
