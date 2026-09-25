# Performance lab

Instruments recipe for existing `os_signpost` instrumentation.

## Signposts in code

| Handle | Subsystem | Category | Typical call sites |
| --- | --- | --- | --- |
| `AppPerformanceSignposts.feed` | `com.ilkersevim.superDemoApp` | `Feed` | Feed fetch / refresh path |
| `AppPerformanceSignposts.uiKitShowcase` | same | `UIKitShowcase` | UIKit collection `applySnapshot` / showcase load |

Source: `Shared/Diagnostics/AppPerformanceSignposts.swift`.

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

## Honesty rule

If profiling cannot run in the agent/CI environment, keep this as a **recipe only**
and omit FPS / latency claims. Never invent benchmarks.
