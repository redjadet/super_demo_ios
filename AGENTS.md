# AGENTS — superDemoApp

**Map only** — route to `docs/`. No checklists or learned sections here.
Target **≤ 70 lines**. Prefs/facts:
[`docs/agent_preferences.md`](docs/agent_preferences.md),
[`docs/agent_project_context.md`](docs/agent_project_context.md).

## Start

1. Follow [`docs/ai/context_loading.md`](docs/ai/context_loading.md).
2. Non-trivial: [`docs/ai/ai_failure_risks.md`](docs/ai/ai_failure_risks.md) +
   [`docs/agent_kb/agent_safety_contracts.md`](docs/agent_kb/agent_safety_contracts.md).
3. Workflow: [`docs/agent_knowledge_base.md`](docs/agent_knowledge_base.md).

Authority: `AGENTS.md` → `docs/` → source comments. Done = plan, execute, verify,
report proof.

## Workspace

| Path | Role |
| ------ | ------ |
| `superDemoApp/` | Git root — run `./bin/*` here |
| Parent `super_demo_ios/` | Optional Cursor workspace root |
| `superDemoApp/superDemoApp/` | App Swift sources |

Facts / CI: [`docs/agent_project_context.md`](docs/agent_project_context.md).
Host / MCP / skills: [`docs/agent_host_notes.md`](docs/agent_host_notes.md),
[`skills-lock.json`](skills-lock.json).

## Task map

| Change | Start here |
| ------ | ------------ |
| Find any path | [`CODEMAP.md`](CODEMAP.md) |
| ≤15 min architecture tour | [`docs/architecture-tour.md`](docs/architecture-tour.md) |
| Any Swift | [`docs/agent_swift_guards.md`](docs/agent_swift_guards.md); `./bin/verify-swift.sh` |
| Feature / layers | [`docs/feature-template.md`](docs/feature-template.md), [`docs/layers.md`](docs/layers.md), [`docs/modularity.md`](docs/modularity.md) |
| SwiftUI / light–dark | [`DESIGN.md`](DESIGN.md), [`docs/design_system.md`](docs/design_system.md) |
| Domain / Data | [`docs/offline-first.md`](docs/offline-first.md), [`docs/dependency-injection.md`](docs/dependency-injection.md) |
| Tests | [`docs/testing.md`](docs/testing.md) |
| Proof / merge | [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md); `./bin/ci.sh` |
| Engineering scorecard | [`docs/engineering/engineering-quality-scorecard.md`](docs/engineering/engineering-quality-scorecard.md) |
| Agent worktree / maintain | `./bin/agent-worktree`; `./bin/agent-maintain`; [`docs/agent_kb/host-maintenance.md`](docs/agent_kb/host-maintenance.md) |

Baseline: [`docs/agent_baseline.md`](docs/agent_baseline.md). Portfolio:
[`docs/portfolio.md`](docs/portfolio.md). Index: [`docs/README.md`](docs/README.md).

## Finish

1. Validation chooser in [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md).
2. Review: [`docs/ai_code_review_protocol.md`](docs/ai_code_review_protocol.md).
3. Report via finish gate in knowledge base / safety contracts.
