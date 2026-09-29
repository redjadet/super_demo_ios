# 2026-09-29 — Flutter demo UITest host-screen false-green

## Summary

`testFlutterAddToAppDemoIsReachable` no longer treats the host
`flutterAddToAppDemoScreen` id as a successful outcome. Outcome wait requires
embedded **or** unavailable chrome (including host-bridge link on the
unavailable path).

## Why

Mac Codex scan on tip `a7424bc` (rank 2; residual after #51):
`openEngineeringDemo` already required the host screen id, so including it in
the outcome set let a missing embed/unavailable surface still pass.

## Changes

- `EngineeringDemosUITests.testFlutterAddToAppDemoIsReachable` — drop host id
  from outcome set; fail message names missing outcome chrome; prefer
  typed a11y queries for outcome chrome
- `FlutterModuleDemoView` — native embedded caption; parent uses
  `accessibilityElement(children: .contain)` so host id does not swallow
  children; Flutter representable `accessibilityHidden` (avoid XCTest hang
  on Flutter semantics); no UIKit stamp on `FlutterViewController.view`
- `UiTestSupport.openEngineeringDemo` — dashboard-scoped link query, scroll
  to top before search, stronger drag/swipe for mid-list links (Feed widget)
- `testDashboardShowsProductionRisks` — use `openEngineeringDemo` (CI missed
  CollectionView link via `app.buttons` + unscrolled swipe; tip `31e25c3`)
- Portfolio tip pin → `ab6784c` / #51; `docs/testing.md` row clarified

## Proof

- GHA Delivery UITests on this PR (iPhone lane) — recovery after
  `Flutter demo missing embedded or unavailable outcome chrome` on tip
  `5bd83dc` / run 36591691457 and tip `8b79706` / run 36596285410
  (also `Missing demo link feedWidgetSnapshotDemoLink` + 3600s hang);
  tip `31e25c3` / run 36606688446: Flutter + Feed widget **passed**; lone
  fail `testDashboardShowsProductionRisks`
- Linux: common-issues / scorecard / markdown / router

## Out of scope

Feed Retry UITest no-op (Codex rank 3); Mac P2-A; visionOS.
