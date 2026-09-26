# Agent Project Context

Machine-readable project facts for agents.

## Repository

- Published: `https://github.com/redjadet/super_demo_ios` (`superDemoApp/` is the only git root).
- Parent folder `super_demo_ios/` may hold gitignored `.cursor/`, `.vscode/`, `tasks/`,
  `buildServer.json`, `.agents/` (skills install target).
- GitHub Actions and local pre-merge proof: `./bin/ci.sh` (see
  [`agents_quick_reference.md`](agents_quick_reference.md)).

## CI and repo tooling

- **Local toolchain (README badges):** Xcode **27.0**, Swift **6.4**, iOS SDK **27**.
- **GitHub Actions** runs on `xcode-27`. `tool/select_xcode.sh` picks the **newest
  released** Xcode ≥ 27 (GM build preferred; seed/beta only if no release qualifies —
  currently **27.1** on the image). iPhone sims use the newest runtime shipping with
  that Xcode (iOS 27). Escape: `runs-on: macos-26` + `SUPER_DEMO_XCODE_MIN_VERSION=26.5`
  (typically 26.6). Local picks the newest install (seed OK) for README Xcode 27.
- `fastlane/README.md` is auto-generated and gitignored; markdownlint skips
  `fastlane/**` in CI (`.markdownlintignore`, `bin/lint-markdown.sh`). For local
  IDE lint on that file, `fastlane/.markdownlint.json` disables MD003/MD041.
- Normal app runs use live HTTP to JSONPlaceholder; UI tests pass `-UITesting` so
  Production Readiness and Feed use sample data only — [`sync-and-networking.md`](sync-and-networking.md),
  [`testing.md`](testing.md).

## Shipped features (current)

- `Features/Items/` — SwiftData reference slice; cancel-safe refresh lifecycle.
- `Features/Feed/` — JSONPlaceholder + read-through cache with explicit stale UI;
  `RefreshFeedUseCase` only.
- `Features/ProductionReadiness/` — dashboard, shared networking, UIKit showcase.
- Deep links: `superdemo://dashboard|/risks|/feed|/items` via `AppNavigation`.
- Diagnostics: `ReleaseDiagnostics` + `OSLogCrashMonitor`; ModelContainer
  recovery on store failure (delete + recreate disk store, then in-memory).
- Reviewer path: [`portfolio.md`](portfolio.md).

## Bash scripts (`set -u`)

- Optional xcodebuild flag arrays stay **unset** when empty (not `=()`).
- Expand with `${VAR+"${VAR[@]}"}` in `bin/ci.sh`, `bin/ci-platform-builds.sh`,
  `bin/checklist`; flags from `tool/xcodebuild_sandbox_flags.sh`.

## Workspace layout

| Path | Role |
| ------ | ------ |
| `superDemoApp/` | Git root; run `./bin/*` and `./tool/*` here |
| `super_demo_ios/` (parent) | Optional Cursor workspace root |
| `superDemoApp/superDemoApp/` | App Swift sources |
| `superDemoApp/superDemoAppTests/` | Unit tests |
| `superDemoApp/superDemoAppUITests/` | UI tests |
| `superDemoApp/Features/` | Layered features (`Presentation` / `Domain` / `Data`) |
| `superDemoApp/Shared/` | Cross-feature presentation helpers |

## Current App

- Project: `superDemoApp.xcodeproj`
- Scheme: `superDemoApp`
- App target: `superDemoApp`
- Unit test target: `superDemoAppTests`
- UI test target: `superDemoAppUITests`
- Current source shape: universal SwiftUI + SwiftData with layered reference feature.
- Reference feature: `Features/Items/{Presentation,Domain,Data}/` (copy this layout).
- Persistence model: `Features/Items/Data/Item.swift` (`@Model`).
- Root UI: `App/AppRootView.swift` (`TabView`: Dashboard / Items / Feed);
  composition in `App/*Composition.swift`.
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

Use [`apple-development-practices.md`](apple-development-practices.md) as the
modern Apple defaults owner. Project-specific short form:

- SwiftUI + Observation + SwiftData + Swift Concurrency.
- `NavigationStack` / `NavigationSplitView`; responsive iPhone, iPad, Stage
  Manager, and Mac windows.
- Swift Testing for new logic tests; XCTest for UI and existing coverage.
- App Intents only for stable domain actions/entities.
- `Logger` / OSLog; privacy manifest and required-reason API review when code or
  dependencies touch covered APIs.

## Caution Zones

- SwiftData schema changes can break existing stores; document model changes and migration strategy.
- `@Query` is convenient for simple views; move data access behind repositories once feature logic grows.
- Feature models must not become business-logic dumps; move rules to use cases.
- Do not introduce global singletons for services; inject protocols at composition boundaries.
- Avoid third-party dependencies until built-in frameworks are insufficient and tradeoff is documented.
- Do not add broad architecture scaffolding before a feature needs it.
- Do not ship iPhone-only layout assumptions into shared views.
- Do not add App Intents for unstable or internal-only actions.
- Do not suppress concurrency/sendability diagnostics or add entitlements,
  background modes, keychain groups, tracking, required-reason APIs, or sensitive
  logging without owner docs and release impact.
