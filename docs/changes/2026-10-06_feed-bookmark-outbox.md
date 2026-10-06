# 2026-10-06 — Feed bookmark offline outbox

## Summary

Adds production-shaped offline **write** support for Feed bookmarks: SwiftData
`OutboxEntry` + `BookmarkedPost`, optimistic UI, `OutboxSyncEngine` actor
(connectivity / foreground / manual flush), coalescing, backoff, idempotency,
and conflict handling. Removes the “no mutation queue” architecture claim.

## Why bookmarks

No prior user write path existed (Feed GET-only; Items local-only). JSONPlaceholder
supports `POST`/`DELETE /posts` — used as the remote mapping without inventing a
`/bookmarks` endpoint. Persistence on that API is fake; the outbox contract is real.

## Key types

- Domain: `PostBookmark`, `OutboxCoalescer`, `OutboxBackoffPolicy`, `OutboxSyncing`
- Data: `OutboxEntry`, `BookmarkedPost`, `SwiftDataOutboxStore`,
  `SwiftDataBookmarkRepository`, `OutboxSyncEngine`,
  `JSONPlaceholderBookmarkRemoteClient`
- Presentation: bookmark chrome on Feed list/detail + failed outbox banner

## Docs

- `docs/architecture/offline-first-behavior.md` (sequence diagram + test map)
- `docs/architecture/cache-behavior.md`, `docs/offline-invariants.md` (OI-08)
- `docs/sync-and-networking.md`, `docs/testing.md`
