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
| Persistence | SwiftData; indexes, unique constraints, history, migrations when data evolves |
| Async | Swift Concurrency, structured tasks, actors, Swift 6 strict concurrency |
| Testing | Swift Testing for logic; XCTest/XCUIAutomation for UI/performance |
| System integration | App Intents for stable Shortcuts, Spotlight, Siri, widgets, controls, and Action Button surfaces when useful |
| Diagnostics | `Logger`, OSLog privacy, signposts, Xcode Organizer, Instruments |
| Accessibility | System controls, Dynamic Type, VoiceOver labels/traits, keyboard/pointer support |
| Privacy | Data minimization, `PrivacyInfo.xcprivacy`, required-reason APIs, privacy labels |

## Current Source Anchors

Use Apple docs for version-sensitive APIs before trusting model memory:

- [SwiftUI](https://developer.apple.com/documentation/swiftui) for app structure, navigation, layout, previews, accessibility, and platform integration.
- [Observation](https://developer.apple.com/documentation/observation/observable)
  for `@Observable`; conformance alone is not enough.
- [SwiftData updates](https://developer.apple.com/documentation/updates/swiftdata)
  for indexes, unique constraints, history, custom stores, and inheritance.
- [Adopting strict concurrency in Swift 6 apps](https://developer.apple.com/documentation/Swift/AdoptingSwift6)
  for data-race checks and shared mutable state fixes.
- [Testing](https://developer.apple.com/documentation/xcode/testing) and
  [Swift Testing](https://developer.apple.com/documentation/testing) for the test pyramid,
  parameterized tests, traits, tags, time limits, and parallel execution.
- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
  and [Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass)
  for modern Apple visual treatment.
- [App Intents](https://developer.apple.com/documentation/appintents/appintent)
  and [Siri / Apple Intelligence integration](https://developer.apple.com/documentation/AppIntents/Integrating-actions-with-siri-and-apple-intelligence)
  for system actions and assistant schemas.
- [Required reason APIs](https://developer.apple.com/documentation/BundleResources/describing-use-of-required-reason-api)
  and [TN3183](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest)
  for privacy manifest review.
- [Logging](https://developer.apple.com/documentation/os/logging) and
  [OSLog privacy](https://developer.apple.com/documentation/os/oslogprivacy) for telemetry and redaction.

## Agent Decision Rules

- Choose native Apple API unless repo doc or measured constraint proves it insufficient.
- Keep feature logic testable outside SwiftUI views.
- Prefer one app target and shared SwiftUI code for iOS, iPadOS, and macOS.
- Verify current SDK/API behavior from Apple docs before relying on model memory for new or version-sensitive APIs.
- Add platform-specific branches only for real interaction differences, not device-name convenience.
- Keep user data collection explicit; update privacy docs/review notes when data practice changes.
- Use App Intents only for stable user actions or domain entities that should appear outside the app.
- Treat new capability, entitlement, background mode, keychain, network, or required-reason API use as privacy/security work.
- Prefer standard controls/materials so new OS visual treatment comes from SwiftUI/UIKit/AppKit.

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
- Let standard controls/navigation adopt Liquid Glass automatically. Custom Liquid Glass belongs in controls/navigation layers, not content-card decoration.
- Respect reduced transparency, increased contrast, reduced motion, keyboard, pointer, and VoiceOver states.

## State And Data

- New feature state uses Observation, not Combine-era `ObservableObject`, unless supporting legacy targets.
- Views own local UI state; feature models own screen state and actions; use cases own business rules.
- SwiftData models stay in Data once logic grows; Domain receives pure entities/value objects.
- SwiftData schema changes need migration thinking, in-memory preview/test data, validation, and rollback notes when store compatibility matters.
- Add SwiftData `#Index` / `#Unique` when query speed or integrity is a product invariant; do not rely on UI de-duplication for persisted uniqueness.
- Use SwiftData history or sync queues only when widgets, App Intents, extensions, or offline sync needs it.
- Keep `@Query` for simple local views; move data access behind repositories once business rules, remote data, or tests need control.

## Concurrency And Performance

- UI mutations run on `@MainActor`; non-UI work must not block main thread.
- Avoid heavy work in SwiftUI `body`, computed view properties, and synchronous button handlers.
- Use `.task(id:)` for async loading tied to input changes; handle cancellation and stale results.
- Use actors or isolated services for shared mutable state.
- Treat Swift 6 strict-concurrency diagnostics as design feedback. Fix isolation, `Sendable`, actor boundaries, or ownership before suppressing warnings.
- Avoid detached tasks unless lifetime, cancellation, and error handling are documented.
- Profile jank, hangs, memory, and excessive invalidation with Instruments when code review is not enough.
- Use OSLog signposts when repeated performance questions need stable Instruments marks.

## Testing And Proof

- Prefer Swift Testing for pure logic, use cases, repositories, and feature models.
- Use XCTest UI tests for critical workflows because UI automation still lives there.
- Add parameterized Swift Testing cases for boundary combinations.
- Use Swift Testing traits/tags/time limits for platform, slow, flaky, or environment-dependent cases.
- Swift Testing parallelizes by default; serialize or isolate shared files, stores, clocks, URLProtocol stubs, and global state.
- Run platform build sanity for meaningful UI changes:
  - iPhone simulator
  - iPad simulator
  - macOS destination
- Add screenshots or UI tests when layout behavior, navigation collapse, accessibility, or platform input matters.
- Use sanitizer/test-plan proof for memory, thread, main-thread, or undefined-behavior risks.

## Avoid

- `NavigationView` in new code.
- New `ObservableObject` / `@Published` for iOS 17+ feature state.
- Global `EnvironmentObject` or singleton service locator by default.
- Blocking disk/network/JSON/image work on MainActor.
- Silencing strict-concurrency warnings without an ownership/isolation reason.
- Hard-coded screen sizes, absolute positioning, or iPhone-only layouts.
- Raw `print` logging, broad `try?`, force unwraps, and sensitive data in logs.
- Custom cryptography, entitlement/capability changes, or privacy manifest edits
  without documented product need and release-review impact.
- Third-party state, routing, networking, or persistence libraries without a written tradeoff.
