# Engineering evidence map

This page links reviewer-facing claims to repository evidence and states the
limits of each proof. It makes no aggregate engineering-quality rating.

## Evidence areas

| Area | Evidence to inspect | Check or source | Proof boundary |
| --- | --- | --- | --- |
| Delivery | [CI map](../ci-cd-map.md), [workflow](../../.github/workflows/ci.yml), `bin/` scripts | Local `./bin/checklist`; hosted `checklist` result for the reviewed commit | Workflow configuration describes the configured lanes. A result applies to its exact commit and destination. |
| Architecture | [Layer guide](../layers.md), [modularity guide](../modularity.md), layer-boundary checker | `./tool/check_layer_boundaries.sh` | Checks configured dependency and import rules. It does not grade design quality. |
| Offline behavior | [Offline invariants](../offline-invariants.md), [offline-first guide](../offline-first.md), [architecture deep-dives](../architecture/README.md), linked repository tests | The named tests and evidence in each invariant row | Results cover recorded cases and fixtures. They do not establish production traffic or service behavior. |
| Validation | [Validation routing](validation_routing_fast_vs_full.md), [CI map](../ci-cd-map.md), [quick reference](../agents_quick_reference.md) | Commands and hosted jobs named by those documents | Routing describes which proof to run. The document itself is not a run result. |
| Portfolio scope | [README](../../README.md), [reviewer guide](../portfolio.md), [Sonar decision](../sonar-decision.md) | Explicit demo and integration-scope statements | Scope statements describe this sample. They do not claim App Store release or production integrations. |

## How to read results

`./tool/check_engineering_evidence_map.sh` checks required evidence links and
sections, verifies the offline-invariant table, rejects numeric self-ratings and
fabricated coverage badges on the README, and runs the layer-boundary checker.
It does not build the app or run tests.

`./bin/lint.sh` includes this documentation gate. Build and test results belong
to the commit, platform, and destination shown by the corresponding command or
hosted check.

## Limits

- A passing documentation gate confirms evidence-map structure and configured
  repository rules. It does not summarize overall product or engineering quality.
- Test presence and green results apply to named cases and the exact run that
  produced them.
- Coverage percentage remains unpublished; the README carries no coverage badge.
- The project describes itself as a portfolio sample, not a shipped App Store
  product.

## Related

- [Code quality and coverage honesty](../code-quality.md)
- [Engineering standards](../engineering-standards.md)
- [Validation routing](validation_routing_fast_vs_full.md)
- [Task router](../../CODEMAP.md)
