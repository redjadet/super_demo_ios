# 2026-09-30 — DESIGN / README / AccentColor amateur polish

## Intent

Close high-confidence cold-path unfinished signals found on tip `b8c494e`
(after #59): broken Liquid Glass prose in `DESIGN.md`, duplicate README mid-page
links, and an empty `AccentColor` asset catalog entry.

## Changes

- [`../../DESIGN.md`](../../DESIGN.md) — repair dangling-comma Liquid Glass
  sentence left by `620a75e`; document `tabBarMinimizeBehavior(.automatic)`;
  link [`../ai_code_review_protocol.md`](../ai_code_review_protocol.md).
- [`../../README.md`](../../README.md) — after #59 hero links, keep mid-page
  **CODEMAP** only (drop repeated tour / scorecard / portfolio row).
- [`../../superDemoApp/Assets.xcassets/AccentColor.colorset/Contents.json`](../../superDemoApp/Assets.xcassets/AccentColor.colorset/Contents.json)
  — set Any `#0066CC` + Dark `#0A84FF` so catalog accent matches DESIGN primary
  (was empty → Xcode system default).

## Honesty

- App Icon still has no custom PNG (Xcode placeholder) — deferred human/design
  asset; not inventing a generated mark this pass.
- Portfolio tip pin left at `fc2837a` / `#36–#57` (tip-pin-only skip).
- No Swift behavior / UITest changes.
