# Agent Host Notes

Host-specific notes for AI agents. Repo docs still own project rules.

## Codex

- Prefer repo commands in [`agents_quick_reference.md`](agents_quick_reference.md).
- XcodeBuildMCP is configured for this project through
  `../.xcodebuildmcp/config.yaml`, active profile `superDemoApp`.
- For iOS simulator workflows, use XcodeBuildMCP first. Always call
  `session_show_defaults` before first build/run/test, then use the configured
  project/scheme/simulator defaults.
- Current MCP defaults: `superDemoApp.xcodeproj`, scheme `superDemoApp`,
  configuration `Debug`, simulator `iPhone 17`, bundle ID
  `com.ilkersevim.superDemoApp`.
- Keep final reports tied to files changed and commands run.

## XcodeBuildMCP

- Active profile: `superDemoApp`.
- Config path from repo root: `../.xcodebuildmcp/config.yaml`.
- Simulator workflow is enabled. Device, macOS, debugging, and UI automation
  tools may require extra XcodeBuildMCP configuration before use.
- Shell `xcodebuild` remains the fallback when MCP lacks a needed platform
  capability.

## Cursor

### Editor (Swift / ObjC)

- Use `swiftlang.swift-vscode` + SweetPad + `xcode-build-server` for Swift editing.
- Avoid duplicate C/C++ LSP extensions (`cpptools`, `clangd`, `sswg.swift-lang`) alongside
  the Swift extension.

### Setup

1. Open workspace: parent `super_demo_ios/` (recommended) or git root `superDemoApp/`.
2. From `superDemoApp/`: `./tool/install-cursor-rules.sh` (see
   [`tool/cursor-template/README.md`](../tool/cursor-template/README.md)).
3. Restart Cursor. Confirm **Rules** include `agents-map` and **MCP** lists
   `xcode-tools`.
4. From git root (`superDemoApp/`): restore shared Apple platform skills (see
   [Agent skills (team)](#agent-skills-team) below).

### Agent skills (team)

Tracked pin: [`skills-lock.json`](../skills-lock.json) (9 skills from
[rshankras/claude-code-apple-skills](https://github.com/rshankras/claude-code-apple-skills)).

After clone or lockfile change:

```bash
cd superDemoApp   # git root; required even if Cursor workspace is parent super_demo_ios/
npx skills experimental_install -y
```

Restores into `.agents/skills/` (gitignored). Reload Cursor. **Repo canon wins:**
[`AGENTS.md`](../AGENTS.md) and `docs/` override skill defaults (architecture, lint,
Growth layers).

| Skill | Use when |
| ------ | ------ |
| `ios-development` | iPhone/iPad SwiftUI, HIG, navigation |
| `macos-development` | macOS target, desktop UX |
| `swift-development` | Swift language / concurrency review |
| `design` | Liquid Glass, motion, visual system |
| `testing` | XCTest, TDD, snapshots |
| `release-review` | Pre-ship / submission review |
| `security` | Keychain, networking, platform security |
| `apple-intelligence` | Foundation Models, App Intents, on-device AI |
| `app-store` | ASO, metadata, review replies |

Add or bump skills:

`npx skills add https://github.com/rshankras/claude-code-apple-skills --skill <name> -y --agent cursor`

(no `-g`); commit updated `skills-lock.json`.

### Policy wiring

- Single agent map: repo-root [`AGENTS.md`](../AGENTS.md) only (no nested copies). Keep
  `AGENTS.md` under 100 lines; put detail in `docs/` (see [`agent_baseline.md`](agent_baseline.md),
  [`agents_quick_reference.md`](agents_quick_reference.md)).
- Always-applied rule `agents-map.mdc` includes `@superDemoApp/AGENTS.md` on every
  Agent session.
- Tracked rule source: [`tool/cursor-template/`](../tool/cursor-template/). Edit
  template, run install, then update owning `docs/` if behavior changes.
- Keep other `.cursor` rules thin; they point back to repo `docs/` and `AGENTS.md`.
- Do not fork architecture guidance into host-only prompts.

### MCP priority (Cursor)

| Order | Tool | When |
| ------ | ------ | ------ |
| 1 | **Xcode tools** (`xcode-tools` in `mcp.json`, `xcrun mcpbridge`) | Build, scheme, simulator, Xcode Intelligence (Xcode 26.3+) |
| 2 | **Repo scripts** | `./bin/lint.sh`, `./bin/ci.sh`, `./bin/checklist`, `xcodebuild` per [`agents_quick_reference.md`](agents_quick_reference.md) |
| 3 | **XcodeBuildMCP** (optional) | If `../.xcodebuildmcp/config.yaml` exists and host exposes it — same profile `superDemoApp` as Codex |

Shell `xcodebuild` is always valid fallback. For iPad/Mac compile proof use
`./bin/ci-platform-builds.sh` or `./bin/checklist`.

### Validation habits

- After Swift edits: `./bin/lint.sh`.
- Before merge/PR: `./bin/ci.sh` (lint, iPhone tests, iPad + macOS builds).
- SwiftUI layout/navigation/universal UI/light-dark: `./bin/checklist` (full matrix), not lint alone.

## Browser/UI Proof

- Use simulator screenshots or UI tests for meaningful SwiftUI workflow changes.
- CI runs `superDemoAppUITests` on the iOS Simulator lane; extend tests as flows grow.
- For docs-only changes, file presence plus lint/scheme sanity is enough.

## Drift Rule

If host assets are added later, source of truth should stay in repo docs or
[`tool/cursor-template/`](../tool/cursor-template/). Installed `.cursor/` copies can
lag; re-run `./tool/install-cursor-rules.sh` after pulling rule changes.
