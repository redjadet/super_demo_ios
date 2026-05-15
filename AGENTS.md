# AGENTS — superDemoApp

**Only `AGENTS.md` in this repo.** Lean map for all agents (Cursor, Codex, others).
Details live in [`docs/`](docs/README.md).

## Authority

This file → `docs/` → source comments when code owns nuance. Done = plan, execute, verify, proof.

## Workspace

| Path | Role |
| ------ | ------ |
| `superDemoApp/` | Git repo root; run `./bin/*` here |
| Parent `super_demo_ios/` | Optional Cursor workspace root |
| `superDemoApp/superDemoApp/` | App Swift sources |

Gitignored: `.cursor/`, `.vscode/`, `tasks/`, `buildServer.json`.

Cursor install, MCP, rules: [`docs/agent_host_notes.md`](docs/agent_host_notes.md),
[`tool/cursor-template/README.md`](tool/cursor-template/README.md).

## Read next (order)

1. [`docs/agent_knowledge_base.md`](docs/agent_knowledge_base.md) — loop, finish gate
2. [`docs/agent_project_context.md`](docs/agent_project_context.md) — project facts
3. [`docs/apple-development-practices.md`](docs/apple-development-practices.md)
4. [`DESIGN.md`](DESIGN.md) + [`docs/design_system.md`](docs/design_system.md) +
   [`docs/universal-apple-platforms.md`](docs/universal-apple-platforms.md) — **required for UI work**
5. [`docs/architecture.md`](docs/architecture.md) + [`docs/layers.md`](docs/layers.md) — **required for `Features/` work**
6. [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md) — commands, proof chooser
7. [`docs/ai_code_review_protocol.md`](docs/ai_code_review_protocol.md)
8. Task docs: [`docs/README.md`](docs/README.md)

## Snapshot

Universal SwiftUI + SwiftData (`superDemoApp.xcodeproj`). **iOS, iPadOS, macOS.**
Growth architecture: `Presentation -> Domain <- Data`. Full facts:
[`docs/agent_project_context.md`](docs/agent_project_context.md).

## Quality (repo root)

```bash
./bin/lint.sh              # after Swift edits
./bin/lint-markdown.sh     # after docs/*.md edits
./bin/ci.sh                # before merge/PR
```

Proof by change type, simulators, CI flags:
[`docs/agents_quick_reference.md`](docs/agents_quick_reference.md),
[`docs/agent_environment_setup.md`](docs/agent_environment_setup.md).

## Swift work

Code under `superDemoApp/superDemoApp/`. After edits: `./bin/lint.sh` (includes layer boundary checks).

**Layered features** use `Features/<Name>/{Presentation,Domain,Data}/` — see
[`docs/feature-template.md`](docs/feature-template.md), [`docs/module-structure.md`](docs/module-structure.md).
Reference layout: `Features/Items/`. Imports in `Features/` enforced by
[`tool/check_layer_boundaries.sh`](tool/check_layer_boundaries.sh).

**Universal UI:** Reuse `Shared/Presentation/AdaptiveNavigationShell.swift` and the
[`docs/design_system.md`](docs/design_system.md) consistency contract — same navigation,
states, toolbars, and layout helpers on every feature. **Light and dark** required from the
first screen (semantic colors; paired `#Preview`s). Proof: `./bin/ci.sh` (iPhone + iPad + Mac).

## Rules & index

- Baseline: [`docs/agent_baseline.md`](docs/agent_baseline.md)
- Preferences: [`docs/agent_preferences.md`](docs/agent_preferences.md)
- Full doc map: [`docs/README.md`](docs/README.md)

## Learned User Preferences

- Terse “caveman” replies unless the user says stop caveman / normal mode.
- No `git commit` or `git push` unless the user explicitly asks.
- Keep this file a lean map (target under ~100 lines); put depth in `docs/` only.
- Prefer strong clean-architecture enforcement (layer checks, `Features/` layout) when adding code.

## Learned Workspace Facts

- Published repo: `https://github.com/redjadet/super_demo_ios` (`superDemoApp/` is the only git root).
- Parent `super_demo_ios/` holds gitignored `.cursor/`, `.vscode/`, `tasks/`, `buildServer.json`.
- Cursor always applies `agents-map.mdc` → `@superDemoApp/AGENTS.md`; rule source in `tool/cursor-template/`.
- Global Apple platform skills are optional; this repo’s `AGENTS.md` and `docs/` override skill defaults.
- Cursor Swift/ObjC editing: `swiftlang.swift-vscode` + SweetPad + `xcode-build-server`; avoid duplicate C/C++ LSP (`cpptools`, `clangd`, `sswg.swift-lang`).
