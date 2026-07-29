# SharedInfo Agent Instructions

## Scope

- Treat this repository as the source of truth for shared CanDoItAll conventions,
  templates, cross-repository tooling, and reusable Codex assets.
- Keep sibling `CanDoItAll*` repositories read-only unless the user explicitly authorizes
  an adoption or migration phase.
- Do not move product code, task bundles, proof artifacts, generated output, secrets, or
  repository-specific scripts here.

## Sources Of Truth

- Put normative rules in `docs/standards`.
- Put copy-ready examples in `templates/repository`.
- Keep the family MIT license, selected-partner contribution policy, README badge contract,
  NuGet license-expression rules, NuGet package-icon contract, and third-party notice
  contract synchronized across their standards, templates, reusable skill, and validation.
  Keep the shared project website URL fixed in project metadata; adopting repositories
  replace only the documented repository metadata.
- Put cross-repository scripts in a purpose-specific `tools/<area>` folder.
- Keep repository-owned entry points in the owning repository and document their contract
  here.
- Keep reusable Codex packages in `codex`; do not mix them with product web-agent
  templates or execution bundles.

## Change Rules

- Prefer portable paths derived from the current script or repository location.
- Never hard-code a developer profile or `C:\repositories` in executable files.
- Make mutating PowerShell commands support `-WhatIf` where practical.
- Validate exact targets before recursive copy, move, or removal.
- Keep templates free of repository-specific names except clearly marked placeholders.
- Update standards, templates, tools, and validation together when a shared contract
  changes.

## Validation

Run `.\tools\validation\Test-SharedInfo.ps1` after structural or tooling changes. Run any
skill- or plugin-specific validator when those packages change.
