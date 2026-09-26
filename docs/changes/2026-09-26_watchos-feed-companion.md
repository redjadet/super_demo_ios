# 2026-09-26 — watchOS Feed snapshot companion (JP-P2-F)

## Summary

Adds a thin **watchOS** companion app that reads the same **Feed widget App
Group snapshot** DTO / honest states as the Home Screen widget. **visionOS**
companion remains deferred.

## Contract

| Piece | Value |
| --- | --- |
| App Group | `group.com.ilkersevim.superDemoApp` (same as Feed widget / Share) |
| iOS companion bundle | `com.ilkersevim.superDemoApp` |
| Watch bundle | `com.ilkersevim.superDemoApp.watchkitapp` |
| Snapshot file | `feed-widget-snapshot.json` via `FeedWidgetShared/` |
| Watch folder | `superDemoAppWatch/` |
| Scheme | `superDemoAppWatch` |
| Platforms | Watch: **watchOS / watch simulator**; embed Watch Content on iPhone/iPad only (`platformFilter = ios`) so Mac lane stays green |
| CI | `./bin/ci-watch-build.sh` from `./bin/ci-platform-builds.sh` (skip: `CI_SKIP_WATCH_BUILD=1`) |

## Honesty

- Watch App Group container is **watch-local** — not live phone↔watch sync.
- No WatchConnectivity transfer claimed in this slice.
- Watch Simulator: use **Seed demo snapshot** when the file is absent /
  unavailable.
- Engineering demos → **watchOS Feed companion (demo)** documents identifiers
  + limitations on iPhone.
- visionOS / tvOS companions still **not in repo**.

## Proof

- Reuses `FeedWidgetSnapshotStoreTests` (DTO / state machine; local Swift Testing)
- Hosted GHA: watch scheme build in platform-builds lane (warnings as errors);
  iPhone/iPad embed watch; Mac skips embed via `platformFilter = ios`
- Limitation: device App Group signing may need team entitlement verification;
  unsigned Simulator may show `unavailable` until group is provisioned

## Docs

- Portfolio **Platform surfaces** (watch In repo; visionOS deferred)
- `CODEMAP.md`, `ci-cd-map.md`, `universal-apple-platforms.md`,
  `architecture-tour.md`, `agents_quick_reference.md`
- Lean README platforms badge includes watchOS
