# Documentation Standard

## README Contract

Every repository README must let a new contributor answer these questions without reading
the full source:

1. What does this repository own?
2. What does it explicitly not own?
3. Which projects or packages are the public entry points?
4. What must be installed?
5. How is the smallest useful build/test/run performed?
6. Where are detailed architecture, operations, and security documents?
7. How are packages or releases produced, if applicable?
8. What license and contribution policy applies?
9. What is the current CI, package, platform, and license status?

Start from [`templates/repository/README.md`](../../templates/repository/README.md).
Remove irrelevant sections instead of leaving placeholders.

## README Badges

Put applicable status badges immediately below the level-one repository heading. Use this
stable order:

1. CI status for the primary validation workflow on `main`;
2. current version and total downloads for the primary user-facing NuGet package;
3. when the repository has two co-equal product entry points, the version and total
   downloads for the second user-facing package;
4. the supported .NET major version;
5. the family license.

Start from the badge block in the README template and remove badges that do not apply. A
repository with no public package omits all NuGet badges; a non-.NET repository omits the
.NET badge. Do not publish decorative, stale, or guessed status badges.

- CI badges must link to the canonical workflow and identify the workflow file, `main`
  branch, and intended event.
- Select the one or, at most, two NuGet packages that users are most expected to install
  to obtain the repository's main capabilities. Prefer user-facing entry or component
  packages over dependency-layer packages such as `Abstractions`, `Core`, or providers.
- When two packages represent distinct co-equal product surfaces, show a version/download
  pair for each. Otherwise show one pair; do not turn the badge block into a package
  inventory.
- NuGet badges must link to the canonical package page and use labels that distinguish
  the selected user-facing packages.
- The .NET badge must link to the supported .NET download page.
- The license badge must link to the repository-owned `LICENSE` file and say
  `MIT-derived with website link`.

## Durable Documentation

- Put architecture decisions, operating guides, and maintained maps under `docs`.
- Link important documents from the root README.
- Prefer relative links and verify them in validation.
- Record commands that are runnable from the repository root.
- State whether commands mutate data, require services, or publish artifacts.
- Keep current behavior in the main document; use version control instead of inline
  changelog prose unless a release history is itself a product requirement.

## Policies

Repositories distributed outside one private development machine should include:

- `CONTRIBUTING.md` with setup, validation, architecture constraints, and contribution
  policy.
- `SECURITY.md` with supported versions and a private reporting path.
- The family `LICENSE` adapted from
  [`licensing.md`](licensing.md), unless the owner has documented an explicit legal
  exception.

The contribution policy is family-wide:

- Code contributions are accepted only from partners who have been explicitly approved
  by the maintainer.
- Unsolicited pull requests are not accepted.
- Prospective partners contact the maintainer through the `fyziktom` account on LinkedIn
  and wait for approval before preparing or opening a pull request.
- The README states that code contributions are limited to approved partners and links to
  `CONTRIBUTING.md`.

Repositories may add setup, validation, architecture, and approved-partner pull-request
guidance, but must not weaken or contradict this policy. Security templates deliberately
leave reporting details as explicit placeholders.

## Generated Evidence

Do not place generated proof at the root. Keep transient evidence ignored under
`artifacts`/`output`. Commit evidence only when it is a durable delivery artifact; place it
inside the owning bundle or a clearly named documentation folder.
