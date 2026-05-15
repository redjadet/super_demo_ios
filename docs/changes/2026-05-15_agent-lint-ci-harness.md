# Agent lint and CI harness — 2026-05-15

## Added

- SwiftLint (`.swiftlint.yml`) and SwiftFormat (`.swiftformat`) with `bin/lint.sh` / `bin/format.sh`
- Xcode Run Script phase **Lint (SwiftLint & SwiftFormat)** via `Scripts/xcode-lint.sh`
- GitHub Actions workflow `.github/workflows/ci.yml`
- Local gate `./bin/ci.sh` (Swift lint, Markdown lint, build, test)
- Markdown lint `bin/lint-markdown.sh` + `.markdownlint.json`
- Checklist commands:
  - `./bin/checklist-fast` for Markdown/Swift lint, common issue checks, project sanity
  - `./bin/checklist` for lint, common issue checks, existing iPhone simulator build/test, iPad/Mac builds
- Focused common issue guard: `tool/check_common_issues.sh`
- `./bin/checklist` iPhone destination resolution:
  `CHECKLIST_IPHONE_DEST`, then booted iPhone, then preferred named iPhone,
  then first available iPhone.
- `./bin/checklist` serializes Xcode test execution by default to avoid cloned
  simulator worker memory churn. Set `CHECKLIST_ALLOW_PARALLEL_TESTS=1` to opt
  back into parallel test workers.
- Expanded SwiftLint opt-in policy for AI-agent-friendly iOS work:
  accessibility, Swift concurrency, XCTest quality, unsafe optional handling,
  modern Swift idioms, and universal-app custom rules.
- `.gitignore` for Xcode/macOS artifacts
- Cursor rules under workspace `.cursor/rules/`
- Workspace `AGENTS.md` pointer; expanded `superDemoApp/AGENTS.md` and agent docs

## Verify

```bash
cd superDemoApp
./bin/ci.sh
./bin/checklist-fast
```
