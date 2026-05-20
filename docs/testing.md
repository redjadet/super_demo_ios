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
- Use parameterized Swift Testing cases for boundary combinations when useful.

## UI smoke (CI)

The iPhone test lane (`bin/ci-iphone-test.sh`, GitHub Actions `iphone-test`) runs
the iPhone app build on GitHub Actions. CI does **not** run `xcodebuild test`
because GitHub Actions repeatedly hangs the XCTest runner before logs are
available, even for unit-only selection. Run unit/UI smoke locally before risky
releases.

| UI test | What it proves |
| --- | --- |
| `testLaunchShowsAddItemControl` | Local Items tab chrome (`addItem` / empty / list) |
| `testDashboardShowsProductionRisks` | Local Dashboard → Production Risks list |
| `testUIKitShowcaseCollectionIsReachable` | Local Dashboard → UIKit showcase collection |
| `testFeedTabIsReachable` | Local Feed tab chrome (toolbar, list, empty, or error) |
| `testLaunch` | Local/full-lane launch duplicate for Items chrome |
| `testLaunchPerformance` | Local launch performance under `-UITesting` |

Helpers live in `superDemoAppUITests/UiTestSupport.swift`:

- **`launchApplication()`** — passes `-UITesting`, terminates any running app
  instance, then launches and waits for foreground (avoids CI
  `Failed to terminate` between tests).
- **`tearDown`** in `superDemoAppUITests` — `@MainActor`, calls
  `terminateApplication` so the next test does not inherit a stuck process
  (SwiftLint: balanced `setUp` / `tearDown`; required for Swift 6 on CI).

### `-UITesting` behavior

When `ProcessInfo` contains `-UITesting` (`AppLaunchConfiguration.isUITesting`):

- **Production Readiness** uses `SampleProductionReadinessRepository` (no live
  JSONPlaceholder health probe).
- **Feed** uses `SampleFeedRepository` via `FeedComposition` (no live posts fetch).

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

## Command

```bash
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 17' test
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
UIKit showcase), and Feed tabs — see table above.
