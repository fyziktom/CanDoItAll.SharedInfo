# Project external identity

Use the optional external namespace/key pair for repeatable project provisioning.
It is independent of display names and unique within the active database profile,
including archived projects. Do not fall back to display-name matching, marker scans
or a local state file when a binding is missing or conflicts.

## Write and resolve

Create through `POST /api/projects` with `name`, `externalNamespace` and `externalKey`.
The normal project editor contract still applies. The response is the new project UUID.
Both identity tokens are trimmed and lowercased and must each contain 1–100 ASCII
letters, digits, dots, underscores or hyphens, with alphanumeric ends.

```http
GET /api/projects/by-external-key/hotels-ai-demos/corallune-guest-journey
```

The response is `ProjectExternalIdentityResolution`:

```json
{
  "projectId": "00000000-0000-0000-0000-000000000001",
  "lifetimeId": "00000000-0000-0000-0000-000000000002",
  "externalNamespace": "hotels-ai-demos",
  "externalKey": "corallune-guest-journey"
}
```

Identifiers above are illustrative synthetic values, not usable admissions. On later
lookups send `?expectedLifetimeId=<previous lifetime>`. Before editing, read the editor
by UUID and verify its `expectedLifetimeId` equals the resolution. Preserve that value
on save. The older editor GET returns a blank template for an unknown UUID; reject that
as a missing read instead of accidentally creating a replacement.

The lookup requires `api.projects.read`; saves require `api.projects.write`. These are
operator scopes. Internal agents retain their independent project-access and lifetime
authorization requirements.

## Compatibility and recovery

Omitting both fields, or sending both null, preserves an existing identity. A new
project remains unbound. Supplying either field requires a complete valid pair. Saving
a pair on an existing project requires a nonempty current `expectedLifetimeId`.
An assigned pair is immutable; empty strings cannot clear it. Renaming and archiving
preserve it. Physical deletion releases it, and a recreated binding has a new lifetime.

| HTTP | Error code | Action |
| --- | --- | --- |
| 400 | `projects.external-identity-invalid` | Correct both tokens or the empty lookup lifetime. |
| 400 | `projects.external-identity-lifetime-required` | Read the existing project and return its current lifetime. |
| 404 | `projects.not-found` | Binding or explicitly supplied save UUID is absent; do not guess a project. |
| 409 | `projects.external-identity-conflict` | Read the binding and review duplicates or concurrent changes before another save. |
| 409 | `projects.external-identity-immutable` | Keep the assigned pair; do not silently substitute another key. |
| 409 | `projects.lifetime-changed` | Lookup found a different lifetime; review the replacement. |
| 400 | `projects.lifetime-changed` | Existing editor-save contract rejected a stale lifetime; reread deliberately. |

Errors use the standard `errors` array. Malformed request binding can return a framework
400 without that envelope. Duplicate create is not an upsert. After an ambiguous network
outcome, resolve and inspect before deciding whether any further write is needed.

Profile/package transfers preserve the external pair and create fresh target lifetimes.
Target collisions fail explicitly. The additive PostgreSQL migration preserves legacy
unbound projects and rejects downgrade while assigned identities exist.
