# Layer boundary enforcement

## Summary

- Added `tool/check_layer_boundaries.sh` — forbidden imports per layer under `Features/`.
- Wired into `./bin/lint.sh` and `./tool/check_common_issues.sh`.
- Agent docs and `AGENTS.md` now require `architecture.md` + `layers.md` for `Features/` work.

## Agent impact

- New layered code must live under `Features/<Name>/{Presentation,Domain,Data}/`.
- `./bin/lint.sh` fails on layer import violations (not optional).
- List demo now lives in `Features/Items/` (see
  [`2026-05-15_design-docs-items-reference.md`](2026-05-15_design-docs-items-reference.md)).
