# super_demo_flutter_module

Portfolio **Flutter add-to-app module** embedded by the iOS host `superDemoApp`.

## What it proves

- Real Flutter module (not contract-only theater)
- Dart calls JP-P0-C `feed.cacheStatus` over MethodChannel
  `com.ilkersevim.superDemoApp/host_bridge`
- Native side: `NativePlatformFacade` + App Group Feed snapshot honesty

## Honesty

- Demo / portfolio product — not production Flutter shipping
- Hosted CI prepares iOS frameworks on macOS runners; Linux agents cannot
  `flutter build ios-framework`
- Mac destination of the universal app does **not** link Flutter (iOS SDK only)
- Simulator / device: run `./tool/prepare_flutter_embed.sh` then build the iOS
  app (see [`docs/flutter-add-to-app.md`](../docs/flutter-add-to-app.md))

## Local module checks

```bash
cd flutter_module
flutter pub get
flutter analyze
flutter test
```
