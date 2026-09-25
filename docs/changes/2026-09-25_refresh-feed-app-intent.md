# 2026-09-25 — Refresh Feed App Intent (JP-P1-B)

## Summary

Adds parameterized **Refresh Feed** App Intent / Shortcut. Day-1 choice:
refresh (not post-entity open). Wires through:

1. Typed `AppNavigationStore.requestFeedRefresh(openFeedTab:)` /
   `feedRefreshRequestID`
2. App-owned `FeedRefreshCoordinator` (registers live `FeedFeatureModel`) so
   `openFeedTab: false` still refreshes when Feed is mounted

Intent **requests** refresh; it does not await network completion.

## Paths

- `superDemoApp/App/AppIntents/OpenDestinationIntents.swift` — `RefreshFeedIntent`
- `superDemoApp/App/AppIntents/FeedRefreshCoordinator.swift`
- `superDemoApp/App/AppIntents/AppIntentNavigationRouter.swift`
- `superDemoApp/App/AppNavigation.swift`
- `superDemoApp/Features/Feed/Presentation/FeedView.swift`
- Tests: `AppIntentNavigationTests`
- Docs: [`navigation.md`](../navigation.md), [`portfolio.md`](../portfolio.md)

## Proof

- Unit tests: state bump, intent perform (open / skip tab), coordinator refreshes
  registered `FeedFeatureModel` via `SampleFeedRepository`
- `./bin/verify-swift.sh` (format + lint)
- Xcode zero-warning `build-for-testing` (generic iOS Simulator) **outside**
  Cursor seatbelt shell, or hosted GHA compile green on merge
- Honesty: Cursor agent shell cannot run `xcodebuild` / `simctl` (FSEvents /
  CoreSimulator sandbox); local Xcode proof needs a normal Terminal session
