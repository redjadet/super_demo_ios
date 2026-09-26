# CI: create iPhone only if runtime supports the device type

Date: 2026-09-26

## Why

GHA `xcode-27` may install iOS **27.1** with no standard iPhone devices yet.
`ensure_ci_simulator` tried global preferred `iPhone 18 Pro` and hit simctl
**403 Incompatible device**, then fell back to **27.0** (works, but SDK/runtime
mismatch risks widget appex install).

## Fix

- `list_preferred_iphone_device_type_ids_for_runtime` / `_for_runtime` helpers use
  each runtime’s `supportedDeviceTypes`.
- Create walks that list on the newest runtime before trying an older one.

## Proof

- Local: helpers return preferred type for installed runtime.
- Hosted: Checklist · iPhone test provisions without 403 on 27.1 (or creates a
  supported type on 27.1 instead of skipping to 27.0 solely for device mismatch).
