# Plan — feed-stale-banner-honesty

## Write-set

- `superDemoApp/Features/Feed/Data/CachingFeedRepository.swift`
- `superDemoApp/Features/Feed/Presentation/FeedFeatureModel.swift`
- `superDemoApp/Features/Feed/Presentation/FeedView.swift` (stale affordance)
- `superDemoAppTests/` Feed repository + feature model tests
- `docs/offline-invariants.md`, `docs/sync-and-networking.md` (honesty only)

## Do not touch

- `.github/workflows/` (unless CI task)
- Flutter embed / `flutter_module/`
- Unrelated ProductionReadiness demos

## Steps

1. Confirm Domain result carries `isStale` (or equivalent) through `RefreshFeedUseCase`.
2. Implement/adjust `CachingFeedRepository` TTL + wholesale replace + fallback.
3. Wire Presentation banner + diagnostic on stale content state.
4. Add/adjust Swift Testing cases for success, fresh fallback, expired miss, cancel.
5. Run `./bin/verify-swift.sh` then focused tests; `./bin/checklist` before merge.

## Architecture notes

- Presentation → Domain ← Data; no SwiftData in Domain; no URLSession in Presentation.
- Composition: `superDemoApp/App/FeedComposition.swift` injects caching repo.
- Concurrency: cancel restores prior UI; no unstructured orphan `Task`.

## Test plan

| Case | Where |
| --- | --- |
| Persist remote success | `CachingFeedRepositoryTests` |
| Fresh cache on remote fail | same |
| Expired TTL miss | same |
| Stale UI + diagnostic | `FeedFeatureModelTests` |
| Cancel restore | Feed + Items feature model tests |

## Rollback

Revert feature commits; cache rows are disposable portfolio data (store recovery
policy already documented).

## Stop criteria

Stop and ask when write-set expands into workflows, signing, or a parallel
outbox PR’s core files; or when TTL policy would contradict OI-* without an ADR.
