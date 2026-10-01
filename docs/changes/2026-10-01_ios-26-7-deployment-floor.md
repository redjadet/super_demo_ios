# 2026-10-01 — iOS 26.7 deployment floor

## Intent

Make the iPhone / iOS app floor explicit at **iOS 26.7** (below iOS 27), so the
product is not iOS 27-only. CI continues to **build** with Xcode 27 / iOS 27 SDK;
deployment target is independent of the build SDK.

## Changes

- `superDemoApp.xcodeproj` — all `IPHONEOS_DEPLOYMENT_TARGET` **26.0 → 26.7**
  (app, unit tests, UI tests, widget, share).
- Left `MACOSX_DEPLOYMENT_TARGET` / `WATCHOS_DEPLOYMENT_TARGET` at **26.0**
  (no needless raise for companions).
- README Minimum OS badge **26.0 → 26.7**.
- `docs/agent_project_context.md` — document the 26.7 iPhone floor vs CI SDK 27.
- `AdaptiveNavigationShell.chromeGlassButtonStyle()` — keep `#available(iOS 26.0,
  macOS 26.0)` glass path; document honest pre-26 fallback (plain chrome). No
  iOS 27-only APIs reintroduced (`toolbarMinimizationBehavior` stays out).

## Not changed

- No `Package.swift` / Podfile / shared `.xcconfig` deploy keys (none present).
- CI matrix stays on `xcode-27` (toolchain); sims run newest iOS 27 runtime —
  valid for an app whose **minimum** is 26.7.
- Info.plist files have no hand-written `MinimumOSVersion` (Xcode injects from
  the deployment target).

## Proof

```bash
./bin/verify-swift.sh
./bin/checklist-fast   # docs + tooling when full Xcode unavailable
# Hosted: GHA lint / iphone-test / platform-builds / checklist (Delivery 4/4)
```
