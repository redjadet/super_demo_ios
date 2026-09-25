# Portfolio tour — superDemoApp

Repo for reviewers: **Universal SwiftUI + SwiftData demo** (iPhone / iPad / Mac)
with a **Feed** trajectory: network client → repository → use cases →
`@Observable` feature model → SwiftUI, DI, cancellation, optional SwiftData
read-through cache.

## Reviewer map

| Quality theme | Path | Talk track | Proof |
| --- | --- | --- | --- |
| Layer boundaries | `Features/*/`, `docs/layers.md` | Presentation → Domain ← Data; composition in `App/` | `./bin/lint.sh` → `tool/check_layer_boundaries.sh` |
| Concurrency cancel | `Shared/Presentation/AsyncLoadController.swift`, Feed/Items/Dashboard models | Cancel restores prior state; `CancellationError` not a Retry failure | Unit tests on feature models; UI Retry IDs |
| Stale cache | `Features/Feed/Data/CachingFeedRepository.swift`, `FeedView`, `App/FeedComposition.swift` | Remote fail + fresh cache → `isStale` banner | `-StaleFeedDemo` / Engineering demos → Stale Feed; `#Preview("Feed — Stale")`; `CachingFeedRepositoryTests` |
| Networking retry / 401 / 429 | `Shared/Networking/` | Injectable session; redacted logger | `URLSessionAPIClientTests`, `RetryPolicyTests` |
| Idempotency | `APIRequest.idempotencyKey` + Dashboard **Idempotent POST** demo | Header enables POST retry; **simulated** duplicate-safe transport in Data | Demo UI + `IdempotentPostDemo*` tests |
| UIKit showcase | `Features/ProductionReadiness/UIKitShowcase/` | Collection reuse, prefetch, hosting, custom transition | UI smoke: `uikitShowcaseLink` |
| Diagnostics / crash swap | `Shared/Diagnostics/` | OSLog non-fatals today; vendor adapter later | [`incident-playbook.md`](incident-playbook.md); Engineering demos → Diagnostics |
| CI / delivery | `bin/`, `.github/workflows/ci.yml`, Fastlane | Local `./bin/ci.sh` = merge proof; GHA build-heavy | [`ci-cd-map.md`](ci-cd-map.md) |
| Performance signposts | `AppPerformanceSignposts`, Feed widget App Group path | Feed + UIKit `os_signpost`; widget recipe (app publish + extension timeline); concurrency cancel talk track; Live Activity recipe **pending JP-P1-A** | [`performance-lab.md`](performance-lab.md) |
| Security habits | Keychain demo, ATS, redaction | Demo auth ≠ production OAuth | [`security-checklist.md`](security-checklist.md) |
| Engineering standards | Layers, Observation, PR proof | Human-readable budget + owners | [`engineering-standards.md`](engineering-standards.md) |
| SonarCloud | Optional static analysis | **Skipped** — no org; use lint/CI gates | [`sonar-decision.md`](sonar-decision.md) |
| Design tokens | `DESIGN.md` ↔ SwiftUI roles | Local table; Figma optional later | [`design-token-figma.md`](design-token-figma.md) |

## Platform surfaces

Apple-platform / hybrid-native skill map for reviewers (inventory after
`origin/main` @ `6abb79a`, 2026-09-25). Honest “not in repo” beats a broken link.
Sibling backlog (do not merge scopes): portfolio plan under agent store
`job-4472017039-portfolio-plan.md`; Flutter quality-system maturity is separate
(`flutter-parity-quality-plan.md`).

| Skill | Current path / proof | Status |
| --- | --- | --- |
| Clean layers + modularity | `superDemoApp/Features/*/`, [`layers.md`](layers.md), [`modularity.md`](modularity.md), `./tool/check_layer_boundaries.sh` | **In repo** |
| SwiftUI + Observation + DI | Feed / Items / ProductionReadiness; `App/*Composition.swift` | **In repo** |
| Swift Concurrency | `async`/`await` networking; actor token refreshers; `AsyncLoadController` | **In repo** |
| Offline / networking | `CachingFeedRepository`, [`offline-first.md`](offline-first.md), [`offline-invariants.md`](offline-invariants.md), [`sync-and-networking.md`](sync-and-networking.md) | **In repo** |
| App Intents (open-tab) | `superDemoApp/App/AppIntents/` + Shortcuts; tests | **In repo** |
| Parameterized Feed/Items intents | `RefreshFeedIntent` (`openFeedTab`) → `FeedRefreshCoordinator` + `feedRefreshRequestID`; tests | **In repo** (JP-P1-B) |
| ObjC legacy interop | `superDemoApp/Shared/LegacyObjC/` + bridging header | **In repo** (thin) |
| Observability / crash swap | `superDemoApp/Shared/Diagnostics/`, [`incident-playbook.md`](incident-playbook.md) | **In repo** |
| Performance (Feed + UIKit) | `AppPerformanceSignposts`, [`performance-lab.md`](performance-lab.md) | **In repo** |
| Performance (widget / concurrency lab) | [`performance-lab.md`](performance-lab.md) widget App Group recipe + concurrency talk track | **In repo** (JP-P1-E; Live Activity recipe pending JP-P1-A) |
| Universal shell (iPhone / iPad / Mac) | Adaptive navigation; CI platform builds | **In repo** |
| WidgetKit / Home Screen widget | `FeedWidgetShared/`, `superDemoAppWidget/`, App Group `group.com.ilkersevim.superDemoApp`; Engineering demos → Feed widget snapshot | **In repo** (JP-P0-B; iOS embed; Mac lane skips extension) |
| Live Activities / Dynamic Island | — | **Not in repo** (JP-P1-A) |
| Push / notification service extension | Engineering demos → Local stale-Feed reminder (local only) | **In repo** (JP-P1-C local; NSE / APNs still **not** in repo — JP-P2-E) |
| Share extension | — | **Not in repo** (JP-P2-A) |
| Sign in with Apple | Demo auth / Keychain ≠ SIWA | **Not in repo** (JP-P2-B) |
| StoreKit 2 | — | **Not in repo** (JP-P1-D) |
| Native↔Flutter host bridge | `Shared/HostBridge/`, [`native-host-boundary.md`](native-host-boundary.md); Engineering demos → Host bridge ping | **In repo** (JP-P0-C contract only; Flutter module not vendored) |
| Core ML / Vision / Speech / Apple Intelligence | — | **Not in repo** (JP-P2-C; no AI entitlement claims) |
| watchOS / visionOS / tvOS companion | Project may mention xr; no reviewer demo | **Not in repo** (JP-P2-F) |
| App Store–shipped product | README honesty | **Not claimed** |

**Maps:** [`../CODEMAP.md`](../CODEMAP.md) · [`architecture-tour.md`](architecture-tour.md) ·
[`engineering/engineering-quality-scorecard.md`](engineering/engineering-quality-scorecard.md).

## How to read this repo (cold reviewer)

1. [`../README.md`](../README.md) — what it proves + 3-minute path.
2. [`../CODEMAP.md`](../CODEMAP.md) — task → path; timed walk
   [`architecture-tour.md`](architecture-tour.md).
3. [`architecture.md`](architecture.md) + [`feature-template.md`](feature-template.md).
4. **`Features/Items/`** — Reference (SwiftData, sync repository API).
5. **`Features/Feed/`** — JSONPlaceholder client + SwiftData read-through cache;
   see [`changes/2026-05-16_feed-feature-shipped.md`](changes/2026-05-16_feed-feature-shipped.md)
   and [`changes/2026-09-15_feed-items-diagnostics-hardening.md`](changes/2026-09-15_feed-items-diagnostics-hardening.md).
6. **`Features/ProductionReadiness/`** — dashboard, networking demos, UIKit showcase;
   see [`changes/2026-05-18_production_readiness_dashboard.md`](changes/2026-05-18_production_readiness_dashboard.md).
7. **`App/`** — `AppRootView` tabs; composition roots wire DI and feature models.
8. **`Shared/Presentation/AdaptiveNavigationShell.swift`** — shared chrome.
9. Deep links: open `superdemo://dashboard/risks`, `superdemo://feed`, or
   `superdemo://items` (or matching `https://superdemo.app/…` paths) to review
   typed routing in `App/AppNavigation.swift`.

## Launch and build flags

Source: `Shared/AppLaunchConfiguration.swift`.

| Flag | Kind | Effect |
| --- | --- | --- |
| `-ReviewerDemoMode` or `SUPERDEMO_REVIEWER_DEMO_MODE=1` | **Launch / env** | Seeded sample Dashboard + Feed + Items |
| `REVIEWER_DEMO` | **Compile-time** (TestFlight beta via Fastlane) | Same seeded path when built into the binary — not a launch argument |
| `-StaleFeedDemo` or `SUPERDEMO_STALE_FEED_DEMO=1` | **Launch / env** | Seed Feed SwiftData cache + failing remote → real stale banner via `CachingFeedRepository` |
| `-UITesting` | Launch | UI-test fixtures / in-memory store |
| `-UITestingFeedFailure` | Launch | Failing remote without cache seed (error + Retry UI) |
| `-KeychainTokenDemo` or `SUPERDEMO_KEYCHAIN_TOKEN_DEMO=1` | Launch / env | Opt-in Keychain-backed token refresher demo |

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

**Reviewer boundary:** Presentation never imports `URLSession`; unit tests stub
HTTP — no live network on default CI.

**Stale demo:** Launch with `-StaleFeedDemo` / `SUPERDEMO_STALE_FEED_DEMO=1`
(Feed tab), or open Dashboard → Engineering demos → **Stale Feed cache fallback**.
Both seed a fresh SwiftData cache and fail remote through existing
`CachingFeedRepository`. Preview `#Preview("Feed — Stale")` and
`CachingFeedRepositoryTests` remain valid proofs.

## Reviewer talking points (5–7)

- **Layers:** `Presentation → Domain ← Data`; `./tool/check_layer_boundaries.sh`.
- **DI:** Injectable `URLSession` + URLs in Data; wired in composition.
- **Concurrency:** `@MainActor` feature model; cancel in-flight fetch;
  `CancellationError` not surfaced as Retry failure.
- **Errors:** Map to `FeedDisplayError`; retry vs transport/decoding semantics.
- **Empty vs bug:** Valid `[]` → **empty** UI (see
  [Edge cases (summary)](#edge-cases-summary)).
- **Tests:** Stub `URLProtocol` / injected session.
- **Cache:** On fetch failure + **fresh** stored rows (15m TTL) → content with
  `isStale` (banner); expired cache rethrows. Signposts mark Feed fetch.
- **Navigation:** Typed `AppTab` / `AppRoute`; custom-scheme + HTTPS universal
  link parsing plus App Intents (Open Feed / Items / Production Risks /
  Refresh Feed) without raw string navigation in views.

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
- **SwiftData store failure** — `AppModelContainer` deletes + recreates the disk
  store when possible; otherwise in-memory + diagnostics.

## Related docs

- [`incident-playbook.md`](incident-playbook.md)
- [`ci-cd-map.md`](ci-cd-map.md)
- [`security-checklist.md`](security-checklist.md)
- [`performance-lab.md`](performance-lab.md)
- [`engineering-standards.md`](engineering-standards.md)

## Proof commands

From **`superDemoApp/`**:

```bash
./bin/lint.sh
./bin/checklist-fast   # docs / fast sanity
./bin/checklist        # fuller local delivery (incl. tests when not skipped)
./bin/ci.sh            # Before merge / PR
```

Note: `./bin/verify-swift.sh` = format + lint only (does not build or test).
