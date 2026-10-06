# Architecture deep-dives (reviewer grade)

Code-cited engineering notes for hiring reviewers and senior engineers. Every
claim maps to a type or test in this repository. Prefer these pages over dated
change notes when the two disagree.

| Topic | Doc |
| --- | --- |
| Native cancellation | [`native-cancellation.md`](native-cancellation.md) |
| Cache behavior | [`cache-behavior.md`](cache-behavior.md) |
| Offline-first | [`offline-first-behavior.md`](offline-first-behavior.md) |
| Flutter add-to-app | [`flutter-add-to-app.md`](flutter-add-to-app.md) |

## Related canon

| Surface | Doc |
| --- | --- |
| Named offline invariants (OI-01…OI-07) | [`../offline-invariants.md`](../offline-invariants.md) |
| Offline posture + store recovery | [`../offline-first.md`](../offline-first.md) |
| Networking / SPM client | [`../sync-and-networking.md`](../sync-and-networking.md) |
| Flutter how-to + honesty table | [`../flutter-add-to-app.md`](../flutter-add-to-app.md) |
| Host-bridge JSON contract | [`../native-host-boundary.md`](../native-host-boundary.md) |
| ADR offline posture | [`../adr/0002-offline-first-posture.md`](../adr/0002-offline-first-posture.md) |
| Evidence map | [`../engineering/engineering-evidence-map.md`](../engineering/engineering-evidence-map.md) |
| AI-native SDLC kit | [`../ai-sdlc/README.md`](../ai-sdlc/README.md) |
| Offline / outbox skill | [`../ai-sdlc/skills/offline-outbox.md`](../ai-sdlc/skills/offline-outbox.md) |
| Flutter boundary skill | [`../ai-sdlc/skills/flutter-add-to-app.md`](../ai-sdlc/skills/flutter-add-to-app.md) |

## Scope honesty

These pages describe **what ships in this portfolio sample**. They do not claim
App Store production traffic, a multi-device sync engine, or Flutter frameworks
in every binary.
