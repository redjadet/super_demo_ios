# 2026-09-29 — Dashboard cancel honesty (remote health)

## Summary

Cancel during Dashboard remote-API health must not become a false “Remote API”
warning. `URLSessionAPIClient` keeps cooperative cancel as `CancellationError`
(including `URLError.cancelled`). `CompositeProductionReadinessRepository`
rethrows cancel instead of mapping it through the soft-fail warning path.

## Why

`docs/sync-and-networking.md` requires cancellation to remain cancellation.
The composite previously caught all remote-health errors (including cancel /
`APIError.cancelled`) and returned a warning row + `releaseCheckFailed`, so a
superseded Dashboard refresh could look like an API health failure.

## Proof

- `CompositeProductionReadinessRepositoryTests` — cancel / `APIError.cancelled`
  rethrow; no diagnostic fail
- `URLSessionAPIClientTests.preservesCancellationError`
- Linux gates: common-issues / markdown / scorecard (GHA owns SwiftLint + tests)

## Out of scope

Mac P2-A screenshots, private Mac worker, visionOS, paid StoreKit, real APNs,
`waitsForConnectivity` policy change.
