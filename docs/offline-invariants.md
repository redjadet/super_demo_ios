# Offline invariants matrix (Feed / Items)

**Status:** Documented for FP-P0-C; evidence from existing code + tests (no new sync engine).  
**Canonical posture:** [`offline-first.md`](offline-first.md)  
**Networking detail:** [`sync-and-networking.md`](sync-and-networking.md)

Named rules make Feed cache TTL, stale UI honesty, Items local-only writes, and
store recovery reviewable without inventing Flutter-style merge/queue machinery
this app does not ship.

## Named invariants

| ID | Invariant | Surface | Evidence |
| --- | --- | --- | --- |
| **OI-01** | **Remote success replaces cache wholesale** — successful fetch persists posts and returns `isStale: false`; rows absent from remote are deleted from cache. | `CachingFeedRepository` | `CachingFeedRepositoryTests.fetchPostsPersistsRemotePosts`, `fetchPostsReplacesStaleCacheWithRemotePosts` |
| **OI-02** | **Fresh cache fallback on remote failure** — when remote throws and cache is within TTL, return cached posts with `isStale: true` (not empty success). | `CachingFeedRepository` | `CachingFeedRepositoryTests.fetchPostsReturnsCachedPostsWhenRemoteFails` |
| **OI-03** | **Expired TTL is a cache miss** — default TTL is 15 minutes; expired cache on remote failure rethrows the remote error (empty fallback ≠ success). `cacheTTL: nil` disables expiry (documented forever-cache). | `CachingFeedRepository`, `CachedFeedPost.cachedAt` | `fetchPostsIgnoresExpiredCacheWhenRemoteFails`, `fetchPostsKeepsExpiredCacheWhenTTLDisabled`; docs in [`offline-first.md`](offline-first.md) § Feed cache TTL |
| **OI-04** | **Stale is visible + diagnosable** — Presentation keeps `isStale` on content state, shows offline banner, and records `feed-cache-fallback` diagnostic. | Feed Presentation | `FeedFeatureModelTests.refreshShowsStaleContentAndRecordsDiagnostic`; `FeedView` stale `Label`; optional in-app fixture via `-StaleFeedDemo` / `SUPERDEMO_STALE_FEED_DEMO` ([`sync-and-networking.md`](sync-and-networking.md)) |
| **OI-05** | **Cancel-safe refresh restores prior UI** — cancelling an in-flight refresh restores prior content/loading state; existing content stays visible during refresh. | Feed + Items Presentation | `FeedFeatureModelTests.cancelRefreshRestoresPriorContent`, `refreshKeepsExistingContentVisible`; `ItemsFeatureModelTests.cancelRefreshRestoresPriorLoadingState`, `refreshKeepsExistingContentVisible` |
| **OI-06** | **Items are local-first with no remote merge** — Items persist only via SwiftData; there is no offline mutation queue or remote conflict policy. Flutter-style “stale remote must not overwrite newer local” is **N/A** until a sync engine exists. | Items Data | `SwiftDataItemRepository` + `SwiftDataItemRepositoryTests` (add/update persist); sync rules prose in [`sync-and-networking.md`](sync-and-networking.md) § Sync Rules remain aspirational for Features that add remote writes |
| **OI-07** | **Corrupt / mismatched store recovers explicitly** — preferred container failure deletes store + `-shm`/`-wal`, recreates on disk (`fallback: recreated-store`), then in-memory if needed — never silent forever-cache of a broken schema. | `AppModelContainer` | `AppModelContainerTests.makeOnDiskRecreatesStoreAfterIncompatibleFile`, `removePersistentStoreFilesDeletesStoreAndSidecars`; [`offline-first.md`](offline-first.md) § App container recovery |

## Proof commands

| Lane | Command |
| --- | --- |
| Docs / fast | `./bin/checklist-fast` |
| Focused unit proof | Xcode test plan / scheme filter on `CachingFeedRepositoryTests`, `FeedFeatureModelTests`, `ItemsFeatureModelTests`, `SwiftDataItemRepositoryTests`, `AppModelContainerTests` |
| Merge gate | `./bin/ci.sh` |

## Out of scope (honesty)

- No new sync engine, mutation queue, or TOCTOU merge guards in this slice.
- Do not invent empty remote-merge tests for Items (local-only) or Feed (cache-aside read model).
- Supply-chain / CI workflow changes are separate (FP-P2-A).

## Related change notes

- [`changes/2026-09-15_signposts-cache-ttl.md`](changes/2026-09-15_signposts-cache-ttl.md)
- [`changes/2026-09-15_feed-items-diagnostics-hardening.md`](changes/2026-09-15_feed-items-diagnostics-hardening.md)
- [`changes/2026-09-15_swiftdata-store-recovery.md`](changes/2026-09-15_swiftdata-store-recovery.md)
