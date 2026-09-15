# 2026-09-15 — SwiftFormat version pin (P1 hygiene)

## Why

Local SwiftFormat **0.61.1** vs CI Homebrew floating caused indent CI fails
before helpers landed. Pin both sides to **0.63.0**.

## Changes

- `tool/expected_tool_versions.sh` — `EXPECTED_SWIFTFORMAT_VERSION=0.63.0`
- `tool/check_swiftformat_version.sh` — hard fail on mismatch
- `bin/lint.sh` / `bin/format.sh` — run the check before format/lint
- Brewfile + `docs/code-style.md` document the pin
- `docs/audits/2026-09-15_ci-green-baseline.md` records green CI evidence
