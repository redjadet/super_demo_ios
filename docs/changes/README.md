# Changes

Record durable implementation notes after meaningful changes.

## Entries

- [`2026-09-25_feature-modularity-guards.md`](2026-09-25_feature-modularity-guards.md)
  — FP-P1-A feature folder contract + cross-feature import leak checks in lint.
- [`2026-09-25_engineering-quality-scorecard.md`](2026-09-25_engineering-quality-scorecard.md)
  — FP-P0-B Engineering scorecard (min-of-areas) + honest gate + README badge.
- [`2026-09-25_adr-bootstrap.md`](2026-09-25_adr-bootstrap.md)
  — FP-P0-D ADR index (layering, offline, crash deferral, Sonar skip, CI honesty).
- [`2026-09-25_codemap_architecture_tour.md`](2026-09-25_codemap_architecture_tour.md)
  — Root CODEMAP + ≤15-min architecture tour + lean README/AGENTS links (FP-P0-A).
- [`2026-09-25_offline-invariants-matrix.md`](2026-09-25_offline-invariants-matrix.md)
  — FP-P0-C named offline invariants (OI-01…OI-07) + link from offline-first.
- [`2026-09-15_agent-docs-bloc-patterns.md`](2026-09-15_agent-docs-bloc-patterns.md)
  — Minimal `docs/ai/` routing + safety contracts from bloc_test_app patterns.
- [`2026-09-15_swiftdata-store-recovery.md`](2026-09-15_swiftdata-store-recovery.md)
  — ModelContainer wipe + recreate before in-memory fallback.
- [`2026-09-15_mainactor-isolation-layer-check.md`](2026-09-15_mainactor-isolation-layer-check.md)
  — MainActor `nonisolated` constants + layer-check `rg`/`grep` fallback.
- [`2026-09-15_app-intents-open-destinations.md`](2026-09-15_app-intents-open-destinations.md)
  — App Intents + Shortcuts for Open Feed / Items / Production Risks.
- [`2026-09-15_signposts-cache-ttl.md`](2026-09-15_signposts-cache-ttl.md)
  — OSSignposter on Feed/UIKit + optional Feed cache TTL.
- [`2026-09-15_associated-domains.md`](2026-09-15_associated-domains.md)
  — Associated Domains entitlement + HTTPS universal-link path parsing.
- [`2026-09-15_keychain-token-demo.md`](2026-09-15_keychain-token-demo.md)
  — Flag-gated Keychain token refresher + AccessTokenStore; CI-safe Liquid Glass trim.
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
