# 2026-09-27 — CODEMAP path honesty + Markdown link-gate self-test

## Why

Post-#39 tip `d21d81a` still had agent-facing path drift and an ungated
link-check regression surface:

1. `CODEMAP.md` used abbreviated paths (`AppNavigation.swift`,
   `App/ActivityKit…`, bare `Shared/…`) that do not resolve from the repo root.
2. `share-inbox.json` looked like a tracked file; it is an App Group runtime
   name only.
3. `docs/tooling_map.md` omitted `check_markdown_relative_links.sh` after #39.
4. The new Markdown link gate had no `--self-test` and would fail if fixtures
   ever contained intentional broken hrefs.

## Changes

- CODEMAP rows use root-resolvable `superDemoApp/…` paths; clarify App Group
  inbox file name.
- `tool/check_markdown_relative_links.sh --self-test`; skip `fixtures/` dirs;
  wired from `check_common_issues.sh`.
- `docs/tooling_map.md` row for the Markdown relative-link gate.
- Portfolio inventory pin → `d21d81a` (post #36–#39).

## Deferred (unchanged)

Mac P2-A screenshots, private Mac worker, visionOS, paid StoreKit, real APNs.
