# Installation Guide

## SharedInfo installation

From the `CanDoItAll.SharedInfo` root, preview installation:

```powershell
.\tools\install\codex\Install-CodexSkills.ps1 -WhatIf
```

Install missing skills and their shared support folder:

```powershell
.\tools\install\codex\Install-CodexSkills.ps1
```

Refresh repository-managed copies intentionally:

```powershell
.\tools\install\codex\Install-CodexSkills.ps1 -Force
```

The installer flattens discoverable skill packages into the target Codex skill root and
keeps `_csharp-architecture-shared` beside them. The examples, templates, checklists, and
integration notes in this folder remain shared source material; they are not discoverable
skills.

For a repository-local skill setup, copy the required `csharp-*` skill folders,
`_csharp-architecture-shared`, and
`bundles/candoitall-csharp-architecture-bundle-guard` into that repository's selected
skill root.

## Activation triggers for Codex

Tell Codex to use these skills whenever the request includes any of these signals:

- refactor large class
- split partial class
- isolate provider
- add new tool
- add new memory provider
- add new process driver
- add workflow executor
- add runtime capability
- create builder
- create factory
- fix cyclic reference
- improve testability
- prepare architecture bundle
- review architecture before implementation

## Minimal prompt addition

Add this line to bundle preparation prompts:

```text
If the bundle touches C# architecture, large-class refactoring, tool/provider/memory/process/runtime composition, or project references, load `candoitall-csharp-architecture-bundle-guard` and require a C# Architecture Gate before implementation.
```
