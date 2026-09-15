# 2026-09-15 — MainActor isolation warnings + layer-check rg fallback

## Why

Default MainActor isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`) made
shared constants and NotificationCenter observers warn under Swift 6. Xcode
run-script PATH often lacks ripgrep, so layer boundary checks could no-op or
fail the build phase.

## Changes

- `nonisolated` on App Intent notification name/key, Feed cache TTL, and
  OSSignposter handles; App Intent `open` stays `@MainActor`.
- `tool/check_layer_boundaries.sh` prefers `rg`, falls back to `grep -nE`.
- Tests capture the URL userInfo key outside the Sendable observer closure.

## Proof

- Xcode Issue Navigator: 0 warnings/errors.
- Unit + UI tests on iPhone 18 Pro Max; main CI green on `70fe3b8`.
