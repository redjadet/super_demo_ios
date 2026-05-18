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
| Domain / Data logic | `./bin/verify-swift.sh` + targeted tests |
| SwiftUI layout, navigation, universal UI, light/dark | `./bin/checklist` |
| Before merge / PR | `./bin/ci.sh` or `bundle exec fastlane ci` (same proof lanes as GitHub Actions) |
| Fastlane lanes (lint, test, builds, CI) | `./bin/fastlane-run <lane>` — see `fastlane/Fastfile` |

`CI_SKIP_PLATFORM_BUILDS=1` skips iPad/Mac in `./bin/ci.sh` only when intentionally narrow.
UI smoke: `superDemoAppUITests.testLaunchShowsAddItemControl` in CI iPhone test lane.

| Situation | Command |
| --- | --- |
| Project/scheme sanity | `xcodebuild -list -project superDemoApp.xcodeproj` |
| Swift after edits (agents) | `./bin/verify-swift.sh` (format + lint; **preferred**) |
| Swift format only | `./bin/format.sh` |
| Swift lint + layer boundaries | `./bin/lint.sh` (indent + agent patterns + SwiftLint + SwiftFormat) |
| Layer boundaries only | `./tool/check_layer_boundaries.sh` |
| Markdown lint gate | `./bin/lint-markdown.sh` |
| DESIGN.md DesignMD lint (needs Node; in checklists) | `./tool/check_design_md.sh` |
| Fast checklist (markdown + DesignMD + lint + sanity) | `./bin/checklist-fast` |
| Full checklist (above + iPhone test + iPad/Mac) | `./bin/checklist` |
| Full local CI | `./bin/ci.sh` (`fastlane ci`) |
| CI lint job only | `bundle exec fastlane ci_lint` |
| iPhone tests lane | `bundle exec fastlane iphone_test` |
| iPad + Mac lane | `bundle exec fastlane platform_builds` |
| iPhone build/test lane only | `./bin/ci-iphone-test.sh` |
| iPad + Mac builds only | `./bin/ci-platform-builds.sh` |
| Install Cursor rules + hooks (after clone) | `./tool/install-cursor-rules.sh` |
| Install git pre-commit (after clone) | `./tool/install-git-hooks.sh` |
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
- Swift indentation is 4 spaces. If Xcode reports `(indent)` or 2-space member
  errors, run `./bin/verify-swift.sh` — see [`agent_swift_guards.md`](agent_swift_guards.md).
- Use Apple-native frameworks first; document dependency tradeoffs.
- Keep changes surgical.
- Prefer `./bin/checklist-fast` for docs/tooling/small Swift edits.
- Use `./bin/checklist` for SwiftUI layout/navigation/universal UI before handoff.
- Use `./bin/ci.sh` before merge/PR (same lint, iPhone test, iPad build, and Mac build proof as CI).
- `./bin/checklist` resolves an available iPhone simulator automatically; set `CHECKLIST_IPHONE_DEST` only when a specific destination is required.
- `./bin/checklist` and `./bin/ci.sh` disable parallel test workers by default;
  set `CHECKLIST_ALLOW_PARALLEL_TESTS=1` or `CI_ALLOW_PARALLEL_TESTS=1` only when
  parallel proof is intentional.
- `./bin/ci-platform-builds.sh` runs iPad and Mac builds in parallel by default;
  set `CI_SERIAL_PLATFORM_BUILDS=1` if Xcode is resource constrained.
- Validate before final report.
- Report exact proof command.
- Add durable doc/test/script when the same failure pattern repeats.
