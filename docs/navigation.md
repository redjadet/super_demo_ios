# Navigation

Use declarative SwiftUI navigation that adapts across iOS, iPadOS, and macOS.

## Defaults

- iPhone / compact window: `NavigationStack` or collapsed `NavigationSplitView`.
- iPad and Mac: `NavigationSplitView` for sidebar/detail workflows.
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

`ContentView` uses a small wrapper for platform-adaptive navigation. Keep that
simple until multiple routes or feature modules justify a route model.
