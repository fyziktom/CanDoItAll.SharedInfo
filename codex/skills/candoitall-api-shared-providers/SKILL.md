---
name: candoitall-api-shared-providers
description: Read CanDoItAll shared-provider catalogs and invoke published models through the bounded OpenAI-compatible HTTP API, including routing identity, scoped tokens, streaming failures, and correlation.
---

# CanDoItAll Shared Providers API

Use this skill for catalog discovery and inference against a CanDoItAll publisher.
Source registration, imports, publication administration and request-history management
remain application/UI operations; do not invent remote administration routes.

## Contract and access

Check `GET /api/access/status` and the target host's `/openapi/v1.json` or
`/swagger/v1/swagger.json`. Use the shared
[snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json) only when its
[provenance manifest](../_candoitall-api-shared/manifest.json) matches the target.
A snapshot from an uncommitted tree is not commit-clean provenance.

With authorization enabled, send the configured bearer token. Catalog/models need
`api.shared-providers.catalog.read`; inference needs `api.shared-providers.invoke`.
The existing `api` umbrella also satisfies these two policies. Token issuance itself
requires `api.tokens.issue`. Do not expose credentials in URLs, prompts or artifacts.

## Discover and invoke

1. Read the native catalog for publication/model identities, availability, capabilities,
   thinking options and public prices. Use ETag/If-None-Match for conditional reads.
2. Select the returned opaque routing model identifier (`providers[].models[].id`, starting
   `sp1.`) exactly. `displayName` is the upstream model name and must never be sent as
   `model`. Keep the publication/source identity when refreshing it.
3. Configure a compatible client endpoint at `/api/shared-providers/openai/v1`.
4. Invoke only a supported operation and supported model features.
   Read [protocol limits and failure handling](references/protocol.md) before constructing
   tools, reasoning, structured output, image, or streaming requests.
5. Inspect terminal status, usage completeness and errors. Do not retry an ambiguous
   inference automatically: it can duplicate provider work and cost. The native catalog
   fails with the general `errors` envelope (for example
   `shared-provider.catalog.unavailable`). The OpenAI-compatible routes use the OpenAI
   `error` object; branch on `error.code`.

Invocation may consume paid upstream resources. A catalog-read request does not authorize
an inference test. Respect the user's requested call and any stated budget.

## Attribution and history

Optional `CanDoItAll-Access-Context-Ref` and `CanDoItAll-Access-Context-Type` headers are
opaque correlation, never authorization. Type requires a reference. They are not
forwarded upstream. The publisher returns `CanDoItAll-Request-Id`; keep it with sanitized
failure evidence. Managed credential/caller identity is derived by the server.

History represents application-visible attempts, not every SDK/HTTP retry. Light mode
retains metadata; Detailed standalone content is bounded, redacted and encrypted.
Canonical content remains authorized by its owner. Do not infer a general history HTTP
API from the `api.provider-history.*` service/UI scopes.

## Source route appendix

<!-- api-docs-skills-parity:routes:start -->

| Method | Route |
| --- | --- |
| `POST` | `/api/shared-providers/openai/v1/chat/completions` |
| `POST` | `/api/shared-providers/openai/v1/images/generations` |
| `GET` | `/api/shared-providers/openai/v1/models` |
| `POST` | `/api/shared-providers/openai/v1/responses` |
| `GET` | `/api/shared-providers/v1/catalog` |
<!-- api-docs-skills-parity:routes:end -->
