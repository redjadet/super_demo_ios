# Spec — feed-stale-banner-honesty

## Goal

Feed refresh failure with fresh SwiftData cache returns content marked stale;
UI shows an offline/stale banner; expired TTL does not fake success.

## Acceptance criteria

- [x] Successful remote replace persists cache with `isStale: false` (OI-01)
- [x] Remote failure + fresh cache → posts + `isStale: true` (OI-02)
- [x] Expired TTL → error path / no silent forever-stale (OI-03)
- [x] Presentation shows stale affordance + diagnostic (OI-04)
- [x] Cancel-safe refresh restores prior UI (OI-05)
- [x] Unit tests cover repository + feature model paths
- [x] UI tests stay on sample data under `-UITesting`

## Behavior

### Happy path

1. User opens Feed; remote succeeds; list shows posts; no stale banner.

### Failure / offline

1. Remote throws; cache within TTL → list + stale banner; `isStale: true`.
2. Cache expired → error state; widget snapshot cleared per OI-03.

### UI states

Loading, content, content+stale, error. Light + dark previews on Feed.

## Domain / Data / Presentation

| Layer | Owns |
| --- | --- |
| Domain | `FeedLoadResult` / freshness in use case inputs-outputs |
| Data | `CachingFeedRepository`, TTL, SwiftData `CachedFeedPost` |
| Presentation | `FeedFeatureModel` state, stale `Label`, diagnostics |

## Out of scope

- Bookmark mutation outbox (separate feature / PR)
- Flutter module channel changes

## Proof bar

| Lane | Command |
| --- | --- |
| Focused | Filter `CachingFeedRepositoryTests`, `FeedFeatureModelTests` |
| Docs / small | `./bin/checklist-fast` |
| Merge | `./bin/checklist` + GHA `checklist` |

## Risks

| Risk | Mitigation |
| --- | --- |
| Silent stale | Banner + diagnostic required |
| UI test flaky live HTTP | `-UITesting` → sample repository |
