# CI workflow parity and build fixes

## Summary

- GitHub Actions now runs **`./bin/ci.sh`** only (single source of truth with local CI).
- `bin/ci.sh` resolves iPhone simulator via `tool/resolve_platform_destination.sh` (works on
  GHA runners without hard-coded OS version).
- `bin/ci.sh` runs `tool/check_common_issues.sh` after markdown lint.
- Fixed compile error: `.dark` preview trait unavailable — use `.previewDarkAppearance()`.
- `bin/lint-markdown.sh` excludes vendored `.agents/**` (already landed).

## Failed runs addressed

| Failure | Fix |
| ------- | --- |
| `AGENTS.md` MD060 table spacing | Tables use spaced pipes (`\| Path \|`) |
| Drifted workflow vs `ci.sh` | Workflow delegates to `./bin/ci.sh` |
| `PreviewTrait` has no member `dark` | `.previewDarkAppearance()` helper |

## Follow-up

- GHA needs `ripgrep` for `tool/check_common_issues.sh` — added to `Brewfile`.
- Project targets iOS 26.5 — CI uses `macos-26` and pins **Xcode 26.5** via `tool/select_xcode_26_5.sh`.
- `tool/ensure_ci_simulator.sh` boots or creates an iPhone on the **newest installed iOS
  Simulator runtime**. On GHA it does **not** run `xcodebuild -downloadPlatform` when the
  SDK patch is ahead of the runtime (e.g. SDK 26.5, runtime 26.4) — that download stalls CI.
- `resolve_iphone_destination` prefers an iPhone on that newest runtime (not the first
  device in `simctl list`).
- Superseded on 2026-05-18: GitHub Actions now uses parallel lint, iPhone test,
  and platform-build lanes; see [`2026-05-18_ci-parallel-lanes.md`](2026-05-18_ci-parallel-lanes.md).

## Proof

```bash
./bin/ci.sh
```
