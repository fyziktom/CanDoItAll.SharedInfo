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
`-Force`.

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
