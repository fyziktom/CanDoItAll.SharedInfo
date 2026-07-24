# Git Standard

## Tracked Baseline

Every repository should track:

- `.editorconfig` for editor-neutral formatting.
- `.gitattributes` for line-ending normalization and binary classification.
- `.gitignore` for generated and local state.

Use the files under [`templates/repository`](../../templates/repository) as the baseline.
Add local entries only for real repository-specific output or secrets.

## Ignore Principles

- Ignore output by category, not by one developer's absolute path.
- Ignore `bin`, `obj`, test results, coverage, package artifacts, IDE state, browser
  output, Codex temporary state, MCP state, and local settings.
- Do not ignore source folders broadly and then recover them with fragile exception chains.
- Do not commit `.env`, `*.local.json`, account keys, access tokens, or generated
  certificates.
- Keep prepared durable Codex bundles visible to Git; ignore their transient logs,
  archives, and runner state.

## Branches And Commits

- Keep `main` buildable.
- Use `codex/` as the default prefix for Codex-created branches.
- Keep commits scoped to one coherent change.
- Do not combine generated artifacts with source changes unless the artifact is a required,
  reviewed deliverable.

## Line Endings

Normalize text to LF in Git. Scripts must not depend on Windows-only line endings.
Mark binary formats in `.gitattributes` so Git never attempts text conversion.
