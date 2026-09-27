# 2026-09-27 — AASA `/feed/*` + release-doc honesty

## Why

After [#36](https://github.com/redjadet/super_demo_ios/pull/36) shipped
`OpenFeedPostIntent` and `superdemo://feed/<id>` (with unit coverage for
`https://superdemo.app/feed/7`), the sample AASA still listed only `/feed`.
Safari → app handoff for post entity HTTPS URLs would not match. Release notes
still claimed “no App Groups / Sign in with Apple” and omitted Open Feed Post
shortcuts — false after P2 A–F.

## Changes

- **AASA:** add `/feed/*` component; document in `Config/associated-domains/README.md`.
- **Gate:** `./tool/check_aasa_deep_links.sh` (wired into
  `./tool/check_common_issues.sh`) requires AppDeepLink path set including
  `/feed/*`.
- **Docs:** `navigation.md` URL table; `portfolio.md` tip pin `f7a2a5e` + deep
  link / intent talk track; `release-checklist.md`;
  `release-notes/{app-store,testflight}.md` capabilities + shortcuts honesty.

## Deferred (unchanged)

Mac P2-A screenshots, private Mac worker, visionOS, paid StoreKit, real APNs.
