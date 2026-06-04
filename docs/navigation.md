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
- Typed deep-link route: `superdemo://dashboard/risks` opens Dashboard →
  Production Risks through `AppNavigationState` for cold and warm app delivery.
  Unsupported `superdemo` URLs fall back to Dashboard and show a user-facing alert.
- URL registration: `Config/AppInfo.plist`. Parsing stays in
  `App/AppNavigation.swift`; views only consume typed `AppRoute` values.
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
| Dashboard → UIKit showcase | `testUIKitShowcaseCollectionIsReachable` |
| Feed tab | `testFeedTabIsReachable` |

Deep-link parsing and cold/warm navigation-state behavior:
`superDemoAppTests/Shared/AppNavigationTests.swift`.

Details: [`testing.md`](testing.md#ui-smoke-ci).
