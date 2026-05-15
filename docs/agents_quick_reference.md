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

| Situation | Command |
| --- | --- |
| Project/scheme sanity | `xcodebuild -list -project superDemoApp.xcodeproj` |
| Swift lint gate | `./bin/lint.sh` |
| Markdown lint gate | `./bin/lint-markdown.sh` |
| Full local CI | `./bin/ci.sh` |
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
- Architecture work: [`architecture.md`](architecture.md), [`layers.md`](layers.md)
- SwiftUI state: [`state-management.md`](state-management.md)
- Universal/responsive UI: [`universal-apple-platforms.md`](universal-apple-platforms.md)
- SwiftData/offline: [`offline-first.md`](offline-first.md)
- API/sync: [`sync-and-networking.md`](sync-and-networking.md)
- Tests: [`testing.md`](testing.md)
- Review: [`ai_code_review_protocol.md`](ai_code_review_protocol.md)

## Reminders

- Start from current diff.
- Use Apple-native frameworks first; document dependency tradeoffs.
- Keep changes surgical.
- Validate before final report.
- Report exact proof command.
- Add durable doc/test/script when the same failure pattern repeats.
