# 2026-05-16 — Portfolio documentation and Feed roadmap

## Summary

- **Docs shipped (this change set):**
  - [`README.md`](../../README.md) — Portfolio (reviewers) section: purpose,
    skill map (with planned Feed footnote); links `docs/portfolio.md` +
    architecture tour.
  - [`docs/portfolio.md`](../portfolio.md) — Guided tour; clarifies Feed as
    planned vs merged Swift.
  - [`docs/sync-and-networking.md`](../sync-and-networking.md) —
    **Portfolio Feed** subsection (URL, timeouts, DTO/repo, CI stubs).
  - [`docs/README.md`](../README.md) — Portfolio link at Start Here.

- **Swift / Xcode (pending Agent-mode implementation):**
  - Tab shell, `Features/Feed/*`, `FeedComposition.swift`,
    SwiftData **`CachedFeedPost`** schema in `superDemoAppApp`.
  - Docs describe target architecture until that lands.

## Proof (docs touches)

From git root **`superDemoApp/`**: `./bin/lint-markdown.sh`
([`AGENTS.md`](../../AGENTS.md)).

## Follow-up when Feed code merges

**Done** — see [`2026-05-16_feed-feature-shipped.md`](2026-05-16_feed-feature-shipped.md).

1. ~~Add sibling `docs/changes/` note with wired paths + `./bin/ci.sh` proof.~~
2. ~~Remove “planned” footnotes from [`README.md`](../../README.md),
   [`portfolio.md`](../portfolio.md) **How to read**.~~
3. ~~Check reviewer boxes in [`portfolio.md`](../portfolio.md) vs CI/device.~~
   (VoiceOver remains a manual reviewer step.)
