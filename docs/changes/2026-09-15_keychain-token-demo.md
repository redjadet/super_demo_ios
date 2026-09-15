# 2026-09-15 — Keychain token demo (P3)

## Why

Prove Keychain-backed access-token persistence on the shared networking auth path
without claiming real OAuth. Keep the production default empty until a session
refresher exists.

## Changes

- `AccessTokenStore` + `KeychainAccessTokenStore` / `InMemoryAccessTokenStore`.
- `KeychainDemoTokenRefresher` persists seed/refresh tokens through the store.
- `AppLaunchConfiguration.usesKeychainTokenDemo` (`-KeychainTokenDemo` or
  `SUPERDEMO_KEYCHAIN_TOKEN_DEMO=1`).
- `TokenRefreshingFactory.makeDefault()`; Production Readiness remote health client
  injects the factory refresher.
- Removed iOS 27-only `toolbarMinimizationBehavior` helper so CI builds on Xcode 26.6.

## Proof

- Unit tests for store round-trip, demo refresher, launch flag, and factory selection.
- Build + targeted networking tests via Xcode.
