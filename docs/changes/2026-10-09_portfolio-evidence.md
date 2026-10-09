# Change — portfolio evidence page for technical reviewers

**Date:** 2026-10-09

## What

- Keep README's badges and introduction first; place a compact bookmark-race
  example under engineering evidence. Link [`EVIDENCE.md`](../EVIDENCE.md),
  which leads with the problem, atomic persistence/intent decision, exact
  regression, and passing unit job together.
- Shorten README to an overview and detail links; move the 3-minute walkthrough
  to the portfolio guide and retain the screenshot gallery.
- Explain architecture, review, and validation responsibilities, including
  the scope of AI assistance; link decisions to inspectable artifacts.
- Retain four more source/test cases and provide complete unit/UI shard
  commands that select an installed iPhone Simulator.
- Link the evidence page from the portfolio tour, architecture index, and
  documentation index; correct the sync engine's `Data` path.
- Limit CI launch-failure wording to what the logs establish.

## Why

Technical reviewers should reach one concrete engineering decision and its
proof immediately, then understand the owner's contribution and the sample's
limits without inferring experience from a list of technologies.

## Verification scope

The named regressions passed in [main run 37828018857](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857)
on **2026-10-08** at `17d795f`. App and test sources match that snapshot.
[PR #107 checks](https://github.com/redjadet/super_demo_ios/pull/107/checks) use
the docs-only route: documentation checks and Delivery aggregation, with
runtime tests and platform builds skipped. That route adds documentation proof;
it does not rerun the application's regressions.
