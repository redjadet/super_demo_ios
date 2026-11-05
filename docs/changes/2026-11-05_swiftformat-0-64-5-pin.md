# Change — SwiftFormat pin 0.64.5

**Date:** 2026-11-05

After squash-merge of #114 (`b46b48a`), tip Delivery failed on Checklist · lint,
platform builds, and iPhone build during `tool/ensure_lint_tool_pins.sh`: runners
had SwiftFormat **0.64.3**, `brew upgrade` resolved to Homebrew stable **0.64.5**,
which did not match pin **0.64.1**.

Bump `EXPECTED_SWIFTFORMAT_VERSION` (and Brewfile / `docs/code-style.md`
comments) to **0.64.5**, matching current Homebrew stable on hosted runners.

## Proof

- Local: `swiftformat --version` → `0.64.5`; `./tool/check_swiftformat_version.sh`
- Tip CI red: [run 42014103935](https://github.com/redjadet/super_demo_ios/actions/runs/42014103935)
  (`SwiftFormat 0.64.1 required after brew sync, got 0.64.5`)
