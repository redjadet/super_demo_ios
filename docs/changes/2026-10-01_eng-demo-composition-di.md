# 2026-10-01 — Engineering demo composition DI

## Why

`ProductionReadinessContent` called `ProductionReadinessComposition` /
`FeedComposition` (and Host bridge demo defaulted to `HostBridgeComposition`)
from Presentation — reversing the App composition boundary (Ask #6 / Codex).

## Changes

- `ProductionReadinessEngineeringDemos` injected from `ProductionReadinessRootView`
  for Idempotent POST + Stale Feed destinations.
- `HostBridgePingDemoView` defaults to `NativePlatformFacade()` (same provider as
  composition) — no Presentation → App composition call.
- Previews use `.preview` stub factories.

## Proof

GHA Delivery 4/4 on this PR. Doc / layer gates locally.

## Out of scope

Broader feature extraction · Flutter Shared host defaults · visionOS / StoreKit / APNs.
