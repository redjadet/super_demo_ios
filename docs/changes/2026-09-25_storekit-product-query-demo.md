# 2026-09-25 — StoreKit 2 product query demo (JP-P1-D)

## Summary

Adds a labeled Engineering-demo **StoreKit 2 product query** path: load
products from the checked-in StoreKit Configuration file, list them, or show
an honest empty / unavailable state. **No purchase / charge path.**

## Paths

- `Config/Products.storekit` — local StoreKit Configuration (demo tip product)
- Scheme `superDemoApp`: StoreKit Configuration on Run + Test →
  `../../Config/Products.storekit` (relative to `xcshareddata/`)
- `superDemoApp/Shared/StoreKit/StoreKitProductQuerying.swift`
- `superDemoApp/Features/ProductionReadiness/Presentation/StoreKitProductQueryDemoView.swift`
- Dashboard → Engineering demos → **StoreKit 2 product query (demo)**
- Tests: `StoreKitProductQueryDemoTests` (querier spy)
- Docs: [`portfolio.md`](../portfolio.md), [`../CODEMAP.md`](../../CODEMAP.md)

## Proof

- Unit tests with querier spy (loaded / empty / unavailable / cancel)
- `./bin/verify-swift.sh`
- Hosted GHA Delivery checklist (`checklist` job); local `xcodebuild` may
  require a non-Cursor Terminal on this host (seatbelt FSEvents limitation)

## StoreKitTest limitation

`StoreKitTest` / `SKTestSession` needs Apple Xcode + the shared scheme’s
StoreKit Configuration. This Linux agent host cannot compile or run
StoreKitTest. Spy-based unit tests cover demo model honesty; live
`Product.products` listing is verified manually on Mac with the shared scheme
(or Simulator) when available.

## Honesty

- Demo product ID: `com.ilkersevim.superDemoApp.demo.tip` (non-consumable in
  config only — not an App Store Connect catalog claim)
- No `Product.purchase`, no payment sheet, no revenue path
