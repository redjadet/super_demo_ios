//
//  FeedWidgetSnapshotStoreTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Feed widget snapshot store")
struct FeedWidgetSnapshotStoreTests {
    @Test
    func loadStateUnavailableWithoutContainer() {
        let state = FeedWidgetSnapshotStore.loadState(
            suiteName: "test.suite.missing.\(UUID().uuidString)"
        )
        #expect(state == .unavailable || state == .absent)
    }

    @Test
    func writeAndLoadOkRoundTrip() throws {
        let root = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let snapshot = FeedWidgetSnapshot(
            writtenAt: Date(timeIntervalSince1970: 1_700_000_000),
            cacheTTLSeconds: 15 * 60,
            isStale: false,
            titles: [.init(id: 1, title: "Hello")]
        )
        try FeedWidgetSnapshotStore.write(snapshot, containerURLOverride: root)

        let state = FeedWidgetSnapshotStore.loadState(
            now: Date(timeIntervalSince1970: 1_700_000_100),
            containerURLOverride: root
        )
        #expect(state == .ok(snapshot))
    }

    @Test
    func loadStateAbsentWhenFileMissing() throws {
        let root = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let state = FeedWidgetSnapshotStore.loadState(containerURLOverride: root)
        #expect(state == .absent)
    }

    @Test
    func loadStateExpiredAndCorrupt() throws {
        let root = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let now = Date(timeIntervalSince1970: 1_700_000_900)

        let expired = FeedWidgetSnapshot(
            writtenAt: Date(timeIntervalSince1970: 1_700_000_000),
            cacheTTLSeconds: 60,
            isStale: true,
            titles: [.init(id: 2, title: "Old")]
        )
        try FeedWidgetSnapshotStore.write(expired, containerURLOverride: root)
        #expect(FeedWidgetSnapshotStore.loadState(now: now, containerURLOverride: root) == .expired(expired))

        var bad = expired
        bad.schemaVersion = 99
        try FeedWidgetSnapshotStore.write(bad, containerURLOverride: root)
        #expect(FeedWidgetSnapshotStore.loadState(now: now, containerURLOverride: root) == .corrupt)

        let fileURL = try #require(
            FeedWidgetSnapshotStore.snapshotFileURL(containerURLOverride: root)
        )
        try Data("not-json".utf8).write(to: fileURL, options: .atomic)
        #expect(FeedWidgetSnapshotStore.loadState(now: now, containerURLOverride: root) == .corrupt)
    }

    @Test
    func publisherNoOpDoesNotThrow() {
        let publisher = NoOpFeedWidgetSnapshotPublisher()
        publisher.publish(
            FeedWidgetSnapshot(
                writtenAt: .now,
                cacheTTLSeconds: nil,
                isStale: false,
                titles: []
            )
        )
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("feed-widget-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
