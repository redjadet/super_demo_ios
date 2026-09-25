# Performance lab

Instruments recipes for existing `os_signpost` instrumentation, the Feed
widget App Group path, and a concurrency talk track. **Recipe only** unless
you record a real local Profile session — never invent FPS / latency numbers
in CI or docs.

## Signposts in code

| Handle | Subsystem | Category | Typical call sites |
| --- | --- | --- | --- |
| `AppPerformanceSignposts.feed` | `com.ilkersevim.superDemoApp` | `Feed` | Feed fetch / refresh path (`CachingFeedRepository`) |
| `AppPerformanceSignposts.uiKitShowcase` | same | `UIKitShowcase` | UIKit collection `applySnapshot` / showcase load |

Source: `Shared/Diagnostics/AppPerformanceSignposts.swift`.

There is **no** dedicated `os_signpost` category for WidgetKit yet. Profile the
widget path with process attach + Time Profiler / Allocations (recipe below).
An optional widget-reload category can land later without changing this honesty
rule.

## Recipe (Feed fetch)

1. Build **Debug** (or Profile) for iOS Simulator or device.
2. Xcode → Product → Profile → **os_signpost** / Points of Interest template.
3. Filter subsystem `com.ilkersevim.superDemoApp`, category `Feed`.
4. Workload: open Feed tab → pull/refresh once → wait for list.
5. Record **device/simulator**, **build configuration**, **workload steps**, and
   **observed interval** for the named signpost interval if you publish a number.

## Recipe (UIKit Showcase)

Same template; category `UIKitShowcase`. Workload: Dashboard → UIKit Showcase →
scroll collection once.

## Recipe (Feed widget / App Group)

Two processes share one contract: the **app** writes the App Group snapshot and
asks WidgetKit to reload; the **widget extension** reads that snapshot in
`TimelineProvider`.

**Contract pointers:** App Group `group.com.ilkersevim.superDemoApp`; writer
`WidgetKitFeedSnapshotPublisher` → `FeedWidgetSnapshotStore.write` +
`WidgetCenter.reloadTimelines(ofKind:)`; reader
`FeedWidgetTimelineProvider` in `superDemoAppWidget/`. States:
`unavailable` · `absent` · `corrupt` · `expired` · `ok`. Details:
[`changes/2026-09-25_widgetkit-feed-snapshot.md`](changes/2026-09-25_widgetkit-feed-snapshot.md).

### A — App process (publish path)

1. Install the app on Simulator or device with the widget target embedded
   (iPhone / iPad; Mac lane skips the extension).
2. Xcode → Product → Profile the **app** → **Time Profiler** (and optionally
   **Allocations**).
3. Workload: open Feed → pull to refresh (or wait for a successful remote /
   stale-fallback publish). Confirm Home Screen widget updates when the App
   Group is available.
4. In Instruments, look for cost around App Group file replace +
   `WidgetCenter.reloadTimelines` on the main-app side of a Feed refresh.
   Correlate with category `Feed` signposts if you also open Points of Interest.
5. Record host, configuration, steps, and whether App Group was actually
   available (`unavailable` on unsigned Simulator is an honest outcome, not a
   failed recipe).

### B — Widget extension process (timeline read)

1. Add the Feed widget to the Home Screen.
2. Profile / attach to the **widget extension** process
   (`com.ilkersevim.superDemoApp.FeedWidget`), not only the app.
3. Trigger a timeline reload (Feed refresh in the app, or wait for the
   provider’s `.after(15 * 60)` policy).
4. Observe `getTimeline` / `FeedWidgetSnapshotStore.loadState` work: JSON read,
   state classification, entry build. Keep allocations small — the widget must
   stay a **read-only** snapshot consumer (no SwiftData / Domain stack).

**Do not** claim widget FPS or “production WidgetKit at scale” from CI. Hosted
GHA compiles the extension; it does not Profile it.

## Live Activity / Dynamic Island

**Pending JP-P1-A.** ActivityKit is not in the repo yet. Do **not** invent a
Live Activity Instruments recipe, fake attributes, or placeholder timings.
When JP-P1-A lands, add a recipe here that mirrors Feed start/update/end (and
cancel/fail) with the same honesty rule.

## Concurrency talk track (reviewers)

Use this when walking performance **and** Swift Concurrency together — still
no invented numbers.

| Topic | Where to point | What to say |
| --- | --- | --- |
| Cancel-safe refresh | `Shared/Presentation/AsyncLoadController.swift`; Feed / Items / Dashboard feature models | One in-flight `Task`; `cancel()` drops work; cancel restores prior UI — not a Retry failure (`CancellationError`) |
| Structured loads | Feature models + `.task` / disappear cancel | Prefer structured tasks over detached fire-and-forget; lifetime tied to the screen |
| Actors / tokens | Networking token refreshers under `Shared/` | Actor isolation for shared credentials; no ad-hoc locks on the hot path |
| Signposts vs concurrency | `AppPerformanceSignposts.feed` around `fetchPosts` | Interval bounds the repository fetch; cancel mid-flight should end the interval via `defer` without blaming the server |
| Widget boundary | App publisher vs widget `TimelineProvider` | App owns write + reload; widget process is read-only App Group — memory story is “small DTO,” not shared SwiftData |
| Strict concurrency | Swift 6 / `Sendable` on boundaries | Treat diagnostics as design feedback; do not silence without an ownership reason |

**Demo path:** Feed pull-to-refresh → cancel mid-flight (disappear / cancel
control) → prior content restored → then complete a refresh and point at the
Home Screen widget updating from the same cache honesty.

## Honesty rule

If profiling cannot run in the agent/CI environment, keep this as a **recipe
only** and omit FPS / latency claims. Never invent benchmarks. Never invent a
Live Activity recipe before JP-P1-A.
