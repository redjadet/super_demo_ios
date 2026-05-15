# AI Agents Map — `superDemoApp/` source

Thin map beside Swift sources. Full harness lives at repo root.

**Primary map:** [`../AGENTS.md`](../AGENTS.md)  
**Docs:** [`../docs/README.md`](../docs/README.md)

## When editing Swift here

1. Read [`../AGENTS.md`](../AGENTS.md) and the task doc under `../docs/`.
2. From repo root (`superDemoApp/`): `./bin/lint.sh` after Swift edits.
3. Match patterns in neighboring files (`ContentView.swift`, `Item.swift`, app entry).

## Source-folder rules

- SwiftUI + Observation-first; no UIKit unless SwiftUI cannot meet the need.
- Domain logic stays out of Views; persistence/network stay in Data layer.
- Previews for new Views; accessibility labels on new controls.

## Learned Workspace Facts

- Cursor may open parent `super_demo_ios/`; Xcode MCP and workspace maps are in
  [`../../AGENTS.md`](../../AGENTS.md) and [`../../.cursor/mcp.json`](../../.cursor/mcp.json)
  (outside this git repo).
