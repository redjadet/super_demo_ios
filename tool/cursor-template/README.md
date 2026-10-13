# Cursor agent setup (template)

Tracked copy of Cursor rules and MCP config for this project. The live `.cursor/`
folder is gitignored; install from the repo after clone or when rules change.

## Workspace roots

| Open in Cursor | Install target | Notes |
| ------ | ------ |
| Parent `super_demo_ios/` (optional) | bare `./tool/install-cursor-rules.sh` → `../.cursor` | Script default; local multi-folder workspace |
| Published git repo root | `CURSOR_INSTALL_DIR="$PWD/.cursor"` | Required override for GitHub clones; run `./bin/*` here |

See [`../../AGENTS.md`](../../AGENTS.md) workspace layout.

## Install

From the **git repo root** (directory with `bin/`, `docs/`, and `superDemoApp/`),
install into **repo-local** `.cursor/` (gitignored):

```bash
CURSOR_INSTALL_DIR="$PWD/.cursor" ./tool/install-cursor-rules.sh
```

Without `CURSOR_INSTALL_DIR`, the script defaults to `../.cursor` (parent of
the git root)—useful for a multi-folder parent workspace, not for a clone
opened at the published repo root.

Options:

```bash
# Parent-workspace default (writes ../.cursor)
./tool/install-cursor-rules.sh

# Dry run
CURSOR_INSTALL_DIR="$PWD/.cursor" ./tool/install-cursor-rules.sh --dry-run
```

Restart Cursor or reload the window after install.

Git pre-commit (staged `.swift` → `./bin/verify-swift.sh`):

```bash
./tool/install-git-hooks.sh
```

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
- `hooks.json` + `hooks/format-swift-after-edit.sh` — SwiftFormat after agent/Tab edits
  (one file, fail open)
- `.cursorignore` — copied to workspace root (parent of `.cursor/`); keeps local
  secrets and DerivedData out of Agent context ([`docs/ai/agent-customization-layers.md`](../../docs/ai/agent-customization-layers.md))

Canonical policy: lean [`AGENTS.md`](../../AGENTS.md) (map) + `docs/` (detail). Edit the
template here, run install, and update owning docs if behavior changes.
Feature SDLC kit (any agent): [`docs/ai-sdlc/README.md`](../../docs/ai-sdlc/README.md);
gates: [`docs/ai-sdlc/gates.md`](../../docs/ai-sdlc/gates.md).

## MCP priority (Cursor)

1. **Xcode tools** — `xcode-tools` in `mcp.json` (Xcode 26.3+ Intelligence)
2. **Shell** — `./bin/ci.sh`, `./bin/checklist`, `xcodebuild` from
   [`docs/agents_quick_reference.md`](../../docs/agents_quick_reference.md)
3. **XcodeBuildMCP** (optional, Codex/other hosts) — `../.xcodebuildmcp/config.yaml`

Details: [`docs/agent_host_notes.md`](../../docs/agent_host_notes.md).
