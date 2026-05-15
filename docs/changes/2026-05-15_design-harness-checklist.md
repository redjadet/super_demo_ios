# Design harness: checklist wiring

## Summary

- `./bin/checklist` now runs `./tool/check_design_md.sh` after Markdown lint (same step
  order as `./bin/checklist-fast`).
- `./tool/check_design_md.sh` lints root `DESIGN.md` via `@google/design.md` when `npx` is
  available; exits 0 with `skip:` when Node is missing (agents without Node still pass).
- `./bin/lint-markdown.sh` ignores vendored `.agents/**` so project docs lint stays green.

## Agent impact

- After editing [`DESIGN.md`](../DESIGN.md): run `./bin/checklist-fast` or `./bin/checklist`
  (not only `./bin/lint-markdown.sh`).
- Merge/PR gate remains `./bin/ci.sh` (no DesignMD step there yet).

## Proof

```bash
./bin/checklist-fast
./bin/checklist   # or CHECKLIST_SKIP_PLATFORM_BUILDS=1 for a faster full lane
```
