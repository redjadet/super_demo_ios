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

## Steps

1. …
2. …
3. Run proof: `./bin/…`

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
