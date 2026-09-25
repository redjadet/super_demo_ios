# 2026-09-25 — Offline invariants matrix (FP-P0-C)

## Why

Flutter-parity P0: make Feed/Items offline rules reviewable as named invariants
with evidence rows, instead of prose-only principles in `offline-first.md`.

## Changes

- Add [`docs/offline-invariants.md`](../offline-invariants.md) — **7** named
  invariants (OI-01…OI-07) mapped to `CachingFeedRepository`, Feed/Items
  Presentation, `AppModelContainer`, and existing unit tests.
- Link matrix from [`docs/offline-first.md`](../offline-first.md).
- Explicit **N/A** for Items remote-merge (local-only; no new sync engine).

## Proof

- Docs-only slice: `./bin/checklist-fast`
- Evidence already on `main`: `CachingFeedRepositoryTests`,
  `FeedFeatureModelTests`, `ItemsFeatureModelTests`,
  `SwiftDataItemRepositoryTests`, `AppModelContainerTests`
