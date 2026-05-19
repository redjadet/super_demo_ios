# superDemoApp

![Xcode](https://img.shields.io/badge/Xcode-26.5-147EFB?logo=xcode&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.3.2-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-SDK%2026-0D96F6?logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20iPadOS%20%7C%20macOS-000000?logo=apple&logoColor=white)
![Minimum OS](https://img.shields.io/badge/Minimum%20OS-26.0-6E6E73?logo=apple&logoColor=white)
![SwiftData](https://img.shields.io/badge/Persistence-SwiftData-0A84FF?logo=swift&logoColor=white)
![Testing](https://img.shields.io/badge/Tests-Swift%20Testing-F05138?logo=swift&logoColor=white)

`superDemoApp` is a universal Apple app for iPhone, iPad, and Mac. It demonstrates a
polished SwiftUI experience, offline-capable data flows, production-minded networking,
UIKit interoperability, and a maintainable project foundation suitable for continued
product work.

## Highlights

- Native Apple interface across iOS, iPadOS, and macOS.
- Clean feature organization with room for growth.
- Production Readiness Dashboard for architecture, API health, release risk, design
  consistency, and AI-assisted validation.
- URLSession async/await client with typed errors, retry policy, token refresh, 429
  handling, cancellation, idempotency protection, and redacted logging hooks.
- UIKit collection-view showcase with reusable cells, prefetching, SwiftUI detail hosting,
  and custom UINavigationController transitions.
- Objective-C interoperability through a narrow legacy utility bridge.
- Local persistence, remote feed loading, and cached fallback behavior.
- Automated quality checks for development and review.

## Get Started

Open `superDemoApp.xcodeproj` in Xcode.

For setup, validation, architecture, and implementation details, use the documentation
index: [`docs/README.md`](docs/README.md).

Command-line proof from repo root:

```bash
./bin/lint.sh
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 17' test
./bin/ci.sh
```

## Reviewer Tour

1. Open the **Dashboard** tab first. It is the senior iOS assessment surface.
2. Review `Features/ProductionReadiness/` for feature/domain/data boundaries and
   SwiftUI state ownership.
3. Review `Shared/Networking/` for retry, token refresh, idempotency, cancellation, and
   redacted logging.
4. Open **UIKit Showcase** from Dashboard to see collection view reuse/prefetching,
   SwiftUI-in-UIKit hosting, and a custom push/pop transition.
5. Review `Shared/LegacyObjC/` for Objective-C interop with nullability and a narrow
   Swift wrapper.

## Adding A Feature Module

- Start with `Features/<FeatureName>/{Presentation,Domain,Data}` only when the feature has
  rules, side effects, or testable business logic.
- Keep Domain pure Swift; keep SwiftUI in Presentation; keep URLSession/SwiftData in Data
  or Shared adapters.
- Wire dependencies in `App/*Composition.swift`.
- Add deterministic unit tests and preview/sample states before relying on manual launch.

## TestFlight And Release

- Archive with Xcode or `TESTFLIGHT_BUILD_NUMBER=<unique-build-number> ./bin/fastlane-run ios beta`.
- Fastlane beta runs existing CI proof, builds a clean App Store archive, uploads to
  TestFlight, and uses release notes from `docs/release-notes/testflight.md`.
- App Store upload: `./bin/fastlane-run ios release` with notes from
  `docs/release-notes/app-store.md` (review submission is opt-in via
  `APP_STORE_SUBMIT_FOR_REVIEW=1`).
- Suggested GitHub Actions gate: lint, unit/UI tests on iPhone simulator, iPad build,
  macOS build, then archive on a signed release runner.
- Before TestFlight, complete [`docs/release-checklist.md`](docs/release-checklist.md) and
  [`docs/production-risks.md`](docs/production-risks.md).

## Monitoring Checklist

- Crash reporting configured for TestFlight and App Store builds.
- OSLog categories for networking, release checks, and device-only failures.
- No secrets or authorization headers in logs.
- Feature flags or remote config for risky rollout paths.
- App Store review notes for permissions, background modes, deep links, and demo accounts.

## Documentation

- Product and reviewer tour: [`docs/portfolio.md`](docs/portfolio.md)
- Architecture: [`docs/architecture.md`](docs/architecture.md)
- Design system: [`DESIGN.md`](DESIGN.md) and [`docs/design_system.md`](docs/design_system.md)
- Release checklist: [`docs/release-checklist.md`](docs/release-checklist.md)
- Production risks: [`docs/production-risks.md`](docs/production-risks.md)
- Universal platform support: [`docs/universal-apple-platforms.md`](docs/universal-apple-platforms.md)
- Development workflow: [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md)
- AI-assisted development notes: [`AGENTS.md`](AGENTS.md)
