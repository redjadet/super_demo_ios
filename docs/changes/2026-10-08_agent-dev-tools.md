# Change — Agent-friendly Mac / Xcode tools

**Date:** 2026-10-08

Wire optional host tools for coding agents: **xcsift** (sift `xcodebuild`),
**SF Symbols 27** CLI, and **RocketTrace** CLI.

- Wrappers: `./bin/xcsift-run`, `./bin/sfsymbols`, `./bin/rockettrace` (soft-fail
  with install hints when missing).
- Smoke: `./tool/smoke_agent_dev_tools.sh` (not a Delivery gate).
- Docs: [`agent_dev_tools.md`](../agent_dev_tools.md); rows in tooling map,
  quick reference, host notes, environment setup, CODEMAP.
- Brewfile / `expected_tool_versions.sh`: document optional pins only — do **not**
  add required CI brew deps (keeps PR lanes lean).

Portfolio honesty: host-optional aids, not product features.
