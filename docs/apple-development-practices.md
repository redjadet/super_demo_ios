# Apple Development Practices For AI Agents

Use this as the compact decision guide for modern Apple development in this
project. Prefer Apple-native frameworks first; add dependencies only when a
documented product need beats the platform stack.

## Default Stack

| Concern | Default |
| --- | --- |
| UI | SwiftUI |
| Universal layout | `NavigationSplitView`, `NavigationStack`, adaptive containers |
| State | SwiftUI Observation: `@Observable`, `@State`, `@Bindable`, `@Environment(Type.self)` |
| Persistence | SwiftData for app-owned structured data; Core Data only for legacy/interoperability; SQLite only when SQL control is required |
| Async | Swift Concurrency: `async`/`await`, structured tasks, actors |
| Testing | Swift Testing for unit/integration logic; XCTest/XCUIAutomation for UI/performance |
| System integration | App Intents for Shortcuts, Spotlight, Siri, widgets, controls, and Action Button when useful |
| Diagnostics | OSLog, Xcode Organizer, Instruments |
| Accessibility | System controls, Dynamic Type, VoiceOver labels/traits, keyboard/pointer support |
| Privacy | Data minimization, privacy manifests/labels, no sensitive logs |

## Agent Decision Rules

- Choose native Apple API unless repo doc or measured constraint proves it insufficient.
- Keep feature logic testable outside SwiftUI views.
- Prefer one app target and shared SwiftUI code for iOS, iPadOS, and macOS.
- Verify current SDK/API behavior from Apple docs before relying on model memory for new or version-sensitive APIs.
- Add platform-specific branches only for real interaction differences, not device-name convenience.
- Keep user data collection explicit; update privacy docs/review notes when data practice changes.
- Use App Intents only for stable user actions or domain entities that should appear outside the app.

## UI And Layout

Visual consistency and SwiftUI recipes: [`../DESIGN.md`](../DESIGN.md),
[`design_system.md`](design_system.md), [`universal-apple-platforms.md`](universal-apple-platforms.md).

- Build adaptive layouts from the start for **all iPhones, iPads, and Macs**; one codebase.
- Master/detail: `AdaptiveNavigationShell` (`NavigationSplitView`) on every platform.
- Single-column-only flows: `NavigationStack`.
- Reuse shared Presentation helpers; follow the design_system **UI consistency contract**.
- Prefer `ViewThatFits`, `Grid`, lazy grids, stacks, layout priorities, and adaptive frames over fixed widths.
- Validate compact, regular, and Mac window sizes; include Dynamic Type and **light + dark**
  (semantic colors and paired `#Preview`s from the first screen — not a later pass).

## State And Data

- New feature state uses Observation, not Combine-era `ObservableObject`, unless supporting legacy targets.
- Views own local UI state; feature models own screen state and actions; use cases own business rules.
- SwiftData models stay in Data once logic grows; Domain receives pure entities/value objects.
- SwiftData schema changes require migration thinking, in-memory preview/test data, and explicit validation.
- Use SwiftData history or sync queues only when widgets, App Intents, extensions, or offline sync behavior needs it.

## Concurrency And Performance

- UI mutations run on `@MainActor`; non-UI work must not block main thread.
- Avoid heavy work in SwiftUI `body`, computed view properties, and synchronous button handlers.
- Use `.task(id:)` for async loading tied to input changes; handle cancellation and stale results.
- Use actors or isolated services for shared mutable state.
- Profile jank, hangs, memory, and excessive invalidation with Instruments when code review is not enough.

## Testing And Proof

- Prefer Swift Testing for pure logic, use cases, repositories, and feature models.
- Use XCTest UI tests for critical workflows because UI automation still lives there.
- Add parameterized tests for boundary combinations.
- Run platform build sanity for meaningful UI changes:
  - iPhone simulator
  - iPad simulator
  - macOS destination
- Add screenshots or UI tests when layout behavior, navigation collapse, accessibility, or platform input matters.

## Avoid

- `NavigationView` in new code.
- New `ObservableObject` / `@Published` for iOS 17+ feature state.
- Global `EnvironmentObject` or singleton service locator by default.
- Blocking disk/network/JSON/image work on MainActor.
- Hard-coded screen sizes, absolute positioning, or iPhone-only layouts.
- Raw `print` logging, broad `try?`, force unwraps, and sensitive data in logs.
- Third-party state, routing, networking, or persistence libraries without a written tradeoff.
