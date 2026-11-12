# Interactive agent chat lifetime

An accepted turn from the floating Blazor chat runs in an application-owned execution
scope. Refreshing the browser, navigating away, minimizing or hiding the window detaches
the view without cancelling that turn. Reopen it through Active chats instead of
submitting the same prompt again. The restored view observes the original conversation,
run and activity stream, including a pending approval or continuation.

Discovery uses the verified issuer and subject plus the current workspace profile,
not a circuit, browser or login-session identifier. The same authenticated user can
rediscover work from another browser. A deployment shares one workspace owner across
browsers only when both API authorization and user authentication are disabled.
Anonymous callers in an authenticated deployment do not inherit that shared owner.

Admission freezes the working context. Reopening a retained chat navigates to its safe
module bookmark, where the routed owner establishes current access. Later navigation
does not retarget an admitted turn. Ownership permits discovery and control; it never
replaces tool policy, project admission, approval or current disclosure authorization.
A database-profile change invalidates the old execution lifetime rather than moving
the run into the replacement database.

Window geometry and unsent drafts belong to the view; do not promise that a full browser
reload restores them. Active execution and pending continuation context are retained
independently. Recent terminal chat metadata has bounded retention; persisted run and
conversation records remain the source for history after the active entry expires.

This is a running-host guarantee. A server restart or crash does not reconstruct the
in-memory active catalog or automatically replay tools. Inspect the persisted run,
receipts and approvals and use the documented recovery/reconciliation operations only
when their preconditions hold. Never start a replacement turn merely because its window
or activity subscription disappeared.

The floating-chat lifetime does not turn the agent HTTP POST/SSE commands into a durable
202 operation API. Follow their same-request and activity-replay contracts separately.
Ordinary Simple Chat has its own durable operation resource under
`/api/llm-chat-operations`; do not exchange those identifiers with agent execution IDs.

The product owns the design and regression proof in
[agent chat execution lifetime](https://github.com/fyziktom/CanDoItAll/blob/development/docs/architecture/agent-chat-execution-lifetime.md).
