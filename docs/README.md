# Documentation Index

Source-of-truth docs for `superDemoApp`.

## Start Here

- **Portfolio / reviewers:** [`portfolio.md`](portfolio.md) (+ [`../README.md`](../README.md) Portfolio section).
- Agent map (lean links only; detail in `docs/`): [`../AGENTS.md`](../AGENTS.md)
- AI routing (`docs/ai/`): [`ai/README.md`](ai/README.md) —
  [`ai/context_loading.md`](ai/context_loading.md),
  [`ai/ai_failure_risks.md`](ai/ai_failure_risks.md)
- AI agent harness: [`agent_knowledge_base.md`](agent_knowledge_base.md)
- Safety contracts: [`agent_kb/agent_safety_contracts.md`](agent_kb/agent_safety_contracts.md)
- Agent harness shards: [`agent_kb/adaptive_execution.md`](agent_kb/adaptive_execution.md),
  [`agent_kb/legibility_and_finish_gate.md`](agent_kb/legibility_and_finish_gate.md),
  [`agent_kb/memory_and_context_ladder.md`](agent_kb/memory_and_context_ladder.md),
  [`agent_kb/tool_orchestration.md`](agent_kb/tool_orchestration.md)
- Agent baseline rules: [`agent_baseline.md`](agent_baseline.md)
- Agent Swift guards (indent, lint, concurrency): [`agent_swift_guards.md`](agent_swift_guards.md)
- Agent preferences: [`agent_preferences.md`](agent_preferences.md)
- Commands: [`agents_quick_reference.md`](agents_quick_reference.md)
- Review gate: [`ai_code_review_protocol.md`](ai_code_review_protocol.md)
- Project context: [`agent_project_context.md`](agent_project_context.md)
- Environment setup: [`agent_environment_setup.md`](agent_environment_setup.md)
- Host notes: [`agent_host_notes.md`](agent_host_notes.md) (Cursor MCP, team skills lockfile)
- Cursor setup: [`../tool/cursor-template/README.md`](../tool/cursor-template/README.md)
- Team skills pin: [`../skills-lock.json`](../skills-lock.json)
- Apple development practices: [`apple-development-practices.md`](apple-development-practices.md)
- Development feedback loop: [`development-feedback-loop.md`](development-feedback-loop.md)
- Validation routing: [`engineering/validation_routing_fast_vs_full.md`](engineering/validation_routing_fast_vs_full.md)
- Release checklist: [`release-checklist.md`](release-checklist.md)
- TestFlight release notes: [`release-notes/testflight.md`](release-notes/testflight.md);
  App Store: [`release-notes/app-store.md`](release-notes/app-store.md)
- Production risks: [`production-risks.md`](production-risks.md)

## Design (SwiftUI)

- Design principles: [`../DESIGN.md`](../DESIGN.md)
- Design system (tokens, components, consistency, light/dark): [`design_system.md`](design_system.md)
- Universal iPhone / iPad / Mac: [`universal-apple-platforms.md`](universal-apple-platforms.md)

## iOS Engineering

- Architecture: [`architecture.md`](architecture.md)
- Apple development practices: [`apple-development-practices.md`](apple-development-practices.md)
- Layers: [`layers.md`](layers.md)
- State management: [`state-management.md`](state-management.md) - SwiftUI Observation-first for iOS 17+
- Universal Apple platforms: [`universal-apple-platforms.md`](universal-apple-platforms.md)
- Offline-first and SwiftData: [`offline-first.md`](offline-first.md)
- Dependency injection: [`dependency-injection.md`](dependency-injection.md)
- Navigation: [`navigation.md`](navigation.md)
- Error handling and logging: [`error-handling.md`](error-handling.md)
- Testing: [`testing.md`](testing.md)
- Development feedback loop: [`development-feedback-loop.md`](development-feedback-loop.md)
- Code style: [`code-style.md`](code-style.md)
- Module structure: [`module-structure.md`](module-structure.md)
- Sync and networking: [`sync-and-networking.md`](sync-and-networking.md)
- Feature template: [`feature-template.md`](feature-template.md)
- AI agent playbook: [`ai-agent-playbook.md`](ai-agent-playbook.md)
- Commit and PR guidelines: [`commit-and-pr-guidelines.md`](commit-and-pr-guidelines.md)
- Production readiness dashboard: [`../superDemoApp/Features/ProductionReadiness/`](../superDemoApp/Features/ProductionReadiness/)

## Validation

- Fast local sanity: `./bin/checklist-fast`
- Full delivery gate: `./bin/checklist`
- CI parity (lint + iPhone test + iPad/Mac builds): `./bin/ci.sh`
- Fast vs full routing:
  [`engineering/validation_routing_fast_vs_full.md`](engineering/validation_routing_fast_vs_full.md)
- Cursor rules install: `./tool/install-cursor-rules.sh`
- Team Apple skills restore: `npx skills experimental_install -y` (from git root; see [`agent_host_notes.md`](agent_host_notes.md))

## History

- Plans: [`plans/README.md`](plans/README.md)
- Changes: [`changes/README.md`](changes/README.md)
- Audits: [`audits/README.md`](audits/README.md)
