# 2026-09-27 — Universal-link host parity + portfolio tip pin

## Why

After [#37](https://github.com/redjadet/super_demo_ios/pull/37), tip was
`296211b` but `docs/portfolio.md` still pinned `f7a2a5e`. Separately,
`AppDeepLink.associatedHosts` accepted `www.superdemo.app` while entitlements
only declare `applinks:superdemo.app` — parser/tests implied Safari handoff
www could never provide. Agent env setup still named GHA `macos-26` as the
XCTest host after Delivery moved to `xcode-27`.

## Changes

- **Swift:** apex-only `associatedHosts`; reject `https://www.superdemo.app/…`.
- **Tests:** apex HTTPS path coverage + explicit www rejection.
- **Gate:** `./tool/check_aasa_deep_links.sh` also asserts
  `associatedHosts` ↔ `applinks:` entitlement host set equality.
- **Docs:** portfolio tip → `296211b`; navigation / associated-domains README
  apex honesty; `agent_environment_setup.md` XCTest host → `xcode-27`.

## Deferred (unchanged)

Mac P2-A screenshots, private Mac worker, visionOS, paid StoreKit, real APNs.
