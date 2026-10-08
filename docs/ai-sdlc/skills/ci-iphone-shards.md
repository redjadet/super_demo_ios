# Skill: CI iPhone UI shards

Use when adding, renaming, removing, or rebalancing `superDemoAppUITests` cases
that run on the hosted **iphone-test** matrix (`ui-1`…`ui-4`).

## Rules

1. **Every UI test exactly once** — shard lists come from
   `tool/ci_iphone_test_shards.sh`. After edits, run
   `python3 ./tool/check_ci_contracts.py` (must pass).
2. **Balance by duration** — prefer moving slow cases off hot shards; see
   [`../../changes/2026-10-07_ci-pr-critical-path.md`](../../changes/2026-10-07_ci-pr-critical-path.md).
3. **Do not** change workflow job names or shard count without updating the
   contract test and [`../../ci-cd-map.md`](../../ci-cd-map.md).
4. **Local proof** — `./bin/ci-iphone-test.sh` or targeted
   `-only-testing:` (see [`../../testing.md`](../../testing.md)); full delivery
   still needs `./bin/checklist` for merge claims.

## Steps

1. Edit tests and/or `tool/ci_iphone_test_shards.sh`.
2. `python3 ./tool/check_ci_contracts.py`
3. `actionlint` if `.github/workflows/ci.yml` changed.
4. Add a short [`../../changes/`](../../changes/README.md) note when behavior or
   shard layout changes.

## Proof

- `python3 ./tool/check_ci_contracts.py` (required)
- GHA `iphone-test` matrix on PR (macOS)
