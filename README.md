# superDemoApp

![Xcode](https://img.shields.io/badge/Xcode-27.0-147EFB?logo=xcode&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-SDK%2027-0D96F6?logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20iPadOS%20%7C%20macOS-000000?logo=apple&logoColor=white)
![Minimum OS](https://img.shields.io/badge/Minimum%20OS-26.0-6E6E73?logo=apple&logoColor=white)

Universal SwiftUI + SwiftData portfolio demo (iPhone / iPad / Mac). **Not** a
production vertical client — architecture, networking, offline Feed, UIKit interop,
and CI proof you can run locally.

**Stack:** Swift 6 / SwiftUI Observation / Clean Architecture layers / URLSession
async networking / SwiftData cache / Fastlane + GitHub Actions. Proof from repo
root: `./bin/lint.sh`, `./bin/verify-swift.sh` (format+lint only), `./bin/ci.sh`
(merge gate).

## What this repo proves

1. **Clean layers** — `Features/*/Presentation|Domain|Data` enforced by
   `./tool/check_layer_boundaries.sh` (via `./bin/lint.sh`).
2. **Offline Feed** — network → repository → use case → `@Observable` model;
   stale cache fallback proven in Xcode preview + repository tests (see below).
3. **Production networking** — retry, 401 refresh, 429, Idempotency-Key, redacted
   logs in `Shared/Networking/`.
4. **UIKit interop** — collection reuse/prefetch, SwiftUI hosting, custom transition
   (Dashboard → UIKit Showcase).
5. **CI / delivery proof** — `./bin/ci.sh` mirrors GitHub Actions lint + iPhone +
   platform builds; map in [`docs/ci-cd-map.md`](docs/ci-cd-map.md).

## 3-minute demo path

1. **Dashboard** — release health / scores (`dashboardTab`).
2. **Feed** — seeded list, Retry, cancel-safe refresh (`feedTab`). Stale-banner
   behavior: open `#Preview("Feed — Stale")` or run
   `CachingFeedRepositoryTests` — no guaranteed in-app stale fixture yet.
3. **Dashboard → UIKit Showcase** — collection + custom transition
   (`uikitShowcaseLink`).
4. **Dashboard → Engineering demos → Risks / Diagnostics / Idempotent POST** —
   production risks, OSLog diagnostics story, simulated duplicate-safe POST demo.

Deep links: `superdemo://dashboard/risks`, `superdemo://feed`, `superdemo://items`.

## Launch and build flags

| Flag | Kind | Effect |
| --- | --- | --- |
| `-ReviewerDemoMode` or `SUPERDEMO_REVIEWER_DEMO_MODE=1` | **Launch / env** | Seeded sample Dashboard + Feed + Items |
| `REVIEWER_DEMO` | **Compile-time** (TestFlight beta via Fastlane) | Same seeded path when built into the binary — not a launch argument |
| `-UITesting` | Launch | UI-test fixtures / in-memory store |
| `-KeychainTokenDemo` or `SUPERDEMO_KEYCHAIN_TOKEN_DEMO=1` | Launch / env | Opt-in Keychain-backed token refresher demo |

Source: `Shared/AppLaunchConfiguration.swift`.

## Get started

Open `superDemoApp.xcodeproj` in Xcode. Index: [`docs/README.md`](docs/README.md).

```bash
./bin/lint.sh
./bin/checklist-fast   # docs / fast sanity
./bin/ci.sh            # before merge
```

## Reviewer map

Full table (theme → path → talk track → proof): [`docs/portfolio.md`](docs/portfolio.md).

Also: [`docs/architecture.md`](docs/architecture.md) ·
[`docs/testing.md`](docs/testing.md) ·
[`docs/sync-and-networking.md`](docs/sync-and-networking.md) ·
[`docs/incident-playbook.md`](docs/incident-playbook.md) ·
[`docs/ci-cd-map.md`](docs/ci-cd-map.md) ·
[`docs/security-checklist.md`](docs/security-checklist.md) ·
[`docs/performance-lab.md`](docs/performance-lab.md) ·
[`docs/engineering-standards.md`](docs/engineering-standards.md)

## TestFlight and release

- Archive / upload: `TESTFLIGHT_BUILD_NUMBER=<n> ./bin/fastlane-run ios beta`
- Checklist: [`docs/release-checklist.md`](docs/release-checklist.md) ·
  risks: [`docs/production-risks.md`](docs/production-risks.md)
- Hosted GHA does **not** archive or upload TestFlight on every PR — see CI/CD map.

## Scope line

Portfolio demo for architecture and delivery review. Demo auth, sample checklist
scores, and simulated idempotency dedupe are labeled as such — not a shipped
App Store product claim.
