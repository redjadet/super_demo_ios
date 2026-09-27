# 2026-09-27 — Next improvements E2E (docs honesty + watch UI + intents)

## Summary

Closes the must-fix / nice-to-have slice from the agent-store
`main-next-improvements` list without inventing coverage %, Island-on-CI, or
deferred platforms.

## Changes

- **Docs honesty:** `code-quality.md` — hosted `iphone-test` **does** run
  `xcodebuild test`; coverage still unavailable because `-enableCodeCoverage`
  is not on the PR lane. `portfolio.md` inventory pin → tip `f773416` + post
  P2 A–F note.
- **UI smoke:** `testWatchCompanionDemoIsReachable`; Vision / Flutter / Watch
  accessibility labels + thin asserts; Live Activity Engineering UI **N/A** row
  in `testing.md`.
- **Adaptive shell:** iPad/Mac selection UI noted as best-effort (hosted
  platform lane is build-only); iPhone selection + `superdemo://feed/1` prove
  the shared selection path.
- **Open Feed Post intent:** `OpenFeedPostIntent` + `feedOpenPostID` /
  `superdemo://feed/<id>` + unit/UI tests.
- **Coverage path:** `./bin/coverage-iphone.sh` (local/nightly; no badge).
- **Widget playbook:** DerivedData / re-add widget steps in `performance-lab.md`.

## Follow-up (CI)

`testDeepLinkOpensFeedPostDetail` failed on hosted iPhone: after
`superdemo://feed/1`, compact `NavigationSplitView` shows the detail column so
sidebar-only `waitForFeedChrome` timed out. Fix: treat `feedPostDetail-*` as
Feed chrome; assert detail first.

## Proof

- `./bin/verify-swift.sh` / `./bin/checklist-fast` locally when available
- Hosted GHA Delivery checklist (Xcode 27) on this PR
- #5 Mac light+dark screenshots / #6 private Mac worker: **blocked / ops** —
  not attempted in agent sandbox
