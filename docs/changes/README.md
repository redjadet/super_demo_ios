# Changes

Record durable implementation notes after meaningful changes.

## Entries

- [`2026-09-26_flutter-add-to-app.md`](2026-09-26_flutter-add-to-app.md)
  — JP-P2-D Flutter module embed + MethodChannel `feed.cacheStatus`.
- [`2026-09-25_storekit-product-query-demo.md`](2026-09-25_storekit-product-query-demo.md)
  — JP-P1-D StoreKit 2 product query Engineering demo (config file; no purchase).
- [`2026-09-25_performance-lab-widget-concurrency.md`](2026-09-25_performance-lab-widget-concurrency.md)
  — JP-P1-E performance lab: widget App Group recipe + concurrency talk track;
  Live Activity pending JP-P1-A.
- [`2026-09-25_local-notification-demo.md`](2026-09-25_local-notification-demo.md)
  — JP-P1-C local stale-Feed reminder demo (not APNs).
- [`2026-09-25_refresh-feed-app-intent.md`](2026-09-25_refresh-feed-app-intent.md)
  — JP-P1-B parameterized Refresh Feed App Intent + typed `feedRefreshRequestID`.
- [`2026-09-25_checklist_gate.md`](2026-09-25_checklist_gate.md)
  — Delivery checklist gate + Flutter-named bin/tooling parity (`tooling_map.md`).
- [`2026-09-25_native-host-bridge.md`](2026-09-25_native-host-bridge.md)
  — JP-P0-C native host-bridge contract (`feed.cacheStatus`) + Engineering demo.
- [`2026-09-25_widgetkit-feed-snapshot.md`](2026-09-25_widgetkit-feed-snapshot.md)
  — JP-P0-B WidgetKit Feed App Group snapshot + iOS-only extension embed.
- [`2026-09-25_platform-skill-map.md`](2026-09-25_platform-skill-map.md)
  — JP-P0-A platform surfaces inventory on portfolio map (honest not-in-repo rows).
- [`2026-09-25_code-quality-overview.md`](2026-09-25_code-quality-overview.md)
  — FP-P1-D code quality overview + coverage honesty (no fake `%` badge).
- [`2026-09-25_agent-worktree-maintain.md`](2026-09-25_agent-worktree-maintain.md)
  — FP-P1-C agent-worktree + thin agent-maintain; FP-P1-B harness scorecard +
  SAFETY-REPORT template.
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
