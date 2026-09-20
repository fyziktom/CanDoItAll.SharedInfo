# API access, sessions and capabilities

Use this reference with the [shared contract](candoitall-web.openapi.json) and its
[provenance](../manifest.json). A target host's live OpenAPI document and
`GET /api/access/status` take precedence when the version or exposure settings differ.
The product owns [deployment configuration and password provisioning](https://github.com/fyziktom/CanDoItAll/blob/development/docs/api-user-access.md).

## Discover the exposed surface

| Configuration | Effective behavior |
| --- | --- |
| `Api:Enabled=false` | Main API is absent. Separately mapped runtime, Project Structure and file routes retain their own switches and policies. |
| Main API on, JWT off, user authentication and management off | Trusted open business API; no account isolation or HTTP administration. |
| `Api:Authorization:Enabled=true`, user authentication off | Machine/legacy business access. Login, self-session and HTTP management routes are absent. |
| `Api:UserAuthentication:Enabled=true` | Login/me/logout are mapped. Main API, JWT, a valid configured administrator hash and valid session lifetime are required. |
| `Api:AccessManagement:Enabled=true` | Account, capability-catalog and token administration are mapped; user authentication must also be enabled. A registered configured-administrator session is required. |
| `Api:OpenApiEnabled=true` | Both `/openapi/v1.json` and `/swagger/v1/swagger.json` are anonymous, even with JWT enabled. |
| `Api:SwaggerUiEnabled=true` and OpenAPI enabled | `/swagger` loads anonymously. Disabling Swagger UI leaves the documents available; disabling OpenAPI disables both documents and UI. |

JWT, user authentication and HTTP management are separate settings. Invalid combinations
fail startup; a missing signing key or administrator hash never opens access. A disabled
HTTP surface returns 404. Settings → API access is an in-process operator surface and
must be protected separately from HTTP API access.

## Obtain and use the correct credential

- `POST /api/access/login` accepts `userName` and `password`, returning a registered JWT,
  expiry and safe session identity. User passwords are not trimmed. There is no default
  administrator password and no refresh-token flow.
- Ordinary accounts receive explicit business capabilities. The configured administrator
  manages access but does not implicitly receive business capabilities.
- `GET /api/access/me` reads a user or administrator session; it is not a validation
  endpoint for machine tokens. `POST /api/access/logout` revokes only the current session
  and returns 204. Log in again after expiry or revocation.
- Machine credentials come from the trusted local Settings workflow or, when enabled,
  `POST /api/access/tokens` authenticated by a registered administrator session.
  Broad `api`, legacy `api.tokens.issue`, an administrator-looking subject and claimed
  roles do not grant HTTP administration. The token plaintext is returned only at issue.
- Send `Authorization: Bearer <token>` on protected operations, including event streams.
  Do not put credentials in URLs, prompts, tracked files, request logs or browser storage.
  Access operations and token-bearing responses use `Cache-Control: no-store`.
- For Swagger, use the host's HTTPS address, select **Authorize**, and paste the raw JWT
  into **Bearer**, without the prefix. **Try it out** sends the header for protected
  operations. **Logout** in that dialog only clears Swagger's stored authorization;
  call `/api/access/logout` to revoke a session on the server.

When user authentication is enabled, API and authorized-file traffic requires HTTPS.
The opt-in `Api:UserAuthentication:AllowLoopbackHttp` exception accepts only direct
original/effective loopback peers without forwarding headers. It is not a proxy setting.
Use exact trusted proxy addresses and allowed browser origins; loopback HTTP API calls
never inherit local Blazor operator privileges.

## Select business capabilities

Read `GET /api/access/scopes` as an administrator for the current server-owned catalog,
credential-kind selection limits and sensitive-grant markers. Ordinary accounts cannot
receive reserved `api`, `api.tokens.issue`, `api.session` or `api.access.manage` grants.
An empty business selection permits self-session operations only. Read, write and execute
capabilities are independent; requesting execution does not grant read access.

| Surface | Capabilities when JWT is enabled |
| --- | --- |
| Projects | `api.projects.read`, `api.projects.write` |
| Agents, governed agent chats and execution | `api.agents.read`, `api.agents.write`, `api.agents.execute`; recovery/reconciliation retains exact `api`; human recruiting review retains exact `agent-recruiting.review` |
| Workflows | `api.workflows.read`, `api.workflows.write`, `api.workflows.execute`; durable external responses and response-operation reads require exact `api.workflows.respond` |
| Processes | `api.processes.read`, `api.processes.write`, `api.processes.execute`; launch/check, launch, dispatch, cancel and rework use execute |
| Prompt Gallery | `api.prompts.read`, `api.prompts.write` |
| CRM/HR | `api.crm-hr.read`, `api.crm-hr.write` |
| Plugins | `api.plugins.read`, `api.plugins.write` |
| Workspace settings | `api.settings.workspace.read`, `api.settings.workspace.write` |
| Runtime status | `api.runtime.read` |
| Project Structure, including reads | `api.project-structure.write` |
| Memory providers | `api.memory-providers.read`, `api.memory-providers.write`, `api.memory-providers.query` |
| Simple Chats | Exact `api.llm-chats.read`, `api.llm-chats.manage`, `api.llm-chats.execute` |
| Shared providers | `api.shared-providers.catalog.read`, `api.shared-providers.invoke` |

The compatibility `api` umbrella remains accepted only where the target policy supports
it; it never substitutes for an exact scope or administrator session. Request-history
and storage-recovery capabilities retain their additional owner, project and service
restrictions. Publication grants, tool approvals and domain ownership checks still apply.
A valid shared-provider JWT cannot read other API sections solely because it is signed.

## Manage accounts and registrations

Use the [access skill](../../candoitall-api-access/SKILL.md) for the operation sequence.
Account updates and password resets require the current `expectedVersion` from a read; deletion
sends it in the query. A stale version or duplicate username returns 409. Read and
reconcile after a conflict instead of overwriting another operator's change.

Profile, permission, password and enabled-state changes invalidate that user's existing
sessions at the next validation. Re-enabling does not restore old sessions; deleting and
recreating a username creates a new GUID. Account changes do not revoke unrelated machine
credentials. Rotating the administrator hash invalidates administrator sessions; changing
the signing key invalidates all tokens signed with it.

The token list defaults to machine metadata. `kind=UserSession` or
`kind=AdministratorSession` selects session registrations. Revoke or delete the exact
registration requested by the operator; neither operation reveals the original token.
Accounts and registrations live under the private control-plane root and survive a
workspace database-profile switch. Do not emulate management by editing their files.

## Handle failures and active streams

Use status and the operation's documented JSON envelope. Distinguish unauthenticated 401,
authenticated-but-forbidden 403, disabled/missing 404, stale/duplicate 409, login throttling
429 (with `Retry-After`), infrastructure 503 and unexpected 500. API transport failures
return safe JSON; preserve domain-specific errors and Problem Details rather than assuming
one envelope for every operation. A 403 is not permission to broaden grants.

Active event streams revalidate credentials before sensitive frames and at most every
15 seconds while idle. Expiry, account changes and registry revocation can close a live
stream. Obtain an authorized session before reconnecting, then follow that API's cursor,
retention and canonical read-back rules. Never silently replace an expired user session
with an administrator or broad machine token.
