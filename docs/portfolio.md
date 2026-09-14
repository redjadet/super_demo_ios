# Portfolio tour — superDemoApp

Repo for reviewers: **Universal SwiftUI + SwiftData demo** (iPhone / iPad / Mac)
with a **Feed** trajectory: network client → repository → use cases →
`@Observable` feature model → SwiftUI, DI, cancellation, optional SwiftData
read-through cache.

## How to read this repo (cold reviewer)

1. [`AGENTS.md`](../AGENTS.md) — agent map; `./bin/*` proof commands.
2. [`docs/architecture.md`](architecture.md) +
   [`docs/feature-template.md`](feature-template.md).
3. **`Features/Items/`** — Reference (SwiftData, sync repository API).
4. **`Features/Feed/`** — JSONPlaceholder client + SwiftData read-through cache;
   see [`changes/2026-05-16_feed-feature-shipped.md`](changes/2026-05-16_feed-feature-shipped.md)
   and [`changes/2026-09-15_feed-items-diagnostics-hardening.md`](changes/2026-09-15_feed-items-diagnostics-hardening.md).
5. **`Features/ProductionReadiness/`** — dashboard, networking, UIKit showcase;
   see [`changes/2026-05-18_production_readiness_dashboard.md`](changes/2026-05-18_production_readiness_dashboard.md).
6. **`App/`** — `AppRootView` tabs; composition roots wire DI and feature models.
7. **`Shared/Presentation/AdaptiveNavigationShell.swift`** — shared chrome.
8. Deep links: open `superdemo://dashboard/risks`, `superdemo://feed`, or
   `superdemo://items` to review typed routing in `App/AppNavigation.swift`.

## Items walkthrough (`Features/Items/`)

- **Domain** — Entities; repository protocol; use cases (`LoadItemsUseCase`, …);
  `DisplayError`. Pure Swift.
- **Data** — `SwiftDataItemRepository`, `@Model Item`. Imports SwiftData.
- **Presentation** — `@Observable ItemsFeatureModel`, `ItemsView`,
  `ItemsNavigationShell`. No persistence imports. Refresh cancel restores prior
  state; `.task` / `.onDisappear` own lifecycle.

Observation + thin use cases on a repository protocol.

## Feed walkthrough (`Features/Feed/`)

- **Domain** — `FeedPost`, `FeedRepository` → `FeedLoadResult` (`posts` +
  `isStale`), **`RefreshFeedUseCase` only** (no separate load use case),
  typed error surface (`FeedDisplayError`).
- **Data** — `PostDTO`, `FeedAPIClient` + live `URLSession`, `RemoteFeedRepository`,
  `CachedFeedPost` + `CachingFeedRepository` (remote fail + non-empty cache →
  `isStale: true`).
- **Presentation** — `FeedFeatureModel` (cancel restores prior state; diagnostics on
  failure/stale), list + Retry + **stale banner**, `FeedNavigationShell`.

**Interview boundary:** Presentation never imports `URLSession`; unit tests stub
HTTP — no live network on default CI.

## Interview talking points (5–7)

- **Layers:** `Presentation → Domain ← Data`; `./tool/check_layer_boundaries.sh`.
- **DI:** Injectable `URLSession` + URLs in Data; wired in composition.
- **Concurrency:** `@MainActor` feature model; cancel in-flight fetch;
  `CancellationError` not surfaced as Retry failure.
- **Errors:** Map to `FeedDisplayError`; retry vs transport/decoding semantics.
- **Empty vs bug:** Valid `[]` → **empty** UI (see
  [Edge cases (summary)](#edge-cases-summary)).
- **Tests:** Stub `URLProtocol` / injected session.
- **Cache:** On fetch failure + stored rows → return content with `isStale`
  (banner in UI); diagnostics log `feed-cache-fallback`.
- **Navigation:** Typed `AppTab` / `AppRoute`; custom-scheme deep links for
  dashboard, risks, feed, and items without raw string navigation in views.

## Reviewer checklist

- [x] Layer imports pass `./bin/lint.sh` (also in `./bin/ci.sh`)
- [x] Feed tab reachable; list, Retry, toolbar refresh (`testFeedTabIsReachable` / `FeedView`)
- [x] `./bin/ci.sh` passes on merge (lint + iPhone tests + iPad/Mac builds)
- [x] Previews cover light/dark for `FeedView` (`#Preview` + `UniversalPreviewLayouts`)
- [x] VoiceOver-relevant Feed chrome / rows / Retry proof (`testFeedAccessibilityChromeRowsAndRetry`)
- [x] Deep links for Feed / Items (`testDeepLinkOpensFeedTab` / `testDeepLinkOpensItemsTab`)

## Edge cases (summary)

- **Network / HTTP** — Non-2xx / transport → **failed + Retry** (or stale cache).
- **Decode** — Bad JSON → failure, not a fake-empty list.
- **`[]` response** — Treat as **empty** success.
- **Tab / disappear** — **`cancelRefresh()`** restores prior state; drops orphaned work.
- **SwiftData store failure** — `AppModelContainer` falls back to in-memory + diagnostics.

## Proof commands

From **`superDemoApp/`**:

```bash
./bin/lint.sh
./bin/checklist    # SwiftUI universal / checklist scenarios
./bin/ci.sh       # Before merge / PR
```
