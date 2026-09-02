# Repository Agent Instructions

## Shared Standards

Follow the reviewed standards in a resolved `CanDoItAll.SharedInfo` clone. This
repository owns its local implementation and any documented exceptions.

Use `$apply-candoitall-shared-standards` when available. It checks an explicit
`CANDOITALL_SHAREDINFO_ROOT` and nearby sibling locations without assuming that
SharedInfo is a child of this repository or that every machine uses the same root.

## Repository Scope

- ${PRIMARY_OWNERSHIP_BOUNDARY}
- ${IMPORTANT_DEPENDENCY_BOUNDARY}

## Commands

- Build: `${BUILD_COMMAND}`
- Test: `${TEST_COMMAND}`
- Validate: `${VALIDATION_COMMAND}`

## Validation Closure

Read this repository's testing guide and current CI workflow before choosing validation
for a CI/test repair or changes to source, build/configuration, or tooling. Use the
shared-standards skill to identify applicable gates.

If this repository owns `portability-static` or another reviewed source baseline,
complete its review-and-refresh procedure in the same change. Focused tests or leaving
the full suite to CI do not waive that gate. Review every delta before writing the
baseline, include new protected files in the scan, and require final no-write enforcement.

## Safety

- Keep sibling repositories read-only unless the user explicitly requests a multi-repo
  change.
- Do not commit generated output, local settings, credentials, or runtime state.
- Preserve repository-specific changes that are unrelated to the active task.
