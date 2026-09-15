# 2026-09-15 — Agent docs lift from bloc_test_app patterns

## Why

Port minimal AI routing (context ladder, risk→proof index, safety contracts)
from `flutter_bloc_app` without Flutter tooling sprawl. Codex plan review cut
governance/skill_routing/standalone KB checker.

## Changes

- `docs/ai/{README,context_loading,ai_failure_risks}.md`
- `docs/agent_kb/agent_safety_contracts.md`
- `AGENTS.md` Start/Task map/Finish; ≤ 70 lines; points at context ladder
- Slimmed `docs/ai-agent-playbook.md` + rule-retention table
- KB progressive disclosure → `docs/ai/context_loading.md`
- Indexes: `docs/README.md`, audits, agents quick reference
- `tool/check_common_issues.sh`: required AI files, AGENTS ≤ 70, cross-link
  needles
- Audit: `docs/audits/2026-09-15_agent-docs-vs-bloc-test-app.md`

## Rule retention (playbook)

See table in `docs/ai-agent-playbook.md` — MainActor, cancel, preview,
accessibility, SwiftData-out-of-Domain, Apple-native, report shape retained.

## Negative-path proof (Task 5)

| Case | Expected | Observed |
| --- | --- | --- |
| Move aside `docs/ai/README.md` | non-zero | exit 1; missing required file |
| Pad `AGENTS.md` to 71 lines | non-zero | exit 1; line budget; restored to 48 |

## Proof

```bash
bash -n tool/check_common_issues.sh
./tool/check_common_issues.sh
./bin/checklist-fast
```

Docs/tool wiring only — not full `./bin/ci.sh`.
