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

    func testRealAppGroupSeedOrHonestUnavailable() throws {
        // Unsigned Simulator may lack the App Group container — that is an
        // honest `.unavailable` / seed-failure path, not a silent empty OK.
        // When the container exists, preserve any prior snapshot (Codex P2).
        let before = FeedWidgetSnapshotStore.loadState()
        switch before {
        case .unavailable:
            XCTAssertThrowsError(try FeedWidgetSnapshotStore.write(FeedCompanionDemoSnapshot.watchSeed())) { error in
                XCTAssertEqual(error as? FeedWidgetSnapshotStoreError, .containerUnavailable)
            }
        case .absent, .corrupt, .expired, .ok:
            let priorData = Self.readPersistentSnapshotData()
            defer { Self.restorePersistentSnapshot(priorData: priorData) }
            try FeedWidgetSnapshotStore.write(FeedCompanionDemoSnapshot.watchSeed())
            let after = FeedWidgetSnapshotStore.loadState()
            guard case let .ok(snapshot) = after else {
                XCTFail("expected ok after seed when container exists, got \(after)")
                return
            }
            XCTAssertEqual(snapshot.titles.first?.title, "Watch demo: Feed snapshot")
        }
    }

    private static func readPersistentSnapshotData() -> Data? {
        guard let fileURL = FeedWidgetSnapshotStore.snapshotFileURL(),
              FileManager.default.fileExists(atPath: fileURL.path)
        else {
            return nil
        }
        return try? Data(contentsOf: fileURL)
    }

    private static func restorePersistentSnapshot(priorData: Data?) {
        guard let fileURL = FeedWidgetSnapshotStore.snapshotFileURL() else {
            return
        }
        if let priorData {
            try? priorData.write(to: fileURL, options: .atomic)
        } else {
            try? FeedWidgetSnapshotStore.remove()
        }
    }
}
