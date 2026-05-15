---
version: alpha
name: superDemoApp
description: >-
  Universal SwiftUI demo with clean architecture, native Apple controls, and
  agent-readable design memory for iOS, iPadOS, and macOS.
colors:
  primary: "#007AFF"
  on-primary: "#FFFFFF"
  surface: "#FFFFFF"
  on-surface: "#000000"
  surface-container-low: "#F2F2F7"
  surface-container-highest: "#E5E5EA"
  outline-variant: "#C6C6C8"
  error: "#FF3B30"
  success: "#34C759"
typography:
  large-title:
    fontFamily: System
    fontSize: 34px
    fontWeight: 400
    lineHeight: 1.12
  title-large:
    fontFamily: System
    fontSize: 22px
    fontWeight: 400
    lineHeight: 1.27
  title-medium:
    fontFamily: System
    fontSize: 17px
    fontWeight: 600
    lineHeight: 1.29
  body-large:
    fontFamily: System
    fontSize: 17px
    fontWeight: 400
    lineHeight: 1.29
  body-medium:
    fontFamily: System
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.33
  label-large:
    fontFamily: System
    fontSize: 15px
    fontWeight: 600
    lineHeight: 1.33
  label-medium:
    fontFamily: System
    fontSize: 13px
    fontWeight: 600
    lineHeight: 1.23
rounded:
  sm: 8px
  md: 12px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  row-min: 44px
components:
  button-filled:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-large}"
    rounded: "{rounded.sm}"
    padding: "{spacing.md}"
  button-outlined:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    typography: "{typography.label-large}"
    rounded: "{rounded.sm}"
    padding: "{spacing.md}"
  list-row:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-large}"
    padding: "{spacing.sm}"
  empty-state:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-medium}"
    padding: "{spacing.lg}"
  error-banner:
    backgroundColor: "{colors.surface-container-low}"
    textColor: "{colors.error}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
  status-success:
    backgroundColor: "{colors.success}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-medium}"
    rounded: "{rounded.sm}"
    padding: "{spacing.sm}"
  status-error:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-medium}"
    rounded: "{rounded.sm}"
    padding: "{spacing.sm}"
---

# superDemoApp Design

## Overview

The app should feel like a **native Apple utility**: calm, legible, predictable, and
ready for repeated use on phone, tablet, and Mac. Visual choices support scanning state,
understanding async data flows, and moving through features without marketing decoration.

This file is **agent-readable design memory**. Runtime behavior comes from SwiftUI system
styles, asset catalog (`AccentColor`), and feature Presentation code. When code and this
brief diverge, fix the implementation first, then update this file and
[`docs/design_system.md`](docs/design_system.md).

## Colors

YAML hex values are **light-appearance reference anchors** for agents and DesignMD lint.
**Every screen ships light and dark from the first commit** — no “add dark later” pass.

In SwiftUI always prefer **semantic APIs**: `Color.accentColor`,
`foregroundStyle(.primary)`, `Color(.systemBackground)`, and asset catalog **Any,
Dark** pairs — not YAML literals, `Color.white` / `Color.black`, or fixed hex in views.

- **Primary (#007AFF):** Maps to accent / prominent actions. Use
  `.buttonStyle(.borderedProminent)` or `.tint` — one main action per region.
- **Surface / containers:** `List`, `Form`, and system backgrounds adapt to `colorScheme`.
- **Error / success:** Failure and positive status only — not decoration.
- **Outline variant:** Dividers and subtle borders via `Divider()` or list separators.

Named colors belong in **Assets.xcassets** with light/dark variants when a role repeats
across features. See [`docs/design_system.md`](docs/design_system.md#light-and-dark-mode-required-from-day-one).

## Typography

YAML sizes approximate **SF Pro** at default content size. Runtime code uses **Dynamic Type
text styles** (`.largeTitle`, `.title3`, `.body`, `.subheadline`, etc.) — not fixed px.

- `body-large` / `title-medium` → list primary lines and section headers.
- `label-large` → toolbar and button labels (`Label` + symbol).
- `label-medium` → compact status chips.
- Test at **Accessibility Extra Large**; avoid fixed row heights that clip text.

## Layout

Spacing follows an **8 pt grid**: 8, 16, 24, 32. Minimum tappable area **44×44 pt** on iOS.

**Universal rule:** one adaptive layout for **all iPhones, all iPads, and Mac** — no
separate phone/tablet/Mac screens unless behavior truly differs.

- **Master/detail features:** `AdaptiveNavigationShell` (`NavigationSplitView`) on every
  platform; system collapses to one column on compact iPhone width.
- **Single-column flows only:** `NavigationStack` when there is no sidebar (sign-in, wizard).
- **iPad / Mac:** resizable windows, Stage Manager, split view — sidebar width via
  `.featureSidebarColumnWidth()`; loading/empty/error use `.featureScreenFrame()`.
- **Proof:** `./bin/ci.sh` (iPhone test + iPad + Mac build); layout-heavy changes also
  [`docs/universal-apple-platforms.md`](docs/universal-apple-platforms.md).

Operational screens stay **scannable**: stable row heights, predictable padding, no nested
cards. Compact is not a squeezed desktop layout — stack sections with spacing instead.

## Elevation and depth

Prefer **flat hierarchy**: list backgrounds, grouped styles, materials on sheets. Avoid
custom drop shadows and gradient hero backgrounds. Depth clarifies grouping, not branding.

## Shapes

- Grouped panels and cards: **12 pt** continuous corners when custom containers are needed.
- Compact controls: **8 pt** when not using system button styles.
- System buttons and lists: default platform cornering — do not override without reason.

Do not mix sharp and heavily rounded corners in the same component family.

## Components

| YAML token | SwiftUI implementation |
| --- | --- |
| `button-filled` | `.buttonStyle(.borderedProminent)` |
| `button-outlined` | `.buttonStyle(.bordered)` |
| `list-row` | `NavigationLink` in `List` |
| `empty-state` | `ContentUnavailableView` |
| `error-banner` | `ContentUnavailableView` + Retry action |
| `status-error` / `status-success` | compact `Label` badges when inline status is needed |

Also: toolbars with `Label` + SF Symbol; `ProgressView` for loading; `Form` for input;
`AdaptiveNavigationShell` per [`docs/navigation.md`](docs/navigation.md) and
[`docs/design_system.md`](docs/design_system.md#ui-consistency-contract-all-features).
Reference: `ItemsView` + `Shared/Presentation/AdaptiveNavigationShell.swift`.

Extract shared wrappers to `Shared/` (or `Features/Shared/Presentation/`) only when **two
or more** features need the same shell.

## Do's and don'ts

- Do read [`docs/design_system.md`](docs/design_system.md) before new UI.
- Do use semantic colors, system text styles, and SF Symbols.
- Do implement loading, empty, error, disabled, and content states.
- Do support **light and dark** on every new screen (semantic colors; `#Preview` for both).
- Do prove iPhone, iPad, and Mac after layout changes (`./bin/ci.sh` or `./bin/checklist`).
- Do add `#Preview` per screen and update UI tests for critical flows.
- Do update this file when adding a **shared** visual role or component recipe.
- Don't use `NavigationView`, `ObservableObject` for new screens, or hex colors in views.
- Don't put business logic in `body` or Domain imports in Presentation beyond types.
- Don't use device-model checks, fixed screen-size layout, or light-only hardcoded colors.
- Don't treat this file as compile-time enforcement — run `./bin/lint.sh` and tests.

## Agent prompt guide

Keep in working memory when generating or refactoring SwiftUI:

- **Tokens first:** YAML colors/typography/spacing → semantic SwiftUI APIs per
  [`docs/design_system.md`](docs/design_system.md#token-map-yaml--swiftui); never paste hex
  from YAML into views.
- **Workflow first:** ship the real feature surface; optimize for scanning and repeat
  actions, not landing-page layout.
- **Complete states:** loading, empty, failed (with retry), disabled, content; async via
  `.task` and `Task { await model... }`.
- **Universal:** `AdaptiveNavigationShell` everywhere; `./bin/ci.sh` iPhone + iPad + Mac;
  see [`docs/universal-apple-platforms.md`](docs/universal-apple-platforms.md).
- **Consistent:** same state switch, toolbar placement, and shared layout helpers per
  [`docs/design_system.md`](docs/design_system.md#ui-consistency-contract-all-features).
- **Accessible:** labels on icon-only controls; Dynamic Type; light + dark previews;
  Reduce Motion aware motion.
- **Layers:** UI only under `Features/<Name>/Presentation/`; see [`docs/layers.md`](layers.md).
