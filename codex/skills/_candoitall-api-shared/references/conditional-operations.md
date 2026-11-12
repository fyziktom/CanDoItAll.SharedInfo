# Conditional operations and recovery

The November 2026 snapshot adds the operations below. Read their generated request,
response and error schemas before constructing a command. Keep owner-issued originals,
dataset/caller bindings, revisions and complete operation identities unchanged. They
are concurrency preconditions, not permission grants. Preserve decimal-string revisions
as strings; never round them through a JavaScript number.

## Project definitions and lifecycle

For new project-definition integrations, read `/api/projects/definition-write-context`
before freezing an operation. Read `/api/projects/{projectId}/definition` for an existing
definition and its original expectation. Submit creation through `/api/projects/definitions`,
complete replacement through `/api/projects/{projectId}/definition`, or a scalar-only
edit through its `/scalars` child. Scalar edits preserve children; replacement requires
complete phase and option arrays. The Structure-side `/definition` read supplies a coherent
expectation for its conditional scalar editor.

Retain the complete command and its operation address before dispatch. On timeout or
Unconfirmed, query `/api/projects/definition-operations/{namespaceId}/{epoch}/{operationId}`
with the original caller binding, or retry the exact original command. A different payload
under the same identity is rejected. NotObserved alone does not prove rollback; an exact
accepted receipt or a fully retained ClosedAbsent observation is needed to resolve uncertainty.

For project deletion or hierarchy changes, obtain `/api/projects/lifecycle-write-context`
and submit to `/api/projects/lifecycle-operations` with the original project/edge identities,
revisions and endpoint lifetimes. Observe the original operation address with its original
database profile and caller binding. An accepted database mutation can leave cleanup pending;
follow the returned cleanup obligations. Never replace an uncertain operation with a new
identity or refreshed expectations.

## Project Structure refresh feeds

`GET /api/project-structure/projects/{projectId}/changes` establishes or resumes a bounded
cursor; `/changes/stream` follows the same feed with SSE. Retain its exact cursor and use
matching `after` and `Last-Event-ID` values if both are supplied. On `requiresRefresh`,
reload canonical structure and establish a current cursor. The feed is scoped to this server
process and database profile; it is neither a durable audit log nor execution evidence.

## Agent policy, planning and saved receipts

Read `/api/agents/{agentId}/decision-data-policy` before a conditional replacement. Retain
the original expectation and submit a complete version-one override envelope; null fields
inherit. The `/lookup` POST reads a historical receipt for the complete original submission.
Missing evidence remains unresolved and never authorizes another write. A policy change
applies to future admissions, not decisions already admitted.

`POST /api/agents/execution-runs/{executionRunId}/planning/actions` applies the displayed
approval, refresh or cancellation to the original chat, decision generation and run/journal
revisions. Approval names the exact saved publication; refresh requires renewed review.
An uncertain result is not permission to replay automatically.

The run's `/saved-receipts/read` POST is an explicit read of at most four authorized original
effect receipts per page. It does not resume, recover, approve or republish work, update the
journal, or clear coordination warnings. A receipt is evidence only within its current
disclosure authorization.

## Process launch, root cancellation and planning review

`GET /api/processes/launch/decision-contracts` discovers registered planning contracts and
policy ceilings. It does not prove launch eligibility or grant authority. Preserve one
caller intent throughout preparation and acceptance. After an uncertain preparation or
launch response, read `/api/processes/launch/intents/{callerIntentId}` under the original
caller, database profile and operator surface. A found admission restores the saved review;
404 does not prove that an earlier in-flight request cannot finish.

For a root run, `POST /api/processes/runs/{runId}/cancellation` accepts no body and requires
Process read/execute authority plus an enabled recovery worker. It admits a cancellation
barrier and returns before descendant cleanup. Follow its Location GET after acceptance
or uncertainty. Cancelled runtime status alone does not mean cleanup is complete;
LegacyUntracked and ReconciliationRequired need operator attention. The legacy `/cancel`
command is limited to a selected child and refuses root mutation before writing.

Read the exact child's `/steps/{stepInstanceId}/planning/{executionRunId}/review` before
submitting a manager choice. Preserve the full request and action ID for exact recovery of
an uncertain result. `/review/accounting` settles accounting for a verified completed
original Agent child; it cannot approve or republish an effect. These routes recheck the
required Process, Agent and Project permissions, independently of their original state.

## Workspace policy and CRM business stewardship

Prefer `/api/settings/workspace/v2` for conditional workspace editing. Read all six defaults,
the complete root decision policy (or explicit legacy absence), and the original dataset/head.
PUT replaces defaults and the full root policy under that original expectation. A root has
no parent policy to inherit from. Invalid stored policy returns 503 without substituting
defaults; saving does not activate producers or change admitted decisions.

Read `/api/crm-hr/ai-stewards/{partyId}` before saving business stewardship. Both the read
and write require CRM/HR read and write capabilities. Send the original unchanged, including
an absent-profile observation; a peer edit causes 409. This surface owns business ownership,
review state and notes, and cannot change technical Agent provider, model, capabilities or
execution settings. Treat those notes and originals as potentially private data.
