# 2026-09-29 — Release health score excludes sample API

## Summary

Composite Dashboard prepends a live Remote API probe to sample Auth/Release/Push
rows. The hero “Release health” % now scores only the live probe for API health
when one is present; sample API rows stay listed with an honest caption.

## Why

Mac Codex scan on tip `bc71880` (rank 1): list caption said “live probe” while
the score still folded simulated API status into one live-looking number.

## Proof

- `ProductionReadinessTests.scoreExcludesSampleAPIWhenLiveProbePresent`
- `CompositeProductionReadinessRepositoryTests` asserts `isLiveProbe` on remote row
- Linux: common-issues / scorecard / markdown / router (GHA owns SwiftLint + tests)

## Out of scope

Mixed-age widget TTL, Feed Retry / Flutter UITest false-greens (Codex ranks 3–5).
