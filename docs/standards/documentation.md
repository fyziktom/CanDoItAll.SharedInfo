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

Start from [`templates/repository/README.md`](../../templates/repository/README.md).
Remove irrelevant sections instead of leaving placeholders.

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
- A license file chosen by the owner. SharedInfo does not impose a license because current
  repositories use different policies.

The templates deliberately leave owner and reporting details as explicit placeholders.

## Generated Evidence

Do not place generated proof at the root. Keep transient evidence ignored under
`artifacts`/`output`. Commit evidence only when it is a durable delivery artifact; place it
inside the owning bundle or a clearly named documentation folder.
