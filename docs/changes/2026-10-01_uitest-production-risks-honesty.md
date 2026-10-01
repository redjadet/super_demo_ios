# 2026-10-01 — Production Risks UITest honesty

## Why

`testDashboardShowsProductionRisks` only opened `productionRisksScreen`. An
empty risks list would still pass despite the test name claiming risks are shown
(Codex Ask #7 false-green scan, tip `cf1aa4d`).

## Changes

- `ProductionRisksView`: per-row `productionRiskRow-<id>` accessibility ids.
- UITest: require seeded `productionRiskRow-push-notifications` with title +
  mitigation/detail tokens in the combined accessibility label.

## Proof

Hosted GHA Delivery 4/4 on this PR. Local Mac checklist / UITest when Simulator
available.

## Out of scope

Diagnostics / SIWA / notification / widget reachability smokes (intentional).
P2-A screenshots · visionOS companion · paid StoreKit · real APNs.
