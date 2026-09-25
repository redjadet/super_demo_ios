# 2026-09-25 — Performance lab: widget + concurrency (JP-P1-E)

## Summary

Expands [`performance-lab.md`](../performance-lab.md) beyond Feed + UIKit
signposts: Instruments recipes for the JP-P0-B Feed widget App Group publish /
timeline-read path, a concurrency talk track for reviewers, and an honest
**pending JP-P1-A** note instead of a fake Live Activity recipe.

## Acceptance

- Widget recipe: app process (snapshot write + `WidgetCenter.reloadTimelines`)
  and widget extension process (`TimelineProvider` / `loadState`)
- Concurrency talk track: `AsyncLoadController`, cancel restore, actors,
  signposts vs cancel, widget process boundary
- Live Activity: pending JP-P1-A only — no invented ActivityKit steps
- Honesty rule preserved (no fake numbers in CI)

## Docs

- [`performance-lab.md`](../performance-lab.md)
- Portfolio reviewer map + platform surfaces row
- Incident playbook signposts pointer

## Proof

- Docs lane: `./bin/lint-markdown.sh` / `./bin/checklist-fast`
- No Swift changes in this slice (optional widget signpost category deferred)
