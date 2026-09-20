---
name: candoitall-api-workspace-settings
description: Use when reading or updating CanDoItAll workspace business defaults through the HTTP API, including workspace name, default provider, output format, currency, culture and notes.
---

# CanDoItAll Workspace Settings API

Use this skill for `/api/settings/workspace`. API exposure, users, credentials and
administrator configuration belong to the separate [access skill](../candoitall-api-access/SKILL.md).

## Contract and authority

- Check `GET /api/access/status` and the running host's OpenAPI document.
- Use the [shared snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  when its [provenance manifest](../_candoitall-api-shared/manifest.json) matches the target.
- Follow [authentication and capability rules](../_candoitall-api-shared/references/access-and-authentication.md).
  Reads require `api.settings.workspace.read`; writes require
  `api.settings.workspace.write`, or compatible `api`. Administrator status alone does
  not grant either business capability. These routes also require the main API switch.

## Read, update and reconcile

Read the current settings before editing. Change only the requested business defaults
and retain the other values. Send only the six fields of `WorkspaceSettingsApiRequest`
to `PUT`: `workspaceName`, `defaultProviderProfileId`, `defaultPromptOutputFormat`,
`currencyCode`, `currencyCultureName` and `notes`. Do not echo extra persistence metadata
from the read response; unknown request members are rejected. A default provider must
exist and be enabled, or be null. Use the actual provider GUID, not its display name.

The write normally returns the persisted read-back. If the write committed but read-back
failed, it remains successful with the saved snapshot and
`X-CanDoItAll-Read-Back: pending`. Refresh with `GET`; do not repeat the write merely to
obtain confirmation. Do not attempt to use this model for API users, hashes, signing keys
or exposure switches.

## Source route appendix

<!-- api-docs-skills-parity:routes:start -->

| Method | Route |
| --- | --- |
| `GET` | `/api/settings/workspace` |
| `PUT` | `/api/settings/workspace` |

<!-- api-docs-skills-parity:routes:end -->
