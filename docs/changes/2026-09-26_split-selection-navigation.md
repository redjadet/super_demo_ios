# Fix split-view selection navigation (Feed / Items)

Date: 2026-09-26

## Why

Master/detail taps in Feed and Items appeared to do nothing: destination-only
`NavigationLink` inside `NavigationSplitView` (and nested under Dashboard) never
updated the detail column. Stale Feed demo had the same nested-stack problem.

## Changes

- `FeedPost` / `ItemEntity`: `Hashable` for value links + list selection.
- Feed / Items: `List(selection:)` + `NavigationLink(value:)` + selection-driven
  detail in feature shells via `AdaptiveNavigationShell(preferredCompactColumn:)`.
- Compact: flip `preferredCompactColumn` to `.detail` when selection is set.
- Items: clear selection when the selected row is deleted.
- Stale Feed demo: `FeedView(embedsOwnNavigation: false)` on Production Readiness's
  stack (no nested split/stack) so rows push detail and a11y id stays findable.
- Catalog: String Catalog comment refresh in `Localizable.xcstrings`.

## Proof

- `./bin/verify-swift.sh`
- `./bin/checklist` (navigation / universal UI)
