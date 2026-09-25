# Modularity

Single-app-target modularity for `superDemoApp`: feature folders stay
independent; composition lives in `App/` and reusable contracts in `Shared/`.

## Rules

| Rule | Detail |
| --- | --- |
| Layered skeleton | Marked features under `Features/<Name>/` must have `Presentation/`, `Domain/`, and `Data/` (each with Swift). |
| No feature↔feature | Feature A must not reference types owned by Feature B. |
| Composition | `App/*Composition.swift` and `Shared/` may use feature types. |
| Shared extraction | Move cross-feature contracts to `Shared/` only after a real second call site. |

Mark layered features in [`../tool/config/layered_features.txt`](../tool/config/layered_features.txt).
Non-layered opt-outs: [`../tool/config/feature_folder_non_layered_allowlist.txt`](../tool/config/feature_folder_non_layered_allowlist.txt).
Leak exceptions (prefer none): [`../tool/config/feature_import_leak_allowlist.txt`](../tool/config/feature_import_leak_allowlist.txt).

## Validation

```bash
./tool/check_feature_folder_contract.sh
./tool/check_feature_import_leaks.sh
./bin/lint.sh   # runs both after layer boundaries
```

Self-tests (fixtures under `tool/fixtures/`):

```bash
./tool/check_feature_folder_contract.sh --self-test
./tool/check_feature_import_leaks.sh --self-test
```

Layer import direction (Presentation / Domain / Data frameworks) remains
[`../tool/check_layer_boundaries.sh`](../tool/check_layer_boundaries.sh).

## Related

- [`feature-template.md`](feature-template.md) — scaffold
- [`layers.md`](layers.md) — layer responsibilities
- [`module-structure.md`](module-structure.md) — extraction rule
- [`adr/0001-feature-layering.md`](adr/0001-feature-layering.md) — ADR
