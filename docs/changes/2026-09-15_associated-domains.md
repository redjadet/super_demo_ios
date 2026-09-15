# 2026-09-15 — Associated Domains + HTTPS deep links (P4)

## Why

Extend typed deep-link routing beyond the `superdemo` custom scheme so the app
can claim universal links for a documented domain, matching portfolio / device
proof expectations for Associated Domains.

## Changes

- Entitlement: `applinks:superdemo.app` (+ `?mode=developer` for local proof).
- `AppDeepLink` parses HTTPS paths on `superdemo.app` / `www.superdemo.app`
  (TLS only); rejects unknown hosts and `http://`.
- `AppRootView` continues browsing-web user activities into the same handler.
- Sample AASA + hosting notes in `Config/associated-domains/`.
- Docs: navigation, release checklist, App Store notes, portfolio.

## Proof

- Unit tests for HTTPS parse/reject/route paths.
- `./bin/lint.sh` / markdown lint before merge.
