# Change — SwiftFormat pin 0.64.1

**Date:** 2026-10-23

Homebrew stable moved past the repo pin **0.63.1**. Tip `562e03c` (#112)
Delivery failed on Checklist · lint / iPhone build during
`tool/ensure_lint_tool_pins.sh`: runners already had SwiftFormat **0.64.0** and
could not satisfy the older pin after `brew upgrade`.

Bump `EXPECTED_SWIFTFORMAT_VERSION` (and Brewfile / `docs/code-style.md`
comments) to **0.64.1**, matching current Homebrew stable on the Mac mini agent
host. `ensure_lint_tool_pins.sh` still refreshes + upgrades until the installed
CLI matches the pin.

## Proof

- Local: `swiftformat --version` → `0.64.1`; `./tool/check_swiftformat_version.sh`
- Tip CI red: [run 39800992964](https://github.com/redjadet/super_demo_ios/actions/runs/39800992964)
  (`SwiftFormat 0.63.1 required after brew sync, got 0.64.0`)
