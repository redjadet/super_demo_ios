# 2026-11-13 — Offline-first article gap fixes

## Summary

Thin Feed read-path improvements mapped from a public offline-first article
(local truth, warm cache, fail-fast timeout, sync observability) without
porting Flutter/Hive or inventing new OI IDs.

## Changes

- `peekCachedPosts()` on `CachingFeedRepository` + `FeedFeatureModel` warm serve
  (no spinner when TTL-valid cache exists; OI-02/OI-03 still gate validity)
- `FeedLoadResult.lastSyncedAt` → `feedLastSynced` chrome (OI-04 observability)
- `LiveFeedAPIClient.requestTimeout` **8s** (was 30s request timeout)
- Docs honesty: `cache-behavior.md`, `offline-invariants.md`,
  `offline-first-behavior.md`, `offline-first.md`, `sync-and-networking.md`

## Proof

- `CachingFeedRepositoryTests` peek + `lastSyncedAt` asserts
- `FeedFeatureModelTests.warmCacheServesContentWithoutWaitingForRemote`,
  `refreshRecordsLastSyncedAtFromResult`
- `RemoteFeedRepositoryTests.liveFeedAPIClientUsesFailFastTimeout`

## Out of scope

- Pure local-only UI (network never drives presentation state machine)
- Items remote sync (OI-06)
- P2-A screenshots; Hive/Flutter ports
