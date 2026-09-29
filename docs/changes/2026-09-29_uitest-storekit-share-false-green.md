# 2026-09-29 — StoreKit / Share inbox UITest false-green harden

## Summary

Harden Engineering-demo UITests so StoreKit and Share inbox cannot false-green
on non-terminal chrome. Surface Share Seed append failures instead of `try?`.

## Why

Mac Codex scan on tip `3a2569c`: after Load, StoreKit accepted `idle`/`loading`;
after Seed, Share accepted pre-seed `absent`/`corrupt` and skipped non-hittable
Seed silently. Seed used `try?` so write failures looked like an empty inbox.

## Changes

- `EngineeringDemosUITests` — StoreKit terminal-only; Share Seed required +
  post-seed entry / unavailable / seed-failed
- `ShareInboxDemoView` — honest Seed failure status (`shareInboxSeedFailed`)
- `docs/testing.md` + portfolio tip pin bundled (`c8479a2`)

## Out of scope

Mac P2-A screenshots, visionOS, paid StoreKit purchase, real APNs.
