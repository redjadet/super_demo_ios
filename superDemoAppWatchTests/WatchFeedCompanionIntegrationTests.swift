//
//  WatchFeedCompanionIntegrationTests.swift
//  superDemoAppWatchTests
//
//  watchOS-hosted integration tests for the Feed snapshot companion demo.
//

import XCTest
@testable import superDemoAppWatch

final class WatchFeedCompanionIntegrationTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("watch-feed-it-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: self.tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: self.tempRoot)
        self.tempRoot = nil
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
        XCTAssertEqual(loaded.titles.first?.title, "Watch demo: Feed snapshot")
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

    func testRealAppGroupSeedOrHonestUnavailable() {
        // Unsigned Simulator may lack the App Group container — that is an
        // honest `.unavailable` / seed-failure path, not a silent empty OK.
        let before = FeedWidgetSnapshotStore.loadState()
        switch before {
        case .unavailable:
            XCTAssertThrowsError(try FeedWidgetSnapshotStore.write(FeedCompanionDemoSnapshot.watchSeed())) { error in
                XCTAssertEqual(error as? FeedWidgetSnapshotStoreError, .containerUnavailable)
            }
        case .absent, .corrupt, .expired, .ok:
            do {
                try FeedWidgetSnapshotStore.write(FeedCompanionDemoSnapshot.watchSeed())
                let after = FeedWidgetSnapshotStore.loadState()
                guard case let .ok(snapshot) = after else {
                    XCTFail("expected ok after seed when container exists, got \(after)")
                    return
                }
                XCTAssertEqual(snapshot.titles.first?.title, "Watch demo: Feed snapshot")
                try? FeedWidgetSnapshotStore.remove()
            } catch {
                XCTFail("seed should succeed when container exists: \(error)")
            }
        }
    }
}
