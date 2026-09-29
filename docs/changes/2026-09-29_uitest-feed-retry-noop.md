# 2026-09-29 — Feed Retry UITest no-op harden

## Summary

`testFeedAccessibilityChromeRowsAndRetry` proves Retry advances a refresh cycle
via `feedFailed-<n>` (backed by `FeedFeatureModel.completedRefreshCount`), not
merely that the Retry control still exists after tap.

## Why

Mac Codex scan on tip `ab6784c` (rank 2 / e2e-13 after #52): tapping Retry then
asserting Retry still exists was a no-op pass if the tap did nothing.

## Changes

- `FeedFeatureModel.completedRefreshCount` — increments on success/failure
  completion (not cancel)
- `FeedView` — `feedLoading`, `feedFailed-<n>` (children contained)
- UITest waits for `feedFailed-1` then post-tap `feedFailed-2`
- Unit: `retryAfterFailureIncrementsCompletedRefreshCount`
- Portfolio tip pin → `e399339` / #52

## Proof

- Unit test above; GHA Delivery UITests on this PR
- Linux: common-issues / scorecard / markdown / router

## Out of scope

Mac P2-A screenshots; visionOS; paid StoreKit; real APNs.
