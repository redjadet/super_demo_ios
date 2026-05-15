# Agent-ready universal CI and Cursor template

## Summary

- `./bin/ci.sh` and GitHub Actions now compile for iPad simulator and macOS after
  iOS Simulator tests.
- Added `bin/ci-platform-builds.sh` and `tool/resolve_platform_destination.sh` for
  portable destinations.
- Tracked Cursor rules/MCP under `tool/cursor-template/` with
  `./tool/install-cursor-rules.sh`.
- Documented Cursor MCP priority, validation chooser, and UI smoke test in CI.

## Agent impact

- Before merge/PR: run `./bin/ci.sh` (not iPhone-only proof).
- Universal SwiftUI work: run `./bin/checklist` before handoff.
- After clone: `./tool/install-cursor-rules.sh` then restart Cursor.
