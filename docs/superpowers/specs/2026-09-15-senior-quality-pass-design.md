# Senior Quality Pass — Design Spec

**Date:** 2026-09-15  
**Status:** Approved; implementation plan at `docs/superpowers/plans/2026-09-15-senior-quality-pass.md`  
**Scope:** Hybrid quality bar — product-grade primary surfaces + polished engineering showcase + shared infra cleanup

## Problem

The app already demonstrates strong Clean Architecture, `@Observable` feature models, networking (retry / token refresh), offline feed cache, App Intents, and solid test coverage. Remaining “amateur” signals are:

1. **Meta / resume UI** on the Dashboard (“Senior iOS Demo”, “AI Feedback Loop”, design-token laundry lists) that reads as self-praise rather than ops health.
2. **Triple-copied refresh / cancel / restore** logic across Feed, Items, and Production Readiness feature models.
3. **Combine-style Intent handoff** via `NotificationCenter` + `onReceive` despite project preference for Observation / async.
4. **Thin Items feature** (timestamp-only entities and one-line detail) that undercuts the architecture story.
5. **Feed detail inline in list**, duplicated accessibility labels.
6. **Force-unwrapped deep-link URLs**, `String(describing:)` diagnostics, and inconsistent DI for scoring.
7. **Awkward `@main` type name** `superDemoAppApp`.

## Goals

- Primary tabs (Dashboard, Items, Feed) feel like a **credible product**, not a checklist of buzzwords.
- Engineering demos (UIKit showcase, ObjC legacy bridge, risks) remain reachable but **visually demoted** under an “Engineering demos” / ops framing.
- Shared load lifecycle is **one tested abstraction**, not three near-copies.
- App Intent → UI navigation uses **Observation / MainActor store**, not NotificationCenter + Combine publisher.
- Items become **local notes** (title + optional body) with real list/detail UX and SwiftData migration path.
- Diagnostics and deep links use **stable, non-force-unwrapped** APIs.
- All existing unit / UI test contracts preserved or intentionally updated.

## Non-Goals

- New backend or auth product.
- Vendor crash / analytics SDK (keep OSLog adapter as swap point).
- Full Liquid Glass redesign or new design system tokens beyond copy/layout cleanup.
- Mass folder / target rename of `superDemoApp` Xcode project.
- Mac-only feature expansion beyond existing adaptive shells.

## Architecture Decisions

### A. Shared async load controller

Introduce a small `@MainActor` helper under `Shared/Presentation/` (name: `AsyncLoadController` or `CancellableLoadSession`) that owns:

- active `Task`
- optional prior state for cancel restore
- `start(showLoadingIfNeeded:operation:)`
- `startAndWait(...)`
- `cancel()`

Each feature model keeps its own **state enum** and maps operation results into that enum. The controller does **not** become a generic state machine for all features — only the cancel / loading / restore choreography.

**Consumers:** `FeedFeatureModel`, `ItemsFeatureModel`, `ProductionReadinessFeatureModel`.

### B. Navigation store for Intents

Replace:

```text
AppIntent → NotificationCenter → onReceive → AppNavigationState.handle(url:)
```

With:

```text
@Observable @MainActor AppNavigationStore (owns AppNavigationState)
AppIntent → AppNavigationStore.shared.apply(deepLink)  // or environment-injected singleton registered at launch
AppRootView binds TabView / path to the store
```

Deep links from `onOpenURL` / universal links continue to call the same `apply` / `handle(url:)` API. Remove `Notification.Name.appIntentNavigation` and Combine `onReceive`.

URL construction for known deep links must be **non-failing** (e.g. static `URL` constants built once, or `URL(string:)` with `precondition` only in DEBUG helpers that tests assert — prefer compile-time-safe constants).

### C. Dashboard content reframing

Keep domain models for modules, API health, checklist, risks. Changes:

| Current | Target |
| --- | --- |
| Hero “Senior iOS Demo” | “Release health” (or equivalent product copy) |
| “AI Feedback Loop” section | Remove from primary dashboard |
| Design tokens section as primary scroll content | Remove from primary dashboard (optional footnote in Engineering demos only if needed for docs) |
| UIKit Showcase at bottom of main list | Move under **Engineering demos** section |
| Module / checklist copy that brags about architecture | Rewrite as ops status language |

`ProductionReadinessSnapshot` may drop `aiFeedbackNotes` and `designTokens` if unused after UI change; update sample repository + score use case + tests accordingly. Prefer **delete unused fields** over leaving dead data.

Accessibility IDs used by UI tests (`productionReadinessDashboard`, `productionRisksLink`, `uikitShowcaseLink`) **must remain** unless UI tests are updated in the same change.

### D. Items → local notes

Domain:

```swift
struct ItemEntity: Equatable, Identifiable {
    let id: UUID
    var title: String
    var note: String
    let timestamp: Date
}
```

SwiftData `@Model Item`: add `title`, `note` with defaults (`""` / `"Untitled"`) so existing stores migrate; rely on existing `AppModelContainer` recovery patterns if schema drift is already handled for feed.

Repository / use cases:

- `addItem(title:note:timestamp:)` or keep `addItem()` creating a default titled note (“New note”, empty body, `Date()`).
- Add `UpdateItemUseCase` for detail edits (title/note).

UI:

- List row: title + relative/secondary timestamp.
- Detail: editable title + note (`TextField` / `TextEditor`), autosave or explicit Save via model method.
- Empty / add affordances keep current accessibility IDs where possible (`addItem`, `addItemEmpty`).

### E. Feed polish

- Extract `FeedPostDetailView` (title, body, navigation title).
- Single combined accessibility element on rows (remove duplicate label on link + label).
- Keep stale cache banner and refresh semantics.

### F. App entry naming

Rename `@main struct superDemoAppApp` → `@main struct SuperDemoApp`. Update only references that break; do not rename the Xcode target in this pass.

### G. Diagnostics

Feature models report failures with:

- prefer `error.localizedDescription` when `LocalizedError`
- else a stable `String(describing: type(of: error))` + known domain code if available

Avoid dumping full `String(describing: error)` as the only signal when a typed display/domain error exists.

Inject `ScoreProductionReadinessUseCase` into `ProductionReadinessFeatureModel` init (default arg OK for production composition).

## File Impact Map

| Area | Create | Modify |
| --- | --- | --- |
| Shared load | `Shared/Presentation/AsyncLoadController.swift` (+ tests) | Three feature models |
| Navigation | optional thin store file or extend `AppNavigation.swift` | `AppRootView`, App Intents router, intent navigation tests |
| Dashboard | — | `ProductionReadinessView`, sample repo, models, score use case, PR tests |
| Items | `UpdateItemUseCase`, `ItemDetailView` | Entity, Item model, repository, use cases, feature model, view, all Items tests, UI if needed |
| Feed | `FeedPostDetailView` | `FeedView` |
| App entry | — | `superDemoAppApp.swift` (type rename) |
| Docs | this spec + later plan | Touch `docs/architecture.md` / portfolio only if copy claims become false |

## Testing Strategy

1. **Unit:** AsyncLoadController cancel/restore; navigation store apply without NotificationCenter; Items CRUD + update; score / snapshot after model field removal; existing Feed / networking suites remain green.
2. **UI:** Keep launch, tabs, deep links, production risks, UIKit showcase paths. Adjust assertions only when labels/copy change by design.
3. **Migration:** Unit test that SwiftData Item with new attributes reads defaults for legacy rows (or document wipe via existing recovery and assert composition still boots — match current feed schema-drift strategy).
4. **Gates:** `./bin/lint.sh` / layer boundary script; Xcode unit tests for app test target.

## Rollout Order

1. AsyncLoadController + refactor three models (behavior-preserving).
2. Navigation store + remove NotificationCenter Intent path.
3. Deep-link URL safety + app entry rename.
4. Dashboard reframing + snapshot model trim.
5. Items notes domain → data → presentation → tests.
6. Feed detail + a11y cleanup.
7. Diagnostics / DI scoring injection polish.
8. Doc touch-ups if architecture/portfolio claims diverge.

## Success Criteria

- No NotificationCenter / Combine `onReceive` for App Intent navigation.
- No duplicated refresh-task choreography across feature models.
- Dashboard primary scroll has no “Senior iOS Demo” / “AI Feedback Loop” / primary design-token section.
- Items support title + note with editable detail.
- Feed detail is a dedicated view; row a11y not duplicated.
- `SuperDemoApp` is `@main`; deep-link URL helpers do not force-unwrap in production paths.
- Unit + UI test suites pass for changed contracts.

## Risks

| Risk | Mitigation |
| --- | --- |
| SwiftData schema change wipes local Items | Defaults + existing container recovery; document in PR |
| UIKit showcase buried → UI test scroll fails | Keep `uikitShowcaseLink` id; update scroll target section if needed |
| Shared load controller over-abstracts | Keep thin; feature-specific state stays in models |
| Intent store singleton vs tests | Inject / reset hook for tests (same pattern as `ReleaseDiagnostics`) |
