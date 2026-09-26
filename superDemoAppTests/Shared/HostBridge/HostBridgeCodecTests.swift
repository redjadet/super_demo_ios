//
//  HostBridgeCodecTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Host bridge codec + facade")
struct HostBridgeCodecTests {
    @Test
    func decodeValidFeedCacheStatusRequest() throws {
        let data = Data(#"{"v":1,"method":"feed.cacheStatus","id":"abc"}"#.utf8)
        let request = try HostBridgeCodec.decodeRequest(from: data).get()
        #expect(request.schemaVersion == 1)
        #expect(request.method == HostBridgeContract.feedCacheStatusMethod)
        #expect(request.id == "abc")
    }

    @Test
    func decodeRejectsMalformedAndVersionMismatch() {
        #expect(HostBridgeCodec.decodeRequest(from: Data()) == .failure(.malformedJSON))
        #expect(HostBridgeCodec.decodeRequest(from: Data("not-json".utf8)) == .failure(.malformedJSON))
        #expect(
            HostBridgeCodec.decodeRequest(from: Data(#"{"v":2,"method":"feed.cacheStatus","id":"x"}"#.utf8))
                == .failure(.versionMismatch)
        )
        #expect(
            HostBridgeCodec.decodeRequest(from: Data(#"{"v":1,"method":"","id":"x"}"#.utf8))
                == .failure(.malformedJSON)
        )
    }

    @Test
    func encodeOkAndErrorRoundTripShape() throws {
        let ok = HostBridgeResponse.ok(
            id: "1",
            schemaVersion: 1,
            result: FeedCacheStatusResult(
                postCount: 2,
                isStale: true,
                cacheAgeSeconds: 40,
                source: "snapshot"
            )
        )
        let okData = try HostBridgeCodec.encode(ok)
        let okJSON = try #require(String(data: okData, encoding: .utf8))
        #expect(okJSON.contains(#""ok":true"#))
        #expect(okJSON.contains(#""postCount":2"#))
        #expect(okJSON.contains(#""source":"snapshot"#))
        #expect(okJSON.contains(#""v":1"#))

        let err = HostBridgeResponse.error(
            id: "2",
            schemaVersion: 1,
            code: .unsupportedMethod,
            message: "nope"
        )
        let errData = try HostBridgeCodec.encode(err)
        let errJSON = try #require(String(data: errData, encoding: .utf8))
        #expect(errJSON.contains(#""ok":false"#))
        #expect(errJSON.contains(#""unsupportedMethod"#))
    }

    @Test
    func facadeReturnsSnapshotStatus() throws {
        let provider = FixedFeedCacheStatusProvider(
            result: FeedCacheStatusResult(
                postCount: 3,
                isStale: false,
                cacheAgeSeconds: 5,
                source: "snapshot"
            )
        )
        let facade = NativePlatformFacade(cacheStatusProvider: provider) {
            Date(timeIntervalSince1970: 1_700_000_000)
        }
        let request = Data(#"{"v":1,"method":"feed.cacheStatus","id":"req-1"}"#.utf8)
        let response = try facade.handle(request)
        let json = try #require(String(data: response, encoding: .utf8))
        #expect(json.contains(#""id":"req-1""#))
        #expect(json.contains(#""postCount":3"#))
        #expect(json.contains(#""source":"snapshot"#))
        #expect(json.contains(#""ok":true"#))
    }

    @Test
    func facadeUnsupportedMethodAndMalformed() throws {
        let facade = NativePlatformFacade(
            cacheStatusProvider: FixedFeedCacheStatusProvider(
                result: FeedCacheStatusResult(
                    postCount: 0,
                    isStale: false,
                    cacheAgeSeconds: nil,
                    source: "unavailable"
                )
            )
        )

        let badMethod = try facade.handle(
            Data(#"{"v":1,"method":"feed.refresh","id":"x"}"#.utf8)
        )
        let badMethodJSON = try #require(String(data: badMethod, encoding: .utf8))
        #expect(badMethodJSON.contains("unsupportedMethod"))

        let malformed = try facade.handle(Data("{".utf8))
        let malformedJSON = try #require(String(data: malformed, encoding: .utf8))
        #expect(malformedJSON.contains("malformedJSON"))
    }

    @Test
    func facadePropagatesCancellation() async {
        let facade = NativePlatformFacade(
            cacheStatusProvider: FixedFeedCacheStatusProvider(
                result: FeedCacheStatusResult(
                    postCount: 0,
                    isStale: false,
                    cacheAgeSeconds: nil,
                    source: "unavailable"
                )
            )
        )
        let task = Task {
            try Task.checkCancellation()
            return try facade.handle(
                Data(#"{"v":1,"method":"feed.cacheStatus","id":"c"}"#.utf8)
            )
        }
        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test
    func snapshotProviderMapsExpiredAndOk() throws {
        let root = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let writtenAt = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = FeedWidgetSnapshot(
            writtenAt: writtenAt,
            cacheTTLSeconds: 60,
            isStale: false,
            titles: [.init(id: 1, title: "A"), .init(id: 2, title: "B")]
        )
        try FeedWidgetSnapshotStore.write(snapshot, containerURLOverride: root)

        let expiredNow = Date(timeIntervalSince1970: 1_700_000_200)
        let expiredState = FeedWidgetSnapshotStore.loadState(
            now: expiredNow,
            containerURLOverride: root
        )
        #expect(expiredState == .expired(snapshot))

        let okNow = Date(timeIntervalSince1970: 1_700_000_030)
        let okState = FeedWidgetSnapshotStore.loadState(now: okNow, containerURLOverride: root)
        #expect(okState == .ok(snapshot))
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("host-bridge-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

nonisolated struct FixedFeedCacheStatusProvider: FeedCacheStatusProviding {
    let result: FeedCacheStatusResult
    func cacheStatus(now _: Date) -> FeedCacheStatusResult {
        self.result
    }
}
