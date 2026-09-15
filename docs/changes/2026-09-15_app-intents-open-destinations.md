# 2026-09-15 — Open Feed/Items/Risks App Intents (P6)

## Why

Expose the three highest-value destinations to Siri / Shortcuts without new
navigation models — reuse typed `AppDeepLink` routing.

## Changes

- `OpenFeedIntent`, `OpenItemsIntent`, `OpenProductionRisksIntent` (`openAppWhenRun`).
- `SuperDemoAppShortcuts` phrases (each includes `\(.applicationName)`).
- `AppIntentNavigationRouter` calls `AppNavigationStore.current.apply(_:)`.
- `AppDeepLink.customSchemeURL` + `AppNavigationState.apply(_:)`.

## Proof

- Unit tests for URL round-trip, apply routing, and intent → store handoff.
- Build + lint gates.
