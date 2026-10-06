# 2026-10-06 — CI Node 24 actions, honest Xcode select, iPhone timeout

## Summary

Unstick main CI hygiene after run `37314985527` hung on `iphone-test` with no
steps: bump Node-20 actions, prefer clean released Xcode path labels, and fail
hung iPhone jobs faster.

## Changes

- `.github/workflows/ci.yml` + `release-smoke.yml`: `actions/cache@v6` (Node 24);
  `actions/upload-artifact@v7` on release-smoke.
- `iphone-test` `timeout-minutes: 70` (was 90); xcodebuild hard timeout 3300s.
- `tool/select_xcode.sh`: keep `/Applications` aliases so CI picks
  `Xcode_27.1.app` over `Xcode_27.1_beta.app` when both point at the same GM;
  log `[released]` vs beta/path-label honestly.

## Why

- GHA annotated `actions/cache@v4` as Node 20 (forced to 24 via env).
- Image ships GM 27.1 under a `_beta` path plus clean aliases; prior select
  deduped to the `_beta` name and labelled it `[released]`.
- Hung runner burned ~95m against the old 90m job timeout with empty steps.
