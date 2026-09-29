# 2026-09-29 — Mixed-age widget snapshot TTL

## Summary

Offline Feed fallback publishes the App Group widget snapshot with
`writtenAt` set to the **oldest** surviving cache row’s `cachedAt` (was
`max`). Widget expiry then matches the oldest title still shown.

## Why

Mac Codex scan on tip `a7424bc` (rank 1): filtering by per-row age then using
`max(cachedAt)` let a newer title keep an older surviving title “ok” past its
own age + TTL.

## Proof

- `CachingFeedRepositoryTests.fetchPostsUsesOldestCachedAtForStaleWidgetSnapshot`
- Existing mixed-age filter test still expects oldest (sole) survivor stamp
- Linux: common-issues / scorecard / markdown / router (GHA owns SwiftLint + tests)

## Out of scope

Flutter / Feed Retry UITest false-greens (Codex ranks 2–3).
