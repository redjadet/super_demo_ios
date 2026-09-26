# superDemoApp

[![CI](https://github.com/redjadet/super_demo_ios/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/redjadet/super_demo_ios/actions/workflows/ci.yml)
![Engineering](https://img.shields.io/badge/Engineering-10%2F10-0A7A3E)

![Xcode](https://img.shields.io/badge/Xcode-27.0-147EFB?logo=xcode&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-SDK%2027-0D96F6?logo=swift&logoColor=white)
![SwiftData](https://img.shields.io/badge/SwiftData-persistence-F05138?logo=swift&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-add--to--app-02569B?logo=flutter&logoColor=white)

![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20watchOS-000000?logo=apple&logoColor=white)
![Minimum OS](https://img.shields.io/badge/Minimum%20OS-26.0-6E6E73?logo=apple&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20layers-0A7A3E)

Universal SwiftUI + SwiftData demo (iPhone / iPad / Mac) with a thin watchOS
Feed-snapshot companion. Portfolio sample for architecture, offline Feed,
networking, UIKit interop, optional Flutter add-to-app, and local CI proof —
not a shipped App Store product.

## What this proves

1. Feature layers with lint enforcement — [`docs/layers.md`](docs/layers.md)
2. Offline Feed + stale-cache path — [`docs/offline-first.md`](docs/offline-first.md)
3. Production-minded URLSession client — [`docs/sync-and-networking.md`](docs/sync-and-networking.md)
4. UIKit ↔ SwiftUI showcase — [`docs/portfolio.md`](docs/portfolio.md)
5. Optional Flutter host bridge — [`docs/flutter-add-to-app.md`](docs/flutter-add-to-app.md)
6. Merge proof (`./bin/ci.sh` / GHA) — [`docs/ci-cd-map.md`](docs/ci-cd-map.md)

[`CODEMAP.md`](CODEMAP.md) ·
[`docs/architecture-tour.md`](docs/architecture-tour.md) ·
[`docs/engineering/engineering-quality-scorecard.md`](docs/engineering/engineering-quality-scorecard.md) ·
[`docs/portfolio.md`](docs/portfolio.md)

## 3-minute path

1. **Dashboard** — release health
2. **Feed** — list / Retry; stale banner (`-StaleFeedDemo` or Engineering demos)
3. **UIKit Showcase** — from Dashboard
4. **Engineering demos** — Risks / Diagnostics / Idempotent POST / Flutter add-to-app

Deep links and launch flags: [`docs/portfolio.md`](docs/portfolio.md).

## Run and proof

Open `superDemoApp.xcodeproj`. From repo root:

```bash
./bin/lint.sh
./bin/verify-swift.sh   # format + lint
./bin/ci.sh             # merge gate
```

## Docs

| Topic | Doc |
| --- | --- |
| Task → path router | [`CODEMAP.md`](CODEMAP.md) |
| ≤15 min architecture tour | [`docs/architecture-tour.md`](docs/architecture-tour.md) |
| Reviewer map / talk tracks | [`docs/portfolio.md`](docs/portfolio.md) |
| Design system | [`DESIGN.md`](DESIGN.md) |
| Layers / modularity | [`docs/layers.md`](docs/layers.md) |
| Offline / networking | [`docs/offline-first.md`](docs/offline-first.md) |
| Flutter add-to-app | [`docs/flutter-add-to-app.md`](docs/flutter-add-to-app.md) |
| CI / CD map | [`docs/ci-cd-map.md`](docs/ci-cd-map.md) |
| Code quality honesty | [`docs/code-quality.md`](docs/code-quality.md) |
| Full index | [`docs/README.md`](docs/README.md) |
