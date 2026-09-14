# Production Risks

Simulator success is necessary, not sufficient. These issues often appear only on real
devices, TestFlight, or after App Store release.

## Risk Areas

- Push notifications: APNs environment, token rotation, entitlements, user settings.
- Deep links: custom-scheme fixtures (`superdemo://…`) plus associated domains,
  deferred routing, cold-start restoration.
- Background modes: system scheduling, battery policy, entitlement mismatch.
- Keychain: access groups, protected data, biometric changes, reinstall semantics.
- Permissions: denied states, limited access, Settings changes.
- Memory pressure: older devices, large images, long lists, background return.
- Slow networks: retry storms, duplicate POSTs, cancellation, rate limits.
- Signing: provisioning profiles, capabilities, App Groups, TestFlight build type.
- App Store review: unclear permission copy, missing demo access, policy-sensitive flows.
- Crash gaps: device-only crashes, OS-version differences, release-only optimization.

## How This Project Surfaces Risk Earlier

- Mock states and sample repositories make failure UI launchable without live services.
- `Shared/Networking` encodes retry and idempotency rules with tests.
- UIKit collection view uses reusable cells, prefetching, and cancellation.
- Dashboard checklist + OSLog release diagnostics / `OSLogCrashMonitor` keep
  release risk visible before a vendor crash SDK is wired.
- Docs and UI tests create a short path for humans and AI agents to validate changes.
