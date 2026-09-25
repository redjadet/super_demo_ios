# 2026-09-25 — Feature folder contract + import leak guards (FP-P1-A)

## Summary

Enforce layered `Features/<Name>/{Presentation,Domain,Data}` skeleton and
fail Feature A → Feature B type references. Wired into `./bin/lint.sh`.
Composition stays in `App/` / `Shared/`.

## Paths

- [`../../tool/check_feature_folder_contract.sh`](../../tool/check_feature_folder_contract.sh)
- [`../../tool/check_feature_import_leaks.sh`](../../tool/check_feature_import_leaks.sh)
- [`../../tool/config/layered_features.txt`](../../tool/config/layered_features.txt)
- [`../../tool/config/feature_import_leak_allowlist.txt`](../../tool/config/feature_import_leak_allowlist.txt)
- [`../modularity.md`](../modularity.md)
- Fixtures: `tool/fixtures/feature_folder_contract/`, `tool/fixtures/feature_import_leaks/`

## Proof

```bash
./tool/check_feature_folder_contract.sh --self-test
./tool/check_feature_import_leaks.sh --self-test
./tool/check_feature_folder_contract.sh
./tool/check_feature_import_leaks.sh
./bin/lint.sh
./bin/checklist-fast
```
