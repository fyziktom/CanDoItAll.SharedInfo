---
name: candoitall-api-cognitive-memory
description: Use when inspecting the retired CanDoItAll base-host Cognitive Memory HTTP surface, reading its migration contract, or verifying 410 Gone guidance for legacy clients.
---

# CanDoItAll Cognitive Memory API

Use this skill for the Cognitive Memory retirement surface that remains in the main
CanDoItAll web host. The former in-process ingestion, recall, consolidation, projection,
review, and distributed-work endpoints are not current base-host APIs.

## Contract Source

- Use the shared
  [OpenAPI snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  for exact schemas when it matches the target source version.
- Check the snapshot's [provenance manifest](../_candoitall-api-shared/manifest.json)
  before relying on it.
- When the target host differs, inspect its live `/openapi/v1.json` or
  `/swagger/v1/swagger.json` document.
- Check `GET /api/access/status` before assuming bearer tokens are required.

## Current Surface

Two compatibility bases are registered:

- `/api/cognitive-memory`
- `/api/cognitive-memory/v1`

Read `GET {basePath}/contract` to obtain the `retired-v1` contract. It identifies the
compatibility base, the generic Memory UI path `/memory`, and the migration guidance.

Every `GET`, `POST`, `PUT`, `PATCH`, or `DELETE` request to either base root or any
catch-all path returns `410 Gone`. The response reports:

- `status`
- `message`
- `requestedPath`
- `contractPath`
- `genericMemoryUiPath`
- `guidance`

The base host directs callers to generic Memory UI/API surfaces and explicit memory
provider profiles. Configure the native remote provider driver when a separate native
Cognitive Memory service is required.

## Operating Rules

- Do not call the former status, database-profile, ingestion, recall, consolidation,
  projection, settings, review, probe, professor-review, epistemic-drive, or distributed
  job routes through the main web host.
- Do not write directly to old Cognitive Memory tables or call Qdrant as a substitute for
  the removed API.
- Treat `410 Gone` as an intentional migration response, not a transient host failure.
- Discover the separate native service from its own configured provider and contract; do
  not infer its address or routes from the retired base-host paths.

## Validation

1. Read both legacy and v1 contract endpoints.
2. Verify the response version is `retired-v1` and the status is
   `Retired from base host`.
3. Send a non-mutating `GET` to an old path and verify `410 Gone`, the requested path, and
   actionable migration guidance.
4. Verify the client does not retry the retired path as though it were a transient error.

## Source Route Appendix

The catch-all `{path}` entries represent the source route parameter `{**path}`.

<!-- api-docs-skills-parity:routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/cognitive-memory/contract` |
| `GET` | `/api/cognitive-memory` |
| `POST` | `/api/cognitive-memory` |
| `PUT` | `/api/cognitive-memory` |
| `PATCH` | `/api/cognitive-memory` |
| `DELETE` | `/api/cognitive-memory` |
| `GET` | `/api/cognitive-memory/{path}` |
| `POST` | `/api/cognitive-memory/{path}` |
| `PUT` | `/api/cognitive-memory/{path}` |
| `PATCH` | `/api/cognitive-memory/{path}` |
| `DELETE` | `/api/cognitive-memory/{path}` |
| `GET` | `/api/cognitive-memory/v1/contract` |
| `GET` | `/api/cognitive-memory/v1` |
| `POST` | `/api/cognitive-memory/v1` |
| `PUT` | `/api/cognitive-memory/v1` |
| `PATCH` | `/api/cognitive-memory/v1` |
| `DELETE` | `/api/cognitive-memory/v1` |
| `GET` | `/api/cognitive-memory/v1/{path}` |
| `POST` | `/api/cognitive-memory/v1/{path}` |
| `PUT` | `/api/cognitive-memory/v1/{path}` |
| `PATCH` | `/api/cognitive-memory/v1/{path}` |
| `DELETE` | `/api/cognitive-memory/v1/{path}` |

<!-- api-docs-skills-parity:routes:end -->
