# App Store Review Notes

No reviewer account or credentials are required.

## Credentials-Free Walkthrough

1. Launch the app and open the Dashboard tab.
2. Open Production Risks from Dashboard, or open
   `superdemo://dashboard/risks` to verify the registered custom URL scheme and
   typed deep-link route.
3. Open Feed to review remote loading, retry/error handling, and cached fallback
   behavior.
4. Open Items to review local SwiftData persistence: add an item, delete it, and
   relaunch to confirm the remaining local state.
5. Open the UIKit Showcase from Dashboard to review collection-view reuse,
   prefetching, SwiftUI detail hosting, and custom navigation transitions.

## Reviewer Demo Mode

Reviewer demo mode seeds deterministic Dashboard, Production Risks, Feed, and
Items data without credentials. TestFlight archives built through
`fastlane ios beta` include the `REVIEWER_DEMO` build flag. Local reviewer-demo
proof can also launch with `-ReviewerDemoMode` or
`SUPERDEMO_REVIEWER_DEMO_MODE=1`.

## Deep Link

`superdemo://dashboard/risks` opens Dashboard -> Production Risks. Unsupported
`superdemo` URLs fall back to Dashboard and show a "Link Not Available" alert.
The app registers the `superdemo` custom URL scheme and Associated Domains for
`applinks:superdemo.app`. HTTPS paths under that host parse the same routes as
the custom scheme. Full Safari handoff needs the hosted AASA file (see
`Config/associated-domains/`).

## Permissions And Background Modes

The current app does not request runtime permissions and does not declare
background modes, push notifications, keychain access groups, App Groups,
or Sign in with Apple. Networking is limited to the Feed and
Dashboard health-check demo paths. Release diagnostics are OSLog-only today; no
Crashlytics, Sentry, or equivalent crash-monitoring provider is configured yet.
