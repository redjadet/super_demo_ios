# Skill: progressive prompting

How humans should **prompt** Cursor/Codex agents and how agents should **execute**
within the [`../README.md`](../README.md) intent → spec → plan → review loop.

Source pattern: Chris Dunlop, *Progressive Prompting* (Cursor workflow) — build
through a sequence of small prompts; each step starts from something that already
works and adds **one** new behavior you can see or verify.

## Rules (humans and agents)

1. **One verifiable behavior per step** — not “implement the feature,” but “add
   pending state when a bookmark is queued offline.”
2. **Start green** — branch from passing `main` / prior step’s proof; do not
   stack unverified steps.
3. **Verify before the next step** — run a named gate from [`../gates.md`](../gates.md)
   (typically `./bin/verify-swift.sh` for Swift, `./bin/lint-markdown.sh` for
   docs-only, `./bin/checklist` before merge).
4. **No one-shot multi-feature asks** — if acceptance has multiple behaviors,
   list them as ordered steps in `plan.md` and execute one step per agent session
   when possible.
5. **Align with write-set** — a step must not silently expand paths declared in
   `plan.md`; stop per plan stop criteria.

## Breaking `plan.md` into steps

Use the table in [`../templates/plan.md`](../templates/plan.md). Each row needs:

- **Behavior** — user-visible or test-assertable (banner, queue count, error text).
- **Proof** — exact command or manual UI check (simulator screen + action).

Good steps are **independently mergeable** when reasonable (land → expand). Bad
steps bundle Domain + UI + sync in one row.

## Example: Feed bookmark offline outbox (iOS / SwiftUI)

Hypothetical feature aligned with [`offline-outbox.md`](offline-outbox.md) — adjust
write-set if an outbox PR is already open.

| Step | Behavior (one) | Proof |
| --- | --- | --- |
| 1 | Domain model for a pending bookmark op (stable id, idempotent retry contract) | New Swift Testing unit tests pass; `./bin/verify-swift.sh` |
| 2 | Data layer enqueues op locally when network unavailable (no UI yet) | Repository tests; `./bin/verify-swift.sh` |
| 3 | Presentation: bookmark control shows pending/disabled while op is queued | `FeedFeatureModelTests` (or feature model tests); `./bin/verify-swift.sh` |
| 4 | Flush queue when connectivity returns; failure surfaces in UI | Integration/unit tests for flush + error path; manual: airplane mode → bookmark → online |
| 5 | Review + merge | `./bin/checklist`; `REVIEW.md` vs spec acceptance |

If step 3 fails, fix step 3 — do not proceed to sync flush until proof is green.

## Example: Feed first load (smaller slice)

| Step | Behavior (one) | Proof |
| --- | --- | --- |
| 1 | Repository returns cached feed when remote fails (existing OI rules) | `CachingFeedRepositoryTests`; `./bin/verify-swift.sh` |
| 2 | Presentation shows stale banner when `isStale` | Model + snapshot or model test; `./bin/verify-swift.sh` |

See filled plan: [`../examples/feed-stale-banner-honesty/plan.md`](../examples/feed-stale-banner-honesty/plan.md).

## Related

- Gates: [`../gates.md`](../gates.md)
- Offline writes: [`offline-outbox.md`](offline-outbox.md)
- Human harness: [`../../using-agents-here.md`](../../using-agents-here.md)
