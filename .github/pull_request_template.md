## Delivery checklist (required)

- [ ] Ran local proof: `./bin/checklist-fast` (docs/tooling) **or** `./bin/checklist` (code / pre-merge)
- [ ] Zero Xcode errors **and** warnings on proof builds (warnings treated as errors)
- [ ] GHA **Delivery checklist** job green before merge
- [ ] Reviewed [`docs/engineering/checklist_gate.md`](../docs/engineering/checklist_gate.md) if changing gates/CI

## Scope

- [ ] Change note under `docs/changes/` when behavior, gates, or agent policy changed
- [ ] No secrets / credentials committed

## Honesty

Name the exact proof command in the PR body (do not write “CI passed” alone).
See [`docs/adr/0005-ci-pr-vs-local-honesty.md`](../docs/adr/0005-ci-pr-vs-local-honesty.md).
