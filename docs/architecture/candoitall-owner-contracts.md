# CanDoItAll Owner Contracts For UI And Integration Work

## Decision

The `CanDoItAll` product is a modular monolith in which every business fact has one
authoritative writer and one owner persistence context. UI, HTTP, agent tools, workflow
executors and process steps reach an owner only through its typed application service or
its published contract; a cache or projection carries its source, scope and revision and
is never a fallback master. This page is the reusable orientation for teams that build
UI, adapters or partner integrations on top of the product. The product repository owns
the contracts themselves; this page links to them and does not duplicate them.

Source of truth in the product repository (`docs/architecture/modules.md`, section
"Owner contracts and adapters", and `docs/architecture/modules-decoupling/`). The
generated HTTP surface is the shared OpenAPI snapshot in
[`_candoitall-api-shared`](../../codex/skills/_candoitall-api-shared/README.md); its operation
and schema descriptions come from the product's XML documentation. Use the
[API domain glossary](candoitall-api-domain-glossary.md) for the terms on this page and in
integration work.

## Owner map

| Owner | Authoritative facts | Read and command entry point | Never |
|---|---|---|---|
| Agents / Providers | technical agent definitions, capabilities, provider and model configuration, AI tariffs and usage evidence | `/api/agents`, `/api/shared-providers`; in-process `IAgentFrameworkWorkspaceService` | edit technical agent facts through CRM or Project Structure |
| CRM / HR | parties, contacts, affiliations, workforce facts and human rates, staffing, capacity, technical-agent projections | `/api/crm-hr`; agent tools `crm_planning_search`, `crm_planning_summary_get` (privacy-filtered, no rate disclosure) | treat a CRM projection of a technical agent as its definition; read a person's rate outside the Projects cost-rate bridge |
| Projects | project lifecycle, hierarchy, identity, lifetime admission | `/api/projects`; in-process `ProjectsService`, `ProjectWriteAdmissionService` | mutate a project that a cached page selection no longer represents |
| Project Structure / Workbench | native notes, nodes, placements, links, assets, canonical tasks, dependencies, assignments | `/api/project-structure`; agent tools `project_structure_*`, `project_task_*` | copy tasks or assignments into another module; use generic node writes for task or asset lifecycle |
| Workflows and Processes | definitions, admitted executions, checkpoints, approvals, cancellation, recovery, outcomes | `/api/workflows`, `/api/processes` | relaunch a completed process because a delayed Structure update is missing |
| Resources / Storage | resource catalog metadata versus bytes, locators, placement and file-operation receipts | `/storage`, `/api/storage-placement-recovery`; agent tools `storage_*` | convert an uncertain placement into success or a blind retry |
| Simple Chats | ordinary definitions, conversations, turns | `/api/llm-chats`, `/api/llm-conversations`, `/api/llm-chat-operations` | expose transcripts or add tools through HR definition administration |

## How the UI reads and sends commands

- Read through the owner's application service or HTTP endpoint that returns a typed
  projection. Do not inject an owner `DbContext`, `IQueryable` or tracked entity into
  presentation code; the product guards this with architecture tests.
- Send a command to the owner that holds the fact. A mutation that spans owners goes
  through the owner-provided adapter (for example the Projects-owned party bridges that
  CRM/HR implements) and records a receipt; the UI never composes two owner writes itself.
- Keep the current authority, original scope and project lifetime across awaits,
  approvals, restarts and replays. A page that changes project or profile while a
  command is admitted must not retarget it; the admitted scope is rechecked at
  consumption.
- Agent chat context is published through `IAgentChatContextRegistry` with one active
  scope per circuit. A provider that was superseded by a newer scope stands down; it
  does not throw and does not overwrite the live scope.

## How modules contribute safely

- Register first-party agent tools in an `IAgentRuntimeToolProvider` at the owning
  module boundary. A process pre-dispatch preflight receives an inert tool inventory
  (`ToolInventoryOnly`); an inventory is never an executable grant.
- Report an owner rejection that happens before any write as a typed no-effect failure
  (`EffectState: None`) only where the owner proves the phase; anything after a partial
  write or with uncertain transport stays `Unknown` and requires reconciliation.
- A replayed pre-dispatch denial is restored without consulting the owner; a saved
  successful private result still requires current disclosure authorization.

## Where ordinary business persistence is forbidden

- Composition and migration code may know the complete model; product modules may not
  inject the global application context or its factory.
- Reusable UI libraries (`src/UI/*`) reference abstractions only; no persistence,
  runtime registration or foreign DTO leaks into them transitively.
- Plan and cost surfaces read the recorded task execution state as the progress truth;
  the canvas status hint is decoration. Historical charges keep their recorded price.

## Snapshot status

The shared OpenAPI snapshot records the exact product branch and commit it was captured
from in its manifest; it is captured from the product's `development` branch, which includes
the module-decoupling work. A snapshot describes one build: the live `/openapi/v1.json`
of the target host stays authoritative when it differs.

Behavior newer than the current snapshot is recorded in the shared package's README and in the
security delta of its partner migration matrix: workflow idempotency keys and their lookup belong
to the caller that recorded them, workflow cancellation and analytics no longer return a run's
launch origin, the `/api/runtime` snapshots need a bearer token where API authorization is on,
HTTP agent run starts refuse a caller context that claims a process step or binds host folders,
and Project Structure analytics returns recorded bodies only to the caller that made the call.
