# Remote instances and shared templates

Use the publisher's template catalog when the operator wants to copy definitions
from another instance. These read-only routes are mapped when both the main API
and API authorization are enabled. Each catalog requires its own exact bearer scope.

| Definition | Publisher catalog (GET) | Required scope |
| --- | --- | --- |
| Agent | `/api/shared-agent-templates/v1/templates` | `api.shared-agent-templates.read` |
| Simple Chat | `/api/shared-simple-chats/v1/templates` | `api.shared-simple-chats.read` |
| Workflow | `/api/shared-workflows/v1/templates` | `api.shared-workflows.read` |

Read the catalog first, then append `/{id}` for the selected definition. Agent
and Simple Chat catalogs also support `/{id}/avatar` for an embedded raster.
Keep the publisher identity and revision with the selected item. Refresh discovery
on a workspace or revision conflict. A withdrawn template disappears from the
catalog and its direct read returns 404.

The publisher controls **Available through the API** and **Share as a template**
independently on the definition's **Sharing** tab. The first governs ordinary API
discovery and new work. The second publishes instructions and portable settings
to authorized catalog readers. The `api` and `shared` tags reflect those settings.

On the consumer, choose the publisher under **Settings → Remote instances** or add
it from the feature's import dialog. The dialog creates an independent local copy.
A matching shared provider from that connection is preferred. Confirm a compatible
local provider and model when needed. A workflow can have multiple model requirements.
For a batch, confirm each item's choices or use **Apply to all compatible**.
An imported definition executes locally. When its selected provider is shared,
model calls go to that provider's publisher. See the
[operator guide](https://github.com/fyziktom/CanDoItAll/blob/development/docs/architecture/remote-instance-connections.md#operator-steps).
