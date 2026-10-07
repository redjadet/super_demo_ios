# 2026-10-07 — tvOS Feed snapshot companion

## Summary

Adds a thin **tvOS** companion app that reads the same **Feed widget App
Group snapshot** DTO / honest states as the Home Screen widget and the
existing **watchOS** companion. **visionOS** companion remains deferred.

## Contract

| Piece | Value |
| --- | --- |
| App Group | `group.com.ilkersevim.superDemoApp` (same as Feed widget / Share / Watch) |
| iOS companion bundle | `com.ilkersevim.superDemoApp` |
| tvOS bundle | `com.ilkersevim.superDemoApp.tvos` |
| Snapshot file | `feed-widget-snapshot.json` via `FeedWidgetShared/` |
| TV folder | `superDemoAppTV/` |
| Scheme | `superDemoAppTV` |
| Platforms | TV: **tvOS / tvOS simulator** (standalone; not embedded in iPhone) |
| Floor | `TVOS_DEPLOYMENT_TARGET` **26.7** |
| CI | `./bin/ci-tvos-build.sh` from `./bin/ci-platform-builds.sh` (skip: `CI_SKIP_TVOS_BUILD=1`) |

## Honesty

- TV App Group container is **tv-local** — not live phone↔TV sync.
- No Multipeer / CloudKit transfer claimed in this slice.
- tvOS Simulator: use **Seed demo snapshot** when the file is absent /
  unavailable.
- Engineering demos → **tvOS Feed companion (demo)** documents identifiers
  and limitations on iPhone.
- watchOS companion unchanged functionally; maps/docs now cite both companions.
- visionOS companion still **not in repo**.

## Proof

- Reuses `FeedWidgetSnapshotStoreTests` (DTO / state machine; local Swift Testing)
- Hosted GHA: tvOS scheme build in platform-builds lane (warnings as errors)
- Limitation: device App Group signing may need team entitlement verification;
  unsigned Simulator may show `unavailable` until group is provisioned

## Docs

- Portfolio **Platform surfaces** (tvOS In repo; visionOS deferred)
- `CODEMAP.md`, `ci-cd-map.md`, `universal-apple-platforms.md`,
  `architecture-tour.md`, checklist / Fastlane platform wording
- Follow-up honesty: `testing.md`, `agent_environment_setup.md`,
  `agent_project_context.md`, `code-style.md`, `agents_quick_reference.md`,
  `tooling_map.md`; README title + Companions badge; Engineering demo UITest
  `testTVCompanionDemoIsReachable`
- Lean README platforms badge includes tvOS
