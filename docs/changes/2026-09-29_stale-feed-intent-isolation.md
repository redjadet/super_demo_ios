# 2026-09-29 — Stale Feed demo App Intent isolation

## Summary

Engineering Stale Feed embeds `FeedView` with `embedsOwnNavigation: false`.
That path no longer registers with `FeedRefreshCoordinator`, so
`RefreshFeedIntent(openFeedTab: false)` cannot steal refresh from the live
Feed tab model while the demo is on-screen.

## Why

Mac Codex scan on tip `bc71880`: demo `FeedView.task` registered its isolated
model as `activeModel`, consumed App Intent refresh, and left the real Feed
tab missing the request until remount.

## Proof

- `AppIntentNavigationTests.feedRefreshCoordinatorIgnoresUnregisteredDemoModel`
- Linux: common-issues / scorecard / markdown / router (GHA owns SwiftLint + tests)

## Out of scope

Release-health sample vs live score, mixed-age widget TTL, Feed Retry / Flutter
UITest false-greens (Codex ranks 1 / 3–5).
