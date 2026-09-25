# Architecture tour (≤15 minutes)

**Audience:** Cold reviewer or agent who needs the iOS portfolio spine without a
full demo script. Companion to [`portfolio.md`](portfolio.md) (theme table) and
[`../CODEMAP.md`](../CODEMAP.md) (task → path).

**Date:** 2026-09-25  
**Scope:** Read paths + open one real folder per stop. No product API changes.

| Min | Stop | Do | Open |
| --- | --- | --- | --- |
| 0–2 | Orient | Name what the repo proves; land badges + 3-minute path | [`../README.md`](../README.md), [`../CODEMAP.md`](../CODEMAP.md) |
| 2–5 | Layers | Presentation → Domain ← Data; enforcement command | [`architecture.md`](architecture.md), [`layers.md`](layers.md), `superDemoApp/Features/Feed/` |
| 5–9 | Offline Feed | Network → repository → use case → `@Observable` model; stale path | `Features/Feed/Data/CachingFeedRepository.swift`, `Features/Feed/Presentation/FeedFeatureModel.swift`, [`offline-first.md`](offline-first.md) |
| 9–12 | Networking | Retry / 401 / 429 / Idempotency-Key + redaction | `superDemoApp/Shared/Networking/`, [`sync-and-networking.md`](sync-and-networking.md) |
| 12–15 | Composition + proof | DI roots wire features; run a fast proof lane | `superDemoApp/App/FeedComposition.swift`, `./bin/checklist-fast` or `./bin/ci.sh` |

## Optional one-liners (if asked)

| Follow-up | Point here |
| --- | --- |
| “Where do agents start?” | [`../AGENTS.md`](../AGENTS.md), [`../CODEMAP.md`](../CODEMAP.md) |
| “Full reviewer talk tracks?” | [`portfolio.md`](portfolio.md) |
| “Items as SwiftData reference?” | `superDemoApp/Features/Items/` |
| “UIKit interop?” | `superDemoApp/Features/ProductionReadiness/UIKitShowcase/` |
| “Diagnostics / crash later?” | `superDemoApp/Shared/Diagnostics/`, [`incident-playbook.md`](incident-playbook.md), [`adr/0003-crash-vendor-deferred.md`](adr/0003-crash-vendor-deferred.md) |
| “Validation chooser?” | [`agents_quick_reference.md`](agents_quick_reference.md), [`engineering/validation_routing_fast_vs_full.md`](engineering/validation_routing_fast_vs_full.md) |
| “Engineering X/10?” | [`engineering/engineering-quality-scorecard.md`](engineering/engineering-quality-scorecard.md) |
| “Why layering / offline / Sonar / CI honesty?” | [`adr/README.md`](adr/README.md) |

## Honesty

- Portfolio demo — not a shipped App Store product claim ([`../README.md`](../README.md) scope).
- SonarCloud skipped for this demo ([`sonar-decision.md`](sonar-decision.md),
  [`adr/0004-sonarcloud-skip.md`](adr/0004-sonarcloud-skip.md)).
- Stale Feed is deterministic under `-StaleFeedDemo` / Engineering demos — see portfolio map.
- PR-lane vs local-test honesty: [`ci-cd-map.md`](ci-cd-map.md),
  [`adr/0005-ci-pr-vs-local-honesty.md`](adr/0005-ci-pr-vs-local-honesty.md).
