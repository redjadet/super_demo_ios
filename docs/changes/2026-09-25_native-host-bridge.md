# 2026-09-25 — Native host-bridge contract (JP-P0-C)

## Summary

Adds a Flutter-shaped **native host bridge** without vendoring Flutter:
`HostBridgeCodec` + `NativePlatformFacade` with day-1 method `feed.cacheStatus`
backed by the JP-P0-B App Group Feed snapshot reader.

## Paths

- `superDemoApp/Shared/HostBridge/`
- `superDemoApp/App/HostBridgeComposition.swift`
- Engineering demo: `HostBridgePingDemoView`
- Docs: [`native-host-boundary.md`](../native-host-boundary.md)

## Proof

- `HostBridgeCodecTests` (decode/encode, unsupported method, malformed,
  cancellation, golden JSON shape)
- `swiftlint --strict` + SwiftFormat via `./bin/verify-swift.sh`
- Honesty: no Flutter SDK embed claim
