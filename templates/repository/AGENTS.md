# Repository Agent Instructions

## Shared Standards

Follow the reviewed standards in `CanDoItAll.SharedInfo/docs/standards`. This repository
owns its local implementation and any documented exceptions.

## Repository Scope

- ${PRIMARY_OWNERSHIP_BOUNDARY}
- ${IMPORTANT_DEPENDENCY_BOUNDARY}

## Commands

- Build: `${BUILD_COMMAND}`
- Test: `${TEST_COMMAND}`
- Validate: `${VALIDATION_COMMAND}`

## Safety

- Keep sibling repositories read-only unless the user explicitly requests a multi-repo
  change.
- Do not commit generated output, local settings, credentials, or runtime state.
- Preserve repository-specific changes that are unrelated to the active task.
