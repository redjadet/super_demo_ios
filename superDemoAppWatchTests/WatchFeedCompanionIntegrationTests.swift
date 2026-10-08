//
//  WatchFeedCompanionIntegrationTests.swift
//  superDemoAppWatchTests
//
//  watchOS-hosted integration tests for the Feed snapshot companion demo.
//

import XCTest
@testable import superDemoAppWatch

final class WatchFeedCompanionIntegrationTests: XCTestCase {
    private let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("watch-feed-it-\(UUID().uuidString)", isDirectory: true)

    override func setUpWithError() throws {
        try super.setUpWithError()
        try FileManager.default.createDirectory(at: self.tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: self.tempRoot)
        try super.tearDownWithError()
    }

    func testAbsentWhenOverrideContainerEmpty() {
        let state = FeedWidgetSnapshotStore.loadState(containerURLOverride: self.tempRoot)
        XCTAssertEqual(state, .absent)
    }

    func testWatchSeedRoundTripOk() throws {
        let seed = FeedCompanionDemoSnapshot.watchSeed(
            writtenAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        try FeedWidgetSnapshotStore.write(seed, containerURLOverride: self.tempRoot)

        let state = FeedWidgetSnapshotStore.loadState(
            now: Date(timeIntervalSince1970: 1_700_000_100),
            containerURLOverride: self.tempRoot
        )
        XCTAssertEqual(state, .ok(seed))
        guard case let .ok(loaded) = state else {
            return
        }
        XCTAssertEqual(loaded.titles.count, 3)
        XCTAssertEqual(loaded.titles.first?.title, "A quiet morning on the Bosphorus")
        XCTAssertFalse(loaded.isStale)
    }

    func testExpiredHonestyForStaleSeed() throws {
        let expired = FeedWidgetSnapshot(
            writtenAt: Date(timeIntervalSince1970: 1_700_000_000),
            cacheTTLSeconds: 60,
            isStale: true,
            titles: [.init(id: 9, title: "Expired watch row")]
        )
        try FeedWidgetSnapshotStore.write(expired, containerURLOverride: self.tempRoot)
        let state = FeedWidgetSnapshotStore.loadState(
            now: Date(timeIntervalSince1970: 1_700_000_900),
            containerURLOverride: self.tempRoot
        )
        XCTAssertEqual(state, .expired(expired))
    }

    func testCorruptHonestyForBadJSON() throws {
        let fileURL = try XCTUnwrap(
            FeedWidgetSnapshotStore.snapshotFileURL(containerURLOverride: self.tempRoot)
        )
        try Data("not-json".utf8).write(to: fileURL, options: .atomic)
        let state = FeedWidgetSnapshotStore.loadState(containerURLOverride: self.tempRoot)
        XCTAssertEqual(state, .corrupt)
    }

    func testRealAppGroupReadIsStableAndNonMutating() {
        // A real-container smoke check must never overwrite the reviewer's data.
        let file = FeedWidgetSnapshotStore.snapshotFileURL()
        let before = file.flatMap { try? Data(contentsOf: $0) }
        let now = Date()
        let first = FeedWidgetSnapshotStore.loadState(now: now)
        let second = FeedWidgetSnapshotStore.loadState(now: now)
        XCTAssertEqual(first, second)
        XCTAssertEqual(file.flatMap { try? Data(contentsOf: $0) }, before)
        if file == nil {
            XCTAssertEqual(first, .unavailable)
        }
    }
}
