# Sync And Networking

## Portfolio Feed

The **Feed** feature (see [`docs/portfolio.md`](portfolio.md) and
[`README.md`](../README.md) Portfolio) implements:

- **GET** `https://jsonplaceholder.typicode.com/posts`
  (`{ userId, id, title, body }` rows in a JSON array).
- **`FeedAPIClient`** lives under `Features/Feed/Data/` only.
- Injectable **`URLSession`**; **`timeoutIntervalForRequest` ~ 30s** in app
  composition when using a custom configuration.
- **`PostDTO` → `FeedPost`** in **`RemoteFeedRepository`**.
- **`CachingFeedRepository`** / **`CachedFeedPost`**: persist on success;
  on network failure with cached rows, return `FeedLoadResult(isStale: true)`
  so Presentation can show a stale banner (not a silent success).
- **Auth path honesty:** production wiring uses `EmptyTokenRefresher` by default.
  Opt into Keychain-backed demo refresh with `-KeychainTokenDemo` or
  `SUPERDEMO_KEYCHAIN_TOKEN_DEMO=1` (`KeychainDemoTokenRefresher` +
  `KeychainAccessTokenStore`). `InMemoryDemoTokenRefresher` /
  `InMemoryAccessTokenStore` cover unit tests. Not real OAuth.

**DummyJSON** alternate (`/posts`): wrapper `{ posts: [...], ... }` before DTO map.

Tests: **`URLProtocol`** or injected **`URLSession`** — no flaky live HTTP on CI.
UI tests pass **`-UITesting`**; `FeedComposition` uses **`SampleFeedRepository`**
instead of `RemoteFeedRepository` so the Feed tab does not open live HTTP during
`superDemoAppUITests` (see [`testing.md`](testing.md#-uitesting-behavior)).

**Status:** Shipped under `Features/Feed/`; see
[`changes/2026-05-16_feed-feature-shipped.md`](changes/2026-05-16_feed-feature-shipped.md)
and
[`changes/2026-09-15_feed-items-diagnostics-hardening.md`](changes/2026-09-15_feed-items-diagnostics-hardening.md).
Core networking rules stay below.

## Networking Rules

- Use typed request and response models.
- Keep URLSession details in Data.
- Decode into DTOs, then map to Domain.
- Support cancellation.
- Set explicit timeout and retry policy where product needs it.
- Never build URLs with unescaped string concatenation.

## Production Networking Client

`Shared/Networking/` demonstrates production retry policy without third-party dependencies:

- retryable: timeout/connectivity failures, 429, and selected 5xx statuses
- non-retryable: most 4xx statuses
- `401`: refresh token once, then retry the original request once
- `429`: respect `Retry-After` when present
- exponential backoff plus jitter; limited attempts
- POST retries only when an idempotency key is present
- cancellation remains cancellation, not a user-facing server failure
- logs use host/status/error metadata only; no secrets or authorization headers

Feature Data adapters map `APIError` into domain/UI-safe messages.

## Sync Rules

- Local write first when offline-first requirement applies.
- Queue pending operations with stable IDs.
- Make retries idempotent.
- Track sync state per record or operation.
- Handle conflict policy explicitly.
- Surface durable failure state to users when action cannot complete.

## Security

- Keep secrets out of repo and logs.
- Use least-privilege API tokens.
- Validate server trust and auth state before mutation.
- Document privacy-label impact for any collected, linked, tracking, diagnostic,
  or third-party-shared data.
- Prefer background/off-main processing for parsing, sync reconciliation, image
  processing, and other heavy work.
