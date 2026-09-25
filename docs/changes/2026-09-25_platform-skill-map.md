# 2026-09-25 — Platform skill map (JP-P0-A)

## Summary

Docs-only inventory of Apple-platform / hybrid-native skill-bar rows against
`origin/main` @ `6abb79a`. Adds a **Platform surfaces** table to
[`docs/portfolio.md`](../portfolio.md) with explicit **Not in repo** rows (no
broken links to missing WidgetKit / host-bridge / StoreKit paths). Lean README +
CODEMAP pointers only.

## Inventory method

1. Synced checkout to remote `main` tip `6abb79a` (FP P0–P1 already merged).
2. Verified present: `CODEMAP.md`, `docs/architecture-tour.md`,
   `docs/offline-invariants.md`, `docs/engineering/engineering-quality-scorecard.md`,
   `docs/modularity.md`, App Intents, LegacyObjC, Diagnostics, Feed cache.
3. Verified absent: WidgetKit target, ActivityKit, Share extension, SIWA,
   StoreKit 2, HostBridge, Core ML / Vision / Speech demos.

## Proof

- `./bin/lint-markdown.sh`
- `./bin/checklist-fast` docs/lint lane (note any local `xcodebuild -list` host
  abort separately; docs-only slice)

## Non-goals

- No new extension targets or entitlements in this slice.
- No employer / apply framing; sibling Flutter-parity and product portfolio plans
  stay separate.
