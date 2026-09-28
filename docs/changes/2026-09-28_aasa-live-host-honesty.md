# 2026-09-28 — AASA live-host DNS honesty + tip pin

## Why

After [#43](https://github.com/redjadet/super_demo_ios/pull/43) restored Delivery
on tip `9aa3e05`, public DNS for `superdemo.app` still does not resolve, but
portfolio / navigation cold paths invited `https://superdemo.app/…` as if Safari
→ app handoff worked. The AASA gate only checked the sample file + entitlement
host set, so CI could print “AASA … OK” without live-host honesty.

## Changes

- **Gate:** `./tool/check_aasa_deep_links.sh` DNS-probes entitlement hosts; when
  unresolved, requires honesty marker `does not currently resolve` in
  `docs/portfolio.md`, `docs/navigation.md`, and
  `Config/associated-domains/README.md`.
- **Docs:** prefer `superdemo://` for reviewer cold-path; label HTTPS as
  parse-only; release checklist / notes / quick reference / checklist gate.
- **Portfolio tip pin:** `6c5d4be` → `9aa3e05` (bundled with honesty — not
  tip-pin-only).

## Deferred (unchanged)

Mac P2-A screenshots, private Mac worker, visionOS, paid StoreKit, real APNs,
UITest tab/Feed-chrome false-green harden (rank 3 — needs GHA sim proof).
