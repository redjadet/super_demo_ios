# Harness scorecard (agent maturity)

Measured contract for claiming **Harness X/10** on this repo’s *agent*
tooling — separate from app **Engineering** quality
([`../engineering/engineering-quality-scorecard.md`](../engineering/engineering-quality-scorecard.md)).

Do **not** substitute harness maturity for Engineering score (or the reverse).

## Scoring rule

- **Overall = minimum** of all area scores below.
- Each area is binary for now: **10** when its proof criteria hold, otherwise
  **0**.
- No README Harness badge until a gate exists and Overall is **10/10**
  (day-one: document + manual check; no fake badge).

## Areas

| Area | Score | Proof | Pass criteria |
| --- | ---: | --- | --- |
| AGENTS map | 10/10 | [`../../AGENTS.md`](../../AGENTS.md), [`../../CODEMAP.md`](../../CODEMAP.md) | Map-only `AGENTS.md` (≤70 lines); CODEMAP routes task → path |
| Validation routing | 10/10 | [`../agents_quick_reference.md`](../agents_quick_reference.md), [`../engineering/validation_routing_fast_vs_full.md`](../engineering/validation_routing_fast_vs_full.md) | Fast vs full lanes documented; PR-lane vs local-test honesty |
| Finish gate | 10/10 | [`../agent_kb/legibility_and_finish_gate.md`](../agent_kb/legibility_and_finish_gate.md), [`../agent_knowledge_base.md`](../agent_knowledge_base.md) | Finish gate linked from knowledge base; inspectable proof required |
| Safety contracts | 10/10 | [`../agent_kb/agent_safety_contracts.md`](../agent_kb/agent_safety_contracts.md), [`../agent_kb/safety-report-template.md`](../agent_kb/safety-report-template.md) | SAFETY-01…06 + SAFETY-REPORT; closeout template present |
| Quick reference | 10/10 | [`../agents_quick_reference.md`](../agents_quick_reference.md), `./bin/agent-maintain` | Chooser table + `session` / `preflight` / `closeout` entrypoints |

**Overall: 10/10** (min of areas) — revisit if any area proof regresses.

## Claim gate

Claim Harness 10/10 only when:

1. Overall above is **10/10**.
2. `./bin/agent-maintain preflight` and `./bin/agent-maintain closeout` print
   the expected paths (smoke: exit 0).
3. Engineering claims stay on the Engineering scorecard — not this file.

## Proof commands

```bash
./bin/agent-maintain session
./bin/agent-maintain preflight
./bin/agent-maintain closeout
./bin/checklist-fast   # docs/tooling lane after harness doc edits
```

## Out of scope (this scorecard)

- App Engineering areas (delivery, layers, offline, portfolio) — FP-P0-B.
- Flutter host sync / install / trim (`agent-maintain` stays thin — FP-P1-C).
- Supply-chain scanners (FP-P2-A).

## Related

- Host maintenance: [`../agent_kb/host-maintenance.md`](../agent_kb/host-maintenance.md)
- Engineering scorecard: [`../engineering/engineering-quality-scorecard.md`](../engineering/engineering-quality-scorecard.md)
- Task router: [`../../CODEMAP.md`](../../CODEMAP.md)
