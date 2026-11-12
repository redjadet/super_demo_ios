# Change — Portfolio demo polish (Feed empty AX + Dashboard title)

## Summary

Align Feed empty-state accessibility with Items, match the Dashboard
navigation title to the tab / reviewer path, and state README screenshot
appearance honestly.

## Details

- `FeedView` empty now exposes `feedEmpty` + VoiceOver label `No posts`
  (parity with `itemsEmpty`).
- `UiTestSupport.waitForFeedChrome` prefers the `feedEmpty` identifier and
  still accepts the localized "No Posts" label.
- Production Readiness root `navigationTitle` is **Dashboard** so the cold
  path matches the tab and portfolio 3-minute walkthrough.
- README Screenshots notes iPhone gallery is Light; paired Dark remains a
  human Simulator pass.

## Validation

- `./bin/verify-swift.sh`
- Matching iPhone unit / UI smoke for changed surfaces
- Docs: markdown relative links + markdownlint on touched files
