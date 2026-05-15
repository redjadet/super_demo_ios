# AGENTS — superDemoApp (Codex, Cursor, and other agents)

**This is the only `AGENTS.md` for this project.** Repo docs under `docs/` are the
system of record for detail.

## Workspace layout

| Path | Role |
|------|------|
| `superDemoApp/` | **Git repo root** — open here or `superDemoApp.xcodeproj` for app work |
| Parent `super_demo_ios/` | Optional Cursor workspace root; not in git |
| `superDemoApp/superDemoApp/` | App Swift sources (`ContentView.swift`, `Item.swift`, entry) |

Gitignored local-only (never commit): `.cursor/`, `.vscode/`, `tasks/`, `buildServer.json`.

When the editor workspace root is the parent folder, Cursor MCP and rules live in
`../.cursor/mcp.json` and `../.cursor/rules/` (Xcode 26.3+ Intelligence MCP;
keep `superDemoApp.xcodeproj` open in Xcode).

## Authority

Priority: this file → repo `docs/` → source comments only when code owns nuance.
Done = Plan, Execute, Verify, Report proof.

## Start

1. This `AGENTS.md` (repo root)
2. [`docs/agent_knowledge_base.md`](docs/agent_knowledge_base.md)
3. [`docs/apple-development-practices.md`](docs/apple-development-practices.md)
4. [`docs/ai_code_review_protocol.md`](docs/ai_code_review_protocol.md)
5. [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md)
6. Task docs from [`docs/README.md`](docs/README.md)

## Snapshot

Native universal SwiftUI app in `superDemoApp.xcodeproj`. Required product surface:
iOS, iPadOS, and macOS. Current app target uses SwiftUI and SwiftData (`Item`,
`ContentView`, `ModelContainer`). Test targets exist for unit and UI tests.

Preferred architecture for growth: feature-first Clean Architecture:
`Presentation -> Domain <- Data`; SwiftUI views, Observation-first feature models,
async use cases, protocol-driven repositories, SwiftData-backed local persistence.

## Loop

Plan once → execute end-to-end → verify → report proof. Ask only blockers:
credentials/tooling, unsafe ambiguity below 95% confident, user-owned choice.

Non-trivial work: local `tasks/codex/todo.md` (gitignored), context ladder, one
observe/revise loop.

## Quality gate

From **repo root** (`superDemoApp/`):

```bash
brew bundle --file Brewfile   # SwiftLint + SwiftFormat
./bin/lint.sh                 # after Swift edits
./bin/lint-markdown.sh        # after docs/*.md edits
./bin/ci.sh                   # before merge/PR — lint, build, tests
```

Use `./bin/format.sh` for safe Swift formatting when needed. Narrow delivery:
`./bin/checklist-fast`. Full proof: `./bin/checklist`.

Default iOS simulator: **iPhone 17** — see [`docs/agent_environment_setup.md`](docs/agent_environment_setup.md).

## Editing Swift (`superDemoApp/superDemoApp/`)

1. Read this file and the task doc under `docs/`.
2. `./bin/lint.sh` after Swift edits; `./bin/checklist-fast` or `./bin/checklist` before handoff.
3. Match neighbors (`ContentView.swift`, `Item.swift`, app entry). SwiftLint:
   [`.swiftlint.yml`](.swiftlint.yml). SwiftFormat: [`.swiftformat`](.swiftformat).
   Style: [`docs/code-style.md`](docs/code-style.md).

Feature work: [`docs/feature-template.md`](docs/feature-template.md),
[`docs/module-structure.md`](docs/module-structure.md),
[`docs/navigation.md`](docs/navigation.md).

## Map

- Harness: [`docs/agent_knowledge_base.md`](docs/agent_knowledge_base.md)
- Project context: [`docs/agent_project_context.md`](docs/agent_project_context.md)
- Environment: [`docs/agent_environment_setup.md`](docs/agent_environment_setup.md)
- Host notes (Codex/Cursor): [`docs/agent_host_notes.md`](docs/agent_host_notes.md)
- Review: [`docs/ai_code_review_protocol.md`](docs/ai_code_review_protocol.md)
- Commands: [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md)
- Docs index: [`docs/README.md`](docs/README.md)
- Apple practices: [`docs/apple-development-practices.md`](docs/apple-development-practices.md)
- Architecture: [`docs/architecture.md`](docs/architecture.md), [`docs/layers.md`](docs/layers.md)
- State: [`docs/state-management.md`](docs/state-management.md)
- Universal UI: [`docs/universal-apple-platforms.md`](docs/universal-apple-platforms.md)
- Persistence/sync: [`docs/offline-first.md`](docs/offline-first.md), [`docs/sync-and-networking.md`](docs/sync-and-networking.md)
- DI/navigation: [`docs/dependency-injection.md`](docs/dependency-injection.md), [`docs/navigation.md`](docs/navigation.md)
- Reliability/quality: [`docs/error-handling.md`](docs/error-handling.md), [`docs/testing.md`](docs/testing.md), [`docs/code-style.md`](docs/code-style.md)
- Playbook: [`docs/ai-agent-playbook.md`](docs/ai-agent-playbook.md)
- Commit/PR: [`docs/commit-and-pr-guidelines.md`](docs/commit-and-pr-guidelines.md)

## Must keep

- Smallest reversible change; every changed line traces to request or required validation/doc update.
- UI stays SwiftUI-first; no UIKit bridge unless native SwiftUI cannot meet the need.
- UI responsive across iPhone, iPad, Mac windows, orientations, Dynamic Type, touch, pointer, keyboard.
- Apple-native first: SwiftUI, Observation, SwiftData, Swift Concurrency, Swift Testing, App Intents when appropriate.
- Domain has no SwiftUI, SwiftData, URLSession, or platform UI dependencies.
- Data owns persistence/network DTO mapping; repositories hide storage and transport.
- Async work uses Swift Concurrency; isolate mutable shared state with `@MainActor` or actors.
- SwiftData model changes need migration thinking, preview fixture update, and focused persistence tests.
- New user-facing flows need accessibility, Dynamic Type, dark/light sanity, and critical UI tests when workflows matter.
- Repeated failure → add repo capability, not a longer prompt.

## Learned preferences

- Terse “caveman” replies unless the user says stop caveman / normal mode.
- No `git commit` or `git push` unless the user explicitly asks.
