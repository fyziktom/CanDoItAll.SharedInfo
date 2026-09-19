# CanDoItAll API Domain Glossary

The shared vocabulary for CanDoItAll HTTP API documentation, API skills and integration guidance. Use the
same qualified term for the same concept, and never merge the pairs listed under **Not the same as**.
The [API documentation standard](../standards/api-documentation.md) says how to write descriptions; this
page says which words to use.

- Terms describe meanings, not names. Do not rename JSON members, route segments, operation identifiers,
  enum tokens or C# symbols to match a term.
- Keep externally defined protocol vocabulary, such as the OpenAI-compatible shared-provider relay
  fields, as that protocol defines it.
- A term is not a field contract. Check the owner's code before describing a specific member.
- Identifiers such as `PROJ-005` let reviews refer to a term unambiguously; clients do not need them.
- **Anchors** name representative source symbols or routes in the CanDoItAll product repository.

This is the single maintained copy. Product documentation links here instead of copying it. Terms were
reviewed against the CanDoItAll product source during the 2026-09 API documentation completion; add a
term only with evidence from the owning code, and correct a term when the owner's behavior changes.

## API fundamentals

### API-001 — HTTP operation

One HTTP method and route handled by the web application. It has its own request, response and authorization contract.

**Not the same as:** agent tool; application service method.

**Anchors:** `MapGet`, `MapPost`, `MapPut`.

### API-002 — OpenAPI document

The generated machine-readable description of the HTTP surface of a particular build and configuration.

**Not the same as:** Swagger UI; timeless source of runtime truth.

**Anchors:** `/openapi/v1.json`, `/swagger/v1/swagger.json`.

### API-003 — Swagger UI

The interactive documentation frontend displaying the generated OpenAPI document. It does not generate this product's contract.

**Not the same as:** Swagger generator.

**Anchors:** `UseSwaggerUI`, `AddOpenApi`.

### API-004 — wire DTO

A serialized request or response shape exposed over a transport, including internal C# types reachable from endpoints.

**Not the same as:** persistence entity; every public C# type.

**Anchors:** `PartyCreateApiRequest`, `LlmChatDefinitionApiResponse`.

### API-005 — domain model

An owner-managed representation of business facts and rules; its shape is not automatically an HTTP contract.

**Not the same as:** wire DTO; UI view model.

**Anchors:** `Party`, `Opportunity`, `ProjectTaskEstimatePolicy`.

### API-006 — projection

A representation derived from authoritative owner data for a particular reader or purpose. It is not an alternative writer.

**Not the same as:** authoritative record; editable master copy.

### API-007 — required property

A JSON member whose presence the applicable transport contract requires. Presence and acceptance of null are separate decisions.

**Not the same as:** non-nullable property; C# public property.

**Anchors:** `[JsonRequired] CurrentCostBasis`.

### API-008 — nullable property

A member whose contract permits a JSON null value. This does not imply the member may be omitted.

**Not the same as:** optional property; clear command in every DTO.

**Anchors:** `CurrentCostBasis`, `ScheduleChange`.

### API-009 — omitted property

A JSON member that is absent. Its effect is defined by the particular reader, default, update semantics and validation.

**Not the same as:** null; empty string; empty collection.

**Anchors:** `JsonIgnoreCondition.WhenWritingNull`, `PageIndex ?? 0`.

### API-010 — replacement

An operation submitting the complete intended collection for the named owner/target. Omitted existing rows may be removed under the owner contract.

**Not the same as:** patch; append.

**Rule:** Describe empty-list behavior after verifying the owner; never describe a replacement as an incremental update.

**Anchors:** `PartyRelationshipsReplaceApiRequest`, `ReplaceCrmHrPartyRelationships`.

### API-011 — page index

An integer position in a page-based collection. The CRM/HR list queries start at page index zero and default to it.

**Not the same as:** cursor; one-based page number everywhere.

**Rule:** Specify the origin per endpoint; do not globalize the CRM default.

**Anchors:** `CrmHrPartyPageApiQuery.PageIndex`.

### API-012 — cursor

A continuation value returned by a cursor-paged API. Send it back through the matching continuation contract rather than treating it as a page number.

**Not the same as:** page index; authorization token.

**Anchors:** `LlmChatApiPage<T>.NextCursor`, `NextMessageCursor`.

### API-013 — error envelope

The endpoint-specific serialized container for failure information. This product has more than one envelope.

**Not the same as:** ProblemDetails for all operations; one universal Errors type.

**Anchors:** `ApiErrorResponse.Errors`, `Error.ErrorCode`.

### API-014 — correlation identifier

A diagnostic/run-correlation reference, not evidence that a mutation was committed and not automatically an idempotency key.

**Not the same as:** idempotency key; receipt.

**Anchors:** `ApiErrorResponse.CorrelationId`.

## Authority and identity

### AUTH-001 — API bearer authorization

HTTP authentication and endpoint policy enforcement when configured. It is not an agent capability grant.

**Not the same as:** agent permission; project lease.

**Anchors:** `ApiAuthorizationPolicies`, `Authorization: Bearer`.

### AUTH-002 — authorization scope

A permission category tested by an authorization policy. State the concrete policy and accepted scopes for the operation.

**Not the same as:** query scope; workspace scope.

**Anchors:** `HasScope`, `HasApiOrSpecificScope`.

### AUTH-003 — query scope

A filter selecting which categories of records a query may return; it is not an access grant.

**Not the same as:** authorization scope.

**Anchors:** `PartyRecordScope`, `RecruitmentApplicationScope`.

### AUTH-004 — workspace scope

The organization/project or other admitted workspace context under which an operation resolves data and files.

**Not the same as:** filesystem path; bearer scope.

### AUTH-005 — project write admission

The owner-provided evidence binding a write to the project lifetime that the caller read. The HTTP task update requires the returned admission even though its C# property is nullable.

**Not the same as:** lease token; bearer token; client-generated version.

**Anchors:** `ProjectWriteAdmission`, `ExpectedProjectAdmission`.

### AUTH-006 — project lifetime

A particular incarnation of a project used to fence stale writes and projections; equality of the public project identifier alone is insufficient.

**Not the same as:** project identifier; request duration.

**Anchors:** `ExpectedProjectAdmission`, `ProjectLifetimeId`.

### AUTH-007 — lease

A coordination claim under a defined scope/key and validity period. Do not present it as a substitute for authorization or lifetime admission.

**Not the same as:** project write admission; ownership of business facts.

**Anchors:** `ProjectStructureLeaseSnapshot`, `LeaseToken`.

### AUTH-008 — concurrency token

An owner-returned value representing the state a later mutation expects. Preserve its exact representation and obtain a fresh value by reading the owner.

**Not the same as:** revision reason; timestamp in every API; client counter.

**Anchors:** `ExpectedConcurrencyToken`, `ConcurrencyToken`.

### AUTH-009 — revision

A version in a specified owner stream. Qualify it as definition, transcript, assignment or publication revision; these are not interchangeable.

**Not the same as:** one global revision; concurrency token by default.

**Anchors:** `DefinitionRevision`, `TranscriptRevision`, `CurrentDirectAssignmentRevision`.

### AUTH-010 — external code

A business-supplied reference on a party. The CRM/HR persistence model indexes it without declaring it unique.

**Not the same as:** party identifier; guaranteed idempotency key.

**Anchors:** `Party.ExternalCode`.

## Projects, Project Structure and tasks

### PROJ-001 — project

The Projects-owned business container and lifecycle record to which project structure and participation are attached.

**Not the same as:** Project Structure node; workspace directory.

**Anchors:** `projectId`, `ProjectsService`.

### PROJ-002 — Project Structure

The Workbench-owned hierarchy and related task, node, link and asset operations within a project.

**Not the same as:** Projects lifecycle API; generic filesystem tree.

**Anchors:** `/api/project-structure`.

### PROJ-003 — node identifier

An opaque structure-node key returned by the owner. It is not universally a GUID.

**Not the same as:** projectId; display label.

**Anchors:** `nodeId`, `ProjectStructureNodeSummary.Id`.

### PROJ-004 — canonical task

A task governed by the typed task application boundary, not an arbitrary WorkItem created through a generic node mutation.

**Not the same as:** generic node; recruiting lifecycle task.

**Anchors:** `project_task_update`, `/tasks`, `ProjectWorkItemKind.Task`.

### PROJ-005 — task identifier

The string node identifier of the canonical task. In task-update HTTP requests the body and route identifiers must match exactly.

**Not the same as:** GUID wrapper object; task title.

**Anchors:** `TaskId`, `taskId`.

### PROJ-006 — current task state

The previously read task values used as preconditions for an edit; not guesses and not copies of the desired new values.

**Not the same as:** proposed task state; latest state silently substituted at save time.

**Anchors:** `CurrentTitle`, `CurrentEstimate`, `CurrentExecution`.

### PROJ-007 — proposed task state

The caller's intended new task values, checked against current owner state and domain rules.

**Not the same as:** already committed state.

**Anchors:** `ProposedTitle`, `ProposedEstimate`, `ProposedExecution`.

### PROJ-008 — current progress percentage

Previously read task progress. The task-details validator accepts the untracked sentinel -1 or a tracked value from 0 through 100.

**Not the same as:** always 0..100; execution state.

**Anchors:** `CurrentProgressPercent`.

### PROJ-009 — proposed progress percentage

Requested tracked progress, accepted only from 0 through 100 by the task-details validator.

**Not the same as:** -1 untracked input; probability of winning an opportunity.

**Anchors:** `ProposedProgressPercent`.

### PROJ-010 — task execution snapshot

The current or proposed explicit execution state and related actual timestamps; it is separate from displayed progress and planned schedule.

**Not the same as:** schedule interval; run result.

**Anchors:** `CurrentExecution`, `ProposedExecution`, `ActualStartedAtUtc`, `ActualEndedAtUtc`.

### PROJ-011 — schedule change

A typed schedule edit identifying affected tasks and their previous/proposed intervals, with a gesture and optional critical-task information.

**Not the same as:** actual execution timestamps; only the edited task always moves.

**Anchors:** `ProjectStructureTaskScheduleAgentChange`, `AffectedTasks`.

### PROJ-012 — schedule interval

The start and end timestamps of a planned task interval. Preserve offsets/UTC semantics and owner constraints; do not silently convert to date-only values.

**Not the same as:** effort; calendar-day duration in every case.

**Anchors:** `PreviousStart`, `PreviousEnd`, `ProposedStart`, `ProposedEnd`.

### PROJ-013 — expected effort hours

Effort stored in hours, even when the chosen input/display unit is ManDays. Conversion belongs to the effort policy.

**Not the same as:** raw value in the selected unit; elapsed schedule hours.

**Anchors:** `ProjectTaskEstimate.ExpectedEffortHours`.

### PROJ-014 — effort unit

The chosen Hours or ManDays input/display unit. It does not change the stored unit of ExpectedEffortHours.

**Not the same as:** currency unit.

**Anchors:** `ProjectWorkItemEffortUnit`, `ExpectedEffortUnit`.

### PROJ-015 — hours per man-day

The conversion factor used by the effort policy; its default is eight, and overloads accept an explicit positive factor.

**Not the same as:** universal working calendar.

**Anchors:** `DefaultHoursPerManDay`.

### PROJ-016 — expected cost

A nonnegative estimated amount with its associated currency, distinct from historical charges and recognized sales.

**Not the same as:** cost rate; recognized sales total.

**Anchors:** `ExpectedCostAmount`, `ExpectedCostCurrencyCode`.

### PROJ-017 — expected cost basis

The owner-returned basis for an expected task cost, used with the edit precondition. The member can be null but CurrentCostBasis must be present in this JSON input.

**Not the same as:** a freely edited price; zero cost when null.

**Anchors:** `ProjectTaskExpectedCostBasis`, `CurrentCostBasis`.

### PROJ-018 — direct-assignment revision

The nonnegative owner revision for a task's direct assignments, submitted unchanged as an edit precondition.

**Not the same as:** number of assignees; task progress; project revision.

**Anchors:** `CurrentDirectAssignmentRevision`.

### PROJ-019 — direct task assignee

A person or agent selected through the typed task-assignment path. This update does not accept process/workflow selections as direct assignees.

**Not the same as:** every task resource kind; project participant.

**Anchors:** `AssigneeChanged`, `ProposedAssignee`.

### PROJ-020 — task resource

A typed execution/resource selection for a task. The separate resource-attachment endpoint can handle cases beyond direct person/agent assignment.

**Not the same as:** storage object; only a person.

**Anchors:** `ProjectStructureTaskResourceSelection`, `/tasks/{taskId}/resource`.

### PROJ-021 — project participation

CRM/HR-owned involvement and staffing facts in a project, distinct from Workbench-owned task assignments.

**Not the same as:** direct task assignment.

### PROJ-022 — asset

A Project Structure content record/placement whose metadata and actual bytes are retrieved through distinct supported operations.

**Not the same as:** metadata proves file content; arbitrary local file path.

**Anchors:** `/assets/{nodeId}`, `/assets/{nodeId}/content`.

### PROJ-023 — canonical-current read

A read through the authoritative current Project Structure service; the explicit HTTP read source.

**Not the same as:** invocation snapshot.

**Anchors:** `ProjectStructureReadSource.CanonicalCurrent`.

### PROJ-024 — invocation snapshot

A bounded snapshot attached to an eligible in-process agent invocation; unavailable as an HTTP read source and never silently replaced by canonical data.

**Not the same as:** downloaded OpenAPI snapshot; any cached project.

**Anchors:** `ProjectStructureReadSource.InvocationSnapshot`.

## CRM and HR

### CRM-001 — party

A CRM/HR business identity used by roles, contacts, relationships and workforce records. Qualify the type; a party is not necessarily a customer or person.

**Not the same as:** user account; customer in every case.

**Anchors:** `Party`, `PartyId`, `PartyType`.

### CRM-002 — person party

A party representing a human; its party ID is distinct from login identity, workforce-profile ID and recruitment-application ID.

**Not the same as:** all parties; agent definition.

**Anchors:** `PartyType.Person`, `PartyId`.

### CRM-003 — CRM account

The commercial account identified by AccountPartyId, with a separate CRM account profile. It is not an authentication account.

**Not the same as:** user login; account-profile ID.

**Anchors:** `AccountPartyId`, `CrmAccountProfile`.

### CRM-004 — CRM account profile

Commercial relationship-stage and note fields for an account party; its own Id is not AccountPartyId.

**Not the same as:** party identity record.

**Anchors:** `CrmAccountProfile.Id`, `RelationshipStage`.

### CRM-005 — account connection

A typed link from an account to another party, optionally associated with project links.

**Not the same as:** generic party relationship; login connection.

**Anchors:** `CrmAccountConnection`, `RelatedPartyId`.

### CRM-006 — party relationship

A typed directed source-party/target-party relationship with its own identity and optional dates.

**Not the same as:** account connection in every context; affiliation ID.

**Anchors:** `PartyRelationship.SourcePartyId`, `TargetPartyId`.

### CRM-007 — party role assignment

A business role attached to a party, with its own title, primary flag and optional validity interval.

**Not the same as:** authorization role; task assignee.

**Anchors:** `PartyRoleAssignment`.

### CRM-008 — contact point

A typed contact value attached to a party, with a label and primary/public flags. It is not itself a person identity.

**Not the same as:** contact person; party.

**Anchors:** `PartyContactPoint`, `PartyPublicContactCreateApiRequest`.

### CRM-009 — public contact

A contact created through the party-create `publicContacts` input; the mapper marks it `IsPublic = true`. Do not infer internet-public authorization from this data flag.

**Not the same as:** anonymous API access.

**Anchors:** `PublicContacts`, `IsPublic`.

### CRM-010 — sensitive party

A party marked for restricted handling by its owner. Visibility and redaction still depend on the actual read endpoint and current authority.

**Not the same as:** all its data is absent in every response; public flag.

**Anchors:** `Party.IsSensitive`.

### CRM-011 — confidential note

A separate restricted CRM/HR note record, not Party.Notes or Party.Summary. The party-create API does not accept this collection.

**Not the same as:** ordinary note; summary.

**Anchors:** `PartyConfidentialNote`, `ConfidentialNotes`.

### CRM-012 — opportunity

A prospective commercial engagement associated with an account, owner, stage, optional value and project link.

**Not the same as:** project; invoice; CRM account.

**Anchors:** `Opportunity`.

### CRM-013 — opportunity stage

The commercial lifecycle position of an opportunity; not the account relationship stage or party lifecycle status.

**Not the same as:** account relationship stage; workforce status.

**Anchors:** `Opportunity.Stage`, `OpportunityStageHistory`.

### CRM-014 — probability percentage

The opportunity's ProbabilityPercent value; it describes commercial likelihood, not execution progress. Validate its allowed range at the owner before adding constraints.

**Not the same as:** task progress.

**Anchors:** `Opportunity.ProbabilityPercent`.

### CRM-015 — recognized amount

The monetary value retained on an opportunity-stage history record for recognition, distinct from its current editable opportunity amount.

**Not the same as:** invoice payment; current quoted amount.

**Anchors:** `OpportunityStageHistory.RecognizedAmount`, `RecognizedCurrencyCode`.

### CRM-016 — workforce profile

A workforce-specific record linked to a party, with work classification, capacity, rates and managerial fields. Profile Id and PartyId have different meanings.

**Not the same as:** person identity; technical agent definition.

**Anchors:** `WorkforceProfile.Id`, `PartyId`.

### CRM-017 — internal cost rate

The workforce cost amount expressed per RateUnit and in RateCurrencyCode, not a total task estimate.

**Not the same as:** external billing rate; expected cost total.

**Anchors:** `InternalCostRate`, `RateUnit`, `RateCurrencyCode`.

### CRM-018 — external billing rate

The workforce billing amount per the declared rate unit and currency, distinct from internal cost.

**Not the same as:** internal cost rate.

**Anchors:** `ExternalBillingRate`.

### CRM-019 — capacity block

A dated capacity restriction/reservation fact for a party, with a block kind, percentage and optional project reference. It is not itself a task assignment.

**Not the same as:** task; workforce profile.

**Anchors:** `CapacityBlock`.

### CRM-020 — staffing request

A request for a role/skills and allocation over an interval, optionally bound to a project and its lifetime.

**Not the same as:** confirmed assignment; recruitment application.

**Anchors:** `StaffingRequest`.

### CRM-021 — skill definition

A catalog definition of a workforce skill. This is not an executable agent skill package.

**Not the same as:** Codex/API skill; agent capability.

**Anchors:** `SkillDefinition`.

### CRM-022 — party skill

A party's recorded proficiency/experience in a referenced workforce skill definition.

**Not the same as:** skill definition itself.

**Anchors:** `PartySkill`, `SkillId`, `PartyId`.

### CRM-023 — recruitment application

A candidate party's application for a role, with its own identity, stage and decision. Qualify application to avoid confusion with the software product.

**Not the same as:** software application; person party.

**Anchors:** `RecruitmentApplication`, `ApplicationId`.

### CRM-024 — recruitment interview

An interview belonging to a recruitment application, with scheduling, interviewer and outcome fields.

**Not the same as:** application; general interaction record.

**Anchors:** `RecruitmentInterview`.

### CRM-025 — recruiting lifecycle task

An onboarding/offboarding task associated with a party and optionally a project. Not a canonical Project Structure task.

**Not the same as:** canonical task.

**Anchors:** `OnboardingTask`, `LifecycleTaskKind`.

### CRM-026 — interaction record

A CRM communication/activity record with subject, summary and optional next-action/related opportunity or project information.

**Not the same as:** agent chat message; execution run.

**Anchors:** `InteractionRecord`.

### CRM-027 — next action

A follow-up associated with a CRM interaction, optionally assigned and due-dated; not an implicit canonical task.

**Not the same as:** Project Structure task.

**Anchors:** `NextActionText`, `NextActionOwnerPartyId`, `NextActionDueUtc`.

## Agents, providers and conversations

### AGT-001 — technical agent definition

An Agents-owned executable agent configuration and identity. CRM exposes a projection/binding rather than another authoritative technical definition.

**Not the same as:** CRM party; model.

### AGT-002 — agent capability

A declared/assigned capability that participates in runtime eligibility checks. A catalog entry alone does not make a tool executable.

**Not the same as:** HTTP permission; automatically attached tool.

**Anchors:** `IAgentRuntimeToolProvider`, `RuntimeToolProviderComposer`.

### AGT-003 — runtime tool

An executable function attached to an eligible invocation through the runtime provider/composition policy.

**Not the same as:** HTTP operation; capability template.

**Anchors:** `AITool`, `project_task_update`.

### AGT-004 — tool call

One invocation of a runtime function, with arguments and an outcome. Distinguish a call, its retry attempt and the business target.

**Not the same as:** whole execution run; HTTP operationId.

### AGT-005 — agent execution run

A governed agent execution instance, not the entire chat session and not a workflow/process run.

**Not the same as:** chat session; workflow run; process run.

**Anchors:** `ExecutionRunId`, `ChatSessionId`.

### AGT-006 — provider profile

An owner-managed provider configuration selected by a ProviderProfileId. Distinguish it from a provider kind, model name and shared publication.

**Not the same as:** model identifier; shared publication ID.

**Anchors:** `ProviderProfileId`, `ProviderKind`.

### AGT-007 — model identifier

The model-selection value used within a specific provider/transport contract. It is not the provider profile identifier.

**Not the same as:** DTO model; ProviderProfileId.

**Anchors:** `Model`, `SharedProviderRoutingModelId`.

### AGT-008 — shared-provider publication

A published provider capability identified by its publication identity/revision; not the caller's local provider profile.

**Not the same as:** local provider profile.

**Anchors:** `SharedProviderPublicationId`, `SharedProviderPublicRevision`.

### AGT-009 — shared routing model identifier

The routing value accepted by the shared-provider relay as model; do not substitute a private upstream configuration ID.

**Not the same as:** local ProviderProfileId.

**Anchors:** `SharedProviderRoutingModelId`.

### AGT-010 — Simple Chat definition

A reusable ordinary LLM chat configuration with revisions, provider/model settings and optional response format. It is not a governed agent.

**Not the same as:** technical agent definition; conversation.

**Anchors:** `LlmChatDefinitionApiResponse`.

### AGT-011 — Simple Chat conversation

A conversation referring to a definition and definition revision, with transcript revision and optional active operation.

**Not the same as:** definition; agent chat session.

**Anchors:** `LlmChatConversationApiResponse`.

### AGT-012 — conversation turn

The conversational unit identified by TurnId; messages/entries and active operation IDs are separate identities.

**Not the same as:** message entry; definition revision.

**Anchors:** `LlmChatMessageApiResponse.TurnId`, `EntryId`, `ActiveOperationId`.

### AGT-013 — message entry

One recorded conversation message with role, content and its own EntryId, associated with a turn.

**Not the same as:** entire turn.

**Anchors:** `LlmChatMessageApiResponse`.

### AGT-014 — transcript revision

The revision of conversation history used in relevant read/edit preconditions, distinct from definition revision and conversation concurrency token.

**Not the same as:** definition revision; token count.

**Anchors:** `ExpectedTranscriptRevision`, `TranscriptRevision`.

### AGT-015 — token usage

Provider-reported input, output and cached-input usage quantities, not a monetary cost or authorization token.

**Not the same as:** API bearer token; price.

**Anchors:** `LlmChatUsageApiResponse`.

## Execution and effects

### RUN-001 — workflow definition

The reusable workflow configuration; distinguish the definition/catalog identity from a particular workflow execution.

**Not the same as:** workflow run; process definition.

### RUN-002 — workflow run

A particular workflow execution, with its own status, external responses and recovery/observation contract.

**Not the same as:** agent execution run; workflow definition.

**Anchors:** `WorkflowRunStartApiResponse`, `/api/workflows`.

### RUN-003 — process run

A particular process orchestration execution; it can contain steps and agent/workflow work without sharing their identifiers.

**Not the same as:** workflow run; agent execution run.

**Anchors:** `/api/processes`.

### RUN-004 — committed effect

An authoritative owner-observed write/effect. A transport success, a generated answer or a completed read is not by itself proof of commitment.

**Not the same as:** HTTP 200; no error message.

**Anchors:** `RecordCommitted`, `EffectState`.

### RUN-005 — known no-effect rejection

A rejection whose owner proves that the relevant effect did not occur. Do not use it for arbitrary failures after dispatch.

**Not the same as:** all exceptions; unknown effect.

**Rule:** Do not treat None and NotCommitted enum values as interchangeable; describe their actual owner-specific contract.

**Anchors:** `RecordRejectedBeforeEffect`, `None`, `NotCommitted`.

### RUN-006 — unknown effect

An outcome for which the system cannot prove whether the effect committed. Reconciliation, not blind repetition, is required.

**Not the same as:** definitely failed write; safe-to-retry guarantee.

**Anchors:** `Unknown`.

### RUN-007 — reconciliation

Owner-backed determination/recovery of an uncertain or partially delivered operation using retained identity/evidence; it is not a new business mutation by default.

**Not the same as:** rerun; automatic retry.

### RUN-008 — result disclosure

Permission to expose a previously saved tool result under current authority. It is distinct from permission to execute another mutation.

**Not the same as:** tool execution permission.

**Anchors:** `AuthorizeResultDisclosureAsync`.

### RUN-009 — receipt

Owner-produced evidence identifying a committed effect or coordinated operation. State the exact receipt type and its guarantees.

**Not the same as:** correlation identifier; request ID.

## Storage and schema values

### STO-001 — storage object

Content addressed through a storage provider/catalog and locator contract. Do not describe it as an arbitrary filesystem path.

**Not the same as:** Project Structure node; workforce resource.

### STO-002 — locator

A storage-provider-specific reference to content; its accepted syntax and visibility are contract-specific.

**Not the same as:** URL in every case; absolute local path.

### STO-003 — content bytes

The actual stored content returned by a content endpoint/stream, distinct from metadata, filename or a placement record.

**Not the same as:** metadata; successful file registration.

**Anchors:** `/assets/{nodeId}/content`.

### STO-004 — placement

The association/delivery of content into an owner-managed location, potentially with separate recovery and continuation evidence.

**Not the same as:** content creation itself; mere file path.

**Anchors:** `/api/storage-placement-recovery`.

### STO-005 — response-format schema

The schema governing a requested model response format. It is not the OpenAPI schema of the surrounding HTTP DTO.

**Not the same as:** OpenAPI document; database schema.

**Anchors:** `LlmChatResponseFormatApiRequest.Schema`.

### STO-006 — JSON-valued member

A member serialized as JSON data, with its own allowed shape; it is not necessarily a string containing serialized JSON.

**Not the same as:** JSON string; free-form metadata by default.

**Anchors:** `JsonElement ModelParameterConfiguration`, `JsonElement Schema`.

### STO-007 — UTF-8 body byte limit

A request-body limit measured in encoded bytes, distinct from character counts. Verify the limit for each endpoint.

**Not the same as:** UTF-16 text length.

**Anchors:** `MaximumBodyBytes`.

### STO-008 — UTF-16 text length

The text-length unit explicitly used by the shared-provider relay subset; it is not a global API length convention.

**Not the same as:** UTF-8 byte length; Unicode grapheme count.

**Anchors:** `MaximumTextCharacters`.

## Wire representation

### WIRE-001 — integer enum

An enum member sent and received as a JSON integer because no string converter is registered for that
enum on the route's serializer. Its schema description lists each number with its meaning.

**Not the same as:** enum text token; the C# member name.

**Anchors:** `ProjectTaskExecutionState`, `GanttScheduleGesture`, `ErrorSeverity`.

### WIRE-002 — enum text token

A camel-case string written and accepted for an enum by a registered string converter, for example
`notStarted` or `providerError`. Tokens are case-sensitive where the converter says so.

**Not the same as:** integer enum; display label.

**Anchors:** `AgentProviderFailureCategory`, `LlmChatDefinitionStatus`, `ProjectObjectType` in Project
Structure responses.

### WIRE-003 — JSON string member

A string member whose content is itself a JSON document, such as a node's `metadataJson`. Clients parse
it separately; its members use their own naming and enum conventions (camel-case text tokens in
`metadataJson`), which can differ from the surrounding request or response.

**Not the same as:** JSON-valued member; free text.

**Anchors:** `ProjectStructureNodeSummary.MetadataJson`, `ProjectObjectMetadataSerializer`.

**Rule:** Name the extraction path of every value a client must read from it, and state how its enum
tokens map to the integers another operation expects.

### WIRE-004 — required nullable member

A member that must be present in the JSON body but may be `null`. Omitting it is rejected; sending
`null` is valid.

**Not the same as:** optional member; non-nullable member.

**Anchors:** `[JsonRequired] CurrentCostBasis`.

### WIRE-005 — general error envelope

The `errors` array envelope of the general API families: each item has a stable `code`, a `message` and
a `severity`, and agent failures add correlation and failure-category members.

**Not the same as:** Project Structure error envelope; problem details.

**Anchors:** `ApiErrorResponse`, `ApiErrorItem`.

### WIRE-006 — Project Structure error envelope

The single `error` object returned by Project Structure operations, with `errorCode`, `message` and
optional `details`.

**Not the same as:** general error envelope; problem details.

**Anchors:** `ProjectStructureErrorResponse`, `ProjectStructureAgentException`.

### WIRE-007 — problem details

An RFC 9457 `application/problem+json` response. LLM Chat operations add a stable `code` extension and,
for operation failures, `operationId` and `retryable`.

**Not the same as:** general error envelope; a success body.

**Anchors:** `ProblemDetails`, `LlmChatApiResults`.

### WIRE-008 — framework binding rejection

An HTTP 400 produced by the web framework before the operation's handler runs, for example for malformed
JSON, a wrong JSON type or a missing required member. It does not use the family's error envelope.

**Not the same as:** an owner validation rejection; a rejection with a stable error code.

**Anchors:** request-body binding of Minimal API handlers.

### WIRE-009 — node key

The opaque string identifier of a Project Structure node, for example
`custom:3f2504e04f8911d39a0c0305e82c3301` for a task. Send it exactly as returned; it is not generally a
GUID and never a wrapper object in requests.

**Not the same as:** project identifier; title; identifier object with a `value` member in some responses.

**Anchors:** `nodes[].id`, `taskId`, `GanttTaskId`.

### WIRE-010 — operation (three meanings)

Qualify the word. An **HTTP operation** is one method and route (API-001). An **OpenAPI operation
identifier** is the stable `operationId` name of an HTTP operation. An **LLM Chat operation** or a
**Memory provider operation** is a durable record of asynchronous work that clients poll or stream; an
**agent execution operation** is the in-memory, host-local activity stream of one agent command, not a
durable record (read the agent execution run for results).

**Not the same as:** each other.

**Anchors:** `WithName`, `LlmChatOperationApiResponse`, `/api/memory-providers/operations/{operationId}`.
