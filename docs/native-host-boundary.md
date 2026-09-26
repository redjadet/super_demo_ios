# Native host boundary

Reviewable **native ↔ host** contract, now with an optional real Flutter
add-to-app embed (JP-P2-D).

## Honesty

| Surface | Status |
| --- | --- |
| Codec + `NativePlatformFacade` + Engineering **Host bridge ping** | Always available (JP-P0-C) |
| Flutter module `flutter_module/` + MethodChannel | **In repo** (JP-P2-D) |
| Linked `Flutter.xcframework` in every binary | **No** — iOS only after `./tool/prepare_flutter_embed.sh` |
| Mac destination | Does **not** link Flutter |

Full embed how-to: [`flutter-add-to-app.md`](flutter-add-to-app.md).

## Day-1 method: `feed.cacheStatus`

| Field | Value |
| --- | --- |
| Request | `{ "v": 1, "method": "feed.cacheStatus", "id": "<uuid>" }` |
| Response ok | `{ "v": 1, "id": "<uuid>", "ok": true, "result": { "postCount": Int, "isStale": Bool, "cacheAgeSeconds": Int?, "source": "snapshot"\|"repository"\|"unavailable" } }` |
| Response err | `{ "v": 1, "id": …?, "ok": false, "error": { "code": "…", "message": "…" } }` |

Error codes: `malformedJSON` · `unsupportedMethod` · `versionMismatch` ·
`cancelled` · `unavailable`.

Dart invokes the same JSON over MethodChannel
`com.ilkersevim.superDemoApp/host_bridge` method `invoke`.

## Ownership

| Piece | Path |
| --- | --- |
| Messages | `superDemoApp/Shared/HostBridge/HostBridgeMessage.swift` |
| Codec | `HostBridgeCodec.swift` |
| Facade | `NativePlatformFacade.swift` |
| Snapshot status | `SnapshotFeedCacheStatusProvider` (reads JP-P0-B App Group snapshot) |
| Composition | `App/HostBridgeComposition.swift` |
| Flutter channel / engine | `Shared/FlutterEmbed/` |
| Flutter module | `flutter_module/` |
| Demo (native) | Engineering demos → **Host bridge ping** |
| Demo (Flutter UI) | Engineering demos → **Flutter add-to-app module** |

`source: "snapshot"` when the App Group Feed widget snapshot is present (ok or
expired). `source: "unavailable"` when absent / corrupt / App Group missing.
`repository` is reserved for a later provider; day-1 does not invent a second
cache path.

`postCount` is the **full** Feed cache size from the snapshot (not the
widget title list, which stays capped for Home Screen UI).

## Proof

- Unit: `HostBridgeCodecTests` (encode/decode, unsupported method, malformed,
  cancellation, snapshot `postCount` map)
- Flutter: `flutter_module/test/host_bridge_channel_test.dart`
- Lint / Swift verify via pre-commit
- Demo: Production Readiness → Host bridge ping / Flutter add-to-app module
