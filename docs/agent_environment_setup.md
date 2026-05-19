# Agent Environment Setup

Goal: repeatable local work through Xcode command-line tools.

## Required Tools

- Xcode with command-line tools selected.
- `xcodebuild` available on PATH.
- Git available on PATH.
- SwiftLint and SwiftFormat installed through `brew bundle --file Brewfile`.

Check:

```bash
xcodebuild -version
xcodebuild -list -project superDemoApp.xcodeproj
git status --short
```

## XcodeBuildMCP

This workspace has XcodeBuildMCP session defaults configured in
`../.xcodebuildmcp/config.yaml`.

Active profile:

```text
superDemoApp
```

Defaults:

```text
projectPath: /Users/ilkersevim/Flutter_SDK/projects/super_demo_ios/superDemoApp/superDemoApp.xcodeproj
scheme: superDemoApp
configuration: Debug
simulatorName: iPhone 17
simulatorPlatform: iOS Simulator
bundleId: com.ilkersevim.superDemoApp
```

Agent rule: when XcodeBuildMCP tools are available, call
`session_show_defaults` first and prefer MCP simulator build/run/test tools
over raw shell commands. Use shell `xcodebuild` only as fallback or for
platform flows not enabled in MCP.

## Commands

Swift verify (format + lint; use after edits and before commit):

```bash
./bin/verify-swift.sh
```

Lint only (after verify, or when no Swift changed):

```bash
./bin/lint.sh
```

Format only:

```bash
./bin/format.sh
```

## Hooks (one-time install)

```bash
./tool/install-cursor-rules.sh   # ../.cursor/hooks.json + format-swift-after-edit.sh
./tool/install-git-hooks.sh      # pre-commit → verify-swift on staged .swift
```

See [`agent_swift_guards.md`](agent_swift_guards.md#automated-hooks-optional-recommended).

Full CI locally (lint + iPhone test/build + parallel iPad/Mac builds; same proof
lanes as GitHub Actions):

```bash
./bin/ci.sh
```

Fastlane wrapper (bootstraps Bundler when needed, then runs the same repo scripts):

```bash
./bin/fastlane-run ci
./bin/fastlane-run ci_lint
./bin/fastlane-run iphone_test
./bin/fastlane-run platform_builds
```

iPad/Mac compile only (same as CI platform step; parallel by default with isolated DerivedData):

```bash
./bin/ci-platform-builds.sh
```

Fast checklist (lint + focused common issue checks + project sanity):

```bash
./bin/checklist-fast
```

Full checklist (lint + common issue checks + iPhone build/test + iPad/Mac builds).
It uses `CHECKLIST_IPHONE_DEST` when provided; otherwise it chooses an
available existing iPhone simulator, preferring a booted simulator first.
Checklist tests run serially by default to avoid Xcode spawning multiple
cloned simulator workers.

```bash
./bin/checklist
```

Build app:

```bash
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

Run tests:

```bash
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test
```

GitHub Actions on push/PR to `main` runs lint, iOS Simulator tests (which build
the app and tests), and `./bin/ci-platform-builds.sh` for iPad simulator + macOS
builds as parallel lanes. The `lint-build-test` job is an aggregate required-check
gate over those lanes (see `.github/workflows/ci.yml`).

The **iphone-test** job runs `./bin/ci-iphone-test.sh` (serial UI tests, skips
`LaunchTests` and `testLaunchPerformance` on CI). UI tests use `-UITesting` and
terminate the app between cases — see [`testing.md`](testing.md#ui-smoke-ci).

## Cursor (first-time)

From git root (`superDemoApp/`), even when the Cursor workspace is parent `super_demo_ios/`:

```bash
./tool/install-cursor-rules.sh
npx skills experimental_install -y
```

Restart Cursor. Confirm **Rules** (`agents-map`, `agent-execution-ios`) and MCP
`xcode-tools`.

See [`tool/cursor-template/README.md`](../tool/cursor-template/README.md),
[`agent_host_notes.md`](agent_host_notes.md), and [`../skills-lock.json`](../skills-lock.json).

If destination is unavailable:

```bash
xcrun simctl list devices available
```

Override checklist destinations only when needed:

```bash
CHECKLIST_IPHONE_DEST='platform=iOS Simulator,id=<UDID>' ./bin/checklist
CHECKLIST_PREFERRED_IPHONE='iPhone 17 Pro' ./bin/checklist
CHECKLIST_SKIP_PLATFORM_BUILDS=1 ./bin/checklist
CI_SKIP_PLATFORM_BUILDS=1 ./bin/ci.sh
CHECKLIST_ALLOW_PARALLEL_TESTS=1 ./bin/checklist
```

## Agent Setup Rules

- Verify scheme/destination before build assumptions.
- Prefer simulator builds for app code changes.
- Use narrow tests first, then broader build/test when surface area grows.
- Use `./bin/checklist-fast` for docs/tooling/small Swift edits and
  `./bin/checklist` for full delivery proof.
- Do not commit `xcuserdata`, local DerivedData, secrets, or machine-specific settings.
- If Xcode or simulator tooling fails, report exact command and failure.
