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

Detailed routing: [`engineering/validation_routing_fast_vs_full.md`](engineering/validation_routing_fast_vs_full.md).

| Change type | Minimum proof |
| --- | --- |
| Docs / tooling / small Swift | `./bin/checklist-fast` |
| Domain / Data logic | `./bin/verify` + targeted tests |
| SwiftUI layout, navigation, universal UI, light/dark | `./bin/checklist` |
| Before merge / PR | `./bin/checklist` (local) + GHA **`checklist`** green — [`engineering/checklist_gate.md`](engineering/checklist_gate.md) |
| Fastlane lanes (lint, test, builds, CI, beta) | `./bin/fastlane-run <lane>` — see `fastlane/Fastfile` |

`CI_SKIP_PLATFORM_BUILDS=1` skips iPad/Mac in `./bin/ci.sh` only when intentionally narrow.
UI smoke (CI `iphone-test` / `bin/ci-iphone-test.sh`): Items launch, Dashboard →
Production Risks, UIKit showcase, Feed tab, Feed/Items deep links — see
[`testing.md`](testing.md#ui-smoke-ci).
Launch via `UiTestSupport.launchApplication()` (`-UITesting`, terminate between tests).

| Situation | Command |
| --- | --- |
| Project/scheme sanity | `xcodebuild -list -project superDemoApp.xcodeproj` |
| Swift after edits (agents) | `./bin/verify` (format + lint; **preferred**) |
| Swift format only | `./bin/format` |
| Swift lint + layer boundaries | `./bin/lint` (indent + agent patterns + SwiftLint + SwiftFormat + modularity) |
| Layer boundaries only | `./tool/check_layer_boundaries.sh` |
| Feature folder contract | `./tool/check_feature_folder_contract.sh` (also via `./bin/lint.sh`) |
| Cross-feature import leaks | `./tool/check_feature_import_leaks.sh` (also via `./bin/lint.sh`) |
| Engineering scorecard gate | `./tool/check_engineering_quality_scorecard.sh` (also via `./bin/lint.sh`) |
| Clean build caches (dry-run) | `./bin/clean-build-caches` |
| Prune stale worktrees/branches (dry-run) | `./bin/prune-git-stale` |
| Install git hooks | `./bin/install-git-hooks` |
| Checklist re-run + optional format | `./bin/checklist_fix` |
| Flutter → iOS script map | [`tooling_map.md`](tooling_map.md) |
| Isolated agent worktree | `./bin/agent-worktree --name <slug> [--apply]` → `.worktrees/<slug>`, branch `cursor/<slug>` |
| Harness scorecard (agent) | [`ai/harness-scorecard.md`](ai/harness-scorecard.md) |
| SAFETY-REPORT template | [`agent_kb/safety-report-template.md`](agent_kb/safety-report-template.md) |
| Markdown lint gate | `./bin/lint-markdown.sh` |
| DESIGN.md DesignMD lint (needs Node; in checklists + CI lint) | `./tool/check_design_md.sh` |
| Fast checklist (markdown + DesignMD + lint + sanity) | `./bin/checklist-fast` |
| Full delivery checklist (merge gate; warnings as errors) | `./bin/checklist` — [`engineering/checklist_gate.md`](engineering/checklist_gate.md) |
| Full local CI (Fastlane) | `./bin/ci.sh` (`./bin/fastlane-run ci`) |
| TestFlight beta lane | `TESTFLIGHT_BUILD_NUMBER=<unique-build-number> ./bin/fastlane-run ios beta` |
| App Store upload lane | `TESTFLIGHT_BUILD_NUMBER=<unique-build-number> ./bin/fastlane-run ios release` |
| Release IPA only (no upload) | `TESTFLIGHT_BUILD_NUMBER=<n> ./bin/fastlane-run ios build_ipa` |
| match signing sync | `./bin/fastlane-run ios sync_signing` (needs `Matchfile` or `FASTLANE_USE_MATCH=1`) |
| CI lint job only | `./bin/fastlane-run ci_lint` |
| iPhone tests lane | `./bin/fastlane-run iphone_test` |
| iPad + Mac lane | `./bin/fastlane-run platform_builds` |
| iPhone build/test lane only | `./bin/ci-iphone-test.sh` |
| iPad + Mac + watchOS builds | `./bin/ci-platform-builds.sh` (watch: `./bin/ci-watch-build.sh`; skip watch: `CI_SKIP_WATCH_BUILD=1`) |
| Install Cursor rules + hooks (after clone) | `./tool/install-cursor-rules.sh` |
| Install git pre-commit | `./bin/install-git-hooks` |
| Restore team Apple skills from lockfile | `npx skills experimental_install -y` (from git root) |
| Safe formatting | `./bin/format` |
| Compile app | `xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build` |
| iPad build sanity | `xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build` |
| Mac build sanity | `xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=macOS' build` |
| Unit + UI test sweep | `xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test` |
| Available simulators | `xcrun simctl list devices available` |
| Xcode destinations | `xcodebuild -showdestinations -project superDemoApp.xcodeproj -scheme superDemoApp` |
| Source search | `rg "pattern" superDemoApp superDemoAppTests superDemoAppUITests docs` |

## Routing

- Apple defaults: [`apple-development-practices.md`](apple-development-practices.md)
- Architecture / `Features/` work: [`architecture.md`](architecture.md),
  [`layers.md`](layers.md), [`module-structure.md`](module-structure.md),
  [`feature-template.md`](feature-template.md), [`modularity.md`](modularity.md)
- SwiftUI state: [`state-management.md`](state-management.md)
- Universal/responsive UI: [`universal-apple-platforms.md`](universal-apple-platforms.md)
- Light/dark policy: [`design_system.md`](design_system.md#light-and-dark-mode-required-from-day-one)
- SwiftData/offline: [`offline-first.md`](offline-first.md)
- API/sync: [`sync-and-networking.md`](sync-and-networking.md)
- Tests: [`testing.md`](testing.md)
- Review: [`ai_code_review_protocol.md`](ai_code_review_protocol.md)

## Reminders

- Pre-Flight (non-trivial): [`ai/ai_failure_risks.md`](ai/ai_failure_risks.md) +
  [`agent_kb/agent_safety_contracts.md`](agent_kb/agent_safety_contracts.md).
- Context ladder: [`ai/context_loading.md`](ai/context_loading.md).
- Start from current diff.
- Swift indentation is 4 spaces. If Xcode reports `(indent)` or 2-space member
  errors, run `./bin/verify-swift.sh` — see [`agent_swift_guards.md`](agent_swift_guards.md).
- Apple-native defaults and version-sensitive API checks: [`apple-development-practices.md`](apple-development-practices.md).
- Keep changes surgical.
- Prefer `./bin/checklist-fast` for docs/tooling/small Swift edits.
- Use `./bin/checklist` for delivery proof before PR; merge only when GHA
  **checklist** is green — [`engineering/checklist_gate.md`](engineering/checklist_gate.md).
- Script names vs Flutter: [`tooling_map.md`](tooling_map.md).
- Use `./bin/ci.sh` before merge/PR (same lint, iPhone test, iPad/Mac/watchOS
  build proof as CI).
- `./bin/checklist` resolves an available iPhone simulator automatically; set `CHECKLIST_IPHONE_DEST` only when a specific destination is required.
- `./bin/checklist` and `./bin/ci.sh` disable parallel test workers by default;
  set `CHECKLIST_ALLOW_PARALLEL_TESTS=1` or `CI_ALLOW_PARALLEL_TESTS=1` only when
  parallel proof is intentional.
- `./bin/ci-platform-builds.sh` runs iPad and Mac builds in parallel by default,
  then `./bin/ci-watch-build.sh`; set `CI_SERIAL_PLATFORM_BUILDS=1` if Xcode is
  resource constrained; set `CI_SKIP_WATCH_BUILD=1` to skip watch only.
- Validate before final report.
- Report exact proof command.
- Add durable doc/test/script when the same failure pattern repeats.
