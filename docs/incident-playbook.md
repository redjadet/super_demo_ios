# Incident playbook

How to investigate failures using symbols that already exist in this repo.

## Reproduce

1. Note launch flags (`-UITesting`, `-ReviewerDemoMode`, `-KeychainTokenDemo`).
2. Reproduce on Simulator or device; capture exact tab/route.
3. Prefer seeded sample state for deterministic Dashboard/Feed when reviewing.

## Console / OSLog

Subsystem: `com.ilkersevim.superDemoApp`

| Category | Type | Source |
| --- | --- | --- |
| `release-checks` | OSLog info/error | `ReleaseDiagnostics` |
| `device-only-failures` | OSLog error | `ReleaseDiagnostics.deviceOnlyFailure` |
| `crash-monitor` | OSLog error (non-fatal) | `OSLogCrashMonitor` |
| `networking` | OSLog | `RedactedAPILogger` (host/status/attempt only) |

Filter in Console.app by subsystem. **OSLog non-fatal events are not the same as
collected production crash reports** from a vendor SDK (Crashlytics/Sentry). Today
`OSLogCrashMonitor` only mirrors non-fatals into OSLog — swap the `CrashMonitoring`
adapter for a vendor before expecting Organizer/crash dashboards.

## Organizer / device logs

Use Xcode Organizer for device crashes when a real crash pipeline exists. Until a
vendor adapter is wired and TestFlight delivery is proven, treat Organizer as
optional and prefer Console + local reproduction.

## Signposts

`AppPerformanceSignposts` — Instruments `os_signpost` categories `Feed` and
`UIKitShowcase`. Widget App Group path + concurrency talk track (no Live
Activity recipe until JP-P1-A): [`performance-lab.md`](performance-lab.md).

## Approved diagnostic fields

Only pass these into `ReleaseDiagnosticCheck` / `DeviceOnlyFailure` /
`CrashMonitorFailure` metadata (and keep `reason` free of secrets):

| Field | Allowed |
| --- | --- |
| `name` / check name | Stable feature or check id (e.g. `feed-cache-fallback`, `signing`) |
| `area` | Coarse area (`push`, `store`, `networking`) |
| `lane`, `endpointHost` | Non-secret ops labels |
| `attempt`, `statusCode` | Counts / HTTP codes |
| `reason` | Short, redacted summary — **no** tokens, passwords, PII, Authorization headers, raw payloads |

`DiagnosticRedaction` strips known sensitive keys and token-like values before
logging. Prefer redacting at the call site; the helper is a backstop.

## Sensitive-sample proof

`ReleaseDiagnosticsTests` / `DiagnosticRedactionTests` feed sample bearer tokens and
password-like metadata and expect redacted output — extend those tests when adding
fields.

## Swap point

`CrashMonitoring` protocol + `OSLogCrashMonitor` in
`Shared/Diagnostics/CrashMonitoring.swift`. Production vendors require consent /
privacy review and a TestFlight event-delivery check (see portfolio plan P2-D) —
do not half-wire an SDK.
