# Testing Strategy

Use a test pyramid: many fast unit tests, fewer integration tests, focused UI
tests for critical workflows.

Testing should shorten the native iOS feedback loop. When a developer would
otherwise need to rebuild, relaunch, navigate, and recreate state by hand, prefer
adding a deterministic test, mock fixture, preview state, or script.

## Defaults

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

The iPhone test lane (`bin/ci-iphone-test.sh`, GitHub Actions `iphone-test`)
boots the **newest available iOS Simulator runtime** iPhone (via
`tool/ensure_ci_simulator.sh` + `tool/ios_simulator_runtime.sh`) and runs
`xcodebuild test` (unit + UI) with warnings-as-errors. Destination preference:
iPhone 18 Pro Max → Pro → Plus → base, then generation-ranked fallback.

Escape hatch: set `CI_IPHONE_GENERIC_BUILD=1` for the legacy
`generic/platform=iOS Simulator` **build-only** path (no XCTest). The lane
retries once after a simulator reboot on Accessibility load timeouts. This
Linux/cloud agent cannot execute simulators — Mac Codex / GHA `macos-26`
runners provide proof.

| UI test | What it proves |
| --- | --- |
| `testLaunchShowsAddItemControl` | Local Items tab chrome (`addItem` / empty / list) |
| `testDashboardShowsProductionRisks` | Local Dashboard → Production Risks list |
| `testUIKitShowcaseCollectionIsReachable` | Local Dashboard → UIKit showcase collection + detail |
| `testFeedTabIsReachable` | Local Feed tab chrome (toolbar, list, empty, or error) |
| `testFeedAccessibilityChromeRowsAndRetry` | Feed VoiceOver-relevant refresh chrome, row label, and Retry label/tap |
| `testDeepLinkOpensFeedTab` | `superdemo://feed` selects Feed chrome |
| `testDeepLinkOpensItemsTab` | `superdemo://items` selects Items chrome |
| `testStaleFeedFixtureShowsBannerOnFeedTab` | `-StaleFeedDemo` shows stale banner + sample row |
| `testStaleFeedEngineeringDemoShowsBanner` | Dashboard → Stale Feed demo shows banner |
| `testShareInboxDemoIsReachable` | Share inbox Engineering demo (absent / seed / unavailable) |
| `testSignInWithAppleDemoIsReachable` | SIWA Engineering demo chrome (Simulator-honest) |
| `testOnDeviceVisionDemoRecognizesOrReportsHonestState` | Vision OCR run → lines or honest failure |
| `testHostBridgePingDemoReturnsResponse` | Host bridge ping returns non-placeholder JSON |
| `testFeedWidgetSnapshotDemoIsReachable` | Feed widget App Group snapshot demo |
| `testStoreKitProductQueryDemoIsReachable` | StoreKit 2 product query demo |
| `testLocalNotificationDemoIsReachable` | Local stale-Feed reminder demo chrome |
| `testIdempotentPostDemoIsReachable` | Idempotent POST demo outcome |
| `testDiagnosticsDemoIsReachable` | Diagnostics Engineering demo screen |
| `testLaunch` | Local/full-lane launch duplicate for Items chrome |
| `testLaunchPerformance` | Local launch performance under `-UITesting` |

Helpers live in `superDemoAppUITests/UiTestSupport.swift`:

- **`launchApplication()`** — passes `-UITesting`, terminates any running app
  instance, then launches and waits for foreground (avoids CI
  `Failed to terminate` between tests).
- **`openDeepLink(_:in:)`** — opens a custom-scheme URL against the running app.
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
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=macOS' build
```

Production Readiness unit coverage:
`superDemoAppTests/Features/ProductionReadiness` and
`superDemoAppTests/Shared/Networking`. Feed unit coverage:
`superDemoAppTests/Features/Feed`. UI smoke covers Items, Dashboard (risks +
UIKit showcase + Engineering demos), Feed, and Feed/Items deep links — see
table above. Engineering demos live in
`superDemoAppUITests/EngineeringDemosUITests.swift`.
