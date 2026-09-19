# Shared-provider protocol

The native catalog currently uses schema version `1.1`, nonempty UUID publication/source
IDs, `sha256:` revisions and opaque `sp1.` routing model IDs. Use returned values rather
than constructing them. Catalog ETags are private-cache validators; inference is private
no-store and does not use ETags.

## Accepted inference subset

The generated operation schema is authoritative. Unknown/duplicate properties,
case-mismatched field names and over-limit bodies fail explicitly. The host and selected
provider can impose narrower limits than the protocol maximum; capabilities are checked
again at dispatch.

- Chat Completions: bounded messages, user-only data-URI images, client-executed function
  tools, tool choice, parallel tools, structured output, sampling, stop and one output
  token limit. `stream_options.include_usage` requires `stream:true`.
  `reasoning_effort` must be allowed by that model. For a tool-call-only assistant message,
  omit `content` or send null. The relay also accepts `""`, although the schema requires at
  least one character.
- Responses: stateless foreground execution. Use `store:false` and `background:false`;
  omitted store is normalized to false. Input can be text or supported message,
  function-call/output and reasoning replay items. Thinking uses `reasoning.effort`.
  No `previous_response_id`, stored response lookup, background polling, hosted tools,
  file IDs or arbitrary provider-specific fields.
- Image generation: prompt, bounded count, supported size/quality/output format and
  `response_format:"b64_json"`. Responses contain base64 image data, not remote URLs.
- Image input: nonempty base64 data URIs for PNG, JPEG or WebP with no whitespace.
  Remote HTTP image URLs and file paths are rejected.
- Tools execute on the client. Named tool choice must reference a tool declared in the
  same request. Do not assume server tool execution from OpenAI compatibility.

General bounds include JSON depth 32, at most 256 messages/input/content parts and 1 to
128 tools when `tools` is present (an empty array is rejected; omit the member), bounded
text (up to 1,048,576 UTF-16 code units), and bounded raw JSON schemas
(up to 262,144 UTF-16 code units). Name tokens allow ASCII letters, digits, underscore,
hyphen and dot, up to 128 characters. Read the live schema and publication for actual
request-body, output-token and image-count limits.

## Streaming and failures

A successful buffered Responses envelope must have `status:"completed"` and no non-null
`error`. Error-null is accepted; failed/incomplete bodies are not successful answers.

Before headers, upstream rate limiting is a sanitized 429 with an optional safe
Retry-After; a deadline is 504. Oversized/unreadable diagnostics do not change the mapped
status. Do not display raw upstream bodies as safe application messages.

After streaming headers, HTTP 200 alone is insufficient. Failed/incomplete Responses,
malformed SSE, idle deadline and upstream disconnect abort the connection; no fabricated
success terminal is sent. Preserve partial text as incomplete and surface transport
failure. A caller cancellation is distinct from an upstream deadline.

Missing usage remains unavailable/partial. A model without `price` is unpriced; it is
free only when `price.isExplicitlyFree` is true. Invocation price provenance is frozen and
is not rewritten by later catalog edits.

## Source network policy

HTTPS public destinations are the default. HTTP loopback is allowed for local
development; other private/HTTP sources require explicit source policy and remain
subject to destination/DNS and redirect restrictions. This is configured through source
administration, not an inference payload or a global network bypass.
