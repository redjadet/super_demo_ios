# 2026-09-26 — Share extension → App Group inbox (JP-P2-A)

## Summary

Adds a **Share** app extension that receives URL/text and writes a versioned
**App Group inbox**. The extension does **not** open the main SwiftData Items
store. Main app Engineering demos → **Share inbox** reads the same boundary.

## Contract

| Piece | Value |
| --- | --- |
| App Group | `group.com.ilkersevim.superDemoApp` (same as Feed widget) |
| App bundle | `com.ilkersevim.superDemoApp` |
| Share bundle | `com.ilkersevim.superDemoApp.Share` |
| Inbox file | `share-inbox.json` (temp + replace; append capped at 20) |
| Shared sources | `ShareInboxShared/` (app + extension membership) |
| Extension folder | `superDemoAppShare/` |
| Platforms | Share: **iPhone / iPad only**; embed `platformFilter = ios` so Mac lane stays green |

## Honest states

`unavailable` · `absent` · `corrupt` · `ok` (entries).

## Proof

- Unit: `ShareInboxStoreTests` (append/load/absent/corrupt/clear/cap via
  `containerURLOverride`; local Swift Testing)
- Hosted GHA: compile share extension with app (scheme builds; iOS embed
  `platformFilter = ios`); GHA remains build-heavy
- Limitation: device App Group signing may need team entitlement verification;
  unsigned Simulator may show `unavailable` until group is provisioned;
  share sheet UI itself is device/Simulator manual — Engineering demo seeds
  the inbox for CI-free review

## Docs

- Portfolio **Platform surfaces** row updated
- [`ci-cd-map.md`](../ci-cd-map.md) notes Share extension compile surface
- `CODEMAP.md` Share inbox row
