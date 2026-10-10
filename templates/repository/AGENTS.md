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

## Development Build And Fixture Reuse

- Reuse standard `Debug` and `Release` configurations and refresh existing `bin`/`obj`
  outputs. Never create bundle-, stage-, attempt- or timestamp-named configurations or
  compiled output trees. Serialize builds that share outputs.
- Reuse dotnetwatch for relevant UI application/sandbox iteration when useful, then
  confirm the affected build/tests on current standard outputs.
- Reuse a suitable explicitly isolated test fixture and bounded database leases. Do not
  create a Docker stack per bundle or stage. A dedicated fixture needs a concrete test
  reason, recorded ownership and cleanup after its last use, including interruptions.
- Preserve ordinary application/database instances, installed tools and useful unrelated
  resources. Historical custom-configuration commands are execution records.

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
