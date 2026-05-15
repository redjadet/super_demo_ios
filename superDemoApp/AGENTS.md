# AI Agents Map — `superDemoApp/` source

Thin map beside Swift sources. **Read [`../AGENTS.md`](../AGENTS.md) first** for the full
harness (authority, loop, Must Keep, doc map).

Also: [`../docs/README.md`](../docs/README.md) ·
[`../docs/agent_host_notes.md`](../docs/agent_host_notes.md) ·
[`../docs/ai-agent-playbook.md`](../docs/ai-agent-playbook.md)

## When editing Swift here

1. Read [`../AGENTS.md`](../AGENTS.md) and the task doc under `../docs/`.
2. From repo root (`superDemoApp/`): `./bin/lint.sh` after Swift edits;
   `./bin/checklist-fast` for narrow work or `./bin/checklist` before delivery.
3. Match patterns in neighboring files (`ContentView.swift`, `Item.swift`, app entry).

## Quality gate (repo root)

```bash
brew bundle --file Brewfile   # once per machine
./bin/lint.sh                 # after Swift edits
./bin/ci.sh                   # before merge/PR
./bin/format.sh               # optional autocorrect
```

- **SwiftLint:** [`../.swiftlint.yml`](../.swiftlint.yml) (strict + SwiftUI/SwiftData rules)
- **SwiftFormat:** [`../.swiftformat`](../.swiftformat)
- **Details:** [`../docs/code-style.md`](../docs/code-style.md)
- **Cursor rules** (parent workspace, not in this git repo):
  [`../../.cursor/rules/ios-swift-quality.mdc`](../../.cursor/rules/ios-swift-quality.mdc),
  [`../../.cursor/rules/agent-execution-ios.mdc`](../../.cursor/rules/agent-execution-ios.mdc)

## Core principles (source-adjacent)

- Clean Architecture: Presentation → Domain ← Data; feature-first folders as app grows.
- SwiftUI + Observation-first (`@Observable` feature models); Swift Concurrency for async work.
- Universal: iOS, iPadOS, macOS — responsive layouts, Dynamic Type, pointer/keyboard.
- Offline-first with SwiftData; sync only when product needs remote data.
- Protocol-driven DI — no global singletons; Domain has no SwiftUI/SwiftData/URLSession.
- Test-first (Swift Testing); smallest reversible change; previews for new Views.

## Feature workflow

1. Define Domain (entities, use cases, state/events) — see [`../docs/feature-template.md`](../docs/feature-template.md).
2. Protocols in Domain; repositories and DTO mapping in Data.
3. Presentation wires to Domain via protocols, not concrete types.
4. Prefer SwiftData; design offline-first; add sync only if required.
5. Declarative navigation — `NavigationSplitView` on iPad/Mac — see [`../docs/navigation.md`](../docs/navigation.md).
6. Tests for use cases/repositories; preview per View; accessibility on custom controls.
7. `./bin/lint.sh`; follow [`../docs/code-style.md`](../docs/code-style.md); avoid new dependencies without justification.
8. Update docs when introducing new patterns — [`../docs/module-structure.md`](../docs/module-structure.md).

## Pattern reminders (feature-first / unidirectional)

- Each feature owns View, feature model, actions, use cases, repository protocols.
- Flow: user action → feature model/use case → state update (no business logic in Views).
- Repositories hide persistence and network; Domain stays framework-free.
- Composable Views with clear inputs; support iPhone, iPad split/Stage Manager, Mac windows.

## When in doubt

- Clarity over cleverness; Apple-native APIs before dependencies.
- Business logic in use cases, not feature models or Views.
- Offline default; sync opportunistically.
- [`../docs/ai-agent-playbook.md`](../docs/ai-agent-playbook.md) ·
  [`../docs/commit-and-pr-guidelines.md`](../docs/commit-and-pr-guidelines.md)

## Learned Workspace Facts

- Cursor may open parent `super_demo_ios/`; Xcode MCP and workspace maps are in
  [`../../AGENTS.md`](../../AGENTS.md) and [`../../.cursor/mcp.json`](../../.cursor/mcp.json)
  (outside this git repo).
