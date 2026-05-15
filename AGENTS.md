# AGENTS - superDemoApp Map

Map only. Repo docs under `docs/` are system of record.

## Authority

Priority: this map -> repo docs -> source-folder maps -> source comments only
when code owns nuance. Done = Plan, Execute, Verify, Report proof.

## Start

1. `AGENTS.md`
2. [`docs/agent_knowledge_base.md`](docs/agent_knowledge_base.md)
3. [`docs/apple-development-practices.md`](docs/apple-development-practices.md)
4. [`docs/ai_code_review_protocol.md`](docs/ai_code_review_protocol.md)
5. [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md)
6. task docs from [`docs/README.md`](docs/README.md)

## Snapshot

Native universal SwiftUI app in `superDemoApp.xcodeproj`. Required product
surface: iOS, iPadOS, and macOS. Current app target uses SwiftUI and SwiftData
(`Item`, `ContentView`, `ModelContainer`). Test targets exist for unit and UI
tests.

Preferred architecture for growth: feature-first Clean Architecture:
`Presentation -> Domain <- Data`; SwiftUI views, Observation-first feature
models, async use cases, protocol-driven repositories, SwiftData-backed local
persistence.

## Loop

Plan once -> execute end-to-end -> verify -> report proof. Ask only blockers:
credentials/tooling, unsafe ambiguity below 95% confident, user-owned choice.
Non-trivial work: local `tasks/codex/todo.md` (gitignored), context ladder,
one observe/revise loop.

## Quality Gate

From repo root:

```bash
brew bundle --file Brewfile   # SwiftLint + SwiftFormat
./bin/lint.sh                 # after Swift edits
./bin/lint-markdown.sh        # after docs/*.md edits
./bin/ci.sh                   # before merge/PR — Swift + Markdown lint, build, tests
```

Use `./bin/format.sh` for safe Swift formatting when needed.

## Map

- Harness: [`docs/agent_knowledge_base.md`](docs/agent_knowledge_base.md)
- Project context: [`docs/agent_project_context.md`](docs/agent_project_context.md)
- Environment setup: [`docs/agent_environment_setup.md`](docs/agent_environment_setup.md)
- Host notes: [`docs/agent_host_notes.md`](docs/agent_host_notes.md)
- Review: [`docs/ai_code_review_protocol.md`](docs/ai_code_review_protocol.md)
- Commands: [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md)
- Docs index: [`docs/README.md`](docs/README.md)
- Apple practices: [`docs/apple-development-practices.md`](docs/apple-development-practices.md)
- Architecture: [`docs/architecture.md`](docs/architecture.md), [`docs/layers.md`](docs/layers.md)
- State: [`docs/state-management.md`](docs/state-management.md) (SwiftUI Observation-first)
- Universal UI: [`docs/universal-apple-platforms.md`](docs/universal-apple-platforms.md)
- Persistence/sync: [`docs/offline-first.md`](docs/offline-first.md), [`docs/sync-and-networking.md`](docs/sync-and-networking.md)
- DI/navigation: [`docs/dependency-injection.md`](docs/dependency-injection.md), [`docs/navigation.md`](docs/navigation.md)
- Reliability/quality: [`docs/error-handling.md`](docs/error-handling.md), [`docs/testing.md`](docs/testing.md), [`docs/code-style.md`](docs/code-style.md)
- Feature structure: [`docs/module-structure.md`](docs/module-structure.md), [`docs/feature-template.md`](docs/feature-template.md)
- Agent playbook: [`docs/ai-agent-playbook.md`](docs/ai-agent-playbook.md)
- Commit/PR: [`docs/commit-and-pr-guidelines.md`](docs/commit-and-pr-guidelines.md)
- Checklists: `./bin/checklist-fast`, `./bin/checklist` (see [`docs/README.md`](docs/README.md))

## Must Keep

- Smallest reversible change; every changed line traces to request or required validation/doc update.
- UI stays SwiftUI-first; no UIKit bridge unless native SwiftUI cannot meet need.
- UI must be responsive across iPhone, iPad, Mac windows, orientations, Dynamic Type, touch, pointer, and keyboard.
- Use Apple-native frameworks first: SwiftUI, Observation, SwiftData, Swift Concurrency, Swift Testing, App Intents when appropriate.
- Domain has no SwiftUI, SwiftData, URLSession, or platform UI dependencies.
- Data owns persistence/network DTO mapping; repositories hide storage and transport.
- Async work uses Swift Concurrency; isolate mutable shared state with `@MainActor` or actors.
- SwiftData model changes need migration thinking, preview fixture update, and focused persistence tests.
- New user-facing flows need accessibility labels/traits, Dynamic Type sanity, dark/light mode check, and critical UI test when workflow matters.
- Repeated failure => add repo capability, not longer prompt.

## Learned Workspace Facts

- When Cursor opens the parent `super_demo_ios` folder, Xcode MCP and
  workspace maps live in [`../../AGENTS.md`](../../AGENTS.md) and
  [`.cursor/mcp.json`](../../.cursor/mcp.json) (outside this git repo).
