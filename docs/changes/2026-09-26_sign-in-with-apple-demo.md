# 2026-09-26 — Sign in with Apple demo (JP-P2-B)

## Summary

Adds a labeled **Sign in with Apple** Engineering demo via
`AuthenticationServices`. Separate from the Keychain token refresher. Never
claims production auth.

## Honesty

- Simulator without Apple ID / capability → honest **unavailable** (not fake success)
- User cancel → cancelled state
- Credential email/name often nil on subsequent sign-ins (Apple behavior)

## Paths

- `superDemoApp/Shared/Auth/SignInWithAppleDemo.swift`
- `Features/ProductionReadiness/Presentation/SignInWithAppleDemoView.swift`
- Entitlement `com.apple.developer.applesignin` = Default
- Tests: `SignInWithAppleDemoTests` (spy)

## Proof

- Unit: spy-driven signed-in / unavailable / cancelled
- Hosted GHA: compile (capability may need team provisioning on device)
- Manual: device or Simulator with Apple ID
