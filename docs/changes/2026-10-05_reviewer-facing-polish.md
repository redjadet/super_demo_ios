# 2026-10-05 — Reviewer-facing polish

## Intent

Remove obvious unfinished signals from the project’s reviewer path and make
claims easier to evaluate against concrete evidence.

## Changes

- Replace the Xcode placeholder with a blue monogram icon and Light, Dark,
  Tinted, and Mac size assets. Keep App Store marketing screenshots out of
  scope.
- Remove internal `JP-P*` backlog IDs from the current portfolio guide and
  source comments. Replace the visionOS backlog string in the demo with plain
  scope wording.
- Retire the numeric engineering self-rating. Link reviewers to an evidence
  map that states what local checks, hosted checks, and tests prove.
- Keep the old scorecard paths as compatibility pointers for historical docs
  and commands.

## Proof

- `./bin/checklist-fast` passed, including Markdown, Swift lint/format, layer,
  evidence-map, common-issue, and scheme checks.
- `CI_SERIAL_PLATFORM_BUILDS=1 python3 tool/run_with_timeout.py --timeout 1800
  -- ./bin/ci-platform-builds.sh` passed iPad simulator, unsigned macOS, and
  watchOS builds.
- `./bin/checklist` built successfully through the iPhone test lane. All 25 UI
  tests passed. The `superDemoAppTests` host failed before connecting to XCTest
  (`The test runner hung before establishing connection`) on local Xcode 27.0
  beta / iOS 27.0 simulator; no unit-test assertion ran. Hosted `checklist`
  remains the merge gate.
