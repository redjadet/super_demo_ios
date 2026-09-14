# Feed / Items / diagnostics hardening

Date: 2026-09-15

## Summary

Post-portfolio hardening across Feed, Items, navigation, and release diagnostics.
Shipped on `main` as `030a24a` (app) and follow-up README toolchain badges.

## Behavior

- Unified Feed refresh on `RefreshFeedUseCase` (removed duplicate load use case).
- Cancel-safe Feed/Items refresh; restore prior UI state on cancel.
- `FeedLoadResult.isStale` + Feed stale banner when cache fallback is used.
- Feature models log failures / stale fallback via `ReleaseDiagnosticsReporting`.
- `AppModelContainer` recovers with in-memory fallback + diagnostics on store failure.
- `OSLogCrashMonitor` default; checklist no longer claims a no-op crash adapter.
- Deep links: `superdemo://dashboard`, `/risks`, `feed`, `items` (+ UITests).
- Demo auth path: documented `EmptyTokenRefresher` + `InMemoryDemoTokenRefresher`.

## Docs touched

README monitoring, portfolio, navigation, sync-and-networking, offline-first,
testing, release-checklist, production-risks, error-handling, architecture,
agent_project_context, agent_environment_setup, agents_quick_reference, code-style.

## Toolchain note

Local / README: **Xcode 27.0**, **Swift 6.4**, SDK **27**, preferred simulator
**iPhone 18 Pro**. CI on `macos-26` selects **Xcode 26.5+** via `tool/select_xcode.sh` (26.6 preferred).
Xcode 27 is local/README until the `xcode-27` runner image is adopted.

## CI follow-up

- Bump `.swiftlint.yml` `swiftlint_version` to **0.65.1** (CI `brew` installs latest;
  pin mismatch failed lint + build-phase lint).
- Replace rigid `select_xcode_26_5.sh` with `tool/select_xcode.sh` (local 27,
  CI 26.6→26.5). Keep `select_xcode_26_5.sh` as a thin wrapper.
- Prefer **iPhone 18 Pro** in simulator selection helpers.

