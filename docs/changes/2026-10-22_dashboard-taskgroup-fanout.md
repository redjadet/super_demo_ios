# 2026-10-22 — Dashboard TaskGroup sample ∥ remote

## Intent

Close the named structured-concurrency follow-up: Composite Dashboard loaded
sample snapshot and live Remote API health **sequentially**. Fan them out with
`withThrowingTaskGroup`, keep cancel honesty, and prove overlap + cancel-child
in unit tests.

## Changes

- `CompositeProductionReadinessRepository` — TaskGroup fan-out; `sample` typed
  as `any ProductionReadinessRepository` for injectable test spies.
- `CompositeProductionReadinessRepositoryTests` —
  `loadsSampleAndRemoteInParallel`, `cancellingParentCancelsSampleAndRemoteChildren`.
- Docs: `swift-concurrency.md`, EVIDENCE case 5, `native-cancellation.md`,
  `failure-concepts-map.md` follow-up check-off.

## Not changed

- Soft-fail warning row for non-cancel remote errors.
- `AsyncLoadController` / Feed cancel paths.
- ConnectivityMonitor lock → actor migration.
