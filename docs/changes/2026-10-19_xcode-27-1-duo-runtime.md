# 2026-10-19 — Xcode 27.1 iOS runtime: iPhone Duo last resort

## Problem

Xcode 27.1’s newest iOS Simulator runtime (`iOS 27.1`) lists only
**iPhone Duo** under `supportedDeviceTypes`. Preferred selection skipped
Duo/Fold/Air as exotic, so provisioning fell back to **iOS 27.0** while
building against the **27.1** SDK (SDK mismatch risk).

## Fix

- Prefer standard iPhones when the runtime supports them.
- When a runtime is exotic-only, use Duo (then Air/Fold) as last resort for
  UDID pick, device-type create lists, and xcodebuild destination parsing.
- Fixture + script guards cover Duo-only selection; `docs/testing.md` documents
  the policy.

## Proof

- `./tool/check_simulator_runtime_compat.sh`
- `CI_IPHONE_TEST_SHARD=unit ./bin/ci-iphone-test.sh` on Mac mini with Xcode 27.1
