---
name: candoitall-api-access
description: Use when authenticating to CanDoItAll, using Swagger JWT authorization, or managing API users, capabilities, sessions and machine-token registrations through the HTTP API.
---

# CanDoItAll API Access

Use the supported access API for account and credential operations. The configured
administrator manages access; business operations use separately granted capabilities.

## Contract and exposure

- Inspect anonymous `GET /api/access/status` and the target host's OpenAPI document.
- Use the [shared snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  when its [provenance manifest](../_candoitall-api-shared/manifest.json) matches the target.
- Read [authentication, configuration and capability rules](../_candoitall-api-shared/references/access-and-authentication.md)
  before choosing a credential or interpreting a 401, 403 or 404.
- `Api:UserAuthentication:Enabled` maps login/me/logout; `Api:AccessManagement:Enabled`
  separately maps administrator operations. A disabled surface returns 404.
- Swagger and its documents are anonymous when enabled. Use HTTPS and **Authorize** with
  a raw JWT to call protected operations. Swagger's **Logout** clears its authorization;
  the API logout operation revokes the current session.

## Session workflow

1. Use the intended host and the caller's supplied or privately configured credentials.
   Send `userName` and `password` to `POST /api/access/login`; never print credentials.
2. Send the returned token as `Authorization: Bearer <token>`. Use `GET /api/access/me`
   for the current user/administrator session, not for machine-token validation.
3. Handle expiry and revocation by authenticating again; there is no refresh-token flow.
   `POST /api/access/logout` revokes only that session.

## Account administration

Use a registered configured-administrator session on a management-enabled host.
A token claiming `api`, `api.tokens.issue`, a role or an administrator-looking subject
cannot substitute. Ordinary users cannot be promoted through account properties.

1. Read `/api/access/scopes` and select only the requested, user-selectable capabilities.
   Read/write/execute grants are independent; an empty business selection is self-session only.
2. Search `/api/access/users` before creating an account when avoiding duplicates matters.
   Paging uses `offset` and `pageSize` (default 25, maximum 100).
3. Create with explicit `userName`, `displayName`, `password`, `enabled` and `scopes`.
   The returned account GUID is the identity; the configured administrator name is reserved.
4. Read the account and carry its current version as `expectedVersion` in a replacement
   or password reset, or in the delete query. On 409, reread and reconcile.
5. Read back the result. Profile, grant, password and enabled-state changes invalidate
   existing sessions. Re-enabling never restores them; a recreated username gets a new GUID.

Perform only the requested account/grant changes. Do not edit private account or registry
files to work around a denied operation. Workspace settings are a separate business API:
see [workspace settings](../candoitall-api-workspace-settings/SKILL.md).

## Machine tokens and session registrations

Issue a machine credential at `POST /api/access/tokens` using administrator authority.
Select machine-assignable catalog capabilities and an allowed lifetime. Return/store the
one-time plaintext only through the caller's intended private credential channel.

`GET /api/access/tokens` lists metadata, defaulting to machine credentials; use
`kind=UserSession` or `kind=AdministratorSession` for session metadata. Revoke with
`POST /api/access/tokens/{id}/revoke` or delete the exact registration at
`DELETE /api/access/tokens/{id}`. Account edits do not revoke unrelated machine tokens.

## Source route appendix

<!-- api-docs-skills-parity:routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/access/status` |
| `POST` | `/api/access/login` |
| `GET` | `/api/access/me` |
| `POST` | `/api/access/logout` |
| `GET` | `/api/access/scopes` |
| `GET` | `/api/access/users` |
| `POST` | `/api/access/users` |
| `GET` | `/api/access/users/{id}` |
| `PUT` | `/api/access/users/{id}` |
| `DELETE` | `/api/access/users/{id}` |
| `POST` | `/api/access/users/{id}/reset-password` |
| `GET` | `/api/access/tokens` |
| `POST` | `/api/access/tokens` |
| `POST` | `/api/access/tokens/{id}/revoke` |
| `DELETE` | `/api/access/tokens/{id}` |

<!-- api-docs-skills-parity:routes:end -->
