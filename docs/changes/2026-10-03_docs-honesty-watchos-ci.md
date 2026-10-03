# 2026-10-03 — Docs honesty: watchOS CI wording + portfolio tip

**Tip base:** `bf9b626` (#74)

## Why

Several agent/CI docs still described merge proof as **iPad/Mac only**, while
`./bin/ci-platform-builds.sh` (and therefore `./bin/ci.sh` / `./bin/checklist` /
Fastlane `platform_builds`) also runs **watchOS**. Portfolio Platform surfaces
inventory lagged tip at `031cc37` / **#36–#67** after #68–#74 ships.

## Changes

- `docs/portfolio.md` — tip pin `031cc37` / #36–#67 → `bf9b626` / #36–#74 with
  inventory for #69 Mac unsigned compile-proof, #70 senior-patterns / flag
  honesty, #71/#74 Mac recipe docs, #72 README evidence; Universal shell +
  reviewer checklist cite iPad/Mac/watchOS; link senior-patterns map.
- `docs/engineering/senior-coding-patterns-map.md` — inventory tip pin →
  `bf9b626`.
- CI/checklist proof wording: `docs/README.md`, `docs/code-style.md`,
  `docs/agent_environment_setup.md`, `docs/agent_host_notes.md`,
  `docs/agents_quick_reference.md`, `docs/agent_project_context.md`,
  `bin/checklist`, `fastlane/Fastfile`.

## Non-goals

- No product / UITest / scheme edits.
- No tip-pin-only bump without inventory/proof substance.
- Historical change notes left as-authored.
- Adaptive-shell “iPhone, iPad, and Mac” layout guidance unchanged (not CI
  proof wording).
