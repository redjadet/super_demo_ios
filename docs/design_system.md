# Design system — SwiftUI implementation

Quick reference for where design memory, theme, and UI code live. Read root
[`../DESIGN.md`](../DESIGN.md) before new shared visual roles or Presentation patterns.

`DESIGN.md` uses a **DesignMD-style YAML frontmatter** (inspired by
[@google/design.md](https://www.npmjs.com/package/@google/design.md) alpha) plus prose
sections. Values describe **semantic Apple roles**, not Material tokens. SwiftUI and the
asset catalog are the runtime source of truth; when they diverge, update code then sync
the YAML and prose.

DesignMD validation: `./tool/check_design_md.sh` (Node `npx`; included in `./bin/checklist`
and `./bin/checklist-fast`; skips if `npx` missing). Not in `./bin/ci.sh` (merge gate).

## Locations

| Area | Path | Purpose |
| ---- | ---- | ------- |
| Visual brief | [`../DESIGN.md`](../DESIGN.md) | Agent-readable tokens + product UI rules |
| App entry | `superDemoApp/superDemoAppApp.swift` | `@main`, `WindowGroup`, model container |
| Composition | `superDemoApp/App/*Composition.swift` | Wire repositories, use cases, root views |
| Feature UI | `superDemoApp/Features/<Name>/Presentation/` | Views, feature models, navigation shells |
| Shared UI | `Shared/Presentation/` | `AdaptiveNavigationShell`, `featureScreenFrame()` |
| Reference UI | `Features/Items/Presentation/` | `ItemsView`, state machine, toolbars |
| Universal policy | [`universal-apple-platforms.md`](universal-apple-platforms.md) | iPhone / iPad / Mac matrix, proof commands |
| Accent / assets | `superDemoApp/Assets.xcassets/` | `AccentColor`, app icon |
| Layer enforcement | [`../tool/check_layer_boundaries.sh`](../tool/check_layer_boundaries.sh) | Presentation must not import SwiftData |

`Shared/Presentation/` holds cross-feature UI primitives. New features must reuse them
before inventing parallel shells or layout helpers.

## UI consistency contract (all features)

Every feature Presentation layer follows the same shape:

| Piece | Rule | Reference |
| ----- | ---- | --------- |
| Navigation | `AdaptiveNavigationShell` (split view; collapses on iPhone) | `Shared/Presentation/AdaptiveNavigationShell.swift` |
| Feature wrapper | Thin `*NavigationShell` only if feature needs a custom detail placeholder | `ItemsNavigationShell` |
| Screen body | `@Bindable` model + `@ViewBuilder` state switch | `ItemsView.content` |
| Toolbar | On feature root view, not hidden inside list-only branches | `ItemsView.itemsToolbar` |
| Loading / empty / error | `ProgressView` / `ContentUnavailableView` + `.featureScreenFrame()` | `ItemsView` |
| Primary action | Toolbar `Label` + `accessibilityIdentifier`; duplicate in empty actions | `addItem` |
| List data | `List` + `NavigationLink`; sidebar column width via `.featureSidebarColumnWidth()` | `ItemsView.itemsList` |
| Previews | In-file `Preview*` repository; `#Preview` per screen | `ItemsView` |

**Do not** copy-paste navigation or state-switch boilerplate with different names per
feature. Extend shared helpers or update this contract when the pattern changes.

## Universal responsive UI (required)

This app ships **iOS, iPadOS, and macOS** with one SwiftUI codebase. UI is not done until
it works on all three.

### Default navigation

- Use **`NavigationSplitView`** via `AdaptiveNavigationShell` for master/detail features.
- Do **not** use `#if os(macOS)` alone to get split view — iPad and iPhone use the same
  shell; the system collapses to one column on compact width.
- Use `NavigationStack` only for true single-column flows (onboarding, login) without a
  persistent sidebar.

### Layout rules

- No fixed screen widths, `UIScreen`/`NSScreen`, or device-model checks.
- Use `List`, `Form`, stacks, and `ViewThatFits` before custom geometry.
- Apply `.featureScreenFrame()` on non-list states so loading/empty/error center on large
  windows.
- Apply `.featureSidebarColumnWidth()` on sidebar `List` content (iPad regular + Mac).
- Support **Dynamic Type**, **light and dark** (required from day one), portrait/landscape,
  and resizable Mac/iPad windows.

### Input

- **Touch (iPhone/iPad):** 44 pt minimum targets; primary actions in toolbar.
- **Pointer (iPad/Mac):** keep list rows readable; do not shrink below legibility.
- **Keyboard (iPad/Mac):** add shortcuts when a feature has frequent actions (optional v1).

### Verification (agents)

After meaningful UI changes, proof **all** of:

```bash
./bin/lint.sh
./bin/ci.sh
```

`./bin/ci.sh` runs iPhone tests plus **iPad simulator** and **macOS** builds. For layout-heavy
work, also run `./bin/checklist` and note compact + regular + Mac window sizes checked.

Full matrix and finish questions: [`universal-apple-platforms.md`](universal-apple-platforms.md).

## Token map (YAML → SwiftUI)

| YAML key | SwiftUI / API |
| -------- | ------------- |
| `colors.primary` | `Color.accentColor`, `.buttonStyle(.borderedProminent)` |
| `colors.on-surface` | `.foregroundStyle(.primary)` |
| `colors.surface-container-low` | grouped list / subtle panel background |
| `colors.error` | `Button(..., role: .destructive)`, error labels |
| `typography.body-large` | `.font(.body)` / list primary text |
| `typography.title-medium` | `.font(.headline)` / section titles |
| `typography.label-large` | toolbar `Label` text |
| `rounded.sm` / `rounded.md` | 8 px / 12 px custom containers (use `px` in YAML only) |
| `spacing.sm` / `md` / `lg` | `.padding(8)`, `.padding(16)`, `.padding(24)` |
| `spacing.row-min` | min 44 pt touch targets on iOS |
| `components.button-filled` | `.buttonStyle(.borderedProminent)` |
| `components.button-outlined` | `.buttonStyle(.bordered)` |
| `components.list-row` | `NavigationLink` in `List` |
| `components.empty-state` | `ContentUnavailableView` |
| `components.error-banner` | `ContentUnavailableView` + Retry |

## Rules

- Read [`../DESIGN.md`](../DESIGN.md) before adding colors, spacing roles, or shared components.
- Prefer `Theme` / environment: `@Environment(\.colorScheme)`, `@Environment(\.dynamicTypeSize)`.
- No hex literals in view files; named colors only in asset catalog.
- Feature views stay in `Presentation/`; inject feature models from composition root.
- Match [`navigation.md`](navigation.md) for stack vs split; never `NavigationView`.
- State: `@Observable` feature models + `@Bindable` in views — see [`state-management.md`](state-management.md).
- After editing [`../DESIGN.md`](../DESIGN.md), run `./tool/check_design_md.sh` when Node is available.

## Typography

- System text styles only: `.largeTitle` … `.caption2` (see YAML `typography`).
- No per-view `Font.custom` unless product adds bundled fonts to the project.
- Dynamic Type: avoid fixed heights; test **Accessibility Extra Large**.

## Light and dark mode (required from day one)

Ship **both appearances on every new screen** — not a follow-up polish pass.

### Color rules

- Use **semantic** colors only in `Presentation/` and `Shared/Presentation/`:
  `foregroundStyle(.primary)`, `.secondary`, `Color.accentColor`, `List` / `Form` defaults,
  `ContentUnavailableView`, system button styles.
- **Forbidden in views:** `Color.white`, `Color.black`, raw hex, `UIColor` fixed fills,
  images/icons that only work on one background.
- **Asset catalog:** Any custom color gets **Any Appearance + Dark** (or grouped semantic
  names). One-off literals belong in `Assets.xcassets`, not Swift source.
- **Materials:** Prefer `.regularMaterial` / system chrome for sheets and overlays so dark
  mode stays legible.
- **No `#if` on `colorScheme`** unless behavior (not just color) truly differs — e.g. a
  platform-specific control, not “use white text in dark.”

### Previews (required)

Pair each primary `#Preview` with a **dark** canvas using `UniversalPreviewLayouts` and
`.previewDarkAppearance()` on the preview root (see `ItemsView`):

```swift
#Preview("Items — iPhone (Dark)", traits: UniversalPreviewLayouts.iPhonePortrait) {
    ItemsPreviewFactory.view(seedItems: ItemsPreviewFactory.sampleItems)
        .previewDarkAppearance()
}
```

Also spot-check in Simulator: **Settings → Appearance** (or Xcode environment override).

### Verification

- [ ] Light + dark `#Preview` for each new public screen
- [ ] No hardcoded `Color.white` / `Color.black` in feature UI (see `check_common_issues.sh`)
- [ ] Lists, empty, and error states readable in both modes
- [ ] After token changes: `./tool/check_design_md.sh` when Node available

## Color and materials

- Foreground: `.primary`, `.secondary`, `.tertiary` via `foregroundStyle`.
- Accents: `Color.accentColor` — set globally via asset catalog, not per screen.
- Sheets: `.presentationBackground(.regularMaterial)` when custom chrome is needed.

## Spacing and layout

- 8 pt grid: 8, 16, 24, 32; `spacing.xs` (4 pt) only for tight inline groups.
- `List` for navigable collections; `Form` for settings/editing.
- `GeometryReader` only when layout cannot be expressed with stacks and safe areas.
- **Size classes:** use `@Environment(\.horizontalSizeClass)` when compact vs regular
  behavior differs beyond navigation shell wrappers.

| Width context | Typical pattern |
| ------------- | ---------------- |
| Compact width | `NavigationStack`, full-width content |
| Regular width | `NavigationSplitView`, optional column widths |
| macOS window | split view, keyboard shortcuts for common actions when added |

## Standard components

Recipes align with YAML `components` in [`../DESIGN.md`](../DESIGN.md).

### Primary button

```swift
Button("Save") { /* action */ }
    .buttonStyle(.borderedProminent)
```

### Destructive

```swift
Button("Delete", role: .destructive) { /* action */ }
```

### List row (navigable)

```swift
NavigationLink {
    DetailView(...)
} label: {
    Text(title)
}
```

### Loading

```swift
ProgressView()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
```

### Empty state

```swift
ContentUnavailableView("No Items", systemImage: "tray")
```

### Error with retry

```swift
ContentUnavailableView {
    Label("Could Not Load", systemImage: "exclamationmark.triangle")
} description: {
    Text(message)
} actions: {
    Button("Retry") { Task { await model.refresh() } }
}
```

Reference: `ItemsView` state switch.

## Screen state machine (Presentation)

| State | UI | Model duty |
| ----- | --- | ---------- |
| Loading | `ProgressView` | fetch in flight |
| Empty | `ContentUnavailableView` | zero items, optional CTA |
| Failed | error + Retry | `DisplayError` or domain message |
| Content | primary list/form | data ready |
| Disabled | `.disabled(true)` on actions | in-flight mutation |

```swift
@ViewBuilder
private var content: some View {
    switch model.state {
    case .loading: ProgressView()
    case .empty: ContentUnavailableView(...)
    case let .failed(error): /* retry UI */
    case let .content(items): itemsList(items)
    }
}
```

Refresh: `.task { await model.refresh() }`; buttons use `Task { await model.... }`.

## Toolbars and editing

- Add: trailing toolbar, `plus` symbol, `Label("Add …", systemImage: "plus")`.
- Edit: `EditButton()` in `.navigationBarTrailing` on iOS when using `onDelete`.
- macOS: list delete key / context menu where appropriate.

## Forms and input

- `Form` + `TextField` / `Picker`; validation errors inline or in state banner.
- Submit: **Save**, **Create**, **Done** — not vague **OK** on multi-field flows.

## Accessibility

- Visible or `accessibilityLabel` on every control; hints only when outcome is unclear.
- `accessibilityElement(children: .combine)` for related groups.
- `@Environment(\.accessibilityReduceMotion)` before decorative animation.

## Motion

- System transitions; `withAnimation` tied to explicit state changes only.

## Platform conditionals

```swift
#if os(iOS)
ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
#endif
#if os(macOS)
.navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
```

Forbidden: `UIDevice` model checks, duplicate screens per platform, Figma pixel constants in code.

## Previews

Use `UniversalPreviewLayouts` (`Shared/Presentation/UniversalPreviewLayouts.swift`) so canvases
match iPhone, iPad, and Mac without device-specific view forks:

```swift
#Preview("Items — iPhone", traits: UniversalPreviewLayouts.iPhonePortrait) {
    ItemsPreviewFactory.view(seedItems: sampleItems)
}
#Preview("Items — iPad", traits: UniversalPreviewLayouts.iPadRegular) { ... }
#Preview("Items — Mac", traits: UniversalPreviewLayouts.macWindow) { ... }
#Preview("Items — iPhone (Dark)", traits: UniversalPreviewLayouts.iPhonePortrait) {
    ... .previewDarkAppearance()
}
```

In-memory repositories; one preview per public screen **in light and dark** (plus
empty/error variants when useful);
`Preview*` types `@MainActor` when needed. Reference: `ItemsView` previews.

## Anti-patterns

| Avoid | Use instead |
| --- | --- |
| `NavigationView` | `NavigationStack` / `NavigationSplitView` |
| `ObservableObject` / `@Published` | `@Observable` feature models |
| `EnvironmentObject` locator | Constructor injection / `@Environment(Type.self)` |
| Hex in views | Semantic colors + asset catalog |
| `Color.white` / `Color.black` in views | Semantic `foregroundStyle` / asset Any+Dark |
| Light-only UI / single-appearance preview | Light + dark previews; semantic colors |
| Force unwrap in views | `guard`, empty/error state |
| Logic in `body` | Feature model + use cases |
| `print` | `Logger` ([`error-handling.md`](error-handling.md)) |
| MainActor blocking in buttons | `Task { await ... }` |

## UI checklist before handoff

- [ ] Read [`../DESIGN.md`](../DESIGN.md); tokens match implementation
- [ ] Loading, empty, error, content (and disabled if mutations exist)
- [ ] Dynamic Type; **light and dark** `#Preview` + simulator Appearance toggle
- [ ] iPhone + iPad + Mac: `./bin/ci.sh` or `./bin/checklist`
- [ ] `#Preview` + UI tests for critical paths
- [ ] `./bin/lint.sh` (includes layer boundaries for `Features/`)

## Related docs

- [`../DESIGN.md`](../DESIGN.md) — visual brief and agent prompt guide
- [`navigation.md`](navigation.md) — routing shells
- [`universal-apple-platforms.md`](universal-apple-platforms.md)
- [`state-management.md`](state-management.md)
- [`feature-template.md`](feature-template.md) — Presentation section
- [`apple-development-practices.md`](apple-development-practices.md)
