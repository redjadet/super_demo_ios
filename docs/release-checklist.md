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

- Release notes source: [`docs/release-notes/testflight.md`](release-notes/testflight.md).
  Keep this file as the exact tester-facing text uploaded by `fastlane ios beta`.
- Demo account or seeded state exists when review/testers need it.
- Crash reporting and OSLog categories are enabled.
- Feature flags or remote config default to safe states.
- Feedback path is monitored after upload.

## Fastlane Beta

Run from repo root:

```bash
TESTFLIGHT_BUILD_NUMBER=<unique-build-number> ./bin/fastlane-run ios beta
```

Prerequisites:

- `./tool/bootstrap_fastlane.sh` has installed the bundled Fastlane gems.
- Xcode 26.5.x is installed; the lane calls `tool/select_xcode_26_5.sh`.
- Apple signing assets can create an App Store archive for
  `com.ilkersevim.superDemoApp` with team `QPG8754DYH`.
- App Store Connect auth is available through Fastlane. Prefer
  `APP_STORE_CONNECT_API_KEY_PATH=<path-to-json>` for CI; local Apple ID/session auth
  may also work.
- `TESTFLIGHT_BUILD_NUMBER` is unique for the app version. The lane passes it as
  `CURRENT_PROJECT_VERSION` for the archive and does not edit the Xcode project.
- [`docs/release-notes/testflight.md`](release-notes/testflight.md) is current,
  non-empty, and has no TODO markers.

Lane behavior:

- Runs the existing repo CI proof (`fastlane ios ci`, backed by `bin/` scripts).
- Builds a clean Release App Store archive into `build/testflight/`.
- Uploads the IPA to TestFlight with release notes from
  [`docs/release-notes/testflight.md`](release-notes/testflight.md).
- Set `TESTFLIGHT_SKIP_UPLOAD=1` only to validate archive shape without upload.
- Set `TESTFLIGHT_SKIP_CI=1` only after a same-commit CI proof already passed.

## App Store

- Entitlements and signing match production bundle ID.
- Privacy labels reflect diagnostics, identifiers, and network services.
- Review notes explain permissions, background modes, deep links, or demo credentials.
- Screenshots show current UI and supported device classes.
