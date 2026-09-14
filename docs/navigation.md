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
- Typed deep links (scheme `superdemo`, registered in `Config/AppInfo.plist`):

  | URL | Result |
  | --- | --- |
  | `superdemo://dashboard` | Dashboard tab, cleared path |
  | `superdemo://dashboard/risks` | Dashboard → Production Risks |
  | `superdemo://feed` | Feed tab |
  | `superdemo://items` | Items tab |
  | unsupported `superdemo` URL | Dashboard + user-facing alert |

  Parsing stays in `App/AppNavigation.swift` (`AppDeepLink` / `AppNavigationState`);
  views only consume typed `AppTab` / `AppRoute` values.
- Feature stacks: Items and Feed use `ItemsNavigationShell` / `FeedNavigationShell`
  → `AdaptiveNavigationShell` for master/detail inside a tab.
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

Details: [`testing.md`](testing.md#ui-smoke-ci).
