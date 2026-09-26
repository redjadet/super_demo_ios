# Flutter add-to-app (JP-P2-D)

Real Flutter **module** embedded in the iOS host — not contract-only theater.

## Honesty

| Claim | Reality |
| --- | --- |
| Flutter module in repo | Yes — `flutter_module/` |
| Dart → native `feed.cacheStatus` | Yes — MethodChannel → `NativePlatformFacade` |
| Always linked in every binary | **No** — iOS only, after `./tool/prepare_flutter_embed.sh` |
| Mac destination | Intentionally **unlinked** (Flutter iOS engine ≠ macOS) |
| Production / TestFlight Flutter product | **Not claimed** — portfolio demo |
| Linux agents | Can `flutter test` / `analyze` the module; cannot build iOS frameworks |

Native codec/facade without Flutter remains at
[`native-host-boundary.md`](native-host-boundary.md) (JP-P0-C).

## Layout

| Piece | Path |
| --- | --- |
| Flutter module | `flutter_module/` |
| Dart MethodChannel UI | `flutter_module/lib/main.dart` |
| Native channel + engine | `superDemoApp/Shared/FlutterEmbed/` |
| Engineering demo | Production Readiness → **Flutter add-to-app module** |
| Prepare frameworks | `./tool/prepare_flutter_embed.sh` (flattens XCFramework slices → `Flutter/<Config>/{iphoneos,iphonesimulator}/*.framework` for the linker) |
| Embed script (Xcode) | `Scripts/embed-flutter-frameworks.sh` |
| Optional xcconfig | `Config/FlutterEmbed.local.xcconfig` (gitignored) |

Channel: `com.ilkersevim.superDemoApp/host_bridge` · method `invoke` · UTF-8 JSON
body matching JP-P0-C (`feed.cacheStatus`).

## How to run (macOS)

```bash
# 1) Flutter stable on PATH
flutter --version

# 2) Build XCFrameworks + write local xcconfig
./tool/prepare_flutter_embed.sh

# 3) Open Xcode / run iOS Simulator destination (not Mac)
# Engineering demos → Flutter add-to-app module → Ping feed.cacheStatus
```

Without step 2, the iOS app still builds; the demo shows an honest
“frameworks not linked” screen and links to the native host-bridge ping.

## CI

- **iphone-test** / **platform-builds (iPad):** install Flutter →
  `./tool/prepare_flutter_embed.sh` (default **`--no-codesign`** — hosted runners
  have no Apple Development certs) → `SUPERDEMO_REQUIRE_FLUTTER_EMBED=1`.
- **Mac lane:** same prepare is fine; embed script and sdk-filtered linker flags
  skip Flutter on `macosx`.
- **lint:** no Flutter frameworks required.
- Module unit tests: `cd flutter_module && flutter test` (also run on iPhone CI).
- Local device codesign: `./tool/prepare_flutter_embed.sh --codesign` when you
  have a Development Team.

## Proof

- Dart: `flutter_module/test/host_bridge_channel_test.dart`
- Swift: `FlutterHostBridgeChannelTests` (channel name contract)
- Hosted: GHA Delivery checklist with Flutter prepare on iOS lanes
