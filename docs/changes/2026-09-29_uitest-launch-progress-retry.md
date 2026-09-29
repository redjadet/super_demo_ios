# 2026-09-29 — UITest launch-progress retry

## Summary

`UiTestSupport.launchApplication(from:)` temporarily allows
`continueAfterFailure` so one terminate + relaunch can recover from “Timed out
while requesting launch progress”. `bin/ci-iphone-test.sh` also retries once
after sim reboot on that message (same path as Accessibility load flakes).

`XCUIApplication.launchTimeout` is **not** used — it does not compile on CI
Xcode 27.1 beta (Delivery run
[36585758371](https://github.com/redjadet/super_demo_ios/actions/runs/36585758371)).

## Why

PR #51 Delivery run [36576125333](https://github.com/redjadet/super_demo_ios/actions/runs/36576125333):
`testOnDeviceVisionDemoRecognizesOrReportsHonestState` failed after ~917s on
launch progress (not widget TTL logic), then the job hit the 3600s hard wall.
A follow-up that set `app.launchTimeout` failed to compile (exit 65).

## Proof

- GHA Delivery on this PR after push (iPhone lane)
- Linux: common-issues / markdown / router (no SwiftLint on Linux for UITests)
