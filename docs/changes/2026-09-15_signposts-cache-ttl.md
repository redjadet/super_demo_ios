# 2026-09-15 — Feed/UIKit signposts + cache TTL (P5)

## Why

Give Instruments stable marks for Feed fetch and UIKit showcase snapshot apply,
and stop serving arbitrarily old offline Feed cache after a remote failure.

## Changes

- `AppPerformanceSignposts` — shared `OSSignposter` handles (`Feed`, `UIKitShowcase`).
- `CachingFeedRepository.fetchPosts` begin/end interval + success/fallback events.
- `ModuleCollectionViewController.apply` snapshot interval.
- `CachedFeedPost.cachedAt`; default **15 min** TTL (injectable; `nil` = never expire).

## Proof

- Caching repository unit tests for persist, fresh fallback, expired miss, TTL off.
- Build + lint gates.
