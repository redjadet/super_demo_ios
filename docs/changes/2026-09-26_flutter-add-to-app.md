# 2026-09-26 — Flutter add-to-app embed (JP-P2-D)

## Summary

Vendors a real Flutter module (`flutter_module/`) and embeds it in the iOS host
via generated XCFrameworks. Dart calls JP-P0-C `feed.cacheStatus` through
MethodChannel → `NativePlatformFacade`.

## Paths

- `flutter_module/` (Dart UI + channel test)
- `superDemoApp/Shared/FlutterEmbed/`
- `Features/ProductionReadiness/Presentation/FlutterModuleDemoView.swift`
- `tool/prepare_flutter_embed.sh`, `Scripts/embed-flutter-frameworks.sh`
- Docs: [`flutter-add-to-app.md`](../flutter-add-to-app.md), updated
  [`native-host-boundary.md`](../native-host-boundary.md)

## Honesty

- Portfolio demo; Mac destination does not link Flutter
- Frameworks generated on macOS (local or GHA); not committed
- Without prepare script, iOS build still succeeds with unavailable UI
- Unit test target (`superDemoAppTests`) also includes `App.xcconfig` so
  `xcodebuild test` can resolve the Flutter module dependency when embed is
  prepared (search paths / flags are SDK-filtered; Mac stays unlinked)

## Proof

- `flutter test` in module (channel mock)
- `FlutterHostBridgeChannelTests`
- Hosted GHA: prepare + require embed on iPhone/iPad lanes
