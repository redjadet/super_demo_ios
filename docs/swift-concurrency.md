# Swift concurrency map

Short map of how this app uses Swift Concurrency — for technical reviewers.
AI assists typing; humans own isolation boundaries, cancel honesty, and
acceptance. Deeper cancel lifecycle: [`architecture/native-cancellation.md`](architecture/native-cancellation.md).
Evidence cases: [`EVIDENCE.md`](EVIDENCE.md) (§2 cancel, §5 TaskGroup).

## Patterns in this repo

| Pattern | Ownership | Proof |
| --- | --- | --- |
| One in-flight refresh | `AsyncLoadController` + feature models | `AsyncLoadControllerTests`; Feed/Items/Dashboard model cancel tests |
| Cancel ≠ stale cache | `CachingFeedRepository` | `fetchPostsRethrowsCancellationWithoutCacheFallback` |
| Actor-isolated flush | `OutboxSyncEngine` | `OutboxSyncEngineTests` |
| Soft-fail vs cancel | Dashboard remote health | `rethrowsCancellationInsteadOfRemoteWarning` |
| **TaskGroup fan-out** | `CompositeProductionReadinessRepository.loadSnapshot` | `loadsSampleAndRemoteInParallel`, `cancellingParentCancelsSampleAndRemoteChildren` |
| Unstructured `Task {}` | SwiftUI buttons, composition side effects | Lifecycle-tied where cancel matters (`.task` / `onDisappear`) |

## Dashboard TaskGroup (sample ∥ remote)

Sample snapshot and live Remote API probe do not depend on each other.
`loadSnapshot()` runs both in `withThrowingTaskGroup`:

1. Children start together (overlap proven by a two-party barrier in tests).
2. Remote transport errors still soft-fail to a warning row.
3. `CancellationError` / `APIError.cancelled` still rethrow — never a warning.
4. Cancelling the parent task cancels both children (structured concurrency).

Source:
[`CompositeProductionReadinessRepository.swift`](../superDemoApp/Features/ProductionReadiness/Data/CompositeProductionReadinessRepository.swift)

## Swift 6 / isolation notes

- App targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
- Data protocols used from actors are `Sendable` / `nonisolated` where needed
  (`ConnectivityMonitoring`, bookmark remotes, companion stores).
- Prefer fixing ownership over silencing strict-concurrency diagnostics.

## Reproduce

```bash
CI_IPHONE_TEST_SHARD=unit ./bin/ci-iphone-test.sh
```

Filter: `Composite production readiness repository` in Xcode Test navigator.
