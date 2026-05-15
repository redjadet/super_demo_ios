# Agent lint and CI harness — 2026-05-15

## Added

- SwiftLint (`.swiftlint.yml`) and SwiftFormat (`.swiftformat`) with `bin/lint.sh` / `bin/format.sh`
- Xcode Run Script phase **Lint (SwiftLint & SwiftFormat)** via `Scripts/xcode-lint.sh`
- GitHub Actions workflow `.github/workflows/ci.yml`
- Local gate `./bin/ci.sh` (Swift lint, Markdown lint, build, test)
- Markdown lint `bin/lint-markdown.sh` + `.markdownlint.json`
- `.gitignore` for Xcode/macOS artifacts
- Cursor rules under workspace `.cursor/rules/`
- Workspace `AGENTS.md` pointer; expanded `superDemoApp/AGENTS.md` and agent docs

## Verify

```bash
cd superDemoApp
./bin/ci.sh
```
