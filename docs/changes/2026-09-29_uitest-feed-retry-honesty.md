# 2026-09-29 — Feed Retry UITest no-op honesty

## Summary

`testFeedAccessibilityChromeRowsAndRetry` proves Retry advances a refresh cycle
via `feedFailed-<n>` (backed by `FeedFeatureModel.completedRefreshCount`), not
merely that the Retry control still exists after tap.

## Why

Mac Codex scan on tip `ab6784c` (rank 2 / e2e-13 after #52): tapping Retry then
asserting Retry still exists was a no-op pass if the tap did nothing. First #53
attempt used static `feedFailed` + polling — flaky on GHA (loading→failed
re-assert timed out); folded closed #54 counter approach on same branch.

## Changes

- `FeedFeatureModel.completedRefreshCount` — increments on success/failure
  completion (not cancel)
- `FeedView` — `feedLoading`, `feedFailed-<n>` (children contained)
- `FailingSampleFeedRepository` — 200ms delay so loading is observable
- UITest waits for `feedFailed-1` then post-tap `feedFailed-2` / `feedLoading`
- Unit: `retryAfterFailureIncrementsCompletedRefreshCount`
- Portfolio tip pin → `87455ec` (#53)

## Proof

- Unit test above; GHA Delivery UITests on [#53](https://github.com/redjadet/super_demo_ios/pull/53)
- Linux: common-issues / scorecard / markdown / router

## Out of scope

Mac P2-A screenshots; visionOS; tip-pin-only ships.
