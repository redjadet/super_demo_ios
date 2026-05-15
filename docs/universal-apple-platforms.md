# Universal Apple Platforms

This app must behave as a universal Apple app across iOS, iPadOS, and macOS.
Agents must design and verify features against window size, input method, and
platform conventions, not just one iPhone simulator.

## Platform Contract

- iOS: compact phone layouts, portrait and landscape, touch-first controls.
- iPadOS: regular-width layouts, split view, Stage Manager, keyboard/trackpad,
  multitasking, and resizable windows.
- macOS: resizable windows, pointer precision, keyboard shortcuts, menu/toolbar
  expectations, titlebar/window behavior, and smaller control hit targets.

Current project settings already target Apple multi-platform builds:

- `SUPPORTED_PLATFORMS = iphoneos iphonesimulator macosx xros xrsimulator`
- `TARGETED_DEVICE_FAMILY = 1,2,7`

Required product proof remains iOS, iPadOS, and macOS unless task explicitly
adds visionOS behavior.

## Layout Rules

- Prefer adaptive SwiftUI containers over fixed geometry.
- Master/detail: **`AdaptiveNavigationShell`** in `Shared/Presentation/` — wraps
  `NavigationSplitView` for iPhone, iPad, and Mac (collapses on compact iPhone).
- Single-column-only flows: `NavigationStack`.
- UI consistency across features: [`design_system.md`](design_system.md#ui-consistency-contract-all-features).
- Use `ViewThatFits`, `Grid`, `LazyVGrid`, `LazyHGrid`, adaptive frames, and
  dynamic spacing before device-name branching.
- Use size classes, scene/window size, and platform checks only when layout
  behavior truly differs.
- Avoid hard-coded screen sizes, fixed absolute positions, and iPhone-only
  assumptions.
- Do not hide important actions on large screens; promote secondary actions to
  toolbars/sidebar/context menus when platform-appropriate.
- Keep text wrapping, truncation, and minimum sizes deliberate.

## Responsive States

Every user-facing screen should handle:

- compact phone portrait,
- phone landscape,
- iPad full screen,
- iPad split view / Stage Manager narrow window,
- iPad landscape regular width,
- Mac small window,
- Mac large window,
- Dynamic Type / larger text,
- light and dark appearance,
- keyboard/pointer input where interactive.

## Light and dark (required from day one)

- Every new screen must work in **light and dark** without a separate “dark mode pass.”
- Use semantic SwiftUI colors and system controls; custom colors only via asset catalog
  with Any + Dark appearances.
- Add paired `#Preview` traits (`.dark` + `UniversalPreviewLayouts`) per public screen.
- Verify in Simulator appearance toggle after meaningful UI changes.
- Policy: [`design_system.md`](design_system.md#light-and-dark-mode-required-from-day-one),
  [`../DESIGN.md`](../DESIGN.md).

## Navigation

- Sidebar/detail apps should keep selection as state and show a meaningful
  default detail on iPad/Mac.
- Detail-only iPhone collapse must still have a clear back path.
- Use typed navigation state for multi-step flows and deep links.
- Avoid `NavigationView`; use `NavigationStack` and `NavigationSplitView`.

## Controls And Input

- Touch targets: iOS/iPadOS controls need comfortable spacing and hit areas.
- Pointer targets: macOS can use denser controls, but must remain readable.
- Add keyboard shortcuts for frequent Mac/iPad keyboard actions when useful.
- Prefer system controls and toolbar placements so each platform adapts.
- Custom controls require accessibility labels, traits, focus behavior, and
  pointer/hover review when applicable.

## Verification Matrix

For meaningful UI changes, run or record the narrowest honest matrix:

```bash
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=macOS' build
```

If a destination is unavailable, choose an installed equivalent from:

```bash
xcrun simctl list devices available
xcodebuild -showdestinations -project superDemoApp.xcodeproj -scheme superDemoApp
```

For docs-only changes, `./bin/lint.sh` plus scheme/platform inspection is enough.

CI and `./bin/ci.sh` run iPad simulator + macOS builds via `./bin/ci-platform-builds.sh`
after the iPhone test lane.

## Agent Finish Gate

Before calling UI work done, answer:

- Does layout adapt without clipping or overlap at compact, regular, and Mac
  window sizes?
- Does navigation preserve selection/default detail across iPad/Mac?
- Does the screen work with touch, pointer, and keyboard where relevant?
- Does Dynamic Type or larger text break rows, toolbars, sheets, or forms?
- Is platform-specific code isolated and justified?
- Which destination(s), screenshot(s), or UI test prove the change?
