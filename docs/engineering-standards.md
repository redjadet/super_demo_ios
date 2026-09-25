# Engineering standards

Human-readable standards for contributors who never open `AGENTS.md`.

## Layers

- Layout: `Features/<Name>/{Presentation,Domain,Data}` when the feature has rules
  or side effects ([`feature-template.md`](feature-template.md)).
- Rules: [`layers.md`](layers.md). Presentation must not import URLSession/SwiftData;
  Domain stays pure Swift.
- Enforcement: `./tool/check_layer_boundaries.sh` via `./bin/lint.sh`.

## State

- Prefer SwiftUI **Observation** (`@Observable`) over new Combine pipelines
  ([`state-management.md`](state-management.md)).
- Cancel-safe loads: `AsyncLoadController` + feature-model cancel on disappear.

## When to add `Features/<Name>/`

Add a module when you introduce domain rules, persistence, or network ownership.
Thin UI-only polish can stay in an existing feature’s Presentation.

## PR proof

| Gate | Threshold | Owner / response |
| --- | --- | --- |
| SwiftLint / format (`./bin/verify-swift.sh`) | Zero new lint errors; warnings triage in PR | Maintainer — fix or justify before merge |
| Layer boundaries (`tool/check_layer_boundaries.sh`) | Must pass | Maintainer — block merge on fail |
| Local `./bin/ci.sh` | Must pass before merge to `main` | Author — re-run after fix |
| Test pyramid ([`testing.md`](testing.md)) | New behavior covered at cheapest honest layer | Author — add/extend tests in same PR |

`./bin/verify-swift.sh` formats and lints — it does **not** build or test. Use
targeted tests + `./bin/ci.sh` for merge.

## SonarCloud

Default: **skip**. Require a named maintainer go decision before any SonarCloud
setup (no secrets in repo). Static analysis today = SwiftLint + layer check.

## Repaid debt example

`AsyncLoadController` centralizes cancel-safe refresh so Feed/Items/Dashboard do
not each reinvent task lifecycle.
