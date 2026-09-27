# 2026-09-27 — Markdown relative-link honesty + tip pin

## Why

Re-scan of tip `1a269e2` (#38) found no Swift/product slice, but two real doc
href bugs and one stale change-note claim:

1. Root `DESIGN.md` linked `layers.md` (missing) instead of `docs/layers.md`.
2. `docs/changes/2026-05-15_design-harness-checklist.md` linked `../DESIGN.md`
   (resolves under `docs/`) and still said DesignMD was absent from `./bin/ci.sh`.
3. `docs/portfolio.md` tip pin lagged at `296211b` after #38 squash → `1a269e2`.

## Changes

- Fix `DESIGN.md` → `docs/layers.md`; fix change-note href + DesignMD history.
- Portfolio inventory pin → `1a269e2` (post #36/#37/#38).
- Gate: `./tool/check_markdown_relative_links.sh` via
  `./tool/check_common_issues.sh` (checklist-fast / lint).

## Deferred (unchanged)

Mac P2-A screenshots, private Mac worker, visionOS, paid StoreKit, real APNs.
