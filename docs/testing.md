# Testing Strategy

Use a test pyramid: many fast unit tests, fewer integration tests, focused UI
tests for critical workflows.

Testing should shorten the native iOS feedback loop. When a developer would
otherwise need to rebuild, relaunch, navigate, and recreate state by hand, prefer
adding a deterministic test, mock fixture, preview state, or script.

## Tests as the contract with AI

When agents implement features, **tests and checklist gates** are how “correct”
is communicated—not only prose in the prompt. Prefer:

1. Spec / acceptance bullets in the ask (or [`feature-template.md`](feature-template.md)).
2. Failing or extended tests that encode the contract.
3. Implementation against that contract.
4. Named verification ([`agents_quick_reference.md`](agents_quick_reference.md)).

Human judgment of process vs final diff:
[`using-agents-here.md`](using-agents-here.md),
[`ai_code_review_protocol.md`](ai_code_review_protocol.md).

## Defaults

- **Minimum OS floors:** `IPHONEOS_DEPLOYMENT_TARGET`,
  `MACOSX_DEPLOYMENT_TARGET`, and `WATCHOS_DEPLOYMENT_TARGET` are **26.7**. CI may
  run tests on newer Simulator runtimes (e.g. iOS 27 with Xcode 27); that proves
  the build SDK path, not a higher App Store floor.
- New unit/integration tests: prefer Swift Testing when target supports it.
- Existing XCTest files may stay XCTest.
- UI tests: XCTest/XCUIAutomation.
- Performance-sensitive code: add XCTest performance coverage or metric proof.
- Swift Testing: use parameterized cases, traits/tags/time limits when useful.
  Parallelism is default; isolate or serialize shared files, stores, clocks,
  URLProtocol stubs, process args, and global state.
- Use Xcode test plans or sanitizer-focused runs for memory, race, main-thread,
  or undefined-behavior risk.

## UI smoke (CI)

The iPhone lane (`bin/ci-iphone-build-for-testing.sh` + `bin/ci-iphone-test.sh`)
uses an **already-installed** iPhone Simulator on the newest available runtime
(`tool/ci_simulator_pick_existing.sh`; never create/erase by default). Hosted CI
default layout (`CI_IPHONE_LAYOUT=single`): one `Checklist · iPhone` job starts
simulator boot in the background during setup/Flutter/build, then runs
`test-without-building` for the full suite with
`-parallel-testing-enabled YES` (worker count 3, simulator clones) — same 187
tests as before (still skips `testLaunchPerformance` on CI). Compare/fallback
layout (`CI_IPHONE_LAYOUT=sharded`): units run in the build job; UI splits into
`ui-a` / `ui-b` shards (`tool/ci_iphone_test_shards.sh`). Local checklist runs
unsharded `xcodebuild test` with warnings-as-errors. Destination preference:
iPhone 18 **Pro** → Pro Max → Plus → base (skip Duo/Fold/Air), then
generation-ranked fallback. UDID hex is normalized uppercase for destination
matching. Local Mac prefers a booted iPhone 18 Pro when present.

**Early gate (before UI / manual Simulator):**
`./tool/check_simulator_runtime_compat.sh` runs from `check_common_issues`
(checklist-fast / lint) and again at the start of `ci-iphone-test`. It fails when
the global preferred device type is missing from the newest runtime’s
`supportedDeviceTypes` (simctl **403 Incompatible device** class) and when no
runtime can provision a standard iPhone. Fixture mode: `--self-test`.

Escape hatch: set `CI_IPHONE_GENERIC_BUILD=1` for the legacy
`generic/platform=iOS Simulator` **build-only** path (no XCTest). The lane
retries once after a simulator reboot on Accessibility **or** launch-progress
timeouts only (hard `xcodebuild` timeouts do **not** re-run the full suite —
that can lose the hosted runner). On CI, `testLaunchPerformance` is skipped.
This Linux/cloud agent cannot execute simulators — GHA `xcode-27` (or Mac)
provides proof.

| UI test | What it proves |
| --- | --- |
| `testLaunchShowsAddItemControl` | Local Items tab chrome (`addItem` / empty / list) |
| `testDashboardShowsProductionRisks` | Local Dashboard → Production Risks list |
| `testUIKitShowcaseCollectionIsReachable` | Local Dashboard → UIKit showcase collection + detail |
| `testFeedTabIsReachable` | Local Feed tab chrome (toolbar, list, empty, or error) |
| `testFeedPostRowOpensDetail` | Feed list selection opens `feedPostDetail-1` |
| `testItemRowOpensDetail` | Items list selection opens `itemDetail` (`-ReviewerDemoMode`) |
| `testFeedAccessibilityChromeRowsAndRetry` | Feed VoiceOver-relevant refresh chrome, row label, and Retry label/tap |
| `testDeepLinkOpensFeedTab` | `superdemo://feed` selects Feed chrome |
| `testDeepLinkOpensItemsTab` | `superdemo://items` selects Items chrome |
| `testOfflineBookmarkToggleShowsPending` | `-OfflineBookmarkDemo`: Feed bookmark toggle shows pending sync indicator |
| `testStaleFeedEngineeringDemoShowsBanner` | Dashboard → Stale Feed demo shows banner |
| `testShareInboxDemoIsReachable` | Share inbox Seed must be hittable; after Seed → entry / unavailable / seed-failed (not pre-seed absent) |
| `testSignInWithAppleDemoIsReachable` | SIWA Engineering demo chrome (Simulator-honest) |
| `testOnDeviceVisionDemoRecognizesOrReportsHonestState` | Vision OCR run → lines or honest failure |
| `testHostBridgePingDemoReturnsResponse` | Host bridge ping returns successful `feed.cacheStatus` JSON (`ok:true`, id `demo-1`) — not error / `ok:false` |
| `testFlutterAddToAppDemoIsReachable` | Flutter add-to-app: embedded **or** unavailable chrome (not host screen id alone) |
| `testFeedWidgetSnapshotDemoIsReachable` | Feed widget App Group snapshot demo |
| `testStoreKitProductQueryDemoIsReachable` | StoreKit Load → terminal empty / unavailable / product row (not idle/loading) |
| `testLocalNotificationDemoIsReachable` | Local stale-Feed reminder demo chrome |
| `testIdempotentPostDemoIsReachable` | Idempotent POST: first send Accepted, second send Simulated duplicate-safe (not Failed) |
| `testDiagnosticsDemoIsReachable` | Diagnostics Engineering demo screen |
| `testWatchCompanionDemoIsReachable` | watchOS companion Engineering demo chrome + a11y labels |
| `testTVCompanionDemoIsReachable` | tvOS companion Engineering demo chrome + a11y labels |
| `testDeepLinkOpensFeedPostDetail` | `superdemo://feed/1` opens `feedPostDetail-1` |
| `testLaunch` | Local/full-lane launch duplicate for Items chrome |
| `testLaunchPerformance` | Local launch performance under `-UITesting` |
| Live Activity Engineering demo UI | **N/A** — no Engineering-demo link; Island / lock-screen UI needs device; GHA compiles ActivityKit + unit spy only (see [`performance-lab.md`](performance-lab.md)) |
| iPad split / Mac window selection UI | **Best-effort / not on hosted UI lane** — GHA `platform-builds` is **build-only**; selection smoke (`testFeedPostRowOpensDetail`, `testItemRowOpensDetail`, `testDeepLinkOpensFeedPostDetail`) runs on the **iPhone** destination (compact `AdaptiveNavigationShell`). For regular-width iPad/Mac split sanity, run the same UITests locally on those destinations when a Mac is available. |

Helpers live in `superDemoAppUITests/UiTestSupport.swift`:

- **`launchApplication(from:)`** — passes `-UITesting`, terminates any running
  app, launches, waits for foreground; with a test case, allows one
  terminate+relaunch after launch-progress XCTFail (CI Simulator wedge —
  e.g. Vision demo on run 36576125333). Does **not** set
  `XCUIApplication.launchTimeout` (unavailable on CI Xcode 27).
- **`openDeepLink(_:in:)`** — opens a custom-scheme URL against the running app.
- **`openFeedTab` / `openItemsTab` / `openDashboardTab`** — fail when no tab
  control is tappable (no silent `tapFirstHittable` no-op).
- **`waitForFeedChrome` / `waitForItemsChrome`** — require feature-scoped
  identifiers (`feedList` / `feedPostRow-*` / `feedPostDetail-*` / refresh /
  retry / empty / error; `itemsList` / `itemRow-*` / `addItem*` /
  `itemsLoading` / `itemsEmpty` / `itemsFailed`). Do **not** accept bare
  `app.cells.firstMatch` (Dashboard/Items also have cells → false green).
  Keep toolbar Add visible to UI tests during first-load (avoid
  `.disabled` on `addItem` — use `allowsHitTesting` + in-action guard).
  `waitForItemsChrome` / `waitForItemsLoadSettled` use short
  `waitForExistence` slices (not bare `.exists`) to avoid CI Accessibility
  snapshot hangs on toolbar queries.
- **`tearDown`** in `superDemoAppUITests` — `@MainActor`, calls
  `terminateApplication` so the next test does not inherit a stuck process
  (SwiftLint: balanced `setUp` / `tearDown`; required for Swift 6 on CI).

### `-UITesting` behavior

When `ProcessInfo` contains `-UITesting` (`AppLaunchConfiguration.isUITesting`):

- **Production Readiness** uses `SampleProductionReadinessRepository` (no live
  JSONPlaceholder health probe).
- **Feed** uses `SampleFeedRepository` via `FeedComposition` (no live posts fetch).
- **Feed failure UI tests** add `-UITestingFeedFailure` to use
  `FailingSampleFeedRepository` and prove Retry without live network.
  Retry must advance `completedRefreshCount` — UITest waits for
  `feedFailed-1`, then post-tap `feedFailed-2` or `feedLoading` (not merely
  that `feedRetry` still exists).

Normal app runs still hit JSONPlaceholder for Feed and remote health checks.

Extend UI tests when adding primary navigation or forms; keep smoke green before PR.

## What To Test

- Domain use cases: success, edge, failure, cancellation where relevant.
- Repositories: mapping, persistence, retry/conflict behavior.
- Feature models: actions produce expected state transitions.
- Networking policy: retryable transport/5xx/429, token refresh once, idempotency-key
  behavior for POST, cancellation, and display-error mapping.
- UI: critical user journeys and regressions.
- Universal UI: at least one compact iPhone, one iPad regular/split case, and
  one Mac window sanity check for meaningful layout/navigation changes.
- Device-only risks: signing, entitlements, permissions, push notifications, deep
  links, background modes, keychain, memory pressure, slow networks, and OS-version
  differences need explicit proof notes or release/test plans.

## URLProtocol stubs

When stubbing `URLSession` with a custom `URLProtocol` in unit tests:

- **Do not** use one global static stub queue shared across tests (parallel Swift
  Testing causes flakes).
- **Do** use per-session stubs: `StubURLSessionFactory`, `StubURLProtocolGate`,
  and `X-Stub-Session-ID` (see `superDemoAppTests/Shared/Networking/StubURLProtocol.swift`).
- Prefer single-parameter trailing closures in tests to satisfy
  `closure_parameter_position` and `trailing_closure` (see `withStubSession` in
  `URLSessionAPIClientTests.swift`).

## Test Quality

- Assert behavior, not implementation details.
- Use deterministic clocks, UUIDs, and fake services.
- Keep SwiftData tests in-memory unless store migration is the subject.
- Do not require network for normal test lanes.
- Do not mix Swift Testing and XCTest APIs in the same test method.
- Treat strict-concurrency failures/warnings as defects unless owner docs allow a narrow exception.

## Command

```bash
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

For responsive UI build sanity:

```bash
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
# Unsigned Mac compile-proof (same default as ./bin/ci-platform-builds.sh / #69).
# Omit CODE_SIGN* overrides only when Mac Development profiles exist.
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=- build
```

Production Readiness unit coverage:
`superDemoAppTests/Features/ProductionReadiness` and
`superDemoAppTests/Shared/Networking`. Feed unit coverage:
`superDemoAppTests/Features/Feed`. UI smoke covers Items, Dashboard (risks +
UIKit showcase + Engineering demos), Feed, and Feed/Items deep links — see
table above. Engineering demos live in
`superDemoAppUITests/EngineeringDemosUITests.swift`.

## Optional code coverage (local / nightly)

Hosted `iphone-test` does **not** enable code coverage. For a local or nightly
measurement (not a PR badge):

```bash
./bin/coverage-iphone.sh
```

That script runs `xcodebuild test -enableCodeCoverage YES` on the same iPhone
destination resolution as `ci-iphone-test` and prints the `.xcresult` path.
Inspect with Xcode Organizer or `xcrun xccov`. Do **not** invent a `%` for
README — see [`code-quality.md`](code-quality.md).

## Local platform matrix

The main scheme has unit and UI tests for iPhone, iPad, macOS, and visionOS.
Run each destination explicitly; an iPhone pass does not prove iPad or Mac UI.

watchOS / tvOS companion **integration** tests live in dedicated targets and run
from the companion schemes:

| Target | Scheme | What it proves |
| --- | --- | --- |
| `superDemoAppWatchTests` | `superDemoAppWatch` | Feed snapshot absent / ok / expired / corrupt honesty + watch seed DTO + real App Group or honest `.unavailable` |
| `superDemoAppTVTests` | `superDemoAppTV` | Same honesty contract for tvOS seed DTO / App Group |

Local + platform-builds lanes (`./bin/ci-watch-build.sh`, `./bin/ci-tvos-build.sh`)
prefer `xcodebuild test` on a concrete Simulator UDID. If only
`generic/platform=… Simulator` is available (common on GitHub-hosted runners),
the scripts fall back to compile-only `build` and log a warning — Mac mini /
self-hosted proof is the authoritative XCTest run for those platforms.

iPhone Engineering demos still smoke-test companion chrome
(`testWatchCompanionDemoIsReachable`, `testTVCompanionDemoIsReachable`).

Check installed destinations with `xcodebuild -showdestinations -project
superDemoApp.xcodeproj -scheme superDemoApp`. visionOS execution requires an
installed visionOS Simulator runtime; SDK-only builds do not execute tests.

Mac UI tests require authenticated Automation Mode and a valid local test-host
signing setup. A failure before the runner starts is environment evidence,
not an app assertion failure. Temporary ad-hoc test-host overrides that remove
sandbox or App Group entitlements cannot prove those production capabilities.
