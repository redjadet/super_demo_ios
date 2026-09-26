# Navigation

Use declarative SwiftUI navigation that adapts across iOS, iPadOS, and macOS.

## Defaults

- Master/detail features: **`AdaptiveNavigationShell`** (`NavigationSplitView`) on
  iPhone, iPad, and Mac. Compact width collapses automatically; do not fork navigation per OS.
- Single-column-only flows: `NavigationStack` (no persistent sidebar).
- Represent destinations as typed route values where flow complexity grows.
- Keep route construction out of leaf views.
- Keep selection/default detail state explicit for iPad and Mac.

## Rules

- Avoid raw string route IDs for internal navigation.
- Do not trigger navigation as hidden side effect of rendering.
- Keep deep-link parsing separate from view code.
- UI tests should cover critical navigation paths.
- Verify narrow compact collapse and wide split layout for shared navigation.

## Current App Note

- Root shell: `AppRootView` (`TabView`) — Dashboard, Items, Feed tabs with
  `accessibilityIdentifier` on each tab (`dashboardTab`, `itemsTab`, `feedTab`).
- Typed deep links — custom scheme `superdemo` (`Config/AppInfo.plist`) and
  HTTPS universal links for `superdemo.app` (Associated Domains entitlement +
  sample AASA under `Config/associated-domains/`):

  | URL | Result |
  | --- | --- |
  | `superdemo://dashboard` / `https://superdemo.app/dashboard` | Dashboard tab, cleared path |
  | `superdemo://dashboard/risks` / `https://superdemo.app/dashboard/risks` | Dashboard → Production Risks |
  | `superdemo://feed` / `https://superdemo.app/feed` | Feed tab |
  | `superdemo://items` / `https://superdemo.app/items` | Items tab |
  | unsupported `superdemo` / associated-host HTTPS path | Dashboard + user-facing alert |

  Parsing stays in `App/AppNavigation.swift` (`AppDeepLink` / `AppNavigationState`);
  `@Observable` `AppNavigationStore` owns navigation state for the root shell.
  `AppRootView` binds the store, handles `onOpenURL` and
  `NSUserActivityTypeBrowsingWeb`, and applies deep links via `handle(url:)`.
  Views only consume typed `AppTab` / `AppRoute` values. HTTP (non-TLS) hosts are
  rejected.
- Feature stacks: Items and Feed use `ItemsNavigationShell` / `FeedNavigationShell`
  → `AdaptiveNavigationShell` for master/detail inside a tab.
- **Selection-driven detail:** sidebar uses `List(selection:)` + `NavigationLink(value:)`
  with `Hashable` row models; shells bind selection and flip
  `preferredCompactColumn` to `.detail` on pick (compact iPhone). Destination-only
  `NavigationLink { View }` inside a nested split often no-ops.
- **Nested Feed (Stale Feed demo):** `FeedView(embedsOwnNavigation: false)` pushed
  onto Production Readiness's `NavigationStack` so post rows push detail without a
  nested split/stack fighting the dashboard.
- Shared: `Shared/Presentation/AdaptiveNavigationShell.swift`
- New features: reuse `AdaptiveNavigationShell`; add a thin feature shell only for a custom
  detail placeholder. See [`design_system.md`](design_system.md#ui-consistency-contract-all-features).

### UI test coverage (CI smoke)

| Path | UI test |
| --- | --- |
| Items tab | `testLaunchShowsAddItemControl` |
| Dashboard → Production Risks | `testDashboardShowsProductionRisks` |
| Dashboard → UIKit showcase (+ detail) | `testUIKitShowcaseCollectionIsReachable` |
| Feed tab | `testFeedTabIsReachable` |
| Deep link → Feed | `testDeepLinkOpensFeedTab` |
| Deep link → Items | `testDeepLinkOpensItemsTab` |

Deep-link parsing and cold/warm navigation-state behavior:
`superDemoAppTests/Shared/AppNavigationTests.swift`.

- App Intents: `OpenFeedIntent`, `OpenItemsIntent`, `OpenProductionRisksIntent`,
  and parameterized `RefreshFeedIntent` (`openFeedTab`) via
  `AppIntentNavigationRouter` → `FeedRefreshCoordinator` +
  `AppNavigationStore.requestFeedRefresh(openFeedTab:)`. Coordinator refreshes a
  registered `FeedFeatureModel` when present; cold start relies on Feed `.task`
  after the tab opens. Phrases in `SuperDemoAppShortcuts`.

Details: [`testing.md`](testing.md#ui-smoke-ci).
