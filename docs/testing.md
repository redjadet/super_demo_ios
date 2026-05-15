# Testing Strategy

Use a test pyramid: many fast unit tests, fewer integration tests, focused UI
tests for critical workflows.

## Defaults

- New unit/integration tests: prefer Swift Testing when target supports it.
- Existing XCTest files may stay XCTest.
- UI tests: XCTest/XCUIAutomation.
- Performance-sensitive code: add XCTest performance coverage or metric proof.
- Use parameterized Swift Testing cases for boundary combinations when useful.

## UI smoke (CI)

`superDemoAppUITests.testLaunchShowsAddItemControl` runs in the iOS Simulator CI lane.
Extend UI tests when adding primary navigation or forms; keep smoke green before PR.

## What To Test

- Domain use cases: success, edge, failure, cancellation where relevant.
- Repositories: mapping, persistence, retry/conflict behavior.
- Feature models: actions produce expected state transitions.
- UI: critical user journeys and regressions.
- Universal UI: at least one compact iPhone, one iPad regular/split case, and
  one Mac window sanity check for meaningful layout/navigation changes.

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
