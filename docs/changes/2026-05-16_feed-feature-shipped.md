# 2026-05-16 — Feed feature shipped

## Summary

- **`Features/Feed/`** — Domain, Data (JSONPlaceholder + `CachingFeedRepository`),
  Presentation (`FeedFeatureModel`, `FeedView`, `FeedNavigationShell`).
- **`App/`** — `AppRootView` (Items + Feed tabs), `FeedComposition` /
  `ItemsComposition`, `AppModelContainer` (`Item` + `CachedFeedPost`).
- **Tests** — `superDemoAppTests/Features/Feed/*`; UI test `testFeedTabIsReachable`.
- **Composition stability** — `FeedRootContent` / `ItemsRootContent` hold
  `@State` feature models so SwiftData-backed repositories are not recreated every
  `body` evaluation; refresh keeps visible content during in-flight reload
  (`ItemsFeatureModelTests`, `FeedFeatureModelTests`).
- **UI tests** — `UiTestSupport` helpers for tab + Items chrome across launch
  configurations; `.swiftformat` no longer uses `--xcodeindentation` (matches
  `.editorconfig` 4-space indent).

## Docs sync

- [`README.md`](../../README.md) — Portfolio skill map lists Feed as shipped.
- [`docs/portfolio.md`](../portfolio.md) — Tour + reviewer checklist updated.
- [`docs/sync-and-networking.md`](../sync-and-networking.md) — Feed section current.

Prior roadmap: [`2026-05-16_portfolio-documentation-and-feed-roadmap.md`](2026-05-16_portfolio-documentation-and-feed-roadmap.md).

## Proof

From git root **`superDemoApp/`**:

```bash
./bin/lint.sh
./bin/ci.sh
```
