# 2026-09-25 — Engineering quality scorecard (FP-P0-B)

## Summary

Portfolio-honest Engineering scorecard: areas scored binary 10/0, overall =
**min** of areas. Thin gate verifies wiring + honesty (no fake coverage %
badges). README Engineering badge only when Overall is 10/10 and the gate
passes. Wired into `./bin/lint.sh`.

## Paths

- [`../engineering/engineering-quality-scorecard.md`](../engineering/engineering-quality-scorecard.md)
- [`../../tool/check_engineering_quality_scorecard.sh`](../../tool/check_engineering_quality_scorecard.sh)
- [`../../bin/lint.sh`](../../bin/lint.sh) — runs scorecard gate after layers
- [`../../README.md`](../../README.md) — Engineering 10/10 badge + scorecard link
- [`../../CODEMAP.md`](../../CODEMAP.md), [`../../AGENTS.md`](../../AGENTS.md),
  [`../agents_quick_reference.md`](../agents_quick_reference.md)

## Proof

```bash
./tool/check_engineering_quality_scorecard.sh
./bin/lint.sh
./bin/checklist-fast
```

## Acceptance

- Areas: delivery, architecture/layers, offline honesty, validation honesty,
  portfolio scope; Overall = min.
- Gate is honest (links/scripts/invariants; no invented %).
- README badge only with Overall 10/10 + passing gate.
