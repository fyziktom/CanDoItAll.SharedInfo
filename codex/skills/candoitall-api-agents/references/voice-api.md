# Public voice API

These additive routes reuse the engine's workspace voice settings and
`IAgentVoiceService`; they do not start an agent run. They are present in source
commit `a59e3af7dcba28b7c0bf4a7450898d468a7d6fc3` and the shared snapshot. Verify
the target's live OpenAPI when its version differs.

With authorization enabled, both require `api.agents.execute` or compatible `api`.
Agent read/write scopes alone are insufficient. Keep tokens server-side and use
the existing settings/provider configuration instead of forwarding provider keys.

## Transcription

`POST /api/agents/voice/transcriptions` accepts `multipart/form-data` with either
one `file` or 1–12 repeated `chunks` parts in transcription order. Each chunk must
be an independently decodable audio file. Arbitrary encoded-stream fragments are
not independent files. Do not mix fields or send extra text fields, duplicate
`file` parts, or empty files.

The combined audio limit is 25 MiB (26,214,400 bytes); the entire request allows
another 64 KiB for multipart overhead. Supply matching extensions and media types:

| Extension | Media type |
| --- | --- |
| `.mp3`, `.mpga` | `audio/mpeg`, `audio/mp3` |
| `.mpeg` | `audio/mpeg`, `video/mpeg` |
| `.mp4` | `audio/mp4`, `video/mp4` |
| `.m4a` | `audio/mp4`, `audio/x-m4a` |
| `.wav` | `audio/wav`, `audio/x-wav`, `audio/wave` |
| `.webm` | `audio/webm`, `video/webm` |

Media-type parameters are accepted. Do not use an HTTP client's default
`application/octet-stream` for the audio part. Uploaded filenames are replaced
with generated names before dispatch. The provider validates audio decoding.

Success is JSON `{text, model}`. Chunks are sent sequentially; trimmed transcripts
are joined by line breaks. A later failure returns an error with no partial
transcript; earlier provider calls may already have incurred cost. Let users edit
the transcript before treating it as their instruction. Text-only workflows should
submit the text directly without microphone permission or transcription.

## Speech

`POST /api/agents/voice/speech` accepts JSON, for example:

```json
{"text":"This is a synthetic resort demonstration.","voiceId":"marin"}
```

The text must be nonblank and at most 4,096 UTF-16 characters; the complete JSON
body is limited to 64 KiB. Optional `agentId` selects an existing non-template
agent's voice permission and preference. It neither executes the agent nor reads
its conversations. Omitting it uses workspace-level speech. `Guid.Empty` is invalid.

Optional `voiceId` overrides the agent preference, then the workspace default.
Accepted IDs: `alloy`, `ash`, `ballad`, `coral`, `echo`, `fable`, `nova`, `onyx`,
`sage`, `shimmer`, `verse`, `marin`, `cedar`. The existing speech preprocessor can
omit technical identifiers and include an omission notice. The workspace chooses
the model and format; PCM is wrapped as WAV. Success is raw audio bytes with a
playback content type, without a JSON/base64 wrapper. Disclose AI-generated speech
to listeners.

## Settings, failures and lifecycle

Each operation must be enabled in **Agents → Voice**. Programmatic settings changes
use the workflow-settings API: read and preserve the whole document because its
write replaces the settings. Audio requires an enabled native OpenAI profile with
purpose Chat and a supported driver. Imported shared profiles and image-only
profiles are blocked. Do not silently switch models, providers or protocols.

| Status / `errors[].code` | Action |
| --- | --- |
| 400 `agents.voice-input-invalid` | Correct the documented fields, limits or declared audio format. |
| 401 / 403 | Establish valid execute authority; do not broaden grants automatically. |
| 403 `agents.voice-access-denied` | Respect the selected agent's disabled voice permission. |
| 404 `agents.voice-agent-not-found` | Select an existing non-template agent. |
| 409 `agents.voice-disabled` | Enable the intended workspace operation through authorized configuration. |
| 409 `agents.voice-capability-unavailable` | Select a supported native OpenAI Chat profile/driver. |
| 503 `agents.voice-provider-unavailable` | Check provider configuration/health; it may be missing, disabled, failing or returning empty output. |

Framework body-size, content-type and binding rejections may return 400, 413 or 415
without this voice-specific envelope. Handle HTTP status first. For oversized
uploads the server can reject early; a streaming client may observe connection
termination while still sending. `Expect: 100-continue` allows a client to receive
the early size rejection before uploading the body.

Cancellation propagates to the provider and stops remaining chunks. It cannot
undo work already accepted by a provider. There are no automatic retries, durable
voice assets or agent-run IDs from these routes. Successful responses are
`Cache-Control: no-store`; multipart binding may use temporary request-lifetime
files. Provider retention follows its configured policy. Offer an explicit retry
after diagnosis and preserve user-entered text on voice errors.
