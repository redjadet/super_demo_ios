# 2026-09-29 — Feed Retry UITest no-op honesty

## Summary

`testFeedAccessibilityChromeRowsAndRetry` must prove a real refresh attempt
after tapping Retry under `-UITestingFeedFailure` — not that Retry still
exists (a no-op tap would pass).

## Why

Mac Codex scan on tip `ab6784c` (rank 2 / e2e-13 after #52): Retry tap then
only `waitForExistence` on `feedRetry` false-greens when the button was
already on screen.

## Changes

- `FeedView` — `feedLoading` on ProgressView; `feedFailed` on failed chrome
- `FailingSampleFeedRepository` — short sleep so UITests can observe loading
  before the fixture fails again
- `testFeedAccessibilityChromeRowsAndRetry` — assert loading / failed-left,
  then `feedFailed` + `feedRetry` outcome
- `UiTestSupport.waitForFeedChrome` — accept `feedLoading` / `feedFailed` ids
- Portfolio tip pin → `e399339` (#52)

## Proof

- GHA Delivery UITests on this PR (iPhone lane)
- Linux: `./bin/verify-swift.sh` + checklist-fast / common-issues

## Out of scope

P2-A screenshots; visionOS; tip-pin-only ships.
