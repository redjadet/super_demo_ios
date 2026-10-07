//
//  TVFeedCompanionIntegrationTests.swift
//  superDemoAppTVTests
//
//  tvOS-hosted integration tests for the Feed snapshot companion demo.
//

import XCTest
@testable import superDemoAppTV

final class TVFeedCompanionIntegrationTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("tv-feed-it-\(UUID().uuidString)", isDirectory: true)
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

    func testTVSeedRoundTripOk() throws {
        let seed = FeedCompanionDemoSnapshot.tvSeed(
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
        XCTAssertEqual(loaded.titles.count, 4)
        XCTAssertEqual(loaded.titles.first?.title, "tvOS demo: Feed snapshot")
        XCTAssertEqual(loaded.titles[2].title, "Same honesty contract as watchOS")
        XCTAssertFalse(loaded.isStale)
    }

    func testExpiredHonestyForStaleSeed() throws {
        let expired = FeedWidgetSnapshot(
            writtenAt: Date(timeIntervalSince1970: 1_700_000_000),
            cacheTTLSeconds: 60,
            isStale: true,
            titles: [.init(id: 9, title: "Expired tv row")]
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
        let before = FeedWidgetSnapshotStore.loadState()
        switch before {
        case .unavailable:
            XCTAssertThrowsError(try FeedWidgetSnapshotStore.write(FeedCompanionDemoSnapshot.tvSeed())) { error in
                XCTAssertEqual(error as? FeedWidgetSnapshotStoreError, .containerUnavailable)
            }
        case .absent, .corrupt, .expired, .ok:
            do {
                try FeedWidgetSnapshotStore.write(FeedCompanionDemoSnapshot.tvSeed())
                let after = FeedWidgetSnapshotStore.loadState()
                guard case let .ok(snapshot) = after else {
                    XCTFail("expected ok after seed when container exists, got \(after)")
                    return
                }
                XCTAssertEqual(snapshot.titles.first?.title, "tvOS demo: Feed snapshot")
                try? FeedWidgetSnapshotStore.remove()
            } catch {
                XCTFail("seed should succeed when container exists: \(error)")
            }
        }
    }
}
