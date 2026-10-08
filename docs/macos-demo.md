# macOS portfolio demo

Native macOS destination for the universal SwiftUI shell (not Mac Catalyst).
Hosted CI proves an **unsigned Mac compile**; local Xcode / Terminal runs the same
lane for a live desktop window.

## What this proves

- One app target with `SUPPORTED_PLATFORMS` including `macosx` (see
  [`universal-apple-platforms.md`](universal-apple-platforms.md)).
- Adaptive navigation / chrome on a resizable Mac window (pointer + keyboard).
- Feed / Items / Dashboard / Engineering demos compile for Mac; Flutter embed,
  WidgetKit, and Share extension stay **iOS-linked** (Mac lane skips them).
- Merge proof is the `platform-builds` job → `./bin/ci-platform-builds.sh`
  Mac destination with `CODE_SIGNING_ALLOWED=NO` (same default as #69).

**Not claimed here:** Mac App Store signing, Mac Development profiles, or a
hosted Mac UITest lane. Opt into signed Mac builds only when profiles exist
(`CI_MAC_REQUIRE_CODE_SIGN=1`).

## Run locally (unsandboxed Terminal / Xcode)

Cursor agent / seatbelt shells often abort `xcodebuild` (CoreDevice
`xpc_add_bundle`) or fail SPM manifest loads (`SwiftShims`). Use a normal
Terminal.app or Xcode session on the Mac mini:

```bash
cd /path/to/super_demo_ios
# Preferred: full iPad + Mac (+ watch/tvOS) compile proof
./bin/ci-platform-builds.sh

# Mac-only unsigned compile-proof (matches CI Mac lane)
xcodebuild \
  -project superDemoApp.xcodeproj \
  -scheme superDemoApp \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=- \
  build
```

To **run** the app (needs a development team / signing for `macosx`):

1. Open `superDemoApp.xcodeproj` in Xcode 27.
2. Choose scheme `superDemoApp` → destination **My Mac**.
3. Run. Walk Feed, Items, Dashboard, and Engineering demos in a Mac window.

## Reviewer talk track (2 minutes)

1. Point at Platforms badge + portfolio row **Universal shell (iPhone / iPad / Mac)**.
2. Show `docs/ci-cd-map.md` job `platform-builds` (iPad + Mac + watchOS + tvOS).
3. On a Mac: either open the running app or the unsigned `xcodebuild` log with
   `BUILD SUCCEEDED` for `platform=macOS`.
4. Call out honesty: Mac CI is compile-proof; Flutter / widgets / share are
   intentionally unlinked on `macosx`.

## Source map

| Concern | Owner |
| --- | --- |
| Platforms | `SUPPORTED_PLATFORMS` on app target (`macosx`) |
| Adaptive shell | `superDemoApp/Shared/Presentation/AdaptiveNavigationShell.swift` |
| Mac CI lane | `bin/ci-platform-builds.sh` → `run_mac_build` |
| Destination helper | `tool/resolve_platform_destination.sh` |
| Portfolio honesty | [`portfolio.md`](portfolio.md) |
| Matrix commands | [`testing.md`](testing.md), [`universal-apple-platforms.md`](universal-apple-platforms.md) |

```bash
./bin/ci-platform-builds.sh
# or Mac-only:
xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=- build
```
