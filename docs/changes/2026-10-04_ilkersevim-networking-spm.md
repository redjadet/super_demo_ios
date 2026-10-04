# 2026-10-04 — Adopt IlkerSevimNetworking SPM

## Summary

Replace in-tree `Shared/Networking` implementation with published SPM package
[`redjadet/ilkersevim_networking`](https://github.com/redjadet/ilkersevim_networking)
tag `1.0.0`. Keep app-only `TokenRefreshingFactory` and `AppURLSession`
typealias (`DefaultURLSession`).

## Evidence

- Package pin: `Package.resolved` → revision `c9e1fc5` / version `1.0.0`
- App wrappers: `IlkerSevimNetworkingExport.swift`, `TokenRefreshingFactory.swift`
- CI: project-level `SWIFT_TREAT_WARNINGS_AS_ERRORS` (not xcodebuild CLI) so SPM
  packages keep Xcode’s `-suppress-warnings` without conflicting `-warnings-as-errors`
