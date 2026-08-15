# Test Selection And Invalidation

Validation cost follows the changed contract, not repository size. Proof tier controls
evidence depth and durability; it does not select test breadth. A Governed subbundle can
use focused tests, and a Standard subbundle does not gain confidence from unrelated
solution-wide execution.

## Default Selection

For each subbundle:

1. Map changed behavior and contracts to their owning production and test projects.
2. Select the narrowest stable `FullyQualifiedName`, class, namespace/topic, or trait/category filter that proves the behavior.
3. Add one dependent-flow smoke only when the subbundle is a critical foundation.
4. Record the expected discovered test count or exact named cases before execution.
5. Treat zero tests or an unexpected discovery count as a failed validation command.
6. Build affected projects once, then use `--no-build` or equivalent only while the tested binaries and dependency mode remain current.

Use an explicit `N/A` with the owning static, analyzer, browser, or host check when no
automated test applies. Do not substitute an unfiltered large test project or solution
because test organization is weak.

## Broad Gate Decision

An unfiltered project or solution gate requires a named invalidation trigger that the
focused selection cannot bound. Valid triggers include an actual change to:

- shared build, SDK, dependency, generated-code, or test infrastructure;
- a public contract consumed across otherwise independent packages;
- shared serialization, persistence schema, migration, or runtime composition;
- repository-wide configuration or dependency anchors;
- an explicit user, merge, release, or CI requirement.

Name the changed file or contract and the scopes it invalidates. Task size, proof tier,
habit, and missing test taxonomy are not triggers. Schedule an authorized broad gate once
at a named frozen checkpoint after affected checks pass; do not repeat it after evidence,
documentation, checksum, or unrelated changes.

## Evidence Reuse And Expansion

Reuse earlier proof only when its source/test inputs, build configuration, dependency
mode, and declared invalidation keys remain unchanged. When a focused test fails, diagnose
that owning scope first and expand only to the nearest newly implicated contract. Record
unrelated broad-gate failures honestly; do not repair them or weaken the selected proof
without an explicit scope decision.

## Required Record

Preparation and closure must agree on:

- test project or non-test check;
- filter or topic and selection reason;
- expected and actual discovery;
- invalidation keys;
- broad-gate decision, named trigger, and frozen checkpoint when applicable;
- exact command and result.
