# AGENTS — superDemoApp

**Only `AGENTS.md` in this repo.** Lean map for Cursor, Codex, and other agents.
All policy depth lives in [`docs/`](docs/README.md).

## Authority

`AGENTS.md` → `docs/` → source comments when code owns nuance.
Done means plan, execute, verify, and report proof.

## Workspace

| Path | Role |
| ------ | ------ |
| `superDemoApp/` | Git root — run `./bin/*` here |
| Parent `super_demo_ios/` | Optional Cursor workspace root |
| `superDemoApp/superDemoApp/` | App Swift sources |

Paths, targets, repo URL: [`docs/agent_project_context.md`](docs/agent_project_context.md).
Cursor rules, MCP, team skills: [`docs/agent_host_notes.md`](docs/agent_host_notes.md),
[`tool/cursor-template/README.md`](tool/cursor-template/README.md),
[`skills-lock.json`](skills-lock.json).

## Read next (order)

1. [`docs/agent_knowledge_base.md`](docs/agent_knowledge_base.md) — loop, finish gate
2. [`docs/agent_project_context.md`](docs/agent_project_context.md) — facts, layout
3. [`docs/apple-development-practices.md`](docs/apple-development-practices.md)
4. UI: [`DESIGN.md`](DESIGN.md), [`docs/design_system.md`](docs/design_system.md),
   [`docs/universal-apple-platforms.md`](docs/universal-apple-platforms.md)
5. `Features/`: [`docs/architecture.md`](docs/architecture.md),
   [`docs/layers.md`](docs/layers.md)
6. [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md) — commands, proof
7. [`docs/ai_code_review_protocol.md`](docs/ai_code_review_protocol.md)
8. Full index: [`docs/README.md`](docs/README.md)

## Route by change type

| Change | Start here |
| ------ | ------------ |
| Any Swift edit | [`docs/code-style.md`](docs/code-style.md); then `./bin/lint.sh` |
| New / layered feature | [`docs/feature-template.md`](docs/feature-template.md), [`docs/module-structure.md`](docs/module-structure.md) |
| SwiftUI / navigation / light–dark | [`docs/design_system.md`](docs/design_system.md); `Shared/Presentation/AdaptiveNavigationShell.swift` |
| Domain / Data / persistence | [`docs/offline-first.md`](docs/offline-first.md), [`docs/dependency-injection.md`](docs/dependency-injection.md) |
| Tests | [`docs/testing.md`](docs/testing.md) |
| Commit / PR | [`docs/commit-and-pr-guidelines.md`](docs/commit-and-pr-guidelines.md) |
| Proof before merge | [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md); `./bin/ci.sh` |

Non-negotiables: [`docs/agent_baseline.md`](docs/agent_baseline.md).
User/repo conventions: [`docs/agent_preferences.md`](docs/agent_preferences.md).
