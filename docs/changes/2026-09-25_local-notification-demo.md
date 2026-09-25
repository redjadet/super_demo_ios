# 2026-09-25 — Local notification demo (JP-P1-C)

## Summary

Adds an Engineering-demo **local** notification path: permission request,
schedule a 5s “stale Feed” reminder, cancel pending/delivered, and honest
denied UI. Explicitly **not** APNs / NSE / production push.

## Paths

- `superDemoApp/Shared/Notifications/LocalNotificationScheduling.swift`
- `superDemoApp/Features/ProductionReadiness/Presentation/LocalNotificationDemoView.swift`
- Dashboard → Engineering demos → Local stale-Feed reminder
- Tests: `LocalNotificationDemoTests`
- Docs: [`portfolio.md`](../portfolio.md)

## Proof

- Unit tests with scheduler spy (grant / deny / schedule blocked / cancel)
- `./bin/verify-swift.sh`
- Hosted GHA compile; local `xcodebuild` may require a non-Cursor Terminal on
  this host (seatbelt FSEvents limitation)

## Follow-up (MainActor default-arg)

`SystemLocalNotificationScheduler` / `LocalNotificationDemoView` construct
`UNUserNotificationCenter.current()` and the system scheduler **inside**
MainActor init bodies (`center:` / `scheduler:` optional `nil` defaults), matching
the FeatureModel / CachingFeedRepository pattern under
`SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` (GHA warnings-as-errors).
