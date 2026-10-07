# Offline invariants matrix (Feed / Items)

**Status:** OI-01…OI-07 (cache / Items / recovery) plus **OI-08** (Feed bookmark
outbox). Deep-dive: [`architecture/offline-first-behavior.md`](architecture/offline-first-behavior.md).  
**Canonical posture:** [`offline-first.md`](offline-first.md)  
**Networking detail:** [`sync-and-networking.md`](sync-and-networking.md)

Named rules make Feed cache TTL, stale UI honesty, Items local-only writes,
bookmark outbox sync, and store recovery reviewable.

## Named invariants

| ID | Invariant | Surface | Evidence |
| --- | --- | --- | --- |
| **OI-01** | **Remote success replaces cache wholesale** — successful fetch persists posts and returns `isStale: false`; rows absent from remote are deleted from cache. | `CachingFeedRepository` | `CachingFeedRepositoryTests.fetchPostsPersistsRemotePosts`, `fetchPostsReplacesStaleCacheWithRemotePosts` |
| **OI-02** | **Fresh cache fallback on remote failure** — when remote throws and cache is within TTL, return cached posts with `isStale: true` (not empty success). Widget snapshot `writtenAt` uses the **oldest** surviving SwiftData `cachedAt` (TTL not reset to wall clock or newest row). | `CachingFeedRepository` | `CachingFeedRepositoryTests.fetchPostsReturnsCachedPostsWhenRemoteFails`, `fetchPostsUsesOldestCachedAtForStaleWidgetSnapshot` |
| **OI-03** | **Expired TTL is a cache miss** — default TTL is 15 minutes; offline fallback **filters rows** by `effectiveCachedAt` (mixed-age / migrated `nil` → `distantPast` excluded). If no fresh rows remain, rethrow the remote error and **clear** the App Group Feed widget snapshot. `cacheTTL: nil` disables expiry (documented forever-cache). | `CachingFeedRepository`, `CachedFeedPost.cachedAt`, `FeedWidgetSnapshotPublishing` | `fetchPostsIgnoresExpiredCacheWhenRemoteFails`, `fetchPostsFiltersMixedAgeCacheRows`, `fetchPostsKeepsExpiredCacheWhenTTLDisabled`; docs in [`offline-first.md`](offline-first.md) § Feed cache TTL |
| **OI-04** | **Stale is visible + diagnosable** — Presentation keeps `isStale` on content state, shows offline banner, and records `feed-cache-fallback` diagnostic. | Feed Presentation | `FeedFeatureModelTests.refreshShowsStaleContentAndRecordsDiagnostic`; `FeedView` stale `Label`; optional in-app fixture via `-StaleFeedDemo` / `SUPERDEMO_STALE_FEED_DEMO` ([`sync-and-networking.md`](sync-and-networking.md)) |
| **OI-05** | **Cancel-safe refresh restores prior UI** — cancelling an in-flight refresh restores prior content/loading state; existing content stays visible during refresh. | Feed + Items Presentation | `FeedFeatureModelTests.cancelRefreshRestoresPriorContent`, `refreshKeepsExistingContentVisible`; `ItemsFeatureModelTests.cancelRefreshRestoresPriorLoadingState`, `refreshKeepsExistingContentVisible` |
| **OI-06** | **Items are local-first with no remote merge** — Items persist only via SwiftData; there is no Items remote mutation queue or remote conflict policy. | Items Data | `SwiftDataItemRepository` + `SwiftDataItemRepositoryTests` (add/update persist) |
| **OI-07** | **Corrupt / mismatched store recovers explicitly** — preferred container failure deletes store + `-shm`/`-wal`, recreates on disk (`fallback: recreated-store`), then in-memory if needed — never silent forever-cache of a broken schema. | `AppModelContainer` | `AppModelContainerTests.makeOnDiskRecreatesStoreAfterIncompatibleFile`, `removePersistentStoreFilesDeletesStoreAndSidecars`; [`offline-first.md`](offline-first.md) § App container recovery |
| **OI-08** | **Feed bookmark outbox is durable and idempotent** — optimistic local apply; persistent `OutboxEntry`; crash recovers `inFlight`→`pending` with the same `Idempotency-Key`; coalescing + FIFO per entity; 4xx fails, 5xx/backoff retries; cancel does not increment attempts; 409/412 preserves the acknowledged baseline and reports unresolved failure. | Feed Data / Presentation | `OutboxStoreAndBookmarkRepositoryTests`, `OutboxSyncEngineTests`, `OutboxCoalescerTests`, `OutboxBackoffPolicyTests`, `FeedBookmarkFeatureModelTests`, `testOfflineBookmarkToggleShowsPending`; [`architecture/offline-first-behavior.md`](architecture/offline-first-behavior.md) |

## Proof commands

| Lane | Command |
| --- | --- |
| Docs / fast | `./bin/checklist-fast` |
| Focused unit proof | Filter on `CachingFeedRepositoryTests`, `OutboxSyncEngineTests`, `OutboxStoreAndBookmarkRepositoryTests`, `FeedBookmarkFeatureModelTests`, `SwiftDataItemRepositoryTests`, `AppModelContainerTests` |
| Merge gate | `./bin/ci.sh` |

## Out of scope (honesty)

- Items still have **no** remote sync / merge (OI-06).
- JSONPlaceholder bookmark mapping fakes server durability — contract demo only.
- True device airplane-mode integration is not required;
  `-OfflineBookmarkDemo` with `ManualConnectivityMonitor` covers the offline
  enqueue path.
- Do not invent empty remote-merge tests for Items.
- Supply-chain / CI workflow changes are separate (do not touch
  `.github/workflows` in the outbox PR).

## Related change notes

- [`changes/2026-09-15_signposts-cache-ttl.md`](changes/2026-09-15_signposts-cache-ttl.md)
- [`changes/2026-09-15_feed-items-diagnostics-hardening.md`](changes/2026-09-15_feed-items-diagnostics-hardening.md)
- [`changes/2026-09-26_p2-harden-edge-cases.md`](changes/2026-09-26_p2-harden-edge-cases.md)
  (widget snapshot clear on OI-03; stale `writtenAt` = oldest surviving `cachedAt`)
- [`changes/2026-09-15_swiftdata-store-recovery.md`](changes/2026-09-15_swiftdata-store-recovery.md)
- [`changes/2026-10-06_feed-bookmark-outbox.md`](changes/2026-10-06_feed-bookmark-outbox.md)
