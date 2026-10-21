# Change — ui-1 deep link on one UI-test launch

**Date:** 2026-10-21

## What

- `testDeepLinkOpensFeedPostDetail`, `testDeepLinkOpensItemsTab`, and
  `testDeepLinkOpensFeedTab` pass `superdemo://…` as `-UITestOpenURL` on the
  same `launchApplication` that already passes `-UITesting`.
- `AppRootView` applies that URL once the scene exists, and again if
  `TabView` writes the selection back to Dashboard. `FeedView` sets the
  compact split column to detail when the pending post is selected, including
  one follow-up assignment after the current view update. The UI tests no
  longer call `XCUIApplication.open` and no longer retry the detail case.
- `docs/EVIDENCE.md` gains a CI verification catalog (jobs, shards, local
  commands, workflow links).

## Why

[Run 37773620216](https://github.com/redjadet/super_demo_ios/actions/runs/37773620216)
job **Checklist · iPhone test (ui-1)** failed only
`testDeepLinkOpensFeedPostDetail` after the StoreKit demo. The log shows
`Launch` and then, about 196s later, `Application 'com.ilkersevim.superDemoApp'
does not have a process ID`, with no `Open … with URL` line. The next case,
`testDeepLinkOpensItemsTab`, passed, and its log shows `XCUIApplication.open`
performing a nested `Launch`. That second launch is the timing hazard. Recent
`ci.yml` runs in `gh run list --workflow ci.yml --limit 50` (2026-10-21) did
not fail this case again; the 2026-10-08 ordering-and-retry change is still
what those green runs executed. This change removes the test-level retry and
keeps a single launch. A local rerun of the two ui-1 deep-link cases then
passed once and failed once: `feedPostDetail-1` was still absent after 30s
while `testDeepLinkOpensItemsTab` in the same invocation passed. A later
failure snapshot stayed on `productionReadinessDashboard` (`row=false`,
`list=false`, `loading=false`) for the whole wait, which is `TabView`
resetting the first selection. The root view applies the launch URL again
when the selected tab does not match.

## Proof

Targeted unit and UI commands are in the pull request. Shard lists are
unchanged (`python3 ./tool/check_ci_contracts.py` when lint runs).
