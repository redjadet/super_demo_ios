# Engineering evidence for technical reviewers

Short map from **problem → design trade-off → code → regression test → how to
run**. Prefer this page when you want proof, not a product pitch.

Related: [portfolio tour](portfolio.md) · [architecture tour](architecture-tour.md) ·
[engineering evidence map](engineering/engineering-evidence-map.md) ·
[CI map](ci-cd-map.md).

## My role and AI-assisted workflow

I am **İlker Sevim**, the owner of this repository (`redjadet/super_demo_ios`).
Git history attributes commits to my accounts (`İlker Sevim` /
`ilkersevim2007@gmail.com` and related aliases) as well as agent co-authors
(`Cursor Agent`, `cursor[bot]`) on some changes.

**Division of labor I use here:** the AI handles typing and syntax so I can
focus on architecture, intent, and edge cases. In practice that means:

- I set architecture direction, requirements, and acceptance criteria.
- I review and validate behavior — especially failure paths, offline/cache
  honesty, concurrency cancellation, and CI determinism.
- Implementation is partly produced with AI agents (**Cursor** and **Codex**)
  under that direction.
- Nothing lands on `main` without the same gates I use for any change: pull
  request review, Delivery CI on GitHub Actions, and the regression tests
  cited below.

I do not claim production traffic, employer sponsorship, or headcount for this
sample. Claims stay limited to what this repo and its CI history show.

## Scope and limits

- **Portfolio demo**, not a production-scale service. Feed uses
  JSONPlaceholder where configured; many Engineering demos are labeled
  simulations.
- **watchOS and tvOS** are Feed-snapshot companions (App Group / in-memory
  samples), not phone sync products. See [watch-tv-demo.md](watch-tv-demo.md).
- **macOS** has a native desktop demo path; hosted Mac proof is compile-oriented
  unless a local Mac run is noted. See [macos-demo.md](macos-demo.md).
- Universal links for `superdemo.app` **parse** in-app; public DNS handoff is
  **not** claimed — prefer `superdemo://` for demos.

## Verification (CI)

| Surface | Link |
| --- | --- |
| Workflow badge (main) | [![CI](https://github.com/redjadet/super_demo_ios/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/redjadet/super_demo_ios/actions/workflows/ci.yml) |
| Main-branch runs | [Actions · branch `main`](https://github.com/redjadet/super_demo_ios/actions?query=branch%3Amain) |
| Tip green Delivery (pre-PR) | [run 37828018857](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857) on `17d795f` — includes **Checklist · iPhone test (ui-1)** and **Delivery checklist** |
| This PR green Delivery | [run 37933427839](https://github.com/redjadet/super_demo_ios/actions/runs/37933427839) on `52351f3` (`cursor/portfolio-evidence-6eb4`) — docs-only **Delivery checklist** |

**Untested / not claimed here:** App Store marketing screenshots, production
APNs, paid StoreKit checkout, live `superdemo.app` Safari→app handoff, and
visionOS companion behavior.

## Strongest cases

### 1. SwiftData Feed cache expiry and stale honesty

| | |
| --- | --- |
| **Problem** | Remote Feed can fail while a local SwiftData cache still has rows. Returning expired rows as “fresh” lies to the UI; discarding all cache on any failure hurts offline demos. |
| **Design + trade-off** | `CachingFeedRepository` serves cache within TTL as stale-capable success, ignores expired rows when remote fails, and never treats cancellation as a cache-fallback win. Trade-off: TTL is a policy constant (demo-friendly), not a server-driven cache validator. |
| **Source** | [`CachingFeedRepository`](../superDemoApp/Features/Feed/Data/CachingFeedRepository.swift) · composition in [`FeedComposition`](../superDemoApp/App/FeedComposition.swift) |
| **Regression tests** | `CachingFeedRepositoryTests.fetchPostsReturnsCachedPostsWhenRemoteFails` · `fetchPostsIgnoresExpiredCacheWhenRemoteFails` · `fetchPostsRethrowsCancellationWithoutCacheFallback` in [`CachingFeedRepositoryTests.swift`](../superDemoAppTests/Features/Feed/CachingFeedRepositoryTests.swift) |
| **How to run** | `xcodebuild test -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:superDemoAppTests/CachingFeedRepositoryTests` (or full `./bin/ci-iphone-test.sh` with `CI_IPHONE_TEST_SHARD=unit`) |

### 2. Task cancellation (load controller + repository)

| | |
| --- | --- |
| **Problem** | Overlapping refreshes and view teardown must not surface `CancellationError` as a user-facing Retry failure or overwrite good state with empty/error. |
| **Design + trade-off** | Shared [`AsyncLoadController`](../superDemoApp/Shared/Presentation/AsyncLoadController.swift) cancels the prior operation; Feed caching rethrows cancellation without cache fallback. Trade-off: callers must treat cancellation as control-flow, not domain failure — enforced in tests. |
| **Source** | `AsyncLoadController` · `CachingFeedRepository` cancellation branches |
| **Regression tests** | `AsyncLoadControllerTests.runCancelsPriorOperation` · `runAndWaitPropagatesCallerCancellation` in [`AsyncLoadControllerTests.swift`](../superDemoAppTests/Shared/Presentation/AsyncLoadControllerTests.swift) · `CachingFeedRepositoryTests.fetchPostsRethrowsCancellationWithoutCacheFallback` |
| **How to run** | Same unit shard as above, or `-only-testing:superDemoAppTests/AsyncLoadControllerTests` |

### 3. URLSession networking (retry, 401 refresh, 429, cancel)

| | |
| --- | --- |
| **Problem** | Real clients need injectable sessions, bounded retries, one-shot token refresh on 401, Retry-After on 429, and cooperative cancellation — without baking UI into the transport. |
| **Design + trade-off** | App uses SPM [`IlkerSevimNetworking`](https://github.com/redjadet/ilkersevim_networking) via [`IlkerSevimNetworkingExport`](../superDemoApp/Shared/Networking/IlkerSevimNetworkingExport.swift) / `URLSessionAPIClient`. Trade-off: transport policy lives in the shared package; this app owns composition and demos. |
| **Source** | Re-export + `URLSessionAPIClient` usage in [`FeedComposition`](../superDemoApp/App/FeedComposition.swift) / [`ProductionReadinessComposition`](../superDemoApp/App/ProductionReadinessComposition.swift) |
| **Regression tests** | `URLSessionAPIClientTests.exercisesRetryAuthAndFailureMapping` (covers refresh, Retry-After, failure mapping, cancellation) in [`URLSessionAPIClientTests.swift`](../superDemoAppTests/Shared/Networking/URLSessionAPIClientTests.swift) · [`RetryPolicyTests.swift`](../superDemoAppTests/Shared/Networking/RetryPolicyTests.swift) |
| **How to run** | `-only-testing:superDemoAppTests/URLSessionAPIClientTests` |

### 4. Offline bookmark outbox

| | |
| --- | --- |
| **Problem** | Bookmark toggles must stay responsive offline, coalesce conflicting intents for the same post, and survive conflicts without inventing server state. |
| **Design + trade-off** | Durable `OutboxEntry` + [`OutboxSyncEngine`](../superDemoApp/Features/Feed/Domain/OutboxSyncEngine.swift) with coalescing and backoff. Trade-off: demo remote is injectable/stubbed in tests; hosted UI covers pending chrome, not full network chaos. |
| **Source** | `OutboxSyncEngine` · [`OutboxCoalescer`](../superDemoApp/Features/Feed/Domain/OutboxCoalescer.swift) · [`OutboxBackoffPolicy`](../superDemoApp/Features/Feed/Domain/OutboxBackoffPolicy.swift) · wire-up in `FeedComposition` |
| **Regression tests** | `OutboxSyncEngineTests.singleFlushDrainsSuccessorsForSameEntity` · `conflictKeepsAcknowledgedStateInsteadOfGuessingServerValue` · `toggleDuringRemoteRequestDrainsLatestIntent` in [`OutboxSyncEngineTests.swift`](../superDemoAppTests/Features/Feed/OutboxSyncEngineTests.swift) · suite in [`OutboxCoalescerTests.swift`](../superDemoAppTests/Features/Feed/OutboxCoalescerTests.swift) |
| **How to run** | `-only-testing:superDemoAppTests/OutboxSyncEngineTests` · UI: `testOfflineBookmarkToggleShowsPending` in [`superDemoAppUITests.swift`](../superDemoAppUITests/superDemoAppUITests.swift) |

### 5. UIKit ↔ SwiftUI interop showcase

| | |
| --- | --- |
| **Problem** | Portfolio needs a real UIKit surface (collection reuse, prefetch, hosting, custom transition) without abandoning the SwiftUI shell. |
| **Design + trade-off** | Dashboard entry hosts [`UIKitShowcase`](../superDemoApp/Features/ProductionReadiness/UIKitShowcase/) via `UIViewControllerRepresentable`. Trade-off: UITest proves reachability and detail open on iPhone compact; deep UIKit performance claims stay in talk-track docs, not CI timing budgets. |
| **Source** | [`UIKitShowcaseEntryView`](../superDemoApp/Features/ProductionReadiness/UIKitShowcase/UIKitShowcaseEntryView.swift) · showcase folder |
| **Regression tests** | `superDemoAppUITests.testUIKitShowcaseCollectionIsReachable` in [`superDemoAppUITests.swift`](../superDemoAppUITests/superDemoAppUITests.swift) |
| **How to run** | UI shard containing that case, e.g. `CI_IPHONE_TEST_SHARD=ui-2 ./bin/ci-iphone-test.sh`, or Xcode UI test target filtered to that method |

## CI note — ui-1 deep link (already on main)

Failed main run
[37773620216](https://github.com/redjadet/super_demo_ios/actions/runs/37773620216)
(`857f912`): only **Checklist · iPhone test (ui-1)** /
`testDeepLinkOpensFeedPostDetail` — “Application does not have a process ID”
after long Engineering demos. Root cause was **Simulator/XCTest launch wedge**
after StoreKit/Engineering work, not product deep-link routing.

Fix landed in [#101](https://github.com/redjadet/super_demo_ios/pull/101)
(`45f2784`): run deep-link cases first in `ui-1`, one soft relaunch in the
test, and process-ID retry in `bin/ci-iphone-test.sh`. Change note:
[`changes/2026-10-08_ci-ui1-deeplink-launch-flake.md`](changes/2026-10-08_ci-ui1-deeplink-launch-flake.md).
Tip Delivery after that fix:
[37828018857](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857).
