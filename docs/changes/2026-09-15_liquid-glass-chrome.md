# 2026-09-15 — Liquid Glass chrome (P2)

## Why

Adopt Apple Liquid Glass on **controls/navigation only**, matching HIG and the
repo review protocol (no glass on content cards).

## Changes

- `AppRootView` — migrate to `Tab` API + `tabBarMinimizeBehavior(.automatic)` so
  the system tab bar gets Liquid Glass.
- `AdaptiveNavigationShell` — `chromeGlassButtonStyle()` (`.buttonStyle(.glass)`)
  only (no iOS 27-only `toolbarMinimizationBehavior` — CI stays on released Xcode 26.x SDK).
- Feed / Items / Production Readiness toolbars and empty/error actions use the
  chrome helpers; Items separates Edit vs Add with `ToolbarSpacer(.fixed)`.
- `DESIGN.md` + `docs/design_system.md` document chrome-only Liquid Glass rules.

## Proof

- Xcode build succeeded after the change.
- `./bin/lint.sh` / markdown lint before merge.
