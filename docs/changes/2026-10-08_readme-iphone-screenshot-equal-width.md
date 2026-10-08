# Change — equal-width iPhone README screenshots

**Date:** 2026-10-08

## What

- README iPhone gallery uses `<img width="220">` so Dashboard / Feed / Items
  render at the same width on GitHub (PNGs were already identical 1206×2622).
- `.markdownlint.json` allows `img` under MD033 for that gallery markup.

## Why

Cold reviewers saw the first iPhone screenshot looking larger than the other
two in the README table despite matching pixel dimensions.

## Proof

- `./bin/lint-markdown.sh` (MD033 clean with allowed `img`)
