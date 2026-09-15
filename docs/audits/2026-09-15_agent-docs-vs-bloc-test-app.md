# Audit — Agent docs vs bloc_test_app (2026-09-15)

## Context

Compare AI-harness docs in `bloc_test_app/flutter_bloc_app` with `superDemoApp`
and select minimal iOS-adapted patterns. Plan:
[`../plans/2026-09-15_agent-docs-from-bloc-test-app.md`](../plans/2026-09-15_agent-docs-from-bloc-test-app.md).

## Evidence

| Repo | SHA |
| --- | --- |
| Destination `superDemoApp` | `c6e38cfe2f3ebd097301e2c8076c32d0144c7e9b` |
| Source `flutter_bloc_app` | `f0e883cfe048bab19f797fdf7ccb0c73e8280234` |

### Inspected (source)

- `AGENTS.md`, `docs/ai/context_loading.md`, `docs/ai/ai_failure_risks.md`,
  `docs/ai/governance.md`, `docs/ai/skill_routing.md`,
  `docs/agent_kb/agent_safety_contracts.md`,
  `tool/check_agent_knowledge_base.sh` (structure only)

### Inspected (destination, pre-change)

- `AGENTS.md`, `docs/agent_knowledge_base.md`, `docs/ai-agent-playbook.md`,
  `docs/agent_baseline.md`, `docs/agent_host_notes.md`,
  `docs/agent_kb/*` (4 shards), `tool/check_common_issues.sh`,
  `docs/agents_quick_reference.md`, `docs/README.md`

## Gap / selected patterns

| Pattern | Port? | Why |
| --- | --- | --- |
| `docs/ai/context_loading.md` | Yes | Canonical ladder; unburdens AGENTS |
| `docs/ai/ai_failure_risks.md` | Yes | Risk → honest proof index (iOS commands) |
| `agent_kb/agent_safety_contracts.md` | Yes | SAFETY-01..N adapted to Apple/repo |
| Dedicated KB checker script | No | Extend `check_common_issues.sh` only |
| `governance.md` / `skill_routing.md` | No | Finish gate + host notes already cover |
| AIDLC / harness score / agent-maintain | No | Overweight for single-target iOS demo |

## Risk

Low — docs/tooling only. Residual: agents ignore new ladder until habit forms;
mitigated by AGENTS pointer + common-issues cross-link checks.

## Recommended next step

Implement plan Tasks 2–6 (create docs, migrate pointers, harden common-issues).
