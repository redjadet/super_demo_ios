# Release Checklist

Use before TestFlight or App Store submission.

## Build And Tests

- `./bin/lint.sh` passes.
- `./bin/ci.sh` passes or any skipped lane has a documented reason.
- Dashboard, Production Risks, Feed, and Items launch in simulator.
- iPad and macOS builds pass for universal UI changes.

## Device Proof

- Push notifications: APNs token, permission prompt, foreground/background receipt.
- Deep links: custom scheme fixtures cover `superdemo://dashboard`,
  `superdemo://dashboard/risks`, `superdemo://feed`, and `superdemo://items`
  (typed in `App/AppNavigation.swift`). Verify cold start, warm start, and
  missing-route alert on device. Universal links: entitlement
  `applinks:superdemo.app` + sample AASA in `Config/associated-domains/`;
  host AASA on the live domain before relying on Safari → app handoff.
- Keychain: first install, reinstall, locked device, biometric changes.
- Permissions: denied, limited, revoked, and Settings return paths.
- Slow networks: timeout, retry, cancellation, 429, and offline messaging.
- Memory pressure: image-heavy collection views and large lists.
- iOS versions: oldest supported OS and current release candidate when available.

## Portfolio demo / mock proofs (JP-P2-E)

**Audience:** portfolio reviewers — not production release. Prefer real local /
Simulator proofs when the host can show them. When ASC credentials, push
certificates, or a physical device are unavailable, **labeled mock** proofs are
acceptable under the 2026-09-26 portfolio waiver.

### Honesty labels (required)

| Claim | Allowed for portfolio? | Label |
| --- | --- | --- |
| Real TestFlight build uploaded via `fastlane ios beta` | Yes when credentials exist | Use real build number + ASC link |
| Mock TestFlight build id / “would upload” archive-only | Yes | Prefix notes with `DEMO/MOCK TestFlight` |
| Real device APNs receipt | Yes when device + sandbox cert | Record token prefix + environment |
| Mock APNs token + permission/UI path | Yes | Prefix with `DEMO/MOCK APNs`; point at JP-P1-C local notification for runnable UI |
| Production App Store / live users | **No** | Never |

### Mock TestFlight checklist

- [ ] Ran `TESTFLIGHT_SKIP_UPLOAD=1 TESTFLIGHT_BUILD_NUMBER=<n> ./bin/fastlane-run ios beta` **or** documented blocker (no signing on agent host)
- [ ] Recorded mock build id, e.g. `DEMO/MOCK TestFlight build 9001` (not an ASC URL unless real)
- [ ] Release notes still sourced from [`docs/release-notes/testflight.md`](release-notes/testflight.md)
- [ ] Stated clearly: archive/upload not claimed as production beta unless credentials were used

### Mock APNs checklist

- [ ] Permission prompt path: Engineering demos → **Local stale-Feed reminder** (JP-P1-C) — runnable without APNs
- [ ] Document mock device token: `DEMO/MOCK APNs token deadbeef…` (never a real secret)
- [ ] Document expected environments: `sandbox` vs `production` — portfolio uses **sandbox/mock only**
- [ ] NSE / production push entitlement: still **not** claimed unless a separate slice ships them
- [ ] Foreground/background receipt: real device note **or** `DEMO/MOCK` receipt log line in change note

### What this does *not* prove

- App Store Connect live TestFlight groups
- Production APNs certificate / key rotation
- Notification Service Extension content mutation at scale

## TestFlight

- Release notes source: [`docs/release-notes/testflight.md`](release-notes/testflight.md).
  Keep this file as the exact tester-facing text uploaded by `fastlane ios beta`.
- Reviewer demo mode seeds deterministic Dashboard, Production Risks, Feed, and
  Items walkthrough state for TestFlight. Local proof can pass
  `-ReviewerDemoMode` or `SUPERDEMO_REVIEWER_DEMO_MODE=1`; the
  `fastlane ios beta` lane compiles the TestFlight archive with `REVIEWER_DEMO`.
- Release diagnostics are OSLog-backed today: categories `release-checks` and
  `device-only-failures`, with `OSLogCrashMonitor` for non-fatals. Replace the
  monitor with Firebase Crashlytics, Sentry, or an equivalent provider before
  shipping production crash analytics.
- Feature flags or remote config default to safe states.
- Feedback path is monitored after upload.

## Fastlane Beta

Run from repo root:

```bash
TESTFLIGHT_BUILD_NUMBER=<unique-build-number> ./bin/fastlane-run ios beta
```

Prerequisites:

- `./tool/bootstrap_fastlane.sh` has installed the bundled Fastlane gems.
- Local toolchain matches README (**Xcode 27** / **Swift 6.4**). Release/CI lanes call
  `tool/select_xcode.sh`, which prefers the newest **released** Xcode ≥ 27 on the
  hosted `xcode-27` image (floor override: `SUPER_DEMO_XCODE_MIN_VERSION`).
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
- Archive only (no upload): `TESTFLIGHT_BUILD_NUMBER=<n> ./bin/fastlane-run ios build_ipa`.
- Manual GitHub Actions archive smoke: run **Release Smoke**. It calls
  `./bin/fastlane-run ios build_ipa`, syncs App Store signing through match,
  uploads only the generated IPA artifact, and never uploads to TestFlight.
  Use it after CI proof.

Optional signing via [match](https://docs.fastlane.tools/actions/match/): copy
`fastlane/Matchfile.example` to `fastlane/Matchfile`, run `fastlane match appstore`
once, then set `FASTLANE_USE_MATCH=1` (or keep `Matchfile` in repo). CI should use
`MATCH_READONLY=1` (default when `CI=true`).

GitHub **Release Smoke** secrets:

- `MATCH_GIT_URL`: private signing repo URL.
- `MATCH_PASSWORD`: match encryption password.
- `MATCH_GIT_BASIC_AUTHORIZATION`: git auth token/header for the signing repo,
  unless the runner has equivalent SSH access.

## App Store

- Release notes source: [`docs/release-notes/app-store.md`](release-notes/app-store.md).
- Upload lane (does not submit for review unless you opt in):

```bash
TESTFLIGHT_BUILD_NUMBER=<unique-build-number> ./bin/fastlane-run ios release
```

- Set `APP_STORE_SUBMIT_FOR_REVIEW=1` only when metadata and build are ready for review.
- Set `APP_STORE_SKIP_UPLOAD=1` to validate the archive without upload.
- Entitlements and signing match production bundle ID.
- Privacy labels reflect diagnostics, identifiers, and network services.
- Review notes explain permissions, background modes, deep links, or demo credentials.
- Screenshots show current UI and supported device classes.
