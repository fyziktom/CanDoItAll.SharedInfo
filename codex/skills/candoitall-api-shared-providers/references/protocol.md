# Shared-provider protocol

The native catalog currently uses schema version `1.1`, nonempty UUID publication/source
IDs, `sha256:` revisions and opaque `sp1.` routing model IDs. Use returned values rather
than constructing them. Catalog ETags are private-cache validators; inference is private
no-store and does not use ETags.

## Catalog prices and capabilities

To receive image-input pricing, send `CanDoItAll-Catalog-Features: image-pricing` on
native catalog requests. A supporting publisher echoes the header. Schema `1.1` without
this opt-in retains its legacy price shape. ETags differ between representations;
keep the feature header consistent when using `If-None-Match` and honor `Vary`.

For image models, `inputPerMillionTokensUsd` and `cachedInputPerMillionTokensUsd` are
text-input rates; `outputPerMillionTokensUsd` is the image-output rate. The optional
`imageInputPerMillionTokensUsd` and `cachedImageInputPerMillionTokensUsd` carry separate
image-input rates. Their absence means unavailable, not zero. These are token rates,
not fixed prices per image; quality and size affect token consumption. Current image
request history records image counts and does not calculate a token-based image cost.

Use each returned model's thinking contract rather than inferring it from the provider
kind. The default GPT-6 Astra catalog supports low, medium, high, xhigh and max on both
Chat Completions and Responses. Models, rates and availability can change; confirm the
live catalog and upstream documentation for the selected deployment. A provider-wide
reasoning default must be supported by every affected model, or be replaced by valid
per-model defaults. For example, `low` is invalid for the Pro models that require
`medium` or higher. An invalid published default can make Simple Chats provider-options
return `llm-chat.model-settings-invalid`; correct the publisher configuration and
synchronize its clients before retrying.

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
  The protocol accepts `xhigh` and `max` quality; the OpenAI driver permits them for
  GPT Image 2.5 Sunburst and Flare (including dated snapshots), and rejects them for
  older image models. A protocol enum does not imply every model supports every value.
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

## Real-provider acceptance

When the user requests end-to-end inference validation, record the actual upstream
endpoint and model without credentials. A deterministic fixture proves protocol
behavior only. Compare publication and client model names, options and prices, then
exercise the requested client surfaces and correlate their completion with the real
backend or publisher request history. Preserve unavailable prices and usage as such.
For local Ollama, use its installed inventory and the deployment's standard profile;
do not substitute a fixture or silently choose a different model.

Real GPT Image 2.5 responses include per-image `generation_id` metadata. The relay accepts a bounded identifier and omits this upstream identity from its public image projection. Base64 image data and supported usage survive; URL results and unknown private fields remain rejected. Validate image success using the returned image bytes and the saved workspace artifact.
