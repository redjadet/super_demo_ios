# 2026-09-25 — Harness scorecard + SAFETY-REPORT template (FP-P1-B)

## Why

Separate agent harness maturity from app Engineering score (FP-P0-B). Give
agents a reusable SAFETY-REPORT closeout shape linked from the finish gate.

## Changes

- Add [`../ai/harness-scorecard.md`](../ai/harness-scorecard.md) — areas:
  AGENTS map, validation routing, finish gate, safety contracts, quick ref;
  Overall = **min** of areas (currently 10/10). No fake Harness badge.
- Add [`../agent_kb/safety-report-template.md`](../agent_kb/safety-report-template.md)
  — What We Learned / Files / Verification / Limitations / Follow-ups.
- Link template from finish gate + safety contracts; route from CODEMAP,
  `docs/ai/README`, AGENTS Finish, doc index.

## Proof

```bash
./bin/checklist-fast
```

## Acceptance

- Harness areas listed with on-disk proof paths.
- Template matches SAFETY-REPORT sections named in Flutter-parity plan.
- Finish gate links the template; Engineering scorecard stays separate.
