# AGENTS — superDemoApp

**Map only** — route to `docs/` for policy, style, and feature detail. Do not add
checklists, long bullets, or implementation notes here.

**Only `AGENTS.md` in this repo.** For Cursor, Codex, and other agents.
Target **~70 lines**; if content needs explanation, put it in `docs/`.

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
6. [`docs/agent_swift_guards.md`](docs/agent_swift_guards.md) — indent, lint, concurrency pitfalls
7. [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md) — commands, proof
8. [`docs/ai_code_review_protocol.md`](docs/ai_code_review_protocol.md)
9. Full index: [`docs/README.md`](docs/README.md)

## Route by change type

| Change | Start here |
| ------ | ------------ |
| Any Swift edit | [`docs/agent_swift_guards.md`](docs/agent_swift_guards.md), [`docs/code-style.md`](docs/code-style.md); `./bin/verify-swift.sh` |
| New / layered feature | [`docs/feature-template.md`](docs/feature-template.md), [`docs/module-structure.md`](docs/module-structure.md) |
| SwiftUI / navigation / light–dark | [`docs/design_system.md`](docs/design_system.md); `Shared/Presentation/AdaptiveNavigationShell.swift` |
| Fast feedback / device risk | [`docs/development-feedback-loop.md`](docs/development-feedback-loop.md) |
| Domain / Data / persistence | [`docs/offline-first.md`](docs/offline-first.md), [`docs/dependency-injection.md`](docs/dependency-injection.md) |
| Tests | [`docs/testing.md`](docs/testing.md) |
| Commit / PR | [`docs/commit-and-pr-guidelines.md`](docs/commit-and-pr-guidelines.md) |
| Proof before merge | [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md); `./bin/ci.sh` |

Non-negotiables: [`docs/agent_baseline.md`](docs/agent_baseline.md).
Standing preferences & durable facts: [`docs/agent_preferences.md`](docs/agent_preferences.md),
[`docs/agent_project_context.md`](docs/agent_project_context.md).
Shipped-feature tour: [`docs/portfolio.md`](docs/portfolio.md).
