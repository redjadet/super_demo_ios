# Feed bookmark consistency

Bookmark writes could persist without their outbox operation, and completion of
an older request could overwrite a newer toggle. Queue snapshots could survive
coalescing, successors could bypass a backing-off head or stall after success,
and background sync left the view model showing stale status.

## Changes

- Commit optimistic bookmark and coalesced outbox changes together; rollback on
  save failure. Explicit Retry resets the attempt budget while retaining the key.
- Claim only a still-present, ready FIFO head before sending. Failed/in-flight or
  backing-off heads block their post; successful heads drain successors.
- Preserve newer queued intent when acknowledging an older request. HTTP 409/412
  reports unresolved conflict; it supplies no server value to adopt.
- Notify the feed model after durable changes, show local-save errors, and give
  bookmark/retry controls 44 pt touch targets.
- Break the engine-holder/repository callback retain cycle so discarded Feed
  models release their persistence stack.
- Align canonical offline docs with conflict handling and trigger-based backoff.

## Validation

Four regression tests reproduced lost intent, FIFO bypass, stalled successors,
and invented conflict state on the original code. Added rollback, stale-claim,
and explicit-retry tests; existing model tests now rely on sync notifications
without manually reloading bookmark state.

Local `./bin/checklist` passed: 227 iPhone simulator tests (201 unit, 26 UI),
plus iPad, macOS, and watchOS builds. Swift formatting/lint and Markdown lint
passed. A final unit rerun passed all 202 tests, including the composed-stack
lifetime regression added after the full test lane began. The iPad unit runner
built successfully but exited before XCTest
connected; its result supplies no runtime assertion proof.

JSONPlaceholder remains an HTTP write demonstration: it does not provide
durable remote bookmarks or server-enforced idempotency.
