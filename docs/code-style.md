# Code Style And Linting

## Toolchain

| Tool        | Config              | Install                            |
| ----------- | ------------------- | ---------------------------------- |
| SwiftLint   | `.swiftlint.yml`    | `brew bundle --file Brewfile`      |
| SwiftFormat | `.swiftformat`      | same                               |

## Commands (run from `superDemoApp/`)

```bash
./bin/lint.sh      # fast gate — SwiftLint + SwiftFormat
./bin/format.sh    # autocorrect formatting
./bin/checklist-fast # docs/tooling/small Swift sanity
./bin/checklist    # full delivery checklist
./bin/ci.sh        # full gate — lint + build + unit/UI tests
```

## CI and Xcode enforcement

| Layer | What runs |
| --- | --- |
| **GitHub Actions** | `.github/workflows/ci.yml` - Swift lint, Markdown lint, build, test on `macos-15` |
| **Xcode build** | Run Script phase **Lint (SwiftLint & SwiftFormat)** -> `Scripts/xcode-lint.sh` |
| **Local parity** | `./bin/ci.sh` - Swift + Markdown lint, build, tests (`CI=true`) |
| **Fast checklist** | `./bin/checklist-fast` - Markdown/Swift lint, common issue checks, project sanity |
| **Full checklist** | `./bin/checklist` - lint, common issue checks, existing iPhone simulator build/test, iPad/Mac builds |
| **Docs-only** | `./bin/lint-markdown.sh` |

`ENABLE_USER_SCRIPT_SANDBOXING` is **NO** at project level so the lint script can read Swift sources (required for SwiftFormat directory walks).

Strict lint in Xcode builds: set environment `RUN_LINT_STRICT=1` or `CI=true` in the scheme (otherwise missing Homebrew tools log a warning and skip).

`./bin/checklist` uses serial Xcode test flags by default so local runs reuse one
selected simulator instead of spawning parallel cloned simulator workers. Use
`CHECKLIST_ALLOW_PARALLEL_TESTS=1` only when intentionally stress-testing the
parallel XCTest path.

## Swift style

- **Types:** UpperCamelCase (`ItemRepository`, not `itemRepository`).
- **Members:** lowerCamelCase; acronyms like `id`, `url` stay lowercase in names.
- **Line length:** 120 warn / 150 error (see `.swiftlint.yml`).
- **Imports:** SwiftFormat owns import sorting; SwiftLint analyzer owns unused imports.
- **Access:** Prefer `private` / `fileprivate`; widen only when required.
- **Dependencies:** Prefer Apple frameworks and language features over helper libraries.

## SwiftUI State

- Prefer native SwiftUI Observation for iOS 17+: `@Observable` model types owned by `@State`.
- Use `@Bindable` only when a child needs a binding into an `@Observable` model.
- Use `@Environment(Type.self)` for app-wide shared services/configuration, not feature-local state.
- Use `ObservableObject`, `@StateObject`, `@ObservedObject`, and `@EnvironmentObject` only for iOS 16 support or legacy files.
- Pick ownership first, then wrapper: local value = `@State`; parent value mutation = `@Binding`; reference feature model = `@Observable` + `@State`.

## SwiftUI

- Build universal SwiftUI: iPhone, iPadOS split view/Stage Manager, and resizable Mac windows.
- Use `NavigationStack` for single-column flows and `NavigationSplitView` for iPad/Mac sidebar/detail workflows; never use `NavigationView`.
- Extract subviews when `body` grows; keep side effects in feature model or use case.
- `@State` / `@Binding` only for local UI state; feature state in Observation models.
- Every new screen gets `#Preview` in **light and dark** with realistic or in-memory data
  (`UniversalPreviewLayouts` + `.dark` trait — see [`design_system.md`](design_system.md)).
- Avoid hard-coded screen sizes, absolute positions, and device-name layout branching.
- Prefer adaptive containers (`ViewThatFits`, `Grid`, lazy grids, stacks, split views) and platform-native toolbar/menu placements.

## Concurrency (matches Xcode build settings)

- Default isolation is **MainActor** — UI and SwiftData on main actor unless explicitly backgrounded.
- Use `async`/`await`; prefer structured concurrency (`async let`, task groups) over unstructured fire-and-forget.
- Pass `Sendable` models across actors; avoid capturing non-Sendable types in `@Sendable` closures.
- Avoid `Task.detached`; use structured tasks, injected services, or actor-owned tasks.
- Prefer `@MainActor` or `MainActor.run` over `DispatchQueue.main.async`.

## SwiftData

- `@Model` types: `final class` with explicit initializer.
- Repository layer owns fetch/save; views do not embed query logic beyond simple `@Query` in thin shells.

## Dependencies

Add third-party packages only when:

- native framework is insufficient,
- dependency is maintained,
- license is acceptable,
- privacy manifest / data collection impact is understood,
- added risk is documented,
- validation still runs locally.

## Errors and logging

- No `try!` or force unwrap in new code.
- Replace `fatalError` in recoverable paths with thrown errors or user-visible failure state.
- Use `import os` and `Logger(subsystem:category:)` instead of `print()`.

## Custom SwiftLint rules

| Rule                      | Intent                         |
| ------------------------- | ------------------------------ |
| `no_navigation_view`      | Deprecated API guard           |
| `no_force_try`            | Ban `try!`                     |
| `no_print_debug`          | Ban `print()`                  |
| `no_task_detached`        | Prefer structured concurrency  |
| `no_dispatch_main_async`  | Prefer MainActor isolation     |
| `no_screen_bounds_layout` | Ban screen-size layout hacks   |
| `no_uiapplication_shared` | Protect universal app code     |
| `swiftdata_model_final`   | `@Model` must be `final class` |

## High-signal SwiftLint policy

Enabled opt-in rules prioritize issues AI agents commonly miss:

- Safety: force unwraps, IUOs, force tries, identical operands, unavailable functions.
- Concurrency: async without await, incompatible concurrency annotations,
  unhandled throwing tasks.
- SwiftUI/accessibility: image labels, button traits, private state,
  no Interface Builder.
- Tests: balanced XCTest lifecycle, no empty tests, no focused/pending tests,
  final test cases, test access control.
- Maintainability/performance: optional collections, default-parameter order,
  key paths, `reduce(into:)`, shorthand optional binding, sorted first/last.

## Agent checklist

1. Read repo-root [`AGENTS.md`](../AGENTS.md), then [`agent_baseline.md`](agent_baseline.md).
2. Implement smallest change in the right layer.
3. `./bin/checklist-fast` for narrow work or `./bin/checklist` for full delivery proof.
4. Add/update tests and previews for new UI or domain logic.
