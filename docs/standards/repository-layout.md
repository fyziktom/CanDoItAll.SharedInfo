# Repository Layout Standard

## Baseline

Every maintained CanDoItAll software repository should make these concerns obvious from
the root:

```text
<repository>/
  README.md
  LICENSE
  .editorconfig
  .gitattributes
  .gitignore
  global.json                 # .NET repositories
  Directory.Build.props       # multi-project .NET repositories
  Directory.Build.targets     # shared build/package items when needed
  compose.yaml                # repositories with a Compose application
  .env.example                # non-secret Compose/configuration contract
  .dockerignore               # at each Docker build-context root
  src/
  tests/
  docs/
  samples/                    # only when maintained examples exist
  tools/
    deployment/
      nugets/
    install/
    validation/
```

Only create a directory when the repository has content for it. Empty ceremonial folders
make ownership harder to understand.

## Root Rules

- Keep the root for entry points, policies, and high-level configuration.
- Keep production projects under `src` and test projects under `tests`.
- Keep runnable teaching or integration examples under `samples`; do not hide product
  projects there.
- Keep durable documentation under `docs`.
- Keep the canonical Compose model at `compose.yaml`; keep Dockerfiles beside their
  owning service unless the repository has one unambiguous root image.
- Keep repository-specific engineering automation under `tools/<area>`.
- Use `scripts` only while migrating legacy automation; new scripts belong under
  `tools/<area>`.
- Put generated output under `artifacts`, `.artifacts`, or `output` and ignore it.
- Do not put screenshots, logs, one-off reports, or task proof at the root.

## Tool Areas

Use lower-case category names:

- `tools/deployment`: build, package, publish, and release entry points.
- `tools/install`: machine, dependency, and repository setup.
- `tools/validation`: repository gates and structural checks.
- `tools/dev`: local developer workflow.
- `tools/diagnostics`: probes and troubleshooting.
- `tools/migration`: bounded migrations that remain useful after execution.

Product-specific compiled tools may use PascalCase project folders below a category.

## Codex Material

- Reusable skills, agents, and plugins live in this repository under `codex`.
- A product repository may keep `.codex` for local configuration and active durable
  bundles.
- Do not mix reusable skill source with app/agent templates or generated bundle proof.
- Keep secrets, runtime state, logs, and temporary browser artifacts out of both.

## Naming

- Repository names use the `CanDoItAll.*` family prefix.
- PowerShell entry points use approved verbs and PascalCase, for example
  `Build-NuGets.ps1` or `Test-Repository.ps1`.
- Markdown file names use lower-case hyphenated names except conventional root files.
- Prefer one canonical `.slnx` at the root for .NET repositories.

Docker-owning repositories also follow
[`docker.md`](docker.md) and expose `tools/validation/Test-Docker.ps1`.
