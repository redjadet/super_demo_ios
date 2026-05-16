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

Lint (fast):

```bash
./bin/lint.sh
```

Format:

```bash
./bin/format.sh
```

Full CI locally (lint + iPhone test/build + parallel iPad/Mac builds; matches GitHub Actions):

```bash
./bin/ci.sh
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
the app and tests), then `./bin/ci-platform-builds.sh` for iPad simulator + macOS
builds (see `.github/workflows/ci.yml`).

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
