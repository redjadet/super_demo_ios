# Change — Enforce SwiftFormat pin after Brewfile on CI

**Date:** 2026-10-07

`brew bundle check` treats any installed SwiftFormat as satisfied. With
`HOMEBREW_NO_AUTO_UPDATE=1`, Checklist · lint could see **0.63.1** while
Checklist · iPhone build kept **0.63.0**, failing the Xcode Lint script pin
gate (`SwiftFormat 0.63.1 required, got 0.63.0`).

Add `tool/ensure_lint_tool_pins.sh` and call it from `setup-ios-ci` (+ release
smoke) after Brewfile install: `brew update` + upgrade/reinstall until the
installed version matches `EXPECTED_SWIFTFORMAT_VERSION` (still **0.63.1**).
