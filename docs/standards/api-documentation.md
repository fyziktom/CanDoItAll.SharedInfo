# HTTP API Documentation Standard

## Goal

A developer who sees only one operation and its schemas in Swagger UI or in the generated OpenAPI
document can build a correct request, understand the response and choose the next action without
reading the implementation. IntelliSense and the OpenAPI document carry the same text because both come
from the same source.

This standard applies to every CanDoItAll repository that publishes an HTTP API. Use the shared
[API domain glossary](../architecture/candoitall-api-domain-glossary.md) for vocabulary. The product
repository owns its contracts, endpoint behavior, generated document and a short page describing its
own documentation pipeline.

## Source of truth

- C# XML documentation on route handlers and serialized types is the default canonical operation and
  schema text. A reviewed source-owned metadata path, such as endpoint `DescribeApi` declarations and
  DTO `Description` attributes used by the access and process-authoring APIs, can own that text instead.
  Keep exactly one description owner; do not maintain independent copies in transformers or Markdown.
- The generated OpenAPI document of a build is the published contract. Hand-edited copies are not.
  Fix a description at its source and regenerate.
- A few schemas have no CLR source (hand-built protocol schemas) or come from framework or external
  packages without usable XML. Describe them once, at the owner that builds or exposes them, and record
  that exception.
- A glossary link can add context, but every description must stand on its own.

## Operations

Give every operation a one-sentence summary that names the action and its object, and a description
that answers, where it applies:

| Question | Content |
|---|---|
| What does it do? | Reads, creates, updates, replaces, starts, acknowledges or observes what |
| When is it used? | Supported use and the nearest confusing alternative |
| What must exist first? | The operation that returns each referenced identifier; required state; owner-read preconditions |
| Under what authority? | The actual authentication, policy and scopes; lifetime, admission or lease requirements separately |
| What is sent? | Path, query, header and body meaning; media type; route and body identifiers that must match |
| What happens on success? | Completed, accepted and running, paged, or committed with warnings; the returned identity |
| What can fail? | Each status with its envelope, stable codes and causes |
| What next? | Read back, poll or reconcile; when a retry is safe and when it is not |

Declare every status an operation can return, with the type and media type it really writes. A
response description does not create a response. Do not declare an envelope the route does not use,
wrap existing results in new envelopes or change runtime behavior to simplify documentation.

Say whose data an operation returns. When a response can carry records that another caller
created, name the members withheld or redacted for them, and give the caller scope of every key a
client supplies for retries, so a reader knows whether another caller's key can collide with or
replay theirs. Describing such a key as shared across callers, or a record as complete, is a
security claim: verify it against the store and the authorization scope.

An HTTP operation is not an agent runtime tool, even when both use the same application service.
Never describe HTTP access as a way around a denied or unavailable tool.

## Types and members

Describe each serialized type by its business role, the requests and responses that use it, the
identity it represents and its cross-field rules. A nested type must make sense when opened on its own.

Describe every serialized member, including members of internal types and computed read-only
properties. Establish from the code, not from the name:

- business meaning, and the entity and owner it refers to;
- the source of the value: client choice, owner read, options endpoint, calculation or receipt;
- the wire form: GUID, opaque string key, integer enum, enum text token, instant with offset, date,
  decimal, JSON value, or a string that contains JSON;
- presence, null, omission, empty and default meaning, and for writes whether each preserves, clears
  or is rejected;
- units, origin and limits, including what a length limit counts;
- interactions with other members: matching identifiers, current and proposed pairs, discriminators,
  conditional requirements, full-collection replacement;
- direction and sensitivity: request-only, response-only, owner-issued, redacted.

Required and nullable are independent. A member that must be present but may be null says so; an
optional member says what its absence means. Do not call a required member optional because the C#
type allows null.

A property description states the role of that use of a type. Do not paste the type's description onto
each property that uses it.

## Enums and variants

State the wire form (JSON integer or text token, and the casing) and the meaning of every member.
A C# member name is not proof of a transport token. For flags, say how values combine. For unions,
explain the discriminator and each variant's conditional members. Do not change a serializer, add a
converter or add enum values to make documentation easier.

A property or parameter whose type is an enum also states the wire form and the values accepted at
that use. Viewers such as Swagger UI show the property's own description in place of the enum
type's description, and an integer enum schema carries no list of values, so the type's text alone
does not reach the reader.

## Values

- Say whether a time is an instant, a date or a duration, and keep the endpoint's actual time zone
  handling. Document inclusive or exclusive bounds only when verified.
- Keep effort separate from elapsed schedule time and amounts separate from rates. Name the unit, the
  rate denominator and the currency. A three-letter format check is not currency registry validation.
- A null amount is unknown, not zero.

## Collections, paging and errors

Say what a total count covers, the sort order, the page origin, defaults and limits, and how to fetch
the next page. A cursor is opaque, not an offset. Say whether an empty collection differs from a failed
read, and whether a write replaces the whole collection.

Document each family's actual error envelope. An error status alone does not prove that nothing was
written; explain retained identities, receipts and safe readback where the owner provides them. Do not
promise idempotency or atomicity that the owner does not implement.

## Examples

Examples use synthetic data, real routes, exact casing and media types, and complete values. Build them
from the real serializer or a validated fixture and prove them over HTTP. An example that needs
server-issued values, such as a project admission or a concurrency token, is a recipe: show where each
value comes from; never present an invented token as runnable. Never include secrets, tokens, real
paths or personal data.

## Microsoft.AspNetCore.OpenApi projects

These rules follow from how the XML comment generator of `Microsoft.AspNetCore.OpenApi` works:

- Enable `GenerateDocumentationFile` on every project that declares a route handler or a serialized API
  type. Only project references contribute XML; package references do not.
- XML-documented route handlers are named `internal` or `public` methods: the compiler keeps no XML
  for lambdas and the generator ignores `private` handlers. A reviewed endpoint-metadata path must
  supply and validate the descriptions when a handler cannot contribute XML.
- Every route group sets its tags explicitly. A lambda's default tag is the application name and a
  method's is its declaring class.
- Document path, query, header and body parameters with `<param>`. Do not document service,
  `HttpContext` or `CancellationToken` parameters: each documented parameter that is not an HTTP
  parameter overwrites the request-body description.
- Only a type's `<summary>` and a property's `<summary>` and `<value>` reach the schema. Keep everything
  a client needs there; use `<remarks>` on types and members for maintainer notes only.
- In operation `<remarks>`, separate paragraphs with an empty comment line and write list items as lines
  starting with `1.` or `-`. The generator flattens `<para>`, `<list>`, `<code>` and `<term>`.
- The generator keeps source line breaks, platform line endings and XML entities. Normalize the final
  document's prose so it is identical on every build platform.
- A component first generated from a nullable value type loses its type description. Restore it from the
  same XML rather than from a second text source.

## Documentation access and bearer authorization

Keep documentation exposure settings explicit and independent of API operation permissions.
For Swagger's JWT **Authorize** flow, the page and its OpenAPI document must load before the
user supplies a token. Disabling document exposure must also disable a UI that depends on it.
Serving a document anonymously never grants access to the operations it describes.

Publish an HTTP bearer/JWT security scheme and attach its requirement to the protected
operations. Anonymous login/status operations must remain usable without that requirement.
Verify page and document loading with API authorization enabled, then prove a protected
operation returns 401 without a token, succeeds with an authorized JWT and returns 401 after
Swagger authorization is cleared. UI logout and server-side session revocation are distinct.

## Verification

Keep these checks as separate results; one does not prove another:

1. **Source** — handlers and every exposed type and member carry meaningful descriptions through
   XML comments or a reviewed source-owned metadata path.
2. **Document** — a maintained test fails when an operation, parameter, request body, response,
   component schema or property of the generated document has no description, except for a reviewed
   list of exclusions with reasons.
3. **Structure** — documentation work changes prose only. Compare the documents before and after and
   justify every change to routes, operation identifiers, schemas, required members, enums, media types,
   security or responses with runtime evidence.
4. **Rendering** — Swagger UI shows the operation, parameter, body, nested model and error descriptions.
5. **Consumer** — an independent client without the product's types completes the documented workflow
   with literal JSON.

## Review

Reject a description that could be pasted onto an unrelated member unchanged, that hides a conditional
requirement, that bypasses an owner read, or that promises more than the implementation. Reject filler
such as "Gets or sets …", "The data", "The model" or "The identifier" without naming the entity and
where the value comes from. Coverage counts cannot certify any of this; read the operation and its
schemas as a new integrator would.
