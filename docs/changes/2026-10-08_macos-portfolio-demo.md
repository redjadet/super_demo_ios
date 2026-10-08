# 2026-10-08 — macOS portfolio demo path

## Summary

Document the native macOS portfolio demo path: unsigned CI compile-proof via
`./bin/ci-platform-builds.sh`, local unsandboxed Terminal / Xcode run steps, and
honesty boundaries (no Mac UITest gate; Flutter / widgets / share unlinked on
`macosx`).

## Changes

- Add [`docs/macos-demo.md`](../macos-demo.md) walkthrough (CI + local).
- Link from [`docs/portfolio.md`](../portfolio.md) next to the Watch/TV demo.
- No product / scheme / CI wiring changes — Mac was already first-class.

## Verification

- Tip `platform-builds` green includes Mac unsigned compile
  (`CODE_SIGNING_ALLOWED=NO`).
- Docs-only: `./bin/lint.sh` / checklist changes scope.
