# Change — Native macOS desktop portfolio

**Date:** 2026-10-08

## Behavior

The Mac build previously opened a cramped window with narrow sidebars and no
feature menu commands. Feed refresh could move into toolbar overflow, and
creating a note did not open its editor.

The native main window now defaults to 1040 × 720, with a 680 × 500 minimum content size.
Mac sidebars prefer 300 points and can resize from 260 to 420. Menu commands
switch tabs, create notes, save dirty editors, and refresh the visible feature.
Focused scene values keep New and Save disabled outside their owning feature.
The View menu offers System, Light, and Dark appearance.

New Item selects its editor and focuses the title. The Note field has a visible
label. Saving synchronizes sidebar selection with the updated entity. Mac rows
offer context-menu and Delete-key deletion with confirmation; Cancel preserves
the draft. A deleted editor does not autosave into a missing record.

The Dashboard marks fixture status and timings as sample data and hides the
iOS-only UIKit, Flutter, widget, Host bridge, and Share inbox entries on Mac. Feed refresh belongs to the outer navigation toolbar,
and post text supports selection and copying. Selected Feed rows use native
selection text colors. Mac Feed uses a no-op widget publisher: the iOS widget
App Group writer previously blocked native Feed refresh on the main thread. Mac Light/Dark previews cover
Dashboard, Items, and Feed.

## Portfolio assets

[Mac walkthrough](../macos-demo.md) includes real native-window screenshots,
copyable portfolio text, a two-minute route, keyboard commands, and an unsigned
build/run recipe. README and the portfolio/index pages link to that entry.

Mac UI regressions live in `superDemoAppUITests/Mac/MacPortfolioUITests.swift`:
keyboard create/save/reopen, command availability, and dirty-note deletion
confirmation. These are local Mac tests, separate from iPhone shard discovery.

## Verification

- `./bin/verify-swift.sh` and `./bin/lint-markdown.sh`: passed.
- Native unsigned `macOS` build and `build-for-testing`, using project
  warnings-as-errors settings: passed.
- Native manual checks: tab shortcuts, New Item title focus, Command-S save and
  reopen, disabled File commands, deletion cancellation, Light/Dark appearance,
  compact/default window sizing, Feed selection/refresh, and stale-cache demo.
  The three screenshots were captured from the native app with `-UITesting`.
- `./bin/ci.sh`: iPhone unit run passed 201 tests in 40 suites. Full UI/platform
  completion remains a separate gate; hosted `Delivery checklist` on the PR
  is required before merge.
- `./bin/ci-platform-builds.sh`: iPad/Mac builds and watchOS/tvOS companion tests
  passed before the final Mac-only capability/contrast corrections. The final
  Mac build passed again after those corrections.
- Local Mac UI tests compiled, but the runner was killed before establishing
  its XCTest connection; no Mac UI assertion executed. An earlier Mac unit
  attempt also could not connect. Mac automated runtime coverage is not claimed.
  Result bundles/logs are retained locally under `build/macos-portfolio/`.

## Scope

Native macOS execution is development evidence. The hosted Mac lane remains
compile-only. Signing, entitlements, schemas, third-party dependencies, CI
workflows, and iOS extension linking are unchanged. The single main window
matches app-scoped navigation/App Intent state. Screenshots use `-UITesting`
with a disposable SwiftData store and deterministic sample services.
