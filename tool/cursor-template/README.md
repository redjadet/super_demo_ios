# Cursor agent setup (template)

Tracked copy of Cursor rules and MCP config for this project. The live `.cursor/`
folder is gitignored; install from the repo after clone or when rules change.

## Workspace roots

| Open in Cursor | Install target | Notes |
| ------ | ------ |
| Parent `super_demo_ios/` (recommended) | `../.cursor/` relative to `superDemoApp/` | Matches Xcode MCP at repo parent |
| Git root `superDemoApp/` only | Set `CURSOR_INSTALL_DIR="$PWD/.cursor"` | Rules still reference `superDemoApp/` paths |

See [`../../AGENTS.md`](../../AGENTS.md) workspace layout.

## Install

From **git repo root** (`superDemoApp/`):

```bash
./tool/install-cursor-rules.sh
```

Options:

```bash
# Install into repo-local .cursor (gitignored)
CURSOR_INSTALL_DIR="$(pwd)/.cursor" ./tool/install-cursor-rules.sh

# Dry run
./tool/install-cursor-rules.sh --dry-run
```

Restart Cursor or reload the window after install.

## Team agent skills

Tracked in [`skills-lock.json`](../../skills-lock.json). From git root:

```bash
npx skills experimental_install -y
```

Restores nine Apple-platform skills into `.agents/skills/` (gitignored). Reload Cursor.
Details and skill list: [`docs/agent_host_notes.md`](../../docs/agent_host_notes.md).

## What gets installed

- `rules/agents-map.mdc` — always applies; includes `@superDemoApp/AGENTS.md`
- `rules/agent-execution-ios.mdc` — always applies; lint/CI/checklist discipline
- `rules/ios-swift-quality.mdc` — applies when editing `superDemoApp/**/*.swift`
- `mcp.json` — Xcode Intelligence MCP (`xcrun mcpbridge`)

Canonical policy: lean [`AGENTS.md`](../../AGENTS.md) (map) + `docs/` (detail). Edit the
template here, run install, and update owning docs if behavior changes.

## MCP priority (Cursor)

1. **Xcode tools** — `xcode-tools` in `mcp.json` (Xcode 26.3+ Intelligence)
2. **Shell** — `./bin/ci.sh`, `./bin/checklist`, `xcodebuild` from
   [`docs/agents_quick_reference.md`](../../docs/agents_quick_reference.md)
3. **XcodeBuildMCP** (optional, Codex/other hosts) — `../.xcodebuildmcp/config.yaml`

Details: [`docs/agent_host_notes.md`](../../docs/agent_host_notes.md).
