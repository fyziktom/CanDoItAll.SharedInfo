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
- Maintained CanDoItAll repositories use the unmodified MIT License and display
  applicable CI, user-facing package, .NET, and MIT license badges.
- Code contributions are accepted only from partners explicitly approved by the
  maintainer. Unsolicited pull requests are not accepted; prospective partners contact
  the `fyziktom` account on LinkedIn and wait for approval before preparing or opening a
  pull request.
- Public CanDoItAll NuGet packages use `https://aicandoitall.com` as the default
  `PackageProjectUrl`; keep `RepositoryUrl` pointed at the canonical source repository.
- CanDoItAll .NET repositories pin SDK `10.0.302` with `latestPatch` roll-forward and
  prerelease SDKs disabled; .NET container runtime stages use runtime `10.0.10`.
- NuGet packages declare `PackageLicenseExpression` as `MIT`; do not use
  `PackageLicenseFile` for the family license.
- Repository NuGet build adapters accept `-Version`, forward it as the effective package
  version without committed project-file edits, and default to
  `artifacts/packages/<version>_<yyyyMMdd-HHmmssfff>`.
- Public NuGet packages include the copy-ready square corporate favicon as
  `package-icon.png`; a missing `docs/package-icon.png` is a packaging failure.
- Preserve third-party copyrights and license notices for copied source, vendored or
  wrapped JavaScript/CSS, generated assets, and other redistributed external material.
  Pack `THIRD-PARTY-NOTICES.md` with affected packages.
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
| License text, badge, package license metadata, or third-party notices | `docs/standards/licensing.md` | `templates/repository/LICENSE`, `THIRD-PARTY-NOTICES.md`; README and .NET targets templates |
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
