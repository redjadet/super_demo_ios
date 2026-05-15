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
- Project targets iOS 26.5 — workflow selects newest `Xcode_26*.app` on the runner.
- `resolve_iphone_destination` falls back to `generic/platform=iOS Simulator` when no
  concrete simulator destinations exist for the active Xcode.

## Proof

```bash
./bin/ci.sh
```
