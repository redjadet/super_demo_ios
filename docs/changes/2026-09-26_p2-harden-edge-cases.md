# P2 harden — widget/host-bridge/share/CI edge cases

Date: 2026-09-26

## Why

Post-P2 audit found real honesty / CI footguns after A–E landed on `main`.

## Changes

- **Feed widget snapshot `postCount`**: full cache size for `feed.cacheStatus`;
  titles stay capped at 5 for widget UI. Legacy JSON without `postCount` falls
  back to `titles.count`.
- **Cache miss clears App Group snapshot** so widget / host-bridge match OI miss
  (no stale “ok”).
- **Stale publish uses SwiftData `cachedAt`** for `writtenAt` (TTL no longer
  resets on fallback).
- **Share extension**: refuse empty (nil URL+text) appends; extract URL and text
  independently.
- **CI sim UDID**: normalize hex case; prefer iPhone 18 Pro over Pro Max; still
  skip Duo/Fold/Air.
- **Publisher**: log non-container write/clear failures; tmp-file cleanup on write.

## Proof

- Unit: `CachingFeedRepositoryTests` (postCount / clear / writtenAt),
  `FeedWidgetSnapshotStoreTests`, `HostBridgeCodecTests` snapshot provider map
- Hosted: GHA Delivery checklist (`iphone-test` + platform + lint) on Xcode 27
