# Development Feedback Loop

Native iOS feedback is slower than Flutter-style hot reload. This repo should
therefore make validation cheap, repeatable, and close to production behavior.

## Goal

Reduce rebuild, relaunch, navigation, and manual state recreation time for both
human and AI-assisted development.

The Production Readiness Dashboard makes this visible in-app: small modules, mock states,
previews, UI shortcuts, and deterministic tests reduce validation time in native iOS,
where there is no Flutter-style hot reload/hot restart loop.

## Agent Defaults

- Prefer small feature slices that compile independently.
- Keep UI state injectable so previews, tests, and UI automation can start from
  meaningful states without manual navigation.
- Add or update SwiftUI previews for loading, empty, error, populated, and dark
  states when touching user-facing screens.
- Reuse mock repositories and in-memory SwiftData stores instead of network or
  disk dependencies in normal validation.
- Define proof before editing: fast lint/tests for logic, checklist/CI for UI
  or platform-sensitive work.
- Treat repeated manual verification as a missing repo capability; add a test,
  preview fixture, script, or doc.

## Faster Local Validation

- Keep features modular under `Features/<Name>/` so agents can test Domain,
  Data, and Presentation behavior separately.
- Use pure Domain entities and use cases for fast unit coverage.
- Keep feature models deterministic and directly testable.
- Prefer composition-root dependency injection over global state.
- Use `./bin/checklist-fast` for docs, tooling, and narrow Swift changes.
- Use targeted tests before full `./bin/checklist` or `./bin/ci.sh`.

## SwiftUI Preview Requirements

Preview fixtures should cover the states a developer would otherwise need to
recreate by launching the app:

- loading
- empty
- populated
- error with retry affordance
- light and dark appearance
- compact iPhone and at least one regular-width layout for meaningful UI work

Do not make previews depend on live network, persistent user data, real
credentials, push notification registration, or production-only entitlements.

## Production-Like Risk Areas

Simulator proof is not enough when a change touches:

- signing, capabilities, entitlements, associated domains, or App Groups
- push notifications, background modes, widgets, App Intents, or deep links
- keychain, biometrics, permissions, files, or protected data
- memory pressure, large data sets, slow networks, retries, or offline behavior
- OS-version-specific APIs or App Store review-sensitive flows

For these, add the narrowest durable proof available: device test notes, a UI
test, a TestFlight checklist, a release note in `docs/changes/`, or monitoring
expectations.

## Cross-Platform Consistency

Because native iOS and Android can drift when implemented separately, every new
user-facing capability should align with the shared design system before code is
considered done:

- use `DESIGN.md` semantic tokens and `docs/design_system.md` component rules
- reuse `Shared/Presentation/` navigation and layout primitives
- avoid one-off spacing, typography, colors, and behavior
- document intentional platform differences
- validate iPhone, iPad, and Mac builds for meaningful SwiftUI changes

## Monitoring And Release Feedback

When work affects production behavior, prefer adding a feedback path instead of
trusting local checks alone:

- Crashlytics or equivalent crash monitoring when configured by the app
- OSLog categories for diagnosable failures
- feature flags for risky rollouts
- TestFlight scenarios for device-only behavior
- App Store review notes when capabilities or permissions need context

See also: [`testing.md`](testing.md) (CI UI smoke, `-UITesting`, terminate between tests),
[`design_system.md`](design_system.md),
[`universal-apple-platforms.md`](universal-apple-platforms.md), and
[`agents_quick_reference.md`](agents_quick_reference.md).
