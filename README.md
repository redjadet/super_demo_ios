# superDemoApp — Apple multi-platform engineering portfolio

[![3-minute path](https://img.shields.io/badge/3--minute-reviewer%20path-0066CC)](docs/portfolio.md#3-minute-path)
[![Evidence](https://img.shields.io/badge/Evidence-technical%20reviewer-0066CC)](docs/EVIDENCE.md)
[![Architecture tour](https://img.shields.io/badge/Architecture-tour-0A7A3E)](docs/architecture-tour.md)
[![Engineering evidence](https://img.shields.io/badge/Engineering-evidence-6E6E73)](docs/engineering/engineering-evidence-map.md)

[![CI](https://github.com/redjadet/super_demo_ios/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/redjadet/super_demo_ios/actions/workflows/ci.yml)

![Xcode](https://img.shields.io/badge/Xcode-27.0-147EFB?logo=xcode&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-SDK%2027-0D96F6?logo=swift&logoColor=white)
![SwiftData](https://img.shields.io/badge/SwiftData-persistence-F05138?logo=swift&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-add--to--app-02569B?logo=flutter&logoColor=white)

![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-000000?logo=apple&logoColor=white)
![Companions](https://img.shields.io/badge/Companions-watchOS%20%7C%20tvOS%20Feed%20snapshot-6E6E73?logo=apple&logoColor=white)
![Minimum OS](https://img.shields.io/badge/Minimum%20OS-26.7-6E6E73?logo=apple&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20layers-0A7A3E)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A **Swift / SwiftUI / SwiftData** reference app for iPhone, iPad and Mac,
with thin watchOS and tvOS Feed-snapshot companions. It demonstrates layered
architecture, offline caching, async networking, UIKit interoperability and
an optional Flutter add-to-app module.

This is a portfolio sample, not a shipped App Store product. Platform support,
simulated flows and optional integrations are documented in the
[reviewer guide](docs/portfolio.md#platform-surfaces).

Author: [İlker Sevim](https://redjadet.github.io/react-web-portfolio/).

## Engineering decisions and evidence

### Bookmark race with regression proof

Bookmark → remove during an in-flight request: persist local intent and outbox
atomically, preserve the newer removal, then drain it in order.
[Problem, decision and regression test](docs/EVIDENCE.md#lead-case-preserve-the-latest-bookmark-intent) ·
[Passing unit run · 2026-10-08](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857/job/113485831800).

**My contribution:** architecture and acceptance criteria, review of failure
paths, and regression/CI validation. [Responsibilities and workflow](docs/EVIDENCE.md#my-contribution).

- [Architecture tour](docs/architecture-tour.md): state, layers and dependency injection.
- [More engineering cases](docs/EVIDENCE.md#more-engineering-cases): cache expiry, cancellation, URLSession and UIKit regressions.
- [Flutter add-to-app](docs/flutter-add-to-app.md): optional iOS module, typed host bridge and setup.

## Run the demo

Open `superDemoApp.xcodeproj` in Xcode, choose an iPhone, iPad or Mac destination,
and use `-ReviewerDemoMode` for seeded sample data.

- [3-minute reviewer path](docs/portfolio.md#3-minute-path) and [launch flags](docs/portfolio.md#launch-and-build-flags).
- [Mac walkthrough](docs/macos-demo.md) and [Watch & TV walkthrough](docs/watch-tv-demo.md).
- [Test commands](docs/testing.md), [regression reproduction](docs/EVIDENCE.md#reproduce-the-evidence) and [CI/CD map](docs/ci-cd-map.md).

[Full documentation index](docs/README.md) · [Code map](CODEMAP.md) · [Design system](DESIGN.md) · [MIT License](LICENSE).

## Screenshots

Simulator captures using sample data: the iPhone app runs with
`-ReviewerDemoMode`; the watchOS and tvOS companions use illustrative sample Feed
data. See the [reviewer guide](docs/portfolio.md) and
[Watch & TV walkthrough](docs/watch-tv-demo.md) for demo steps.

### iPhone

| Dashboard | Feed | Items |
| --- | --- | --- |
| <img src="docs/screenshots/iphone/dashboard-light.png" width="220" alt="iPhone Dashboard with sample release-health metrics"> | <img src="docs/screenshots/iphone/feed-light.png" width="220" alt="iPhone Feed with sample posts"> | <img src="docs/screenshots/iphone/items-light.png" width="220" alt="iPhone Items with seeded sample entries"> |

### Apple Watch

| Feed | Headline detail |
| --- | --- |
| ![Apple Watch sample Feed with freshness status](docs/screenshots/watch-tv/watch-feed-40mm.png) | ![Apple Watch full headline detail](docs/screenshots/watch-tv/watch-headline-40mm.png) |

### Apple TV

#### Light appearance

![Apple TV sample Feed with focused headline in light appearance](docs/screenshots/watch-tv/tv-feed-light.png)

#### Dark appearance

![Apple TV sample Feed with focused headline in dark appearance](docs/screenshots/watch-tv/tv-feed-dark.png)

### Mac

![Native macOS Feed in Dark appearance](docs/screenshots/macos/feed-dark.png)
