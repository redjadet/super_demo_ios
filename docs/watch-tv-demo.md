# Watch and Apple TV demo

Two native Feed companions, designed for a short offline portfolio walkthrough.
The Watch uses a scrollable list and headline detail; Apple TV uses native remote
focus and full-screen navigation. Both show the source and freshness of content.

## Run in Xcode

1. Open `superDemoApp.xcodeproj` with Xcode 27 and the relevant Simulator runtime.
2. Choose `superDemoAppWatch` with a Watch Simulator, or `superDemoAppTV` with an
   Apple TV Simulator. Run the app.
3. Choose **Try sample Feed**. The **Sample Feed** label stays visible.
   Illustrative headlines work without network or App Group provisioning.
4. Open a headline to read its full text. On Watch, scroll with the Digital Crown.
   On TV, move focus with the remote and press Select. Use Up/Down to scroll
   long text; Back returns to the list.
5. Open **Demo states**. Show **Cached Feed**, **Expired Feed**, then **Empty Feed**.
   Cached and expired content retains its headlines; empty content offers a fresh
   sample. **No snapshot**, **Unreadable snapshot**, and **Storage unavailable**
   show distinct recovery messages.
6. Choose **Use stored Feed** to leave the sample. **Reload** reads the local
   snapshot; it does not reset an expired sample's timestamp.

For repeatable launches, add `-CompanionDemoScenario fresh` to the scheme's Run
arguments. Accepted values: `fresh`, `stale`, `expired`, `empty`, `absent`,
`corrupt`, `unavailable`. Unknown or incomplete arguments use normal storage.

## What this demonstrates

- Shared snapshot presentation through Observation, with native SwiftUI layouts.
- Explicit cached, expired, missing, malformed, empty, and unavailable states.
- Snapshot disk reads away from the main actor; canceled or superseded reads
  cannot replace newer UI state.
- Foreground reload and 15-second visible polling. Expiry preserves headlines
  and the original timestamp instead of silently renewing freshness.
- System fonts, semantic colors, accessible labels, and native navigation/focus.
- Branded launch icons using the main portfolio app's existing artwork.

**Data boundary:** each device has its own App Group container. The companions
reuse the Home Screen widget's versioned JSON format, not the iPhone's disk.
This demo includes no WatchConnectivity or phone-to-TV transport. Sample states
stay in memory and never write, delete, or repair stored data. Relaunch returns
to storage unless a scenario argument is set. These are demo companions, not
full Feed apps or a shipped App Store release.

## Simulator screenshots

Captured on watchOS 27 (Apple Watch SE 3, 40 mm) and tvOS 27 (Apple TV 4K,
1080p). Headlines are illustrative sample content. These images demonstrate
Simulator layouts, not physical-device or App Store release validation.

| Watch Feed | Full headline |
| --- | --- |
| ![Watch Feed with source and freshness](screenshots/watch-tv/watch-feed-40mm.png) | ![Watch headline detail with full text](screenshots/watch-tv/watch-headline-40mm.png) |

| Apple TV, dark | Apple TV, light |
| --- | --- |
| ![Apple TV Feed with native row focus in dark appearance](screenshots/watch-tv/tv-feed-dark.png) | ![Apple TV Feed with native row focus in light appearance](screenshots/watch-tv/tv-feed-light.png) |

## Source and verification

| Concern | Owner |
| --- | --- |
| Native Watch UI | `superDemoAppWatch/FeedWatchSnapshotView.swift` |
| Native TV UI | `superDemoAppTV/FeedTVSnapshotView.swift` |
| Presentation, sample states, polling | `FeedWidgetShared/FeedCompanionModel.swift` |
| Illustrative headlines | `FeedWidgetShared/FeedCompanionDemoSnapshot.swift` |
| Versioned DTO and coordinated storage | `FeedWidgetShared/FeedWidgetSnapshot.swift`, `FeedWidgetShared/FeedWidgetSnapshotStore.swift` |
| Shared regression tests, run on both hosts | `FeedCompanionTests/FeedCompanionModelTests.swift` |
| Platform storage integration tests | `superDemoAppWatchTests/`, `superDemoAppTVTests/` |

```bash
./bin/verify-swift.sh
./bin/ci-watch-build.sh
./bin/ci-tvos-build.sh
./bin/checklist
```

The companion scripts run hosted XCTest on a concrete Simulator. A generic
Simulator destination provides compile proof only. Full checklist also checks
the main iPhone app and the iPad/Mac builds.

### Verified locally on 2026-10-08

| Proof | Result |
| --- | --- |
| Watch hosted XCTest, watchOS 27 | 15 tests passed |
| TV hosted XCTest, tvOS 27 | 15 tests passed |
| Main iPhone app, iOS 27 | 202 unit tests and 27 UI tests passed |
| iPad and Mac | Builds passed with warnings treated as errors |
| Repo checks | Swift format/lint, Markdown, architecture, and checklist checks passed |
| Watch SE 3, 40 mm | Feed, full headline, state selection, empty recovery, branded Home icon |
| Watch largest Text Size | Source/status, headline scrolling, state selection, and sample recovery readable |
| Apple TV 1080p | Light/dark layouts, remote focus, Select/Back, state selection, branded Home icon |
| TV long stored headline | Up/Down reaches the final sentence and returns to the beginning |

The long-headline fixture used a separate disposable Simulator. Existing device
storage was not seeded or reset. Watch Text Size and TV appearance were restored
after review. Physical hardware and distribution signing remain unverified.

The final unsharded checklist encountered an iPhone unit-runner launch hang
before unit tests started; its 27 UI tests passed. After a Simulator restart,
`CI_IPHONE_TEST_SHARD=unit ./bin/checklist` passed the 202 unit tests and all
remaining platform checks. This combines fresh unit and UI proof for the same
source without treating the failed launch as an assertion failure or hiding it.

Platform guidance: Apple's [watchOS design guidance](https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos)
and [Apple TV focus interactions](https://developer.apple.com/documentation/uikit/about-focus-interactions-for-apple-tv).
