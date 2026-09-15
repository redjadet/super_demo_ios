# Changes

Record durable implementation notes after meaningful changes.

## Entries

- [`2026-09-15_liquid-glass-chrome.md`](2026-09-15_liquid-glass-chrome.md)
  — Tab API + chrome-only Liquid Glass helpers (toolbars / empty actions).
- [`2026-09-15_swiftformat-version-pin.md`](2026-09-15_swiftformat-version-pin.md)
  — Pin SwiftFormat **0.63.0** in lint/format gates; CI-green audit note.
- [`2026-09-15_feed-items-diagnostics-hardening.md`](2026-09-15_feed-items-diagnostics-hardening.md)
  — Cancel-safe refresh, stale feed cache UI, deep links, OSLog crash monitor,
  ModelContainer recovery; docs aligned to Xcode 27 / Swift 6.4 (CI picks newest
  released Xcode on `macos-26`).
- [`2026-05-19_ui-test-ci-stability.md`](2026-05-19_ui-test-ci-stability.md)
  — UI test terminate between launches, Feed sample repo under `-UITesting`, CI fix.
- [`2026-05-18_fastlane-ci-wrapper-hardening.md`](2026-05-18_fastlane-ci-wrapper-hardening.md)
  — Fastlane env isolation, generated-output cleanup, and wrapper docs.
- [`2026-05-18_ci-parallel-lanes.md`](2026-05-18_ci-parallel-lanes.md)
  — GitHub Actions lint/test/platform proof split into parallel lanes with
  `lint-build-test` preserved as aggregate gate.
- [`2026-05-16_feed-feature-shipped.md`](2026-05-16_feed-feature-shipped.md)
  — Feed tab, layered module, SwiftData cache, tests, doc sync.
- [`2026-05-16_portfolio-documentation-and-feed-roadmap.md`](2026-05-16_portfolio-documentation-and-feed-roadmap.md)
  — Portfolio reviewer docs (pre-Feed Swift); follow-up completed in shipped note above.
- See also dated files in this folder (`2026-05-15_*.md`).

Use this for:

- migration notes,
- cross-cutting behavior changes,
- bug-fix summaries with proof,
- decisions too small for a full plan.
