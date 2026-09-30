# 2026-09-30 — Local platform validation

## Repairs

The visionOS build called an iOS-only sidebar modifier and used the unavailable
SwiftUI `.glass` button style. Keep the adaptive sidebar modifier on iOS; use
native split-view column widths elsewhere. Apply glass chrome only on iOS and
macOS, where the API is supported.

`VisionDemoObservation` is a Sendable value constructed by the OCR worker.
Mark its initializer `nonisolated` so Swift's default MainActor isolation does
not require a hop to construct that value.

## Verification

Local Xcode 27.0 compilation passed for visionOS and watchOS with warnings as
errors. Swift format, lint, and repository guards passed. Full available test
results and environment limits are recorded under the ignored local evidence
folder `tasks/codex/local-platform-tests-2026-09-30/`.

No visionOS or watchOS Simulator runtime was installed during this run.
The watch companion has no test target. Mac UI execution requires authenticated
Automation Mode; ad-hoc host runs do not validate production entitlements.
