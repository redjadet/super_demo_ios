# superDemoApp

![CI](https://github.com/redjadet/super_demo_ios/actions/workflows/ci.yml/badge.svg?branch=main)
![Engineering](https://img.shields.io/badge/Engineering-10%2F10-0A7A3E)
![Xcode](https://img.shields.io/badge/Xcode-27.0-147EFB?logo=xcode&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-SDK%2027-0D96F6?logo=swift&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-add--to--app-02569B?logo=flutter&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20iPadOS%20%7C%20macOS-000000?logo=apple&logoColor=white)
![Minimum OS](https://img.shields.io/badge/Minimum%20OS-26.0-6E6E73?logo=apple&logoColor=white)

Universal SwiftUI + SwiftData demo (iPhone / iPad / Mac). Portfolio sample for
architecture, offline Feed, networking, UIKit interop, optional Flutter
add-to-app, and local CI proof — not a shipped App Store product.

## What this proves

1. Clean feature layers (`Presentation` → `Domain` ← `Data`) with lint enforcement
2. Offline Feed with cancel-safe refresh and a deterministic **stale-cache** path
3. Production-minded URLSession client (retry, 401 refresh, 429, Idempotency-Key)
4. UIKit collection showcase hosted from SwiftUI
5. Optional Flutter module ↔ native host bridge (MethodChannel)
6. Merge proof via `./bin/ci.sh` / GitHub Actions (see CI map)

Task → path: [`CODEMAP.md`](CODEMAP.md). Timed walk:
[`docs/architecture-tour.md`](docs/architecture-tour.md). Engineering score
(min of areas; not agent harness):
[`docs/engineering/engineering-quality-scorecard.md`](docs/engineering/engineering-quality-scorecard.md).
Talk tracks: [`docs/portfolio.md`](docs/portfolio.md).

## 3-minute path

1. **Dashboard** — release health
2. **Feed** — list / Retry; stale banner via `-StaleFeedDemo` or Engineering demos →
   **Stale Feed cache fallback**
3. **UIKit Showcase** — from Dashboard
4. **Engineering demos** — Risks / Diagnostics / Idempotent POST / Flutter add-to-app

Deep links: `superdemo://dashboard/risks`, `superdemo://feed`, `superdemo://items`.

## Run and proof

Open `superDemoApp.xcodeproj`. From repo root:

```bash
./bin/lint.sh
./bin/verify-swift.sh   # format + lint
./bin/ci.sh             # merge gate
```

Flutter embed (macOS, iOS Simulator): `./tool/prepare_flutter_embed.sh` — details in
[`docs/flutter-add-to-app.md`](docs/flutter-add-to-app.md).

Launch flags (ReviewerDemo, StaleFeed, UITesting, Keychain demo, compile-time
`REVIEWER_DEMO`): [`docs/portfolio.md`](docs/portfolio.md) ·
`Shared/AppLaunchConfiguration.swift`.

## Docs

| Topic | Doc |
| --- | --- |
| Task → path router | [`CODEMAP.md`](CODEMAP.md) |
| ≤15 min architecture tour | [`docs/architecture-tour.md`](docs/architecture-tour.md) |
| Reviewer map / talk tracks | [`docs/portfolio.md`](docs/portfolio.md) |
| Platform surfaces inventory | [`docs/portfolio.md`](docs/portfolio.md#platform-surfaces) |
| Flutter add-to-app | [`docs/flutter-add-to-app.md`](docs/flutter-add-to-app.md) |
| Code quality / coverage honesty | [`docs/code-quality.md`](docs/code-quality.md) |
| Full index | [`docs/README.md`](docs/README.md) |
