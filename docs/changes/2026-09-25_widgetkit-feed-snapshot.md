# 2026-09-25 — WidgetKit Feed snapshot (JP-P0-B)

## Summary

Adds a **read-only** Home Screen Feed widget backed by a versioned **App Group**
snapshot. The main app owns atomic writes after Feed cache refresh / stale
fallback; `-StaleFeedDemo` / in-memory Engineering demos keep a **NoOp**
publisher so they do not pretend to share live App Group state.

## Contract

| Piece | Value |
| --- | --- |
| App Group | `group.com.ilkersevim.superDemoApp` |
| App bundle | `com.ilkersevim.superDemoApp` |
| Widget bundle | `com.ilkersevim.superDemoApp.FeedWidget` |
| Widget kind | `com.ilkersevim.superDemoApp.FeedWidget` |
| Snapshot file | `feed-widget-snapshot.json` (temp + replace) |
| Shared sources | `FeedWidgetShared/` (app + extension membership) |
| Extension folder | `superDemoAppWidget/` |
| Platforms | Widget: **iPhone / iPad only**; embed `platformFilter = ios` so Mac lane stays green |
| Publish sites | `CachingFeedRepository` remote success + stale fallback via `WidgetKitFeedSnapshotPublisher` |

## Honest states

`unavailable` · `absent` · `corrupt` · `expired` · `ok` (optional stale badge).

## Proof

- Unit: `FeedWidgetSnapshotStoreTests` (write/load/expired/corrupt via
  `containerURLOverride`; local Swift Testing)
- Widget sources typechecked with `swiftc -typecheck -warnings-as-errors`
  (WidgetKit + SwiftUI SDK) — Preview macros use Widget+timeline form
- Lint: `swiftlint --strict` + SwiftFormat 0.63.0 clean on touched paths
- Hosted GHA: compile widget with app (scheme builds; iOS embed
  `platformFilter = ios`); GHA remains build-heavy
- Local host note: agent session `confstr(DARWIN_USER_CACHE_DIR)` returns EIO so
  full `xcodebuild` aborts before compile; CI is the merge-blocking build proof
- Limitation: device App Group signing may need team entitlement verification;
  unsigned Simulator may show `unavailable` until group is provisioned

## Docs

- Portfolio **Platform surfaces** row updated
- [`ci-cd-map.md`](../ci-cd-map.md) notes widget extension compile surface
