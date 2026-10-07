# 2026-10-06 — Low-risk UI trends polish (Views / a11y)

## Intent

Apply only low-risk Presentation polish aligned with Mohit Phogat’s “UI Trends
That Are Actually Happening” (Apr 2026), where this portfolio app already has
matching UI. No Feed / offline-outbox (#86) core edits, no CI (#85) edits, no
schema / networking / Flutter API / navigation redesign.

## Changes

- `Shared/Presentation/DesignSpacing.swift` — YAML spacing/radius anchors as
  constants (trend 6 gap fill; not a new theme system).
- `Shared/Presentation/FeatureLoadingPlaceholder.swift` — list skeleton for
  first-load gap; Reduce Motion falls back to `ProgressView` (trends 2, 5).
- `Items/Presentation/ItemsView.swift` — skeleton loading, clearer empty/error
  a11y, disabled Add while loading, success haptic on add, combined row labels
  (trends 1, 2, 5, 7).
- `Items/Presentation/ItemDetailView.swift` — drop redundant section titles,
  unsaved affordance, Save → Progress while saving, Dynamic Type note height,
  save haptic (trends 1, 2, 3, 5, 7).
- `ProductionReadiness/Presentation/ProductionReadinessView.swift` — skeleton
  loading, retry a11y ids, DesignSpacing, denser a11y labels / selected trait
  on checklist (trends 2, 5, 6, 7).
- `ProductionReadiness/Presentation/ProductionRisksView.swift` — empty state,
  typography hierarchy, combined a11y (trends 2, 7).
- `HostBridgePingDemoView` / `AppRootView` — busy Progress label + success haptic;
  explicit tab a11y labels (trends 2, 5).
- `DesignSpacingTests` — token values match DESIGN.md anchors.

## Deliberately skipped (too risky / out of scope)

- Trend 4 AI-as-a-layer entirely.
- Feed bookmark / outbox UI (#86 conflict surface).
- CI / checklist tooling (#85).
- New undo stack for swipe-delete (system Edit already; custom undo = feature).
- Pref-driven chrome rearrangement (no persisted layout prefs to extend).
- New design-token asset catalog / Theme environment object.
- Networking, models, Flutter module APIs.

## Proof

- `./bin/verify-swift.sh` (format + lint) when toolchain present.
- `./bin/checklist-fast` on Linux agent hosts; full `./bin/checklist` / GHA when
  Xcode available.
