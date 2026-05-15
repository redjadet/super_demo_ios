# Light and dark mode — agent policy

## Summary

- Documented **light + dark from day one** across `DESIGN.md`, `docs/design_system.md`
  (new required section), `AGENTS.md`, baseline/knowledge base, feature template,
  universal platforms, Apple practices, quick reference, code style, review protocol,
  and Cursor rules.
- Reference: dark `#Preview` on `ItemsView`; `UniversalPreviewLayouts` + `.dark` trait.
- `check_common_issues.sh` fails on `Color.white` / `Color.black` / `UIColor` fixed fills
  under `Features/` and `Shared/`.

## Agent impact

- New UI: semantic colors only; asset catalog Any+Dark for custom roles; light **and** dark
  `#Preview` per screen before handoff.
- Do not defer dark mode to a follow-up task.

## Proof

```bash
./bin/lint.sh
./bin/checklist-fast   # includes common issue checks
```
