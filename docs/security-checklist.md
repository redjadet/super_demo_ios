# Security checklist

Reviewer-facing list tied to real files and flags. Aligns with
[`incident-playbook.md`](incident-playbook.md) approved fields.

| Item | Where | Notes |
| --- | --- | --- |
| ATS / HTTPS defaults | App Transport Security / Info.plist entitlements | Prefer HTTPS endpoints; document any exception |
| Demo Keychain token | `KeychainAccessTokenStore`, `-KeychainTokenDemo` / `SUPERDEMO_KEYCHAIN_TOKEN_DEMO=1` | **Demo auth** — not production OAuth |
| Token refresh wiring | `TokenRefreshingFactory` | Opt-in Keychain path vs in-memory demo |
| Log redaction (HTTP) | `RedactedAPILogger` in `Shared/Networking/APILogger.swift` | Logs host/status/attempt — not Authorization or bodies |
| Log redaction (diagnostics) | `DiagnosticRedaction` + `ReleaseDiagnostics` / `OSLogCrashMonitor` | Sensitive keys/values stripped; see playbook |
| No secrets in repo | `.gitignore`, release docs | No API keys in source; use env / CI secrets for beta |
| SwiftData recovery | `AppModelContainer` | Delete+recreate corrupt store; else in-memory + diagnostics |
| Production risks | [`production-risks.md`](production-risks.md) | Device-only / App Store surface |

## Demo vs production OAuth

Reviewer demo and UITesting seed sample state (`AppLaunchConfiguration`). Keychain
token demo proves storage/refresh wiring only. A production app would use a real
OAuth/OIDC client, server-issued refresh rotation, and Keychain access groups —
not the sample checklist tokens.
