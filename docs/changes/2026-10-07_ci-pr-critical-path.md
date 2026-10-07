# PR CI critical path and coverage

Baseline: successful PR run `37645448637` took 40m32s including runner queues.
Flutter preparation recopied cached framework slices for ~2m53s while simulator
boot competed for disk I/O. UI test bodies ranged from ~173s to ~452s per shard.
These timings describe one run, not a fixed CI latency guarantee.

## Changes

- Reuse already flattened Flutter slices when the preparation-script digest and
  required framework directories match. Regenerate the local xcconfig on reuse;
  repair incomplete slices; invalidate the marker before any recopy.
- Boot the build-job simulator after Flutter preparation; overlap native build.
- Compiled embed caches require exact keys. Hash all tracked module inputs
  (including manifests, tests, assets) and preparation logic. Partial restores
  cannot reuse stale compiled Dart. A new namespace incurs an initial cold build.
- Balance the existing four UI shards by observed test duration. Include the
  previously omitted tvOS companion and offline bookmark UI cases.
- `python3 tool/check_ci_contracts.py` checks every UI test appears exactly once
  (except the existing hosted performance exclusion), plus slice reuse/repair
  and failed-preparation invalidation. Runs through common checks / CI lint.

## Proof and limits

Run `actionlint`, `python3 tool/check_ci_contracts.py`, `./bin/checklist-fast`,
local `./bin/ci.sh`, and hosted CI. Merge only after **Delivery checklist** passes
on the submitted PR head. All platform lanes and four UI jobs remain required
by the aggregate gate; runner availability still affects wall time.
