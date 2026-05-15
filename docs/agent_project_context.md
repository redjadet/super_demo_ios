# Agent Project Context

Machine-readable project facts for agents.

## Current App

- Project: `superDemoApp.xcodeproj`
- Scheme: `superDemoApp`
- App target: `superDemoApp`
- Unit test target: `superDemoAppTests`
- UI test target: `superDemoAppUITests`
- Current source shape: universal SwiftUI + SwiftData template.
- Current persistence model: `Item` in `superDemoApp/Item.swift`.
- Current root view: `ContentView` with a SwiftData `@Query`.
- Current platform settings include iPhone, iPad, and Mac support.

## Preferred Growth Direction

Use feature-first Clean Architecture as app grows:

```text
Presentation -> Domain <- Data
```

- Presentation: SwiftUI views, Observation-first feature models, navigation state, formatting.
- Domain: entities, value objects, use cases, repository protocols, pure Swift.
- Data: SwiftData models, DTOs, mappers, API clients, repository implementations.

## Modern iOS Defaults

- SwiftUI for UI.
- Universal app behavior across iOS, iPadOS, and macOS.
- Swift Concurrency (`async`/`await`, `Task`, actors) for async work.
- SwiftUI Observation for feature state on iOS 17+.
- `@MainActor` for UI-facing observable models and state mutation.
- SwiftData for local persistence when it fits app needs.
- `NavigationStack` / `NavigationSplitView` for declarative navigation.
- Responsive layout must handle compact phone, regular iPad, split view,
  Stage Manager, and resizable Mac windows.
- Swift Testing for new unit/integration tests when target supports it; XCTest for UI tests and existing XCTest coverage.
- App Intents for stable actions/entities that should work through Spotlight,
  Shortcuts, Siri, widgets, controls, or Action Button.
- OSLog for structured diagnostics; avoid `print` as permanent logging.

## Caution Zones

- SwiftData schema changes can break existing stores; document model changes and migration strategy.
- `@Query` is convenient for simple views; move data access behind repositories once feature logic grows.
- Feature models must not become business-logic dumps; move rules to use cases.
- Do not introduce global singletons for services; inject protocols at composition boundaries.
- Avoid third-party dependencies until built-in frameworks are insufficient and tradeoff is documented.
- Do not add broad architecture scaffolding before a feature needs it.
- Do not ship iPhone-only layout assumptions into shared views.
- Do not add App Intents for unstable or internal-only actions.
