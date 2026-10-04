# Portfolio tour — superDemoApp

Repo for reviewers: **Universal SwiftUI + SwiftData demo** (iPhone / iPad / Mac)
with a **Feed** trajectory: network client → repository → use cases →
`@Observable` feature model → SwiftUI, DI, cancellation, optional SwiftData
read-through cache.

## Reviewer map

| Quality theme | Path | Talk track | Proof |
| --- | --- | --- | --- |
| Layer boundaries | `superDemoApp/Features/*/`, `docs/layers.md` | Presentation → Domain ← Data; composition in `superDemoApp/App/` | `./bin/lint.sh` → `tool/check_layer_boundaries.sh` |
| Concurrency cancel | `superDemoApp/Shared/Presentation/AsyncLoadController.swift`, Feed/Items/Dashboard models | Cancel restores prior state; `CancellationError` not a Retry failure | Unit tests on feature models; UI Retry IDs |
| Stale cache | `superDemoApp/Features/Feed/Data/CachingFeedRepository.swift`, `FeedView`, `superDemoApp/App/FeedComposition.swift` | Remote fail + fresh cache → `isStale` banner | `-StaleFeedDemo` / Engineering demos → Stale Feed; `#Preview("Feed — Stale")`; `CachingFeedRepositoryTests` |
| Networking retry / 401 / 429 | SPM [`IlkerSevimNetworking`](https://github.com/redjadet/ilkersevim_networking) + app re-export | Injectable session; redacted logger | `URLSessionAPIClientTests`, `RetryPolicyTests` |
| Idempotency | `APIRequest.idempotencyKey` + Dashboard **Idempotent POST** demo | Header enables POST retry; **simulated** duplicate-safe transport in Data | Demo UI + `IdempotentPostDemo*` tests |
| UIKit showcase | `superDemoApp/Features/ProductionReadiness/UIKitShowcase/` | Collection reuse, prefetch, hosting, custom transition | UI smoke: `uikitShowcaseLink` |
| Diagnostics / crash swap | `superDemoApp/Shared/Diagnostics/` | OSLog non-fatals today; vendor adapter later | [`incident-playbook.md`](incident-playbook.md); Engineering demos → Diagnostics |
| CI / delivery | `bin/`, `.github/workflows/ci.yml`, Fastlane | Local `./bin/ci.sh` = merge proof; GHA build-heavy | [`ci-cd-map.md`](ci-cd-map.md) |
| Performance signposts | `AppPerformanceSignposts`, Feed widget App Group path | Feed + UIKit `os_signpost`; widget recipe; Live Activity Feed-refresh recipe (gate A); concurrency cancel talk track | [`performance-lab.md`](performance-lab.md) |
| Security habits | Keychain demo, ATS, redaction | Demo auth ≠ production OAuth | [`security-checklist.md`](security-checklist.md) |
| Engineering standards | Layers, Observation, PR proof | Human-readable budget + owners | [`engineering-standards.md`](engineering-standards.md) |
| SonarCloud | Optional static analysis | **Skipped** — no org; use lint/CI gates | [`sonar-decision.md`](sonar-decision.md) |
| Design tokens | `DESIGN.md` ↔ SwiftUI roles | Local table; Figma optional later | [`design-token-figma.md`](design-token-figma.md) |

## Platform surfaces

Apple-platform / hybrid-native skill map for reviewers (inventory after
`origin/main` @ `bf9b626`, 2026-10-03 — **post P2 A–F + #36–#74**: WidgetKit, Live
Activity, Share, SIWA, StoreKit query, Vision OCR, Flutter embed, watchOS
companion, Open Feed Post intent / AASA `/feed/*` + apex Associated Domains +
Markdown relative-link gate + CODEMAP/router path honesty + Engineering-demo
UITest scroll restore (#43) + UITest tab/Feed–Items chrome false-green harden
(#45) + Dashboard remote-health cancel honesty (#46) + StoreKit/Share UITest
harden (#47) + agent harness evidence (#48) + Stale Feed App Intent isolation
(#49) + Release health sample-vs-live score (#50) + mixed-age widget TTL (#51) +
Flutter host-screen UITest false-green (#52) + Feed Retry UITest honesty (#53) +
Host bridge ping UITest honesty (#55) + Idempotent POST UITest replay honesty
(#56) + visionOS **shared SwiftUI API compile guards** (#57) + portfolio tip-pin
honesty (#58) + README cold-path polish (#59) + amateur DESIGN/AccentColor polish
(#60/#61) + README image badges (#62) + iPhone deployment floor **26.7** (#63) +
post-#63 docs honesty (#64) + macOS/watchOS deployment floor **26.7** parity
(#65) + seeded Production Risks UITest row honesty
(`productionRiskRow-push-notifications`, #66) + Engineering-demo factories
injected from App composition (#67) + portfolio Platform surfaces through #65–#67
(#68) + Mac lane **unsigned compile-proof** default (#69;
`CI_MAC_REQUIRE_CODE_SIGN=1` escape) + Stackademic senior-patterns map +
launch-arg / composition toggle honesty (no remote feature-flag claim) (#70) +
standalone Mac `xcodebuild` recipes aligned with #69 (#71 / index #74) + README
engineering-evidence cold path (#72); visionOS **companion demo still deferred**;
paid StoreKit / production APNs / App Icon PNGs / P2-A light–dark screenshots
stay deferred/human-only).
Honest “not in repo” beats a broken link.
Sibling backlog (do not merge scopes): portfolio plan under agent store
`job-4472017039-portfolio-plan.md`; Flutter quality-system maturity is separate
(`flutter-parity-quality-plan.md`).

| Skill | Current path / proof | Status |
| --- | --- | --- |
| Clean layers + modularity | `superDemoApp/Features/*/`, [`layers.md`](layers.md), [`modularity.md`](modularity.md), `./tool/check_layer_boundaries.sh` | **In repo** |
| SwiftUI + Observation + DI | Feed / Items / ProductionReadiness; `superDemoApp/App/*Composition.swift`; Engineering demos injected from App composition factories (#67) | **In repo** |
| Swift Concurrency | `async`/`await` networking; actor token refreshers; `AsyncLoadController` | **In repo** |
| Offline / networking | `CachingFeedRepository`, [`offline-first.md`](offline-first.md), [`offline-invariants.md`](offline-invariants.md), [`sync-and-networking.md`](sync-and-networking.md) | **In repo** |
| App Intents (open-tab) | `superDemoApp/App/AppIntents/` + Shortcuts; tests | **In repo** |
| Parameterized Feed/Items intents | `RefreshFeedIntent` (`openFeedTab`); `OpenFeedPostIntent` (`postID`) → `feedOpenPostID` + `superdemo://feed/<id>`; tests | **In repo** (JP-P1-B + thin entity open) |
| ObjC legacy interop | `superDemoApp/Shared/LegacyObjC/` + bridging header | **In repo** (thin) |
| Observability / crash swap | `superDemoApp/Shared/Diagnostics/`, [`incident-playbook.md`](incident-playbook.md) | **In repo** |
| Performance (Feed + UIKit) | `AppPerformanceSignposts`, [`performance-lab.md`](performance-lab.md) | **In repo** |
| Performance (widget / concurrency lab) | [`performance-lab.md`](performance-lab.md) widget App Group + Live Activity Feed-refresh recipes + concurrency talk track | **In repo** (JP-P1-E + JP-P1-A) |
| Universal shell (iPhone / iPad / Mac) | Adaptive navigation; CI platform builds (iPad + Mac + watchOS; Mac **unsigned** compile-proof #69); iOS / macOS floors **26.7** (#63 / #65) | **In repo** |
| WidgetKit / Home Screen widget | `FeedWidgetShared/`, `superDemoAppWidget/`, App Group `group.com.ilkersevim.superDemoApp`; Engineering demos → Feed widget snapshot | **In repo** (JP-P0-B; iOS embed; Mac lane skips extension) |
| Live Activities / Dynamic Island | `FeedRefreshActivityAttributes`, `ActivityKitFeedRefreshLiveActivityController`, `FeedRefreshLiveActivity` in widget bundle; Feed refresh gate A | **In repo** (JP-P1-A; compile on GHA; device Island not claimed on hosted CI) |
| Push / notification service extension | Engineering demos → Local stale-Feed reminder (local only); [`release-checklist.md`](release-checklist.md) mock TestFlight/APNs | **In repo** (JP-P1-C local + JP-P2-E labeled mock/demo checklist; no production APNs claim) |
| Share extension | `ShareInboxShared/`, `superDemoAppShare/`, App Group inbox; Engineering demos → Share inbox | **In repo** (JP-P2-A; iOS embed; does **not** open SwiftData; Mac lane skips extension) |
| Sign in with Apple | `superDemoApp/Shared/Auth/`, Engineering demos → Sign in with Apple (demo) | **In repo** (JP-P2-B; Simulator-honest unavailable; not production auth) |
| StoreKit 2 | `Config/Products.storekit`; `superDemoApp/Shared/StoreKit/`; Engineering demos → StoreKit 2 product query (demo) | **In repo** (JP-P1-D query-only; no purchase / charge path) |
| Native↔Flutter host bridge | `superDemoApp/Shared/HostBridge/`, `superDemoApp/Shared/FlutterEmbed/`, `flutter_module/`, [`native-host-boundary.md`](native-host-boundary.md), [`flutter-add-to-app.md`](flutter-add-to-app.md); Engineering demos → Host bridge ping / Flutter add-to-app | **In repo** (JP-P0-C contract + JP-P2-D module embed; `postCount` = full cache size; Mac unlinked; frameworks via prepare script) |
| Core ML / Vision / Speech / Apple Intelligence | `superDemoApp/Shared/OnDeviceAI/`, Engineering demos → On-device Vision OCR | **In repo** (JP-P2-C Vision OCR only; no Speech / Core ML model / Apple Intelligence claim) |
| watchOS companion (Feed snapshot) | `superDemoAppWatch/`, `FeedWidgetShared/`, App Group `group.com.ilkersevim.superDemoApp`; Engineering demos → watchOS Feed companion; scheme `superDemoAppWatch`; `WATCHOS_DEPLOYMENT_TARGET` **26.7** (#65) | **In repo** (JP-P2-F watchOS; embed `platformFilter = ios`; watch-local App Group — not phone sync) |
| visionOS shared SwiftUI API guards | `AdaptiveNavigationShell` / glass chrome availability; `OnDeviceVisionDemo` `nonisolated` init — [#57](https://github.com/redjadet/super_demo_ios/pull/57) / tip `fc2837a` | **In repo** (compile guards only; SDK build may pass without a visionOS Simulator runtime) |
| visionOS companion | Project may mention xr settings; no reviewer companion demo | **Not in repo** (deferred; #57 ≠ companion; JP-P2-F shipped watchOS only) |
| tvOS companion | — | **Not in repo** |
| App Store–shipped product | README honesty | **Not claimed** |

**Maps:** [`../CODEMAP.md`](../CODEMAP.md) · [`architecture-tour.md`](architecture-tour.md) ·
[`engineering/engineering-quality-scorecard.md`](engineering/engineering-quality-scorecard.md) ·
[`engineering/senior-coding-patterns-map.md`](engineering/senior-coding-patterns-map.md).

## How to read this repo (cold reviewer)

1. [`../README.md`](../README.md) — what it proves + 3-minute path.
2. [`../CODEMAP.md`](../CODEMAP.md) — task → path; timed walk
   [`architecture-tour.md`](architecture-tour.md).
3. [`architecture.md`](architecture.md) + [`feature-template.md`](feature-template.md).
4. **`superDemoApp/Features/Items/`** — Reference (SwiftData, sync repository API).
5. **`superDemoApp/Features/Feed/`** — JSONPlaceholder client + SwiftData read-through cache;
   see [`changes/2026-05-16_feed-feature-shipped.md`](changes/2026-05-16_feed-feature-shipped.md)
   and [`changes/2026-09-15_feed-items-diagnostics-hardening.md`](changes/2026-09-15_feed-items-diagnostics-hardening.md).
6. **`superDemoApp/Features/ProductionReadiness/`** — dashboard, networking demos, UIKit showcase;
   see [`changes/2026-05-18_production_readiness_dashboard.md`](changes/2026-05-18_production_readiness_dashboard.md).
7. **`superDemoApp/App/`** — `AppRootView` tabs; composition roots wire DI and feature models.
8. **`superDemoApp/Shared/Presentation/AdaptiveNavigationShell.swift`** — shared chrome.
9. Deep links: open `superdemo://dashboard/risks`, `superdemo://feed`,
   `superdemo://feed/1`, or `superdemo://items` to review typed routing in
   `superDemoApp/App/AppNavigation.swift`. Matching `https://superdemo.app/…`
   paths (including `/feed/<id>` via sample AASA `/feed/*`) **parse** the same
   routes in-app, but public DNS for `superdemo.app`
   **does not currently resolve** — Safari → app handoff is **not** claimed;
   prefer the custom scheme for cold-path demos.

## Launch and build flags

Source: `superDemoApp/Shared/AppLaunchConfiguration.swift`.

| Flag | Kind | Effect |
| --- | --- | --- |
| `-ReviewerDemoMode` or `SUPERDEMO_REVIEWER_DEMO_MODE=1` | **Launch / env** | Seeded sample Dashboard + Feed + Items |
| `REVIEWER_DEMO` | **Compile-time** (TestFlight beta via Fastlane) | Same seeded path when built into the binary — not a launch argument |
| `-StaleFeedDemo` or `SUPERDEMO_STALE_FEED_DEMO=1` | **Launch / env** | Seed Feed SwiftData cache + failing remote → real stale banner via `CachingFeedRepository` |
| `-UITesting` | Launch | UI-test fixtures / in-memory store |
| `-UITestingFeedFailure` | Launch | Failing remote without cache seed (error + Retry UI) |
| `-KeychainTokenDemo` or `SUPERDEMO_KEYCHAIN_TOKEN_DEMO=1` | Launch / env | Opt-in Keychain-backed token refresher demo |

## Items walkthrough (`superDemoApp/Features/Items/`)

- **Domain** — Entities; repository protocol; use cases (`LoadItemsUseCase`, …);
  `DisplayError`. Pure Swift.
- **Data** — `SwiftDataItemRepository`, `@Model Item`. Imports SwiftData.
- **Presentation** — `@Observable ItemsFeatureModel`, `ItemsView`,
  `ItemsNavigationShell`. No persistence imports. Refresh cancel restores prior
  state; `.task` / `.onDisappear` own lifecycle.

Observation + thin use cases on a repository protocol.

## Feed walkthrough (`superDemoApp/Features/Feed/`)

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
  Refresh Feed / Open Feed Post) without raw string navigation in views.

## Reviewer checklist

- [x] Layer imports pass `./bin/lint.sh` (also in `./bin/ci.sh`)
- [x] Feed tab reachable; list, Retry, toolbar refresh (`testFeedTabIsReachable` / `FeedView`)
- [x] `./bin/ci.sh` passes on merge (lint + iPhone tests + iPad/Mac/watchOS builds)
- [x] Previews cover light/dark for `FeedView` (`#Preview` + `UniversalPreviewLayouts`)
- [x] VoiceOver-relevant Feed chrome / rows / Retry proof (`testFeedAccessibilityChromeRowsAndRetry`)
- [x] Deep links for Feed / Items / Feed post (`testDeepLinkOpensFeedTab` /
  `testDeepLinkOpensItemsTab` / `testDeepLinkOpensFeedPostDetail`)

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
