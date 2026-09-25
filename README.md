# superDemoApp

![CI](https://github.com/redjadet/super_demo_ios/actions/workflows/ci.yml/badge.svg?branch=main)
![Xcode](https://img.shields.io/badge/Xcode-27.0-147EFB?logo=xcode&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-SDK%2027-0D96F6?logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20iPadOS%20%7C%20macOS-000000?logo=apple&logoColor=white)
![Minimum OS](https://img.shields.io/badge/Minimum%20OS-26.0-6E6E73?logo=apple&logoColor=white)

Universal SwiftUI + SwiftData demo (iPhone / iPad / Mac). Portfolio sample for
architecture, offline Feed, networking, UIKit interop, and local CI proof — not a
shipped App Store product.

## What this proves

1. Clean feature layers (`Presentation` → `Domain` ← `Data`) with lint enforcement
2. Offline Feed with cancel-safe refresh and a deterministic **stale-cache** path
3. Production-minded URLSession client (retry, 401 refresh, 429, Idempotency-Key)
4. UIKit collection showcase hosted from SwiftUI
5. Merge proof via `./bin/ci.sh` / GitHub Actions (see CI map)

Details and talk tracks: [`docs/portfolio.md`](docs/portfolio.md).

## 3-minute path

1. **Dashboard** — release health
2. **Feed** — list / Retry; stale banner via `-StaleFeedDemo` or Engineering demos →
   **Stale Feed cache fallback**
3. **UIKit Showcase** — from Dashboard
4. **Engineering demos** — Risks / Diagnostics / Idempotent POST

Deep links: `superdemo://dashboard/risks`, `superdemo://feed`, `superdemo://items`.

## Run and proof

Open `superDemoApp.xcodeproj`. From repo root:

```bash
./bin/lint.sh
./bin/verify-swift.sh   # format + lint
./bin/ci.sh             # merge gate
```

Launch flags (ReviewerDemo, StaleFeed, UITesting, Keychain demo, compile-time
`REVIEWER_DEMO`): [`docs/portfolio.md`](docs/portfolio.md) ·
`Shared/AppLaunchConfiguration.swift`.

## Docs

| Topic | Doc |
| --- | --- |
| Reviewer map | [`docs/portfolio.md`](docs/portfolio.md) |
| Architecture / layers | [`docs/architecture.md`](docs/architecture.md) |
| Testing | [`docs/testing.md`](docs/testing.md) |
| Networking / offline Feed | [`docs/sync-and-networking.md`](docs/sync-and-networking.md) |
| CI / CD | [`docs/ci-cd-map.md`](docs/ci-cd-map.md) |
| Diagnostics | [`docs/incident-playbook.md`](docs/incident-playbook.md) |
| Security / performance / standards | [`docs/security-checklist.md`](docs/security-checklist.md) · [`docs/performance-lab.md`](docs/performance-lab.md) · [`docs/engineering-standards.md`](docs/engineering-standards.md) |
| Design | [`DESIGN.md`](DESIGN.md) · [`docs/design_system.md`](docs/design_system.md) · [`docs/design-token-figma.md`](docs/design-token-figma.md) |
| Release | [`docs/release-checklist.md`](docs/release-checklist.md) · [`docs/production-risks.md`](docs/production-risks.md) |
| Index | [`docs/README.md`](docs/README.md) |
