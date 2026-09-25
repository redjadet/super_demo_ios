# Agent harness scorecard

Measured contract for claiming **Harness X/10** on this repo’s *agent* surfaces.

This is **not** the app Engineering score
([`../engineering/engineering-quality-scorecard.md`](../engineering/engineering-quality-scorecard.md)).
Do not substitute one for the other.

## Scoring rule

- **Overall = minimum** of all area scores below.
- Each area is binary for now: **10** when its proof criteria hold, otherwise
  **0**.
- No README Harness badge until a dedicated gate exists and Overall is **10/10**
  (honesty over theater). Until then, cite this doc — do not invent a badge.

## Areas

| Area | Score | Proof | Pass criteria |
| --- | ---: | --- | --- |
| AGENTS map | 10/10 | [`../../AGENTS.md`](../../AGENTS.md), [`../../CODEMAP.md`](../../CODEMAP.md) | Map-only entry (~70 lines); Start / Task map / Finish route to `docs/` |
| Validation routing | 10/10 | [`../engineering/validation_routing_fast_vs_full.md`](../engineering/validation_routing_fast_vs_full.md), [`../agents_quick_reference.md`](../agents_quick_reference.md) | Fast vs full chooser exists; docs/tooling → `checklist-fast`, merge → `ci.sh` |
| Finish gate | 10/10 | [`../agent_kb/legibility_and_finish_gate.md`](../agent_kb/legibility_and_finish_gate.md), [`../agent_knowledge_base.md`](../agent_knowledge_base.md) | Self-verify checklist before final report; links SAFETY-REPORT template |
| Safety contracts | 10/10 | [`../agent_kb/agent_safety_contracts.md`](../agent_kb/agent_safety_contracts.md), [`ai_failure_risks.md`](ai_failure_risks.md) | Contract index + Pre-Flight risk register; `SAFETY-REPORT` points at template |
| Quick reference | 10/10 | [`../agents_quick_reference.md`](../agents_quick_reference.md) | Validation chooser table + proof commands discoverable without chat |

**Overall: 10/10** (min of areas).

## Closeout

Non-trivial sessions: fill
[`../agent_kb/safety-report-template.md`](../agent_kb/safety-report-template.md)
(or equivalent sections) after the finish gate. Template sections: What We Learned /
Files / Verification / Limitations / Follow-ups.

## Claim gate

Do **not** claim top-tier Harness (or add a Harness badge) unless:

1. Overall above is **10/10**.
2. Each area’s proof path resolves on disk.
3. Engineering claims stay on the Engineering scorecard — not here.

## Out of scope (this scorecard)

- App Engineering areas (delivery, layers, offline, portfolio) — FP-P0-B.
- `bin/agent-maintain` / worktrees — FP-P1-C.
- Coverage / code-quality overview — FP-P1-D.
- Flutter AIDLC host-parity badges / Melos / Dart analyzers.

## Related

- Context ladder: [`context_loading.md`](context_loading.md)
- Failure risks: [`ai_failure_risks.md`](ai_failure_risks.md)
- Workflow: [`../agent_knowledge_base.md`](../agent_knowledge_base.md)
