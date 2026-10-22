# Engineering evidence for technical reviewers

Inspect one bookmark race, its design decision, regression, and passing run;
then contribution, proof scope, and four more cases. The
[CI verification catalog](#ci-verification-catalog) lists what GitHub Actions
checks, when it runs, and the local commands that match those lanes.

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

**AI-assisted workflow:** Cursor, Codex, and similar agents handle typing and
syntax (implementation drafts, tests, docs). I own architecture, intent, edge
cases, acceptance criteria, review of trade-offs, and whether the evidence is
enough to accept a change. Commit author names alone do not establish which
lines were typed manually; the linked artifacts make the decisions and
verification inspectable.

## Verification and proof scope

| Evidence | Commit and scope |
| --- | --- |
| **Recorded full run** | [Main run 37828018857](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857), **2026-10-08**, `17d795f`: iPhone unit tests, UI shards `ui-1`–`ui-4`, platform build lane, and Delivery checklist passed. The named cases on this page were checked in the unit or `ui-2` logs. |
| **Evidence page PR** | [PR #107 checks](https://github.com/redjadet/super_demo_ios/pull/107/checks) published the evidence page on a docs-only route (Markdown/DesignMD and Delivery aggregation; iPhone runtime tests and platform builds skipped). App and test sources at that head match the recorded full-run commit. |
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

### 5. TaskGroup fan-out for Dashboard sample ∥ remote

| Evidence | Inspect |
| --- | --- |
| **Problem** | Composite Dashboard sample snapshot and live Remote API probe are independent, but sequential `await`s hid structured concurrency and left no cancel-child proof. |
| **Decision + trade-off** | Load both in `withThrowingTaskGroup`. Soft-fail still maps remote transport errors to a warning row; `CancellationError` / `APIError.cancelled` still rethrow (no warning). Parent cancel cancels both children. |
| **Source** | [`CompositeProductionReadinessRepository`](../superDemoApp/Features/ProductionReadiness/Data/CompositeProductionReadinessRepository.swift) · map: [`swift-concurrency.md`](swift-concurrency.md). |
| **Regressions** | `loadsSampleAndRemoteInParallel` and `cancellingParentCancelsSampleAndRemoteChildren` in [`CompositeProductionReadinessRepositoryTests`](../superDemoAppTests/Features/ProductionReadiness/CompositeProductionReadinessRepositoryTests.swift), plus existing cancel soft-fail cases. |
| **Reproduce** | Unit shard below. |

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

## CI verification catalog

What the repository actually runs to prove a change. Commands are from the
repo root. Workflow files:

- [CI](https://github.com/redjadet/super_demo_ios/actions/workflows/ci.yml) — [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)
- [Release Smoke](https://github.com/redjadet/super_demo_ios/actions/workflows/release-smoke.yml) — [`.github/workflows/release-smoke.yml`](../.github/workflows/release-smoke.yml)

There is no other workflow under `.github/workflows/`. Stage narrative and
Bitrise non-claims: [CI/CD map](ci-cd-map.md). Merge-gate role:
[checklist gate](engineering/checklist_gate.md).

### When CI runs

| Workflow | Trigger | Cancel in progress |
| --- | --- | --- |
| `ci.yml` | `push` to `main`, and `pull_request` targeting `main` | Only when `github.event_name == 'pull_request'`. In-progress `main` runs are not cancelled. |
| `release-smoke.yml` | `workflow_dispatch` only (not on push or pull request) | `false` |

`ci.yml` sets `SUPER_DEMO_XCODE_MIN_VERSION=27` and `CI_SIMULATOR_REUSE_ONLY=1`.
Hosted Xcode jobs use `runs-on: xcode-27` (docs-only bypasses use `ubuntu-latest`).
Which Xcode build that image selects is `tool/select_xcode.sh`; the CI map
records the current pin. This page does not restate a build number.

A docs-only diff is `./bin/checklist --print-scope` → `docs_only=true`
(`tool/checklist_scope.sh`: markdown, mdx, rst, adoc, and `llms.txt`). The
workflow comment says unknown, empty, mixed, code, or workflow diffs take the
full route. The `changes` job currently writes `iphone_layout=sharded`. The
`iphone` job (one runner, parallel UI) runs only when `docs_only` is true or
`iphone_layout` is `single`. With the value hardcoded to `sharded`, code PRs
use `iphone-build` plus the `iphone-test` matrix, and the `iphone` job is skipped.

### Jobs in `ci.yml`

| Job | Name | When | What it runs |
| --- | --- | --- | --- |
| `changes` | Checklist · changes | Always (Ubuntu, 5 min) | `./bin/checklist --print-scope`. Outputs `docs_only` and `iphone_layout`. |
| `lint` | Checklist · lint | After `changes` | Docs-only: `./bin/lint-markdown.sh`, `./tool/check_design_md.sh`, `./tool/check_checklist_scope.sh` on Ubuntu. Otherwise `xcode-27` and `bundle exec fastlane ci_lint` (Swift lint, markdown, DesignMD, `tool/check_common_issues.sh`). |
| `iphone` | Checklist · iPhone | `docs_only` or `iphone_layout=single` | Docs-only: echo bypass, no build. Otherwise build-for-testing, serial unit shard, then parallel UI shard `ui` (`CI_ALLOW_PARALLEL_TESTS=1`, 3 workers). Not the default code-PR path. |
| `iphone-build` | Checklist · iPhone build | Not docs-only and `iphone_layout=sharded` | Flutter embed (skip rebuild on exact cache hit), `./bin/ci-iphone-build-for-testing.sh`, then `./bin/ci-iphone-test.sh` with `CI_IPHONE_TEST_MODE=test-without-building` and `CI_IPHONE_TEST_SHARD=unit`. Uploads artifact `iphone-test-products` (dSYMs stripped, 1 day). |
| `iphone-test` | Checklist · iPhone test | Needs a successful `iphone-build`; not docs-only; sharded | Matrix `shard: [ui-1, ui-2, ui-3, ui-4]`, `fail-fast: false`, 35 min, serial (`CI_ALLOW_PARALLEL_TESTS=0`). Downloads the artifact, boots the simulator after download (`./tool/ci_simulator_boot_ready.sh`), then `test-without-building` for that shard. |
| `platform-builds` | Checklist · platform builds | After `changes` | Docs-only: echo bypass. Otherwise `./bin/ci-platform-builds.sh` (iPad build, Mac build, then watchOS and tvOS). |
| `checklist` | Delivery checklist | `always()` after the jobs above | Ubuntu script. Fails unless `changes`, `lint`, and `platform-builds` succeeded, and the iPhone jobs match the layout (sharded: `iphone` skipped, `iphone-build` and `iphone-test` success; docs-only allows those Xcode jobs to be success or skipped). |

`iphone-test` does not start when `iphone-build` fails. `checklist` still runs
because its `if` is `always()`, and it fails the aggregate when a required lane
failed.

### Test targets

From `superDemoApp.xcodeproj`:

| Target | Role on the CI lanes above |
| --- | --- |
| `superDemoAppTests` | Unit shard (`-only-testing:superDemoAppTests`). Swift Testing and XCTest. |
| `superDemoAppUITests` | UI shards. iPhone cases live in `superDemoAppUITests`, `EngineeringDemosUITests`, and `superDemoAppUITestsLaunchTests`. `Mac/MacPortfolioUITests.swift` is compiled only inside `#if os(macOS)`, so those cases are absent from the iPhone simulator bundle. `platform-builds` Mac step is `xcodebuild build`, not this UI class. |
| `superDemoAppWatchTests` | `./bin/ci-watch-build.sh` via `platform-builds`. Default action is `test` when a concrete watchOS Simulator UDID exists; otherwise compile-only. If CI cannot see a watchOS Simulator destination, the script exits 0 and skips. One retry path exists in that script for install/launch failures. |
| `superDemoAppTVTests` | `./bin/ci-tvos-build.sh`, same pattern as watchOS. |

`platform-builds` compiles the iPad app (`build`, generic iOS Simulator
destination when `CI_PLATFORM_GENERIC_BUILDS` is unset or `1`) and the Mac app
(`build`). Mac signing is off unless `CI_MAC_REQUIRE_CODE_SIGN=1`. That lane
does not run the iPhone UI suite.

Widget (`superDemoAppWidget`) and share (`superDemoAppShare`) extensions are built with the iOS app targets. They are not separate CI jobs.

### Shards

Definitions: [`tool/ci_iphone_test_shards.sh`](../tool/ci_iphone_test_shards.sh).
`python3 tool/check_ci_contracts.py` (from `tool/check_common_issues.sh`) requires
every UI test exactly once across `ui-1`…`ui-4`, except `testLaunchPerformance`.
`bin/ci-iphone-test.sh` adds `-skip-testing:…/testLaunchPerformance` only when
`CI=true`. Local `./bin/ci-iphone-test.sh` without `CI=true` does not add that skip.

Default hosted shards (`ci_iphone_shard_ids`): `unit`, `ui-1`, `ui-2`, `ui-3`, `ui-4`.
The script also accepts legacy ids `ui`, `ui-a`, `ui-b`, `unit-and-app-ui`,
`engineering-a`, and `engineering-b`. The workflow matrix does not pass those.

Duration comments in the shard script (“baseline test bodies ~356s” and similar)
are estimates in comments, not a measured gate.

| Shard | `-only-testing` cases | What those cases cover |
| --- | --- | --- |
| `unit` | `superDemoAppTests` | All unit tests. No UI. |
| `ui-1` | `testDeepLinkOpensFeedPostDetail`, `testDeepLinkOpensItemsTab`, `testIdempotentPostDemoIsReachable`, `testLocalNotificationDemoIsReachable`, `testStoreKitProductQueryDemoIsReachable` | `superdemo://feed/1` opens `feedPostDetail-1`; `superdemo://items` shows Items chrome; idempotent POST demo (accepted, then simulated duplicate-safe); local stale-Feed reminder demo; StoreKit Load reaches a terminal empty, unavailable, or product row. Deep-link cases are listed first. |
| `ui-2` | `testLaunchShowsAddItemControl`, `testHostBridgePingDemoReturnsResponse`, `testSignInWithAppleDemoIsReachable`, `testDeepLinkOpensFeedTab`, `testFeedPostRowOpensDetail`, `testOfflineBookmarkToggleShowsPending`, `testUIKitShowcaseCollectionIsReachable` | Items chrome; host-bridge ping JSON; Sign in with Apple demo chrome; `superdemo://feed`; Feed row opens `feedPostDetail-1`; offline bookmark pending indicator; UIKit showcase collection and detail. |
| `ui-3` | `testDiagnosticsDemoIsReachable`, `testFlutterAddToAppDemoIsReachable`, `testTVCompanionDemoIsReachable`, `testDashboardShowsProductionRisks`, `testFeedTabIsReachable`, `testStaleFeedEngineeringDemoShowsBanner`, `testStaleFeedFixtureShowsBannerOnFeedTab` | Diagnostics demo; Flutter embed or unavailable chrome; tvOS companion demo; Dashboard → Production Risks seeded row; Feed tab chrome; stale-Feed banner from the Engineering demo and from the Feed-tab fixture. |
| `ui-4` | `testFeedWidgetSnapshotDemoIsReachable`, `testOnDeviceVisionDemoRecognizesOrReportsHonestState`, `testShareInboxDemoIsReachable`, `testWatchCompanionDemoIsReachable`, `testFeedAccessibilityChromeRowsAndRetry`, `testItemRowOpensDetail`, `testLaunch` | Feed widget snapshot demo; Vision OCR lines or honest failure; share-inbox seed; watchOS companion demo; Feed refresh/row/retry accessibility; Items row opens detail (`-ReviewerDemoMode`); launch test for Items chrome. |
| `ui` (legacy / single-layout UI step) | `superDemoAppUITests` | Every UI test in that target, including `testLaunchPerformance` unless `CI=true` adds the skip. |

Case descriptions match [`testing.md`](testing.md#ui-smoke-ci). Hosted iPad and Mac
lanes are build-oriented; the selection smoke above runs on the iPhone
destination.

On `CI=true`, `bin/ci-iphone-test.sh` reboots the simulator once and retries
the same xcodebuild when the log matches Accessibility load timeout,
launch-progress timeout, UI-query timeout, “does not have a process ID”, or
“Timed out while launching application”. A hard timeout (exit 124) is not
retried. That retry is the script, not an XCTest `XCTSkip` or measure retry.

### Reproduce locally

Mac with the repo’s Xcode toolchain. `./bin/ci-iphone-test.sh` outside CI runs
`xcodebuild test` (it builds and tests) unless you set
`CI_IPHONE_TEST_MODE=test-without-building` and `CI_IPHONE_PRODUCTS_DIR` after
`./bin/ci-iphone-build-for-testing.sh`. Destination selection is
`tool/resolve_platform_destination.sh` (an installed iPhone simulator).
Warnings are errors unless `XCODEBUILD_ALLOW_WARNINGS=1`.

```bash
# Scope the same way the changes job does.
./bin/checklist --print-scope

# Docs-only lint route.
./bin/lint-markdown.sh
./tool/check_design_md.sh
./tool/check_checklist_scope.sh

# Hosted lint job (needs Ruby/Bundler and the Brewfile tools).
./bin/fastlane-run ci_lint

# Narrow docs/tooling gate (markdown, Swift lint, common checks, DesignMD, xcodebuild -list).
./bin/checklist-fast

# Local delivery gate: lint lanes, unsharded iPhone test, then platform builds.
./bin/checklist

# Unsharded iPhone unit + UI tests (local checklist’s iPhone lane).
./bin/ci-iphone-test.sh

# One hosted shard. Repeat the variable for ui-2, ui-3, ui-4, or unit.
CI_IPHONE_TEST_SHARD=ui-1 ./bin/ci-iphone-test.sh

# Closer to the shard job: build products once, then test without building.
IPHONE_DERIVED_DATA_PATH="$PWD/build/DerivedData-iPhone" ./bin/ci-iphone-build-for-testing.sh
CI_IPHONE_TEST_MODE=test-without-building \
  CI_IPHONE_PRODUCTS_DIR="$PWD/build/DerivedData-iPhone/Build/Products" \
  CI_IPHONE_TEST_SHARD=ui-1 \
  ./bin/ci-iphone-test.sh

# iPad + Mac + watchOS + tvOS lane.
./bin/ci-platform-builds.sh

# Fastlane names for the same scripts.
./bin/fastlane-run iphone_test
./bin/fastlane-run platform_builds
./bin/ci.sh
```

`./bin/ci.sh` is `./bin/fastlane-run ci`. Locally that lane runs lint,
markdown, DesignMD, common checks, iPhone tests, then platform builds. With
`CI=true` it runs platform builds before iPhone tests.
`CI_SKIP_PLATFORM_BUILDS=1` skips the platform lane inside that Fastlane lane
only.

`./bin/coverage-iphone.sh` is optional coverage. It is not a job in `ci.yml`.

Release smoke (manual; builds an IPA and uploads the `release-smoke-ipa`
artifact; the workflow sets `TESTFLIGHT_SKIP_CI=1` and does not run the
TestFlight upload lane):

```bash
TESTFLIGHT_BUILD_NUMBER=<unique-build-number> ./bin/fastlane-run ios build_ipa
```

The workflow also sets `FASTLANE_USE_MATCH=1` and reads match secrets.
Without those secrets the hosted job cannot sign. Do not treat a local
unsigned build as that job.

### `Scripts/`, `bin/`, `tool/`, Fastlane

| Path | Verification role |
| --- | --- |
| `Scripts/xcode-lint.sh` | Xcode build phase. Runs `./bin/lint.sh` (skips when SwiftLint/SwiftFormat are missing and `CI` is not `true`). |
| `Scripts/embed-flutter-frameworks.sh` | Xcode run script. Embeds `Flutter/<config>/<platform>` when present. No-op off iOS. Fails closed if `SUPERDEMO_REQUIRE_FLUTTER_EMBED=1` and the slice is missing. |
| `bin/checklist`, `bin/checklist-fast` | Local gates described above. |
| `bin/ci-iphone-build-for-testing.sh`, `bin/ci-iphone-test.sh`, `bin/ci-platform-builds.sh`, `bin/ci-watch-build.sh`, `bin/ci-tvos-build.sh`, `bin/ci.sh` | iPhone and platform lanes. |
| `bin/lint.sh`, `bin/lint-markdown.sh`, `bin/format.sh`, `bin/verify-swift.sh` | Swift format/lint and markdown lint. `verify-swift` is format then lint. |
| `bin/fastlane-run` | Runs a Fastlane lane under Bundler. |
| `tool/ci_iphone_test_shards.sh` | Shard id → `-only-testing` list. |
| `tool/check_ci_contracts.py` | Shard coverage contract. |
| `tool/ci_simulator_pick_existing.sh`, `tool/ci_simulator_boot_ready.sh`, `tool/ci_simulator_boot_bg.sh`, `tool/ci_simulator_await.sh` | Reuse an existing simulator; shard boot after artifact download; single-layout background boot. |
| `tool/select_xcode.sh` | Xcode selection when `CI=true`. |
| `tool/check_common_issues.sh` | Static checks invoked by lint (docs, layers, secrets scan, shard contract, simulator runtime compat, AASA, markdown links, router paths, and the other sections in that script). |
| `fastlane/Fastfile` | Lanes `ci_lint`, `iphone_test`, `platform_builds`, `ci`, `checklist`, `checklist_fast`, `build_ipa`, `beta`, `release`. `beta` and `release` upload; they are not jobs in `ci.yml` or `release-smoke.yml`. |

Other `bin/` helpers (`agent-worktree`, `coverage-iphone.sh`, symbol and trace wrappers) are not steps in these workflows.
