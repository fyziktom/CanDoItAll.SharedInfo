---
name: candoitall-api-crmhr
description: Use when listing, creating, or relating CanDoItAll CRM/HR parties; managing workforce profiles, skills, and capacity; or operating recruiting applications, interviews, lifecycle tasks, support assignments, and candidate conversion through the HTTP API.
---

# CanDoItAll CRM/HR API

Use this skill for CRM/HR HTTP operations. The CRM/HR application services remain canonical; never replace these routes with SQL, EF tooling, migrations, or startup seed code.

## Access

1. Start the intended CanDoItAll Web instance.
2. Call `GET /api/access/status`.
3. If `authorizationEnabled` is true, send `Authorization: Bearer <token>` from an approved token workflow.
4. Select `api.crm-hr.read` for reads and `api.crm-hr.write` for mutations; compatible `api`
   remains accepted. A valid token from another section is insufficient. Follow the shared
   [authentication and capability rules](../_candoitall-api-shared/references/access-and-authentication.md).

Use `/swagger/v1/swagger.json` to inspect the running contract when source and host versions may differ.

## Contract Source

- Use the shared
  [OpenAPI snapshot](../_candoitall-api-shared/references/candoitall-web.openapi.json)
  for exact schemas when it matches the target source version.
- Check the snapshot's [provenance manifest](../_candoitall-api-shared/manifest.json)
  before relying on it.
- Use the running host's contract when its version differs from the manifest.
- Read [references/api-contract.md](references/api-contract.md) for CRM/HR-specific
  request sequencing and DTO guidance.
- For AI-agent interview attempts, execution evidence, human authorization, and
  production-readiness projection, use the Agent API skill's
  [partner contracts](../candoitall-api-agents/references/partner-api-contracts.md).

## Operating Workflow

1. Read the relevant bounded collection before creating anything.
2. Resolve references to concrete GUIDs; do not send display names where an id is required.
3. For deterministic automation, search by a unique external code or unique scenario name and reuse the returned id.
   `POST /api/crm-hr/parties` always creates another party; there is no party update. External
   codes are neither unique nor searchable on sensitive parties, so a search miss there does not
   prove absence. Keep deterministic demo parties non-sensitive.
4. Submit the smallest typed command that owns the intended change.
5. Read the resource back and verify relationships, workforce state, or recruiting workspace.
6. On a non-success response, inspect `errors[].code`, `errors[].message`, and `errors[].severity`. Do not hide the failure with another persistence path.
   Transport/binding failures return safe JSON rather than the domain `errors` array;
   inspect the status and returned envelope before parsing it.

Read the CRM/HR API contract reference before constructing request bodies or multi-step
scenarios.
Body enums currently use the Web host's numeric encoding; use the reference mapping or a typed .NET client rather than guessing values.

## Party And Relationship Rules

- Party collection reads are source-paged. Keep `pageSize` within the documented limit; follow `pageIndex` rather than loading every record.
- Only directory reads (the party and workforce lists and `GET /api/crm-hr/parties/{partyId}`)
  blank a sensitive party's external code, summary and tags. The workforce workspace blanks only the
  primary email and phone. Recruiting reads return candidates' contacts and summary unredacted:
  treat all of them as personal data and never log them.
- Party creation does not accept confidential notes. Use ordinary tags, public contact points, roles, and addresses only when the business scenario needs them.
- Relationship replacement rewrites the party's relationships in both directions, including
  recruiting support assignments. An empty or omitted list deletes them all, and `null` fails.
  Read the list, merge deliberately, send the complete list and read it back.
- Never create self-references or duplicate source/target/kind identities.

## Workforce Rules

- Create or resolve the party first: a person (Employee, Contractor or Freelancer) or an
  organization or organization unit (DeliveryUnit only).
- Resolve delivery-unit and manager ids before saving a workforce profile.
- Reuse a skill definition by exact normalized name instead of creating near-duplicates.
  Without a known `id`, `POST /api/crm-hr/workforce/skills` updates the definition with the
  same trimmed name and overwrites all its fields. Renaming a definition to another
  definition's name fails with a server error.
- Resolve the saved skill id before assigning proficiency to a party.
- Capacity dates and percentages must describe real scenario facts. Do not fabricate project allocations or financial data.
- Candidate conversion is the canonical path from an approved recruitment application to an
  active workforce profile. It saves the candidate's profile, then marks the application Hired
  and the party Active. It requires decision Approved and a stage other than Rejected or
  Withdrawn, and it resets the profile fields the request does not carry (employee code, end
  date, rates, rate unit, currency).

## Recruiting Rules

- Keep the two recruiting boundaries distinct: CRM/HR owns person/candidate
  applications and workforce conversion; `/api/agent-recruiting` owns AI-agent
  execution evidence and readiness.
- Create or resolve the candidate party before saving an application when deterministic identity matters.
  When updating an application, always send `partyId` from the workspace read. Without it, a new
  candidate party is created and the application moves to it. The save overwrites every
  application field.
- Use application collection paging and exact scenario names to avoid duplicate applications.
- Resolve recruiter, hiring manager, interviewer, task owner, target unit, buddy, and mentor ids before commands that reference them.
- Save the application before its interviews, which reference its id. Lifecycle tasks and
  support assignments belong to the candidate party, not the application. Stages are stored as
  sent with no transition order, and interview outcomes never change the stage or decision.
- Read the recruitment workspace after mutations; it is the aggregate verification surface for stage history, interviews, lifecycle tasks, support assignments, and conversion state.
- Do not convert rejected or withdrawn scenarios merely to populate Workforce.
- CRM/HR candidate conversion does not approve or activate an AI agent. Agent readiness
  also does not mutate CRM/HR application or workforce state.

## Idempotent Demonstration Data

- Use a stable namespace such as `DEMO-CRMHR-*` for party external codes and stable candidate names for applications.
- First pass: search, create only when absent, then capture returned ids.
- Second pass: repeat every search and prove the same ids are resolved. Do not claim idempotency from total row counts alone.
- Adjust an existing deterministic record through its save command. Save commands overwrite all
  fields of the record they find, so start from the latest read. Parties cannot be updated
  through this API.
- Do not add a product seed route, startup hook, direct-database script, or destructive reset endpoint.

## Validation

- Confirm collection `totalCount`, `pageIndex`, `pageSize`, and item identities.
- Read back each created party/workforce/recruiting workspace.
- Exercise at least one invalid reference and confirm the documented status and
  `errors[].code`. Party creation, an application save that creates a candidate, and conversion
  save in steps: after any failure, search or read back before retrying.
- After API source changes, run the focused `CrmHrApiIntegrationTests`, build the Web project, inspect OpenAPI, and refresh this skill if routes or DTOs changed.
