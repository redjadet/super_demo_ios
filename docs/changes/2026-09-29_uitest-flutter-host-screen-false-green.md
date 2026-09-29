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
  from outcome set; fail message names missing outcome chrome
- `FlutterModuleDemoView` — native embedded caption + UIKit
  `FlutterViewController.view` accessibility for `flutterAddToAppEmbedded`
  (SwiftUI id on `UIViewControllerRepresentable` is not XCTest-visible through
  Flutter; GHA iPhone links Flutter so unavailable chrome is absent)
- Portfolio tip pin → `ab6784c` / #51; `docs/testing.md` row clarified

## Proof

- GHA Delivery UITests on this PR (iPhone lane) — recovery after
  `Flutter demo missing embedded or unavailable outcome chrome` on tip
  `5bd83dc` / run 36591691457
- Linux: common-issues / scorecard / markdown / router

## Out of scope

Feed Retry UITest no-op (Codex rank 3); Mac P2-A; visionOS.
