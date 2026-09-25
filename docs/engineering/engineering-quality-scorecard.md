# Engineering quality scorecard (portfolio-honest)

Measured contract for claiming **Engineering X/10** on `superDemoApp`.

This is **not** the agent harness score (AGENTS / finish gate / safety contracts).
Harness maturity is tracked separately (FP-P1-B). Do not substitute one for the
other.

## Scoring rule

- Visible badge (README): `Engineering X/10` **only** when this gate passes and
  overall is **10/10**.
- **Overall = minimum** of all area scores below.
- Each area is binary for now: **10** when its proof criteria hold, otherwise
  **0**.
- Never invent coverage `%` badges here or on README — coverage honesty is
  FP-P1-D (`docs/code-quality.md` later).

## Areas

| Area | Score | Proof | Pass criteria |
| --- | ---: | --- | --- |
| Delivery | 10/10 | `./bin/lint.sh`, `./bin/ci.sh`, [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml), [`ci-cd-map.md`](../ci-cd-map.md) | Lint + merge scripts and GHA workflow exist; CI map names PR jobs vs local merge proof |
| Architecture / layers | 10/10 | `./tool/check_layer_boundaries.sh` (via `./bin/lint.sh`), [`layers.md`](../layers.md), [`feature-template.md`](../feature-template.md) | Layer gate exits 0; Features layout documented |
| Offline honesty | 10/10 | [`offline-invariants.md`](../offline-invariants.md), [`offline-first.md`](../offline-first.md) | ≥5 named invariants; each row has evidence (test, script, or explicit N/A) |
| Validation honesty | 10/10 | [`validation_routing_fast_vs_full.md`](validation_routing_fast_vs_full.md), [`agents_quick_reference.md`](../agents_quick_reference.md), [`ci-cd-map.md`](../ci-cd-map.md) | Fast vs full routing documented; PR-lane vs local-test honesty stated |
| Portfolio scope | 10/10 | [`../README.md`](../../README.md), [`portfolio.md`](../portfolio.md), [`sonar-decision.md`](../sonar-decision.md) | README states portfolio demo (not App Store product); no fake coverage % badge; Sonar skip documented |

**Overall: 10/10** (min of areas).

## Claim gate

Do **not** claim top-tier Engineering (or keep an Engineering badge on README)
unless:

1. Overall score above is **10/10**.
2. `./tool/check_engineering_quality_scorecard.sh` exits **0**.
3. Harness claims stay separate from this scorecard.

If any area drops to 0, set Overall to that min, remove or withhold the README
Engineering badge, and fix proof before reclaiming 10/10.

## Proof commands

```bash
./tool/check_engineering_quality_scorecard.sh
./bin/lint.sh                 # includes scorecard gate + layer boundaries
./bin/checklist-fast          # docs/tooling lane
./bin/ci.sh                   # local merge proof (author)
```

## Out of scope (this scorecard)

- Measured code-coverage % badges (FP-P1-D).
- Harness scorecard / SAFETY-REPORT template (FP-P1-B).
- Supply-chain scanners (FP-P2-A).
- Vendor crash SDK / live SonarCloud / App Store submission.

Modularity folder/import guards (FP-P1-A) live in [`../modularity.md`](../modularity.md)
and `./bin/lint.sh`; they are not separate scorecard areas.

## Related

- Validation routing: [`validation_routing_fast_vs_full.md`](validation_routing_fast_vs_full.md)
- Engineering standards (human prose): [`../engineering-standards.md`](../engineering-standards.md)
- Task router: [`../../CODEMAP.md`](../../CODEMAP.md)
