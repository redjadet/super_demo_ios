# Live feature artifacts

Put **shared** intent/spec/plan/REVIEW for a feature slug here:

```text
docs/ai-sdlc/features/<kebab-slug>/
  intent.md
  spec.md
  plan.md
  REVIEW.md
```

## Rules

1. Use a short kebab-case slug (`feed-bookmark-outbox`, `items-search`).
2. Start from [`../templates/`](../templates/); see filled
   [`../examples/feed-stale-banner-honesty/`](../examples/feed-stale-banner-honesty/).
3. Human approves intent → spec → plan before large coding; fill `REVIEW.md`
   before claiming done.
4. Local throwaway plans stay under gitignored `docs/plans/` — do not commit those.
5. When a PR includes a `plan.md` here, reviewers check the **diff against the plan**.

## Index

| Slug | Status | Notes |
| --- | --- | --- |
| _(none yet)_ | — | Add a row when the first live folder lands |

Examples (not live work): see [`../examples/`](../examples/feed-stale-banner-honesty/).
