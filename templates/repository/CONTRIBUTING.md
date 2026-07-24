# Contributing

## Contribution Policy

${CONTRIBUTION_POLICY_AND_CONTACT}

## Development Setup

1. Install the SDK pinned by `global.json`.
2. Install ${OTHER_REQUIRED_TOOLS}.
3. Run commands from the repository root.

## Validation

```powershell
dotnet restore ${SOLUTION_FILE}
dotnet build ${SOLUTION_FILE} --configuration Release --no-restore
dotnet test ${SOLUTION_FILE} --configuration Release --no-build
```

Add repository-specific architecture, browser, packaging, or integration gates here.

## Architecture Rules

- ${ARCHITECTURE_BOUNDARY}
- Keep generated output and local state out of Git.
- Update documentation when public behavior or package contracts change.

## Pull Requests

- Keep changes focused.
- Add or update tests for behavior changes.
- Describe public API and migration effects.
- Include the exact validation commands and results.
