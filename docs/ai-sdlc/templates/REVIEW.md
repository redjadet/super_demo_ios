# REVIEW — `<slug>`

> Copy to `docs/ai-sdlc/features/<slug>/REVIEW.md` after implementation.
> Human owns accept/reject. Compare the PR diff to `plan.md` and `spec.md`.

## Checklist

- [ ] Diff matches `plan.md` write-set (no drive-by edits)
- [ ] Acceptance criteria in `spec.md` met or explicitly deferred
- [ ] Layer boundaries / modularity scripts green (`./bin/verify-swift.sh` if Swift)
- [ ] Named proof command run; output non-empty and honest
- [ ] Light/dark / cancel / offline paths considered when UI or Feed touched
- [ ] No secrets, no unjustified entitlements / privacy APIs
- [ ] PR body names proof commands; links this folder when useful

## Diff vs plan

| Planned | Delivered | Notes |
| --- | --- | --- |
| … | … | … |

## Proof

```text
# paste command + summary result
```

## Residual risk

- …

## Decision

- [ ] Approve for merge (after GHA `checklist` green)
- [ ] Request changes
- [ ] Reject / spike only
