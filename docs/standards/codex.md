# Codex Asset Standard

## Source Layout

```text
codex/
  agents/
  architecture-review/
  csharp-architecture/
  plugins/
  skills/
  marketplace.json
```

Only reusable, maintained assets belong here. Product task bundles, screenshots, runner
state, proof logs, app templates, and product-only skills remain in their owning
repositories.

## Skills

- Each discoverable skill folder contains `SKILL.md` with only `name` and `description`
  frontmatter.
- Folder and skill names use lower-case hyphenated names.
- Keep the main instructions concise and put conditional detail under `references`.
- Put deterministic helpers under `scripts` and output resources under `assets`.
- Keep every skill self-contained after installation into a flat Codex skills directory.
- Validate changed skills with the current Codex skill validator.

The installer discovers nested source groups but installs each skill by its package name.
It refuses duplicate names and does not overwrite existing installations without
`-Force`. Use `-PackageName` for an exact, reviewable subset; include any underscore
support package required by a selected skill.

Use `apply-candoitall-shared-standards` as the entry skill when working in a CanDoItAll
repository. It locates SharedInfo without a fixed machine path and routes the task to the
smallest relevant set of canonical documents and templates. The skill summarizes
invariants but does not replace the repository documents.

## Shared API Contracts

- Keep one generated CanDoItAll web OpenAPI snapshot in a non-discoverable underscore
  support package under `codex/skills`.
- Generate the snapshot from a clean product-repository commit and record the commit,
  runtime document paths, environment, SHA-256, OpenAPI version, and path, operation, and
  schema counts.
- Capture from the repository's canonical development URL so the OpenAPI `servers` value
  and content hash do not drift with an arbitrary temporary port.
- Record route-family counts that account for every documented path and operation.
- Make every skill that operates the web API link to the shared snapshot and its
  provenance manifest.
- Treat a target host's live OpenAPI document as authoritative when its version differs
  from the recorded snapshot.
- Update the snapshot, API-skill guidance, provenance, and validation together when the
  web API contract changes.

## Agents

Reusable agent profiles are source material. Copy only the profiles a target repository
needs into that repository's `.codex/agents` folder. A profile must state whether it is
read-only and must not claim to be read-only while allowing edits.

## Plugins

- Every plugin contains `.codex-plugin/plugin.json`.
- Companion `.mcp.json`, `.app.json`, `skills`, or assets exist only when the manifest
  declares them.
- Plugins must launch implementations from the repository that owns the implementation;
  do not duplicate MCP source here.
- Portable launchers derive sibling repository paths and fail with actionable messages.
- `codex/marketplace.json` is the repository marketplace catalog.

## Migration Provenance

The initial development/architecture/API skill set and Components plugin were mirrored
from `CanDoItAll`. The CFO skill set was mirrored from `CanDoItAll.Economy`. Those source
repositories remain unchanged until a separate cleanup phase is approved.
