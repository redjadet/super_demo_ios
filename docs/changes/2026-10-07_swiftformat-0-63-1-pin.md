# Change — SwiftFormat pin 0.63.1

**Date:** 2026-10-07

Homebrew CI runners moved to SwiftFormat **0.63.1**, which failed
`tool/check_swiftformat_version.sh` while the repo still required **0.63.0**.

Bump `tool/expected_tool_versions.sh`, Brewfile comment, and `docs/code-style.md`.
