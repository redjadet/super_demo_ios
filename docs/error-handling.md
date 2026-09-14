# Error Handling And Logging

Errors should be typed, visible at the right layer, and safe to log.

## Rules

- Domain defines user-meaningful failure categories.
- Data maps transport/persistence failures into domain failures.
- Presentation turns domain failures into recovery actions and display text.
- Avoid `try?` except when loss is explicitly harmless.
- Avoid broad `catch` without logging or conversion.
- Use OSLog for permanent diagnostics; avoid `print`.
- Feature models may inject `ReleaseDiagnosticsReporting` so failures and
  stale-cache fallbacks are logged without coupling Presentation to a vendor SDK.

## Display Errors

User-facing errors need:

- short title,
- recovery action when available,
- non-sensitive message,
- stable testable state.

## Logging

Log metadata needed to diagnose failure. Do not log secrets, tokens, raw PII,
or full payloads unless explicitly scrubbed.
