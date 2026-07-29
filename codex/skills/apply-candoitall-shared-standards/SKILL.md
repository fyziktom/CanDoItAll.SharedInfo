---
name: apply-candoitall-shared-standards
description: Use whenever planning, creating, changing, or reviewing a CanDoItAll repository's root layout, documentation, README badges, licensing, Git files, .NET defaults, Docker assets, shared tooling, NuGet packaging, or reusable Codex assets. Locates CanDoItAll.SharedInfo, loads only the relevant reviewed standards and templates, preserves repository-owned exceptions, and runs the applicable validation without silently changing sibling repositories.
---

# Apply CanDoItAll Shared Standards

Use `CanDoItAll.SharedInfo` as the reviewed source of truth for repository-family
conventions. Apply its standards as defaults while keeping implementation and documented
exceptions in the repository that owns them.

## Resolve The Source Of Truth

Treat the directory containing this active `SKILL.md` as `<skill-folder>`.

Run:

```powershell
& "<skill-folder>/scripts/Find-CanDoItAllSharedInfo.ps1" -StartPath .
```

The script checks an optional `CANDOITALL_SHAREDINFO_ROOT`, the current repository, and
nearby sibling locations without assuming a developer profile or fixed repositories
directory.

If SharedInfo is unavailable:

1. use the invariant summary in
   [`references/standards-map.md`](references/standards-map.md);
2. state that the canonical documents could not be inspected;
3. do not invent a local copy of a standard or silently weaken it;
4. ask for the SharedInfo location only when the missing source blocks the requested
   change.

## Load Instructions In Order

1. Read the target repository's applicable `AGENTS.md` files and current implementation.
2. Resolve SharedInfo and read its root `AGENTS.md`.
3. Use the routing table in
   [`references/standards-map.md`](references/standards-map.md) to read only the standards
   relevant to the task.
4. Inspect the matching copy-ready files under `templates/repository` when a concrete
   repository-owned file is needed.
5. Inspect current target-repository conventions and documented exceptions before
   proposing or applying a change.

System, user, and target-repository instructions take precedence. A deliberate local
exception does not automatically weaken the shared baseline; preserve or update the
exception explicitly.

## Apply The Ownership Boundary

- Treat SharedInfo and other sibling repositories as read-only unless the user explicitly
  includes them in the change scope.
- Put normative shared rules in `SharedInfo/docs/standards`.
- Put copy-ready shared examples in `SharedInfo/templates/repository`.
- Put cross-repository coordination in `SharedInfo/tools/<area>`.
- Keep the selected-partner contribution policy in SharedInfo and apply it to repository
  READMEs and `CONTRIBUTING.md` files without weakening it.
- Keep the family MIT text, badge contract, NuGet license-expression rules, NuGet
  package-icon contract, artifact run-folder contract, and third-party notice rules in
  SharedInfo. Adapt only the documented repository fields; keep
  `https://aicandoitall.com` as project metadata rather than a license condition.
- Keep product code, product configuration, repository-specific entry points, data,
  secrets, task bundles, proof, logs, and generated output in their owning repository.
- Copy and adapt templates; do not make product repositories depend on filesystem links
  to SharedInfo.
- Shared orchestrators may discover local repository adapters, but they must not absorb
  repository-specific build or deployment knowledge.

When the task is an adoption or migration, change only the repositories named by the
user. Validate each target independently and report exceptions rather than normalizing
them without review.

## Validate Proportionally

Run the target repository's documented validation first. Use SharedInfo validators as
additional read-only checks when applicable:

```powershell
& "<shared-info>/tools/validation/Test-DockerConventions.ps1" -RepositoryPath .
```

When changing SharedInfo itself, update the standard, template, shared tool, routing
reference, and validation together, then run:

```powershell
& "<shared-info>/tools/validation/Test-SharedInfo.ps1"
```

Run the current Codex skill/plugin validator when those packages change. Do not claim
compliance from syntax validation alone; for Docker, builds, health, persistence,
shutdown, backup/restore, and smoke behavior require runtime evidence.

For licensing and packaging work, inspect packed `.nuspec` metadata and archive contents.
Audit copied source, vendored browser assets, generated CSS/JavaScript, wrapper packages,
and lock files for retained third-party copyrights and license notices.

## Report The Result

State:

- which SharedInfo standards and templates were used;
- what changed in the authorized target;
- which validation ran and what it proved;
- any local exception, unresolved adoption dependency, or validation that could not run.
