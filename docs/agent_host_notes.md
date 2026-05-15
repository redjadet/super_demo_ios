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

- Single agent map: repo-root [`AGENTS.md`](../AGENTS.md) only (no nested copies).
- Always-applied project rule: `../.cursor/rules/agents-map.mdc` includes
  `@superDemoApp/AGENTS.md` on every Agent session (`alwaysApply: true`).
- Keep other `.cursor` rules thin; they should point back to repo `docs/` and `AGENTS.md`.
- Do not fork architecture guidance into host-only prompts.
- If a Cursor rule changes agent behavior, update owning source doc first.

## Browser/UI Proof

- Use simulator screenshots or UI tests for meaningful SwiftUI workflow changes.
- For docs-only changes, file presence plus lint/scheme sanity is enough.

## Drift Rule

If host assets are added later, source of truth should stay in repo docs or a
repo template. Generated host copies can lag and should not become canonical.
