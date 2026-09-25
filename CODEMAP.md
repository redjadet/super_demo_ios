# CODEMAP — task → paths

Short router for agents and cold reviewers. Canon stays in [`docs/`](docs/README.md).
Timed walk: [`docs/architecture-tour.md`](docs/architecture-tour.md).

| Task | Start here |
| --- | --- |
| Compact AI context | [`llms.txt`](llms.txt), this file, [`AGENTS.md`](AGENTS.md) |
| ≤15 min architecture tour | [`docs/architecture-tour.md`](docs/architecture-tour.md) |
| Portfolio / reviewer map | [`docs/portfolio.md`](docs/portfolio.md), [`README.md`](README.md) |
| Platform surfaces (WidgetKit, bridge, …) | [`docs/portfolio.md`](docs/portfolio.md) → **Platform surfaces** (honest inventory; missing rows marked) |
| Agent onboard / loop | [`AGENTS.md`](AGENTS.md), [`docs/agent_knowledge_base.md`](docs/agent_knowledge_base.md) |
| Feature shape / layers | [`docs/feature-template.md`](docs/feature-template.md), [`docs/layers.md`](docs/layers.md), [`docs/modularity.md`](docs/modularity.md), `superDemoApp/Features/<Name>/{Presentation,Domain,Data}/` |
| Modularity / import leaks | [`docs/modularity.md`](docs/modularity.md); `./tool/check_feature_folder_contract.sh`, `./tool/check_feature_import_leaks.sh` |
| Feed (offline JSON + cache) | `superDemoApp/Features/Feed/`, [`docs/offline-first.md`](docs/offline-first.md), [`docs/offline-invariants.md`](docs/offline-invariants.md), [`docs/sync-and-networking.md`](docs/sync-and-networking.md) |
| Items (SwiftData reference) | `superDemoApp/Features/Items/` |
| Production readiness / UIKit | `superDemoApp/Features/ProductionReadiness/`, `…/UIKitShowcase/` |
| DI composition roots | `superDemoApp/App/*Composition.swift`, [`docs/dependency-injection.md`](docs/dependency-injection.md) |
| Tabs / deep links / App Intents | `superDemoApp/App/AppRootView.swift`, `AppNavigation.swift`, `App/AppIntents/` |
| Feed Home Screen widget | `FeedWidgetShared/`, `superDemoAppWidget/`, App Group snapshot; demo in ProductionReadiness |
| Native host bridge (no Flutter SDK) | `superDemoApp/Shared/HostBridge/`, [`docs/native-host-boundary.md`](docs/native-host-boundary.md); Engineering demos → Host bridge ping |
| Networking (retry / 401 / 429 / idempotency) | `superDemoApp/Shared/Networking/`, [`docs/sync-and-networking.md`](docs/sync-and-networking.md) |
| Diagnostics / crash swap point | `superDemoApp/Shared/Diagnostics/`, [`docs/incident-playbook.md`](docs/incident-playbook.md) |
| Launch / demo flags | `superDemoApp/Shared/AppLaunchConfiguration.swift` |
| Design / tokens | [`DESIGN.md`](DESIGN.md), [`docs/design_system.md`](docs/design_system.md) |
| Tests | [`docs/testing.md`](docs/testing.md), `superDemoAppTests/` |
| Validation / proof commands | [`docs/agents_quick_reference.md`](docs/agents_quick_reference.md); `./bin/checklist-fast`, `./bin/lint.sh`, `./bin/ci.sh` |
| Engineering quality scorecard | [`docs/engineering/engineering-quality-scorecard.md`](docs/engineering/engineering-quality-scorecard.md); `./tool/check_engineering_quality_scorecard.sh` |
| Agent worktree / maintain | `./bin/agent-worktree`, `./bin/agent-maintain`; [`docs/agent_kb/host-maintenance.md`](docs/agent_kb/host-maintenance.md) |
| Harness scorecard (agent) | [`docs/ai/harness-scorecard.md`](docs/ai/harness-scorecard.md) — separate from Engineering |
| SAFETY-REPORT closeout | [`docs/agent_kb/safety-report-template.md`](docs/agent_kb/safety-report-template.md); `./bin/agent-maintain closeout` |
| Code quality / coverage honesty | [`docs/code-quality.md`](docs/code-quality.md) — no fake `%` badges |
| CI / CD map | [`docs/ci-cd-map.md`](docs/ci-cd-map.md), `.github/workflows/` |
| Architecture decisions (ADR) | [`docs/adr/README.md`](docs/adr/README.md) |
| Sonar deferral | [`docs/sonar-decision.md`](docs/sonar-decision.md), [`docs/adr/0004-sonarcloud-skip.md`](docs/adr/0004-sonarcloud-skip.md) |
| Change evidence | [`docs/changes/`](docs/changes/README.md) |

## Top-level layout

| Path | Role |
| --- | --- |
| `superDemoApp/Features/` | Layered product features (Feed, Items, ProductionReadiness) |
| `superDemoApp/Shared/` | Networking, Diagnostics, Presentation chrome, launch config |
| `superDemoApp/App/` | Composition roots, tabs, navigation, App Intents |
| `docs/` | Behavior canon and agent routing |
| `bin/`, `tool/` | Proof / lint / CI wrappers |

## Do not

- Expand [`AGENTS.md`](AGENTS.md) with long prose — keep it a map; detail lives in `docs/`.
- Treat dated change notes as live API contracts — prefer `docs/` + source.
- Invent quality badges without a passing gate (see Flutter-parity plan P0-B).
