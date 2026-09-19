---
name: candoitall-api-prompt-gallery
description: Use when searching, reading, creating, versioning, archiving, checking compatibility, managing warning suppressions, or rebuilding the search projection for canonical CanDoItAll prompt items through the HTTP API.
---

# CanDoItAll Prompt Gallery API

Operate the canonical prompt and prompt-part library through the CanDoItAll web API. Do not write reusable prompt content through workflow-component endpoints; workflows consume Gallery items and immutable versions.

## Access

- Start the web app and inspect `/swagger` or `/openapi/v1.json` before generating a client.
- Check `/api/access/status` before assuming bearer authentication is disabled.
- When API authorization is enabled, send `Authorization: Bearer <token>`.
- Before exposing the host outside a trusted local environment, set `Api:Authorization:Enabled` to `true` and provide a secret signing key of at least 32 bytes. The repository's local-first defaults do not protect mutation or projection endpoints.

## Contract Source

- Use the shared
  [OpenAPI snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  for exact schemas when it matches the target source version.
- Check the snapshot's [provenance manifest](../_candoitall-api-shared/manifest.json)
  before relying on it.
- When the target host differs, use its live `/openapi/v1.json` or
  `/swagger/v1/swagger.json` document.

## Browse And Read

- Search with `GET /api/prompt-gallery/items`.
- Use `text`, repeated `tag`, `kind`, `status`, `includeArchived`, `favoritesOnly`, `provider`, `model`, `consumer`, `pageIndex`, and `pageSize` query values.
  Query enums accept case-sensitive names or integers; body enums are JSON integers. Search
  returns only a 280-character draft preview.
- Read an item with `GET /api/prompt-gallery/items/{promptId}`.
- Read an immutable version with `GET /api/prompt-gallery/items/{promptId}/versions/{versionId}`.
- Page instead of fetching the entire catalog. Treat returned totals as point-in-time search metadata.

## Change Items

- Create or update a draft with `POST /api/prompt-gallery/items`.
- Draft updates and version creation both require `expectedUpdatedAtUtc`, compared exactly. A
  stale value returns HTTP 400 (not 409) with `prompts.gallery.concurrency-conflict`; reread and
  reconcile instead of overwriting. A draft save replaces `tags`, `supportedModels` and
  `supportedConsumers` (omitted or null clears them), sets the item to Draft and restores an
  archived item; create a version to make it Final. Use the `updatedAtUtc` returned by a draft
  save for the next write; version creation, archiving and favorite changes also change it, so
  read the item again after them.
- Create an immutable version with `POST /api/prompt-gallery/items/{promptId}/versions`.
- Archive with `POST /api/prompt-gallery/items/{promptId}/archive`; do not hard-delete reusable content.
- Set the favorite mark with `POST /api/prompt-gallery/items/{promptId}/favorite`; the mark is
  stored on the item, the same for every caller.
- The API cannot create an item under a caller-chosen id. Send `id: null` to create (every such
  call creates another item), or an existing item's id to overwrite its draft; an unknown id
  returns 404 `prompts.gallery.not-found`.
- `source` and `templateTokens` are read-only here. The packaged-catalog import sets them, and
  the HTTP draft save neither accepts nor changes them.

## Compatibility And Search Projection

- Evaluate provider/model compatibility with `POST /api/prompt-gallery/compatibility/evaluate` before inserting into an agent chat or workflow.
- Store a warning suppression with `POST /api/prompt-gallery/warning-suppressions` only after
  explicit user choice. A suppression is stored per item and consumer and shared by every
  caller; it is not a personal preference. It covers only ItemKindMismatch (3) and
  ProviderModelNotSupported (4) in Selection evaluations and never affects Execution
  evaluations.
- Never suppress execution-blocking compatibility errors.
- Read projection state with `GET /api/prompt-gallery/projection`.
- Run `POST /api/prompt-gallery/projection/rebuild` only when the configured projection driver
  is enabled. The projection only feeds the application's global search index; Gallery search
  reads the canonical items. It is disabled in the default host configuration, so a rebuild
  returns `state` 0 (Disabled) with `processedCount` 0.

## Operating Rules

- Gallery owns title, kind, tags, favorite mark, prompt text, versions, provenance, portable provider/model compatibility, an optional preferred pair, and parameter recommendations.
- Workflow definitions own execution topology, provider profile selection, permissions, ports, and an immutable prompt snapshot/reference.
- Read an exact version for reproducible workflow execution. Use current draft content only for interactive authoring.
- Keep prompt content out of logs, URLs, and error messages. Log ids, version numbers, source keys, and content lengths instead.
- Validate mutations by reading the item or immutable version back.
