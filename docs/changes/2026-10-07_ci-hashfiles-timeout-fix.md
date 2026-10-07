# CI hashFiles timeout fix (2026-10-07)

## Why

Main Delivery went red after #86 (`c31230f`, run
[37591436293](https://github.com/redjadet/super_demo_ios/actions/runs/37591436293)):
**Checklist · iPhone build** failed during `setup-ios-ci` with

`hashFiles('Brewfile') couldn't finish within 120 seconds`

Lint + platform builds were green. Fallout from #85 overlapping background
`simctl` boot with composite cache template evaluation.

## What changed

- Replace GHA `hashFiles(...)` cache keys in
  `.github/actions/setup-ios-ci` with bash 3.2-safe shell digests.
- Start background simulator boot **after** setup/cache restore on
  `iphone` / `iphone-build` (still overlaps Flutter prepare +
  build-for-testing).

## Non-goals

- No product/Swift changes; no Delivery aggregator rename.
