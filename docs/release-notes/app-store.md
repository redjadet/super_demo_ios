# App Store Review Notes

No reviewer account or credentials are required.

## Credentials-Free Walkthrough

1. Launch the app and open the Dashboard tab.
2. Open Production Risks from Dashboard, or open
   `superdemo://dashboard/risks` to verify the registered custom URL scheme and
   typed deep-link route.
3. Open Feed to review remote loading, retry/error handling, and cached fallback
   behavior. Optionally open `superdemo://feed/1` to select a post detail.
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

## App Shortcuts

App Shortcuts include Open Feed, Open Items, Open Production Risks, Refresh
Feed, and Open Feed Post (Siri / Shortcuts). They route through the same typed
navigation as deep links (`AppIntentNavigationRouter`).

## Deep Link

`superdemo://dashboard/risks` opens Dashboard → Production Risks.
`superdemo://feed/<id>` opens Feed and selects the matching post when loaded
(unknown id = Feed tab only). Unsupported `superdemo` URLs fall back to
Dashboard and show a "Link Not Available" alert. The app registers the
`superdemo` custom URL scheme and Associated Domains for
`applinks:superdemo.app`. HTTPS paths under that host parse the same routes as
the custom scheme (sample AASA includes `/feed/*`). Full Safari handoff needs
the hosted AASA file (see `Config/associated-domains/`).

## Capabilities (honest)

Declared in `superDemoApp/superDemoApp.entitlements`:

- **Associated Domains** — `applinks:superdemo.app` (+ developer mode variant)
- **App Group** — `group.com.ilkersevim.superDemoApp` (widget / Share / watch
  Feed snapshot)
- **Sign in with Apple** — Engineering demo only; not production account linking

Not declared / not claimed as production:

- No `UIBackgroundModes`
- No production push (`aps-environment`) / Notification Service Extension
- No Keychain access groups (opt-in Keychain token demo uses default APIs behind
  `-KeychainTokenDemo`)
- No camera / photo-library usage descriptions (Vision OCR uses a bundled sample
  image)

Local stale-Feed reminder (Engineering demos) may request notification
permission on device — labeled demo, not APNs. Networking is limited to Feed
and Dashboard health-check demo paths. Release diagnostics are OSLog-only today;
no Crashlytics, Sentry, or equivalent crash-monitoring provider is configured.
