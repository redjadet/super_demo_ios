# Native host boundary

Reviewable **native ↔ host** contract without vendoring a Flutter module.

## Honesty

Flutter add-to-app / module embedding is **not** in this repo. The artifact
reviewers can verify is the **message codec + `NativePlatformFacade`** and the
Engineering demo that pings it. Do not claim Flutter integration.

## Day-1 method: `feed.cacheStatus`

| Field | Value |
| --- | --- |
| Request | `{ "v": 1, "method": "feed.cacheStatus", "id": "<uuid>" }` |
| Response ok | `{ "v": 1, "id": "<uuid>", "ok": true, "result": { "postCount": Int, "isStale": Bool, "cacheAgeSeconds": Int?, "source": "snapshot"\|"repository"\|"unavailable" } }` |
| Response err | `{ "v": 1, "id": …?, "ok": false, "error": { "code": "…", "message": "…" } }` |

Error codes: `malformedJSON` · `unsupportedMethod` · `versionMismatch` ·
`cancelled` · `unavailable`.

## Ownership

| Piece | Path |
| --- | --- |
| Messages | `superDemoApp/Shared/HostBridge/HostBridgeMessage.swift` |
| Codec | `HostBridgeCodec.swift` |
| Facade | `NativePlatformFacade.swift` |
| Snapshot status | `SnapshotFeedCacheStatusProvider` (reads JP-P0-B App Group snapshot) |
| Composition | `App/HostBridgeComposition.swift` |
| Demo | Engineering demos → **Host bridge ping** |

`source: "snapshot"` when the App Group Feed widget snapshot is present (ok or
expired). `source: "unavailable"` when absent / corrupt / App Group missing.
`repository` is reserved for a later provider; day-1 does not invent a second
cache path.

## Proof

- Unit: `HostBridgeCodecTests` (encode/decode, unsupported method, malformed,
  cancellation)
- Lint / Swift verify via pre-commit
- Demo: Production Readiness → Host bridge ping
