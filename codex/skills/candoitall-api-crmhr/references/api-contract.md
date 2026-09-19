# CRM/HR HTTP Contract

Contract: the operations tagged `CRM / HR` in the target build's OpenAPI document; the handlers
are in `src/App/CanDoItAll.Web/Api/CrmHrApi.cs`.

All routes are under `/api/crm-hr`. JSON uses the Web defaults: camel-case property names and
numeric body enums. Query-string enums accept the case-sensitive member name (for example
`Interviewing`) or the integer. The party `scope` is a flags integer: 1 People, 2 Organizations,
4 OrganizationUnits, 8 AiAgents; add values to combine them (15 means all). Query parameter names
are case-insensitive, and a name the operation does not define is ignored without an error. Check
the running OpenAPI document before operating a different build.

AI-agent recruiting evidence is a separate bounded context under
`/api/agent-recruiting`. Use the Agent API
[partner contract](../../candoitall-api-agents/references/partner-api-contracts.md) for
typed execution targets, challenge/rubric hashes, human authorization, and agent
readiness. Do not write that evidence into CRM/HR application feedback, and do not treat
CRM/HR workforce conversion as AI-agent activation.

## Body enum encoding

The current Web serializer writes and reads body enums as integers. Use the typed client enum when possible. For shell/JSON clients, use these source-ordered values:

- `PartyType`: `Person=0`, `Organization=1`, `OrganizationUnit=2`, `AiAgent=3`.
- `PartyLifecycleStatus`: `Draft=0`, `Active=1`, `Inactive=2`, `Archived=3`, `Former=4`, `Candidate=5`, `Prospect=6`.
- `PartyRoleKind`: `Customer=0`, `CustomerContact=1`, `Partner=2`, `Vendor=3`, `Employee=4`, `Contractor=5`, `Freelancer=6`, `DeliveryUnit=7`, `Candidate=8`, `AiSteward=9`, `AccountManager=10`, `Recruiter=11`, `Stakeholder=12`.
- `PartyContactType`: `Email=0`, `Phone=1`, `Website=2`, `Messaging=3`, `Social=4`, `Other=5`.
- `PartyRelationshipKind`: `MemberOf=0`, `PartOf=1`, `ReportsTo=2`, `CustomerOf=3`, `PartnerOf=4`, `VendorTo=5`, `Represents=6`, `ManagedBy=7`, `OwnedBy=8`, `Supports=9`.
- `WorkforceKind`: `Employee=0`, `Contractor=1`, `Freelancer=2`, `DeliveryUnit=3`.
- `ProjectResourceRateUnit`: `Hour=0`, `ManDay=1`.
- `SkillProficiencyLevel`: `Basic=0`, `Working=1`, `Strong=2`, `Expert=3`.
- `CapacityBlockKind`: `Leave=0`, `Unavailable=1`, `Reserve=2`, `Tentative=3`.
- `RecruitmentStage`: `Applied=0`, `Screening=1`, `Interviewing=2`, `Offer=3`, `Hired=4`, `Rejected=5`, `Withdrawn=6`.
- `RecruitmentDecision`: `Pending=0`, `Approved=1`, `Rejected=2`, `Withdrawn=3`.
- `RecruitmentInterviewType`: `Screening=0`, `Technical=1`, `Manager=2`, `Panel=3`, `Culture=4`.
- `RecruitmentInterviewOutcome`: `Pending=0`, `StrongYes=1`, `Yes=2`, `Mixed=3`, `No=4`, `StrongNo=5`.
- `LifecycleTaskKind`: `Onboarding=0`, `Offboarding=1`, `Training=2`.
- `LifecycleTaskStatus`: `NotStarted=0`, `InProgress=1`, `Completed=2`, `Cancelled=3`.

Do not invent numeric values. Every enum schema and enum-typed property in the live OpenAPI
document lists each value; the document wins when this table differs.

## Bounded reads

### Parties

`GET /parties`

Query:

- `search`: display name and, for parties that are not sensitive, external code or summary;
  maximum 200 characters.
- `tags`: repeat the query parameter for conjunctive tag filters. Sensitive parties never match.
- `scope`: flags value from `PartyRecordScope`; default `All`.
- `pageIndex`: zero based.
- `pageSize`: 1 through 100.
- `includeArchived`: default `false`.

Response: `PartyRecordPage` with `items`, `pageIndex`, `pageSize`, `totalCount`, and derived `totalPages`.

`GET /parties/{partyId}`

Returns the safe directory projection for one party or structured 404.

### Workforce

`GET /workforce`

Accepts `search`, `tags`, `pageIndex`, `pageSize` and `includeArchived` with the party-list rules,
but no `scope`. The population is fixed: every person and organization unit, plus organizations
that have a workforce profile or the DeliveryUnit role. AI agent parties are never listed, and a
listed party need not have a profile.

`GET /workforce/{partyId}`

Returns the workforce workspace for one party or structured 404.

### Recruiting

`GET /recruiting/applications`

Query:

- `search`: text matched case-insensitively in the desired role, the source, the names of the
  candidate, recruiter, hiring manager and target unit, and the candidate's public email
  addresses; at most 200 characters. The document spells the parameter `Search`; a `searchText`
  parameter is ignored.
- `scope`: `All`, `Applied`, `Screening`, `Interviewing`, `Offer`, `Hired`, `Rejected`, or `Withdrawn`.
  Prefer the name: the scope integers are one higher than the `RecruitmentStage` body values
  because 0 means `All`.
- `pageIndex`: zero based.
- `pageSize`: 1 through 100.

`GET /recruiting/applications/{applicationId}`

Returns the aggregate recruitment workspace or structured 404.

## Party commands

`POST /parties`

The request is the source-backed `PartyCreateApiRequest`. Fields:

- `partyType`
- `lifecycleStatus`
- `displayName`
- `legalName`
- `preferredName`
- `externalCode`
- `summary`
- `tags`
- `region`
- `countryCode`
- `timeZone`
- `isSensitive`
- `roles`
- `publicContacts`
- `addresses`

`displayName` is required. Child collections use typed enums and do not accept child ids, private contacts, confidential notes, normalized values, or audit fields. The API normalizes contact values and sets the actor.

`GET /parties/{partyId}/relationships`

`PUT /parties/{partyId}/relationships`

The PUT body is an object whose `relationships` array contains the complete intended relationship list. Each row contains `relatedPartyId`, `relationshipKind`, `isOutgoing`, `isPrimary`, optional `startDateUtc`/`endDateUtc`, and `notes`. The server sets the actor and assigns relationship ids.

The replacement deletes every relationship in which the route party is the source or the target.
That includes rows created from the other party's side and the manager, buddy and mentor rows
saved by `POST /recruiting/support-assignments`. It then stores exactly the submitted rows with
new identifiers. An empty array, or an omitted `relationships` member, deletes all of them; never
send `null` (currently HTTP 500). When copying a `Supports` row, keep its `notes` (`Buddy` or
`Mentor`). There is no concurrency check. `POST /recruiting/support-assignments` also replaces
manager, buddy and mentor together (an omitted or null member removes it) and deletes the party's
outgoing ManagedBy rows, including rows written through the PUT.

## Workforce commands

`POST /workforce/profiles`

Body: `WorkforceProfileSaveApiRequest`. It includes `partyId`, profile fields, optional rate fields, and no client-supplied audit actor.

The profile is found by `partyId` and every field is overwritten; an omitted member takes its
default (for example `rateCurrencyCode` USD, `status` Planned). Start from `profile` in
`GET /workforce/{partyId}` and send every field.

`GET /workforce/skills`

`POST /workforce/skills`

POST body: `SkillDefinitionSaveApiRequest`.

`POST /workforce/party-skills`

Body: `PartySkillSaveApiRequest`.

`POST /workforce/capacity-blocks`

Body: `CapacityBlockSaveApiRequest`.

The relevant enum values are:

- `WorkforceKind`: `Employee`, `Contractor`, `Freelancer`, `DeliveryUnit`.
- `SkillProficiencyLevel`: `Basic`, `Working`, `Strong`, `Expert`.
- `CapacityBlockKind`: `Leave`, `Unavailable`, `Reserve`, `Tentative`.

## Recruiting commands

`POST /recruiting/applications`

Body: `RecruitmentApplicationSaveApiRequest`.

`POST /recruiting/interviews`

Body: `RecruitmentInterviewSaveApiRequest`. Supply `scheduledAtUtc` as an ISO 8601 timestamp with an offset.

`POST /recruiting/lifecycle-tasks`

Body: `LifecycleTaskSaveApiRequest`.

`POST /recruiting/support-assignments`

Body: `RecruitmentSupportAssignmentsSaveApiRequest`.

`POST /recruiting/conversions`

Body: `RecruitmentConversionApiRequest`.

Conversion saves the candidate party's workforce profile, then marks the application Hired and
the party Active. The application must not be Rejected or Withdrawn, and its decision must
already be Approved. An AI-agent candidate also needs a bound technical agent with a completed
application-specific technical assessment and human approval
(`crmhr.recruiting.convert.assessment-not-ready`). On an existing profile, the fields the request
does not carry (employee code, end date, rates, rate unit, currency) are reset. Conversion does
not create, approve or activate an agent, and it does not mutate Agent Framework candidate,
interview or readiness state.

Stage values: `Applied`, `Screening`, `Interviewing`, `Offer`, `Hired`, `Rejected`, `Withdrawn`.

Decision values: `Pending`, `Approved`, `Rejected`, `Withdrawn`.

Interview type values: `Screening`, `Technical`, `Manager`, `Panel`, `Culture`.

Interview outcome values: `Pending`, `StrongYes`, `Yes`, `Mixed`, `No`, `StrongNo`.

Lifecycle task kind values: `Onboarding`, `Offboarding`, `Training`.

Lifecycle task status values: `NotStarted`, `InProgress`, `Completed`, `Cancelled`.

## Response and error behavior

- Successful saves return one GUID as a JSON string, or `{ "ok": true }` for the relationship and
  support-assignment replacements. The GUID is the saved record's own identifier: the profile
  save returns the profile id, not the party id. The exception is conversion, which returns the
  candidate's party id.
- Failures use the general `errors` envelope; branch on `errors[].code`, not on the status. 404
  covers a missing route resource or subject party and some missing referenced records (related
  party, skill definition, project, application, candidate party). Other invalid references, such
  as a manager, recruiter or interviewer that is not an existing person, and validation failures
  return 400.
- A body the framework cannot bind returns 400 without the `errors` envelope, and
  `relationships: null` currently returns 500.
- Cancellation propagates through the HTTP request to application services.
- Handlers do not write EF entities and do not provide seed-only behavior.
