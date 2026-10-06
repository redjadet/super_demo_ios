# Plan — `<slug>`

> Copy to `docs/ai-sdlc/features/<slug>/plan.md`. Human approves before coding.
> PR review should check the diff against this file when present.

## Write-set

Paths the agent may edit (declare; do not expand silently):

- `superDemoApp/…`
- `superDemoAppTests/…`
- `docs/…`

## Do not touch

- …

## Steps (land → expand)

Each step = **one** observable behavior + **named proof** before the next step.
Do not batch unrelated behaviors in one agent turn. Pattern:
[`../skills/progressive-prompting.md`](../skills/progressive-prompting.md).

| Step | Behavior (one) | Proof (command or UI) |
| --- | --- | --- |
| 1 | … | e.g. `./bin/verify-swift.sh` + focused test |
| 2 | … | … |
| N | Ready for review | `./bin/checklist` (or `./bin/checklist-fast` if docs-only) |

## Architecture notes

- Layers / DI / composition roots affected:
- Offline / sync / concurrency notes:

## Test plan

| Case | Where |
| --- | --- |
| … | unit / UI / manual |

## Rollback

How to revert safely (feature flag, revert commit, store migration note).

## Stop criteria

Stop and ask the human when:

- Write-set would expand into protected paths ([`../gates.md`](../gates.md))
- Acceptance cannot be proven with named commands
- Confidence on API/ownership below ~95%
