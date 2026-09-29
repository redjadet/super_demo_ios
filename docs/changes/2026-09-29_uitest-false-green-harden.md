# 2026-09-29 — UITest tab / Feed–Items chrome false-green harden

## Why

After [#44](https://github.com/redjadet/super_demo_ios/pull/44) tip `4a39dcb`
had green Delivery, residual UITest honesty gaps remained (audit rank 3):

1. **`tapFirstHittable`** returned silently when a tab accessibility id was
   missing — `openTab` could no-op and later chrome waits still pass on the
   wrong tab.
2. **`waitForFeedChrome`** / **`waitForItemsChrome`** treated
   `app.cells.firstMatch` as proof — Dashboard and Items also expose cells, so
   Feed/Items smoke could false-green without leaving Dashboard.

## Changes

- **`UiTestSupport`:** fail when tab id never appears; Feed chrome requires
  feed-scoped ids (`feedList`, `feedPostRow-*`, `feedPostDetail-*`, refresh /
  retry / empty / error / stale banner); Items chrome requires `itemsList` /
  `itemRow-*` / `itemDetail` / add / empty / error — no bare cells.
- **`docs/testing.md`:** document the hardened helpers.
- **Portfolio tip pin:** `9aa3e05` → `4a39dcb` (bundled with honesty — not
  tip-pin-only).

## Proof

Hosted GHA `iphone-test` + Delivery checklist (Linux cloud agent has no
Simulator.app). Local Linux: common-issues + markdown + router + scorecard.

## Deferred (unchanged)

Mac P2-A light/dark screenshots, private Mac worker, visionOS, paid StoreKit,
real APNs.
