# Release Checklist

Use before TestFlight or App Store submission.

## Build And Tests

- `./bin/lint.sh` passes.
- `./bin/ci.sh` passes or any skipped lane has a documented reason.
- Dashboard, Production Risks, Feed, and Items launch in simulator.
- iPad and macOS builds pass for universal UI changes.

## Device Proof

- Push notifications: APNs token, permission prompt, foreground/background receipt.
- Deep links: associated domains, cold start, warm start, missing route fallback.
- Keychain: first install, reinstall, locked device, biometric changes.
- Permissions: denied, limited, revoked, and Settings return paths.
- Slow networks: timeout, retry, cancellation, 429, and offline messaging.
- Memory pressure: image-heavy collection views and large lists.
- iOS versions: oldest supported OS and current release candidate when available.

## TestFlight

- Release notes explain what testers should validate.
- Demo account or seeded state exists when review/testers need it.
- Crash reporting and OSLog categories are enabled.
- Feature flags or remote config default to safe states.
- Feedback path is monitored after upload.

## App Store

- Entitlements and signing match production bundle ID.
- Privacy labels reflect diagnostics, identifiers, and network services.
- Review notes explain permissions, background modes, deep links, or demo credentials.
- Screenshots show current UI and supported device classes.
