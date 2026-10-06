# Skill: Flutter add-to-app boundaries

Embedded Flutter module is a **portfolio demo**, not a claimed production
Flutter product. Canon: [`../../flutter-add-to-app.md`](../../flutter-add-to-app.md),
[`../../architecture/flutter-add-to-app.md`](../../architecture/flutter-add-to-app.md),
[`../../native-host-boundary.md`](../../native-host-boundary.md).

## Rules

1. Module lives in `flutter_module/`; native bridge under
   `superDemoApp/Shared/FlutterEmbed/` + `HostBridge/`.
2. Channel: `com.ilkersevim.superDemoApp/host_bridge` · method `invoke` · UTF-8
   JSON (`feed.cacheStatus` and documented peers only).
3. Build frameworks with `./tool/prepare_flutter_embed.sh` before iOS Simulator
   embed demos; frameworks are **generated** (gitignored) — do not commit them.
4. **Mac destination intentionally unlinked** (Flutter iOS engine ≠ macOS).
5. Linux agents may `flutter test` / `analyze` the module; they cannot claim iOS
   framework link proof without macOS + prepare script.
6. Do not expand MethodChannel surface without updating native facade + docs.

## Proof

- Dart: `flutter test` / `analyze` in `flutter_module/` when Dart changes
- iOS embed: prepare script + Engineering demos → Flutter add-to-app on Simulator
- CI iPhone/iPad lanes prepare embed when required by workflow honesty docs
