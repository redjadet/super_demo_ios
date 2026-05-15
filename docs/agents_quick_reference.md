# Agent Quick Reference

Commands and routing lookup.

## Discovery

```bash
git status --short
xcodebuild -list -project superDemoApp.xcodeproj
rg "SymbolName" superDemoApp superDemoAppTests superDemoAppUITests
```

XcodeBuildMCP active profile: `superDemoApp`
(`../.xcodebuildmcp/config.yaml`). If MCP tools are available, call
`session_show_defaults` before build/run/test and prefer MCP simulator tools.

## Validation Chooser

| Change type | Minimum proof |
| --- | --- |
| Docs / tooling / small Swift | `./bin/checklist-fast` |
| Domain / Data logic | `./bin/lint.sh` + targeted tests |
| SwiftUI layout, navigation, universal UI, light/dark | `./bin/checklist` |
| Before merge / PR | `./bin/ci.sh` (matches GitHub Actions) |

`CI_SKIP_PLATFORM_BUILDS=1` skips iPad/Mac in `./bin/ci.sh` only when intentionally narrow.
UI smoke: `superDemoAppUITests.testLaunchShowsAddItemControl` in CI iPhone test lane.

| Situation | Command |
| --- | --- |
| Project/scheme sanity | `xcodebuild -list -project superDemoApp.xcodeproj` |
| Swift lint + layer boundaries | `./bin/lint.sh` |
| Layer boundaries only | `./tool/check_layer_boundaries.sh` |
| Markdown lint gate | `./bin/lint-markdown.sh` |
| DESIGN.md DesignMD lint (needs Node; in checklists) | `./tool/check_design_md.sh` |
| Fast checklist (markdown + DesignMD + lint + sanity) | `./bin/checklist-fast` |
| Full checklist (above + iPhone test + iPad/Mac) | `./bin/checklist` |
| Full local CI | `./bin/ci.sh` |
| iPad + Mac builds only | `./bin/ci-platform-builds.sh` |
| Install Cursor rules (after clone) | `./tool/install-cursor-rules.sh` |
| Restore team Apple skills from lockfile | `npx skills experimental_install -y` (from git root) |
| Safe formatting | `./bin/format.sh` |
| Compile app | `xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 17' build` |
| iPad build sanity | `xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build` |
| Mac build sanity | `xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=macOS' build` |
| Unit + UI test sweep | `xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 17' test` |
| Available simulators | `xcrun simctl list devices available` |
| Xcode destinations | `xcodebuild -showdestinations -project superDemoApp.xcodeproj -scheme superDemoApp` |
| Source search | `rg "pattern" superDemoApp superDemoAppTests superDemoAppUITests docs` |

## Routing

- Apple defaults: [`apple-development-practices.md`](apple-development-practices.md)
- Architecture / `Features/` work: [`architecture.md`](architecture.md), [`layers.md`](layers.md), [`module-structure.md`](module-structure.md), [`feature-template.md`](feature-template.md)
- SwiftUI state: [`state-management.md`](state-management.md)
- Universal/responsive UI: [`universal-apple-platforms.md`](universal-apple-platforms.md)
- Light/dark policy: [`design_system.md`](design_system.md#light-and-dark-mode-required-from-day-one)
- SwiftData/offline: [`offline-first.md`](offline-first.md)
- API/sync: [`sync-and-networking.md`](sync-and-networking.md)
- Tests: [`testing.md`](testing.md)
- Review: [`ai_code_review_protocol.md`](ai_code_review_protocol.md)

## Reminders

- Start from current diff.
- Use Apple-native frameworks first; document dependency tradeoffs.
- Keep changes surgical.
- Prefer `./bin/checklist-fast` for docs/tooling/small Swift edits.
- Use `./bin/checklist` for SwiftUI layout/navigation/universal UI before handoff.
- Use `./bin/ci.sh` before merge/PR (includes iPad/Mac builds).
- `./bin/checklist` resolves an available iPhone simulator automatically; set `CHECKLIST_IPHONE_DEST` only when a specific destination is required.
- `./bin/checklist` and `./bin/ci.sh` disable parallel test workers by default;
  set `CHECKLIST_ALLOW_PARALLEL_TESTS=1` or `CI_ALLOW_PARALLEL_TESTS=1` only when
  parallel proof is intentional.
- Validate before final report.
- Report exact proof command.
- Add durable doc/test/script when the same failure pattern repeats.
