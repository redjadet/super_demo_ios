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

- Shared: `Shared/Presentation/AdaptiveNavigationShell.swift`
- Items: `ItemsNavigationShell` → `AdaptiveNavigationShell`
- New features: reuse `AdaptiveNavigationShell`; add a thin feature shell only for a custom
  detail placeholder. See [`design_system.md`](design_system.md#ui-consistency-contract-all-features).
