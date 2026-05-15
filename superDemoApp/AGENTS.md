# AI Agents Map for superDemoApp

This source-folder map points to the repo-root agent docs. It keeps local SwiftUI
source rules close to app code without duplicating the full handbook.

Primary map: [`../AGENTS.md`](../AGENTS.md).
Host notes: [`../docs/agent_host_notes.md`](../docs/agent_host_notes.md).

## Core principles

- Clean Architecture with clear layers (Presentation, Domain, Data)
- SwiftUI for UI, Swift Concurrency (async/await, actors) for asynchrony
- Universal app behavior across iOS, iPadOS, and macOS
- Offline-first data strategy powered by SwiftData and background sync
- SwiftUI Observation-first state: local `@State`, `@Observable` feature models, explicit actions
- Protocol-driven Dependency Injection (no global singletons)
- Test-first mindset using the Swift Testing framework
- Minimal, focused changes; small, composable features; feature-first organization

## Quality gate (lint)

From the `superDemoApp/` directory (Xcode project root):

```bash
brew bundle --file Brewfile   # once per machine
./bin/lint.sh                 # required after Swift edits
./bin/ci.sh                   # before merge/PR — lint + build + tests
./bin/format.sh               # optional autocorrect
```

- **SwiftLint:** `superDemoApp/.swiftlint.yml` (strict, SwiftUI/SwiftData/concurrency-focused opt-in rules + custom agent rules).
- **SwiftFormat:** `superDemoApp/.swiftformat`
- **Cursor rules:** repo `.cursor/rules/ios-swift-quality.mdc` (Swift files), `agent-execution-ios.mdc` (always on).

Details: [Code style and conventions](../docs/code-style.md).

## How to work in this project (checklist)

1. Start with a feature: define its Domain (entities + use cases) and State/Event model.
2. Create or extend protocols in Domain; implement repositories and data sources in Data.
3. Wire Presentation (SwiftUI + feature model) to Domain via protocols, not concrete types.
4. Prefer SwiftData for persistence; design for offline-first. Add background sync if remote data is involved.
5. Keep navigation declarative and platform-adaptive; use NavigationSplitView for iPad/Mac sidebar/detail workflows.
6. Add tests for Use Cases and Repositories; add a small preview for each View.
7. Run `./bin/lint.sh` after Swift changes; follow [code style](../docs/code-style.md); avoid third-party dependencies without justification.
8. Update docs if you introduce new architectural patterns or modules.

## Docs index

- [Architecture overview](../docs/architecture.md)
- [Apple development practices](../docs/apple-development-practices.md)
- [Layers and responsibilities](../docs/layers.md)
- [State management (SwiftUI Observation-first)](../docs/state-management.md)
- [Universal Apple platforms and responsive UI](../docs/universal-apple-platforms.md)
- [Offline-first strategy with SwiftData](../docs/offline-first.md)
- [Dependency Injection patterns](../docs/dependency-injection.md)
- [Navigation guidance (iOS, macOS)](../docs/navigation.md)
- [Error handling and logging](../docs/error-handling.md)
- [Testing strategy (Swift Testing)](../docs/testing.md)
- [Code style and conventions](../docs/code-style.md)
- [Module and feature structure](../docs/module-structure.md)
- [Networking & sync guidance](../docs/sync-and-networking.md)
- [Feature scaffolding template](../docs/feature-template.md)
- [AI agent playbook and guardrails](../docs/ai-agent-playbook.md)
- [Commit and PR guidelines](../docs/commit-and-pr-guidelines.md)

## Notes inspired by flutter_bloc_app

- Feature-first directory structure is preferred; each feature owns its View, feature model, state/actions, use cases, and repository abstractions.
- Use Observation-first unidirectional flow: user action in, feature model/use case performs effect, state updates out.
- Repositories isolate the app from persistence and network details; domain logic never depends on UI or frameworks.
- Small, composable widgets (SwiftUI Views) with previews and clear inputs.
- Responsive layouts must handle iPhone, iPad split view/Stage Manager, and Mac windows.

## When in doubt

- Favor clarity over cleverness. Prefer protocol abstractions and explicit dependencies.
- Prefer Apple-native frameworks before dependencies.
- Keep feature models small and focused; move business logic to Use Cases.
- Make offline the default; synchronize opportunistically.
- Add tests alongside new code, especially for Domain and Data layers.
