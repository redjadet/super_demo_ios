# Sync And Networking

## Portfolio Feed (when implemented)

The **Feed** feature (see [`docs/portfolio.md`](portfolio.md) and
[`README.md`](../README.md) Portfolio) targets:

- **GET** `https://jsonplaceholder.typicode.com/posts`
  (`{ userId, id, title, body }` rows in a JSON array).
- **`FeedAPIClient`** lives under `Features/Feed/Data/` only.
- Injectable **`URLSession`**; **`timeoutIntervalForRequest` ~ 30s** in app
  composition when using a custom configuration.
- **`PostDTO` → `FeedPost`** in **`RemoteFeedRepository`**.
- **`CachingFeedRepository`** / **`CachedFeedPost`**: persist on success,
  fall back silently on network failure when rows exist.

**DummyJSON** alternate (`/posts`): wrapper `{ posts: [...], ... }` before DTO map.

Tests: **`URLProtocol`** or injected **`URLSession`** — no flaky live HTTP on CI.

**Status:** Core networking rules stay below; Feed bullets document intent before
Swift ships.

## Networking Rules

- Use typed request and response models.
- Keep URLSession details in Data.
- Decode into DTOs, then map to Domain.
- Support cancellation.
- Set explicit timeout and retry policy where product needs it.
- Never build URLs with unescaped string concatenation.

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
