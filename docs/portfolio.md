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
   see [`changes/2026-05-16_feed-feature-shipped.md`](changes/2026-05-16_feed-feature-shipped.md).
5. **`App/`** — `AppRootView` tabs; `ItemsComposition` / `FeedComposition` wire
   `ModelContext` into repositories and hold `@State` feature models.
6. **`Shared/Presentation/AdaptiveNavigationShell.swift`** — shared chrome.

## Items walkthrough (`Features/Items/`)

- **Domain** — Entities; repository protocol; use cases (`LoadItemsUseCase`, …);
  `DisplayError`. Pure Swift.
- **Data** — `SwiftDataItemRepository`, `@Model Item`. Imports SwiftData.
- **Presentation** — `@Observable ItemsFeatureModel`, `ItemsView`,
  `ItemsNavigationShell`. No persistence imports.

Observation + thin use cases on a repository protocol.

## Feed walkthrough (`Features/Feed/`)

- **Domain** — `FeedPost`, `FeedRepository`, load/refresh use cases,
  typed error surface (`FeedDisplayError`).
- **Data** — `PostDTO`, `FeedAPIClient` + live `URLSession`, `RemoteFeedRepository`,
  `CachedFeedPost` + `CachingFeedRepository`.
- **Presentation** — `FeedFeatureModel` (cancel in-flight refresh), list + retry UX,
  `FeedNavigationShell`.

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
- **Cache:** On fetch failure + stored rows → return stale content (demo OK).

## Reviewer checklist

- [x] Layer imports pass `./bin/lint.sh` (also in `./bin/ci.sh`)
- [x] Feed tab reachable; list, Retry, toolbar refresh (`FeedView` / UI tests)
- [x] `./bin/ci.sh` passes on merge (lint + iPhone tests + iPad/Mac builds)
- [x] Previews cover light/dark for `FeedView` (`#Preview` + `UniversalPreviewLayouts`)
- [ ] VoiceOver on Feed chrome / rows / Retry (manual pass on device/simulator)

## Edge cases (summary)

- **Network / HTTP** — Non-2xx / transport → **failed + Retry**.
- **Decode** — Bad JSON → failure, not a fake-empty list.
- **`[]` response** — Treat as **empty** success.
- **Tab / disappear** — **`cancelRefresh()`** drops orphaned work.

## Proof commands

From **`superDemoApp/`**:

```bash
./bin/lint.sh
./bin/checklist    # SwiftUI universal / checklist scenarios
./bin/ci.sh       # Before merge / PR
```
