# 2026-10-01 — macOS / watchOS 26.7 deployment floors

## Intent

Align companion deployment floors with the iPhone floor from #63: raise
`MACOSX_DEPLOYMENT_TARGET` and `WATCHOS_DEPLOYMENT_TARGET` from **26.0** to
**26.7** (still below OS 27). CI continues to build with Xcode 27 / SDK 27.

## Changes

- `superDemoApp.xcodeproj` — all `MACOSX_DEPLOYMENT_TARGET` **26.0 → 26.7**;
  all `WATCHOS_DEPLOYMENT_TARGET` **26.0 → 26.7**.
- Left `IPHONEOS_DEPLOYMENT_TARGET` at **26.7** (already set in #63).
- Left `XROS_DEPLOYMENT_TARGET` at **26.0** (no visionOS companion product).
- Docs: `agent_project_context`, `universal-apple-platforms`, `testing`,
  `portfolio` — companion floors **26.7**.
- `AdaptiveNavigationShell.chromeGlassButtonStyle()` — keep
  `#available(iOS 26.0, macOS 26.0)` glass path; update comments for 26.7 floors.

## Not changed

- No `Package.swift` / Podfile / shared `.xcconfig` deploy keys (none present).
- CI matrix stays on `xcode-27`; platform-builds / watch build scripts unchanged.
- README Minimum OS badge already **26.7** after #63.

## Proof

```bash
./bin/verify-swift.sh
./bin/checklist-fast   # docs + tooling when full Xcode unavailable
# Hosted: GHA lint / iphone-test / platform-builds / checklist (Delivery 4/4)
```
