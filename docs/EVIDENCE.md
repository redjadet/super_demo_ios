# Engineering evidence for technical reviewers

Inspect one bookmark race, its design decision, regression, and passing run;
then contribution, proof scope, and four more cases.

## Lead case: preserve the latest bookmark intent

**Problem:** a user bookmarks a post, then removes it while the `set` request
is still in flight. A late acknowledgement must preserve the newer local
intent, and the queued `clear` must run without waiting for a second flush.

| Evidence | Inspect |
| --- | --- |
| **Design decision** | Save the optimistic bookmark and outbox entry in one transaction. On acknowledgement, update the baseline while retaining a pending successor's intent. Continue draining successors in order during the same flush. |
| **Regression** | [`OutboxSyncEngineTests.toggleDuringRemoteRequestDrainsLatestIntent`](https://github.com/redjadet/super_demo_ios/blob/17d795f471aafae5010b5736d052b316cdedd02a/superDemoAppTests/Features/Feed/OutboxSyncEngineTests.swift#L214-L231) removes the bookmark from inside the first remote call. It asserts `set → clear`, an unbookmarked `.synced` result, and an empty outbox. |
| **Passing run** | [iPhone unit job](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857/job/113485831800): the named regression passed on **2026-10-08** at [`17d795f`](https://github.com/redjadet/super_demo_ios/commit/17d795f471aafae5010b5736d052b316cdedd02a). The [full Delivery run](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857) also passed. |
| **Implementation** | [`SwiftDataBookmarkRepository`](../superDemoApp/Features/Feed/Data/SwiftDataBookmarkRepository.swift): `setBookmarked` and `markSynced` · [`OutboxStore`](../superDemoApp/Features/Feed/Data/OutboxStore.swift): `performTransaction` and `claimPending` · [`OutboxSyncEngine`](../superDemoApp/Features/Feed/Data/OutboxSyncEngine.swift). |

**Trade-off:** local state can be pending until acknowledgement. Conflict
handling uses the last acknowledged baseline and exposes failure without
guessing a server value.

**Related checks:** `singleFlushDrainsSuccessorsForSameEntity` and
`conflictKeepsAcknowledgedStateInsteadOfGuessingServerValue` in the
[current test suite](../superDemoAppTests/Features/Feed/OutboxSyncEngineTests.swift)
passed in the same unit job. The [pending-state UI test](../superDemoAppUITests/superDemoAppUITests.swift)
`testOfflineBookmarkToggleShowsPending` passed in
[ui-2](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857/job/113492500441).
Use the unit and `ui-2` commands under [Reproduce](#reproduce-the-evidence).

The regression uses an injected remote and an in-memory SwiftData fixture.
It proves the encoded race and queue outcome; it is not a production network
load or durability benchmark.

## My contribution

I am **İlker Sevim**, the owner of `redjadet/super_demo_ios`. I own architecture,
requirements, acceptance criteria, and the decision to accept a change.

| Responsibility | Contribution and inspectable evidence |
| --- | --- |
| **Designed** | Feature boundaries and dependency injection; for the lead case, optimistic state plus a durable outbox, atomic local updates, and preservation of newer intent. Inspect the [layer map](layers.md), [Feed composition](../superDemoApp/App/FeedComposition.swift), and implementation above. |
| **Reviewed** | Failure behavior and the limits of claims: cache expiry, cancellation, bookmark conflicts, and platform/demo boundaries. The cases below connect those decisions to source and assertions. [Review protocol](ai_code_review_protocol.md) records the review criteria. |
| **Validated** | Acceptance through behavior assertions and CI evidence: the named race regression, related conflict tests, and pending-state UI test have passing job links above. The proof table below distinguishes runtime checks from documentation checks. |

**AI-assisted workflow:** Cursor and Codex assist with implementation, tests,
documentation, and review suggestions. My responsibility is to direct the
work, review behavior and trade-offs, and assess the resulting evidence.
Commit author names alone do not establish which code was written manually;
the linked artifacts make the decisions and verification inspectable.

## Verification and proof scope

| Evidence | Commit and scope |
| --- | --- |
| **Recorded full run** | [Main run 37828018857](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857), **2026-10-08**, `17d795f`: iPhone unit tests, UI shards `ui-1`–`ui-4`, platform build lane, and Delivery checklist passed. The named cases on this page were checked in the unit or `ui-2` logs. |
| **This documentation PR** | [PR #107 checks](https://github.com/redjadet/super_demo_ios/pull/107/checks) show the current published head. Its docs-only route checks Markdown/DesignMD and Delivery aggregation; iPhone runtime tests and platform builds are skipped. App and test sources in this PR match the recorded full-run commit. |
| **Newer main runs** | [Actions · branch `main`](https://github.com/redjadet/super_demo_ios/actions?query=branch%3Amain). Check each run's commit and executed jobs before treating it as runtime proof. |

Hosted Mac proof is unsigned compilation; an iPhone UI pass does not establish
Mac, iPad, watchOS, or tvOS UI behavior. See the [CI map](ci-cd-map.md) and
[testing guide](testing.md) for each platform's lane and limitations.

## More engineering cases

### 1. SwiftData Feed cache expiry and stale honesty

| Evidence | Inspect |
| --- | --- |
| **Problem** | Remote Feed fails while cache rows remain. Expired rows must not appear as fresh data, and usable cache should keep the offline screen useful. |
| **Decision + trade-off** | Return only rows within TTL after a remote failure and mark the result `isStale = true`; rethrow cancellation without cache fallback. TTL is a local policy with an injectable clock, rather than a server-driven cache validator. |
| **Source** | [`CachingFeedRepository`](../superDemoApp/Features/Feed/Data/CachingFeedRepository.swift) · [`FeedComposition`](../superDemoApp/App/FeedComposition.swift). |
| **Regressions** | `fetchPostsReturnsCachedPostsWhenRemoteFails`, `fetchPostsIgnoresExpiredCacheWhenRemoteFails`, and `fetchPostsRethrowsCancellationWithoutCacheFallback` in [`CachingFeedRepositoryTests`](../superDemoAppTests/Features/Feed/CachingFeedRepositoryTests.swift). All passed in the recorded [unit job](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857/job/113485831800). |
| **Reproduce** | Unit shard below. |

### 2. Task cancellation through the load controller and repository

| Evidence | Inspect |
| --- | --- |
| **Problem** | A new load replaces an earlier operation; caller cancellation must reach the underlying task without turning into a cache-fallback success. |
| **Decision + trade-off** | Cancel the prior task in `AsyncLoadController`; propagate caller cancellation in `runAndWait`; rethrow cancellation in the caching repository. Operations must cooperate with cancellation, and presentation must handle it as control flow. |
| **Source** | [`AsyncLoadController`](../superDemoApp/Shared/Presentation/AsyncLoadController.swift) · [`CachingFeedRepository`](../superDemoApp/Features/Feed/Data/CachingFeedRepository.swift). |
| **Regressions** | `runCancelsPriorOperation` and `runAndWaitPropagatesCallerCancellation` in [`AsyncLoadControllerTests`](../superDemoAppTests/Shared/Presentation/AsyncLoadControllerTests.swift), plus the cache cancellation case above. All passed in the recorded [unit job](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857/job/113485831800). |
| **Reproduce** | Unit shard below. |

### 3. URLSession retry, token refresh, and cancellation

| Evidence | Inspect |
| --- | --- |
| **Problem** | Transport needs bounded retries, one token refresh on 401, `Retry-After` on 429, and cancellation without coupling networking to the UI. |
| **Decision + trade-off** | Use the shared SPM [`IlkerSevimNetworking`](https://github.com/redjadet/ilkersevim_networking) package with injected sessions and policies. Transport policy lives in that package; this app owns composition and integration tests. |
| **Source** | [`IlkerSevimNetworkingExport`](../superDemoApp/Shared/Networking/IlkerSevimNetworkingExport.swift) · [`FeedComposition`](../superDemoApp/App/FeedComposition.swift) · [`ProductionReadinessComposition`](../superDemoApp/App/ProductionReadinessComposition.swift). |
| **Regressions** | `exercisesRetryAuthAndFailureMapping` in [`URLSessionAPIClientTests`](../superDemoAppTests/Shared/Networking/URLSessionAPIClientTests.swift) covers 401 refresh, 429 delay, typed failures, and cancellation. `postRetriesOnlyWithIdempotencyKey` in [`RetryPolicyTests`](../superDemoAppTests/Shared/Networking/RetryPolicyTests.swift) checks the POST retry boundary. Both passed in the recorded [unit job](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857/job/113485831800). |
| **Reproduce** | Unit shard below; the tests inject transport responses. |

### 4. UIKit and SwiftUI interoperability

| Evidence | Inspect |
| --- | --- |
| **Problem** | A UIKit collection and detail transition need to work inside the SwiftUI navigation shell. |
| **Decision + trade-off** | Host the collection through `UIViewControllerRepresentable`, retaining UIKit reuse, prefetching, and transition code. The UI regression checks navigation and detail presentation; it does not measure scroll performance or memory use. |
| **Source** | [`UIKitShowcaseEntryView`](../superDemoApp/Features/ProductionReadiness/UIKitShowcase/UIKitShowcaseEntryView.swift) · [showcase implementation](../superDemoApp/Features/ProductionReadiness/UIKitShowcase/). |
| **Regression** | `testUIKitShowcaseCollectionIsReachable` in [`superDemoAppUITests`](../superDemoAppUITests/superDemoAppUITests.swift) passed in the recorded [ui-2 job](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857/job/113492500441). |
| **Reproduce** | `ui-2` shard below. |

## Reproduce the evidence

From the repository root on a Mac with the project's Xcode toolchain and an
installed iPhone Simulator runtime:

```bash
# All named unit regressions, including the in-flight bookmark race.
CI_IPHONE_TEST_SHARD=unit ./bin/ci-iphone-test.sh

# Pending bookmark presentation and UIKit navigation/detail checks.
CI_IPHONE_TEST_SHARD=ui-2 ./bin/ci-iphone-test.sh
```

The script builds and tests locally, selects an installed iPhone destination,
and writes logs/results under `build/`. Shard definitions live in
[`ci_iphone_test_shards.sh`](../tool/ci_iphone_test_shards.sh). Optional Flutter
framework setup is separate: [add-to-app guide](flutter-add-to-app.md).

## Portfolio scope

- Feed uses JSONPlaceholder where configured; many Engineering demos are
  labeled simulations. Production traffic, production APNs, and paid StoreKit
  checkout are not claimed.
- watchOS and tvOS are Feed-snapshot companions with local samples, rather than
  phone sync products. See the [Watch and TV walkthrough](watch-tv-demo.md).
- macOS has a native desktop demo; see the [Mac walkthrough](macos-demo.md) for
  local execution and hosted compile proof.
- Universal links for `superdemo.app` parse in-app. Public DNS/Safari handoff
  and visionOS companion behavior are not claimed; use `superdemo://` for demos.

Continue with the [portfolio tour](portfolio.md), [architecture tour](architecture-tour.md),
or [full engineering evidence map](engineering/engineering-evidence-map.md).
CI launch-failure history is recorded in the [ui-1 change note](changes/2026-10-08_ci-ui1-deeplink-launch-flake.md).
