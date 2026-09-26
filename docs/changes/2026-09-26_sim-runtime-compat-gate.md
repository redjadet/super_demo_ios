# Early gate: simulator runtime ↔ device-type compat

Date: 2026-09-26

## Why

CI can burn ~20 minutes on iPhone UI tests after a silent simctl **403
Incompatible device** (global preferred iPhone 18 Pro vs iOS 27.1
`supportedDeviceTypes`). Agents then fall back to older runtimes or manual
Simulator debugging. Catch the class of failure in **lint / checklist-fast**
before `xcodebuild test` or hand-testing.

## Gate

`tool/check_simulator_runtime_compat.sh`:

- Fixture `--self-test` for selection algorithm (no simctl).
- Static: create path must use `list_preferred_iphone_device_type_ids_for_runtime`.
- Live: fail if global preferred ∉ newest runtime `supportedDeviceTypes`
  (403 class); warn/fail when no runtime can provision.

Wired into:

- `tool/check_common_issues.sh` → Fastlane `ci_lint` / checklist-fast / checklist
- `bin/ci-iphone-test.sh` (again immediately before provision + UI tests)

## Proof

```bash
./tool/check_simulator_runtime_compat.sh --self-test
./tool/check_simulator_runtime_compat.sh
./tool/check_common_issues.sh
```
