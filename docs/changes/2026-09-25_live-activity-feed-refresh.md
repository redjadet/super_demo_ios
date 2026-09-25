# 2026-09-25 — Live Activity Feed refresh (JP-P1-A)

## Decision gate

**Chosen: (A)** Activity spans Feed refresh + short post-complete hold
(~2.5s), then ends. Recorded so reviewers can see lock screen / Dynamic Island
UI without inventing a durable fake workload. **Not (B).**

## Summary

Adds ActivityKit Live Activity for the Feed refresh lifecycle, following the
existing WidgetKit extension target (`superDemoAppWidget`) patterns from
JP-P0-B.

| Piece | Value |
| --- | --- |
| Attributes | `FeedWidgetShared/FeedRefreshActivityAttributes.swift` (`#if canImport(ActivityKit)`) |
| Controller | `App/ActivityKitFeedRefreshLiveActivityController.swift` (composition) |
| Feature wiring | `FeedFeatureModel` start / succeed / fail / cancel |
| UI | `superDemoAppWidget/FeedRefreshLiveActivity.swift` (lock screen + Dynamic Island) |
| Info | `NSSupportsLiveActivities` in `Config/AppInfo.plist` |
| Hold | ~2.5s after succeed/fail, then `end`; cancel ends **immediately** |
| Cancel invariant | `cancelRefresh` still restores prior Feed UI; Live Activity ends on cancel |

## Honesty / limitations

- **Hosted GHA:** compiles the widget extension + app with warnings-as-errors;
  does **not** verify Dynamic Island appearance on a physical device.
- **Simulator:** ActivityKit may be disabled or silent (`areActivitiesEnabled`);
  Feed UI still works; request failures are swallowed (same honesty as App Group
  unavailable on unsigned Simulator).
- **Mac / visionOS:** ActivityKit controller is a no-op (`canImport` / else
  branch); widget embed remains `platformFilter = ios`.
- No FPS / “production Live Activity at scale” claims.

## Proof

- Unit: `FeedFeatureModelTests` Live Activity spy (start/succeed, fail, cancel)
- `./bin/verify-swift.sh` when host allows; merge proof = hosted GHA Delivery
  checklist green
- Device Island visual verification: **not claimed** on hosted CI

## Docs

- [`performance-lab.md`](../performance-lab.md) Live Activity recipe (was pending)
- Portfolio **Platform surfaces** row updated
