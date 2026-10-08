// Run the same presentation/concurrency contract on both native companion hosts.
import XCTest
#if os(watchOS)
@testable import superDemoAppWatch
#elseif os(tvOS)
@testable import superDemoAppTV
#endif

@MainActor
final class FeedCompanionModelTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    func testSampleSelectionDoesNotReadOrReplaceStoredSnapshot() async {
        let loader = SnapshotLoader()
        let model = self.makeModel { await loader.load() }
        let reload = Task { await model.reload() }
        await loader.waitForRequests(1)
        model.showSample(.stale)
        await loader.finish(0, state: .corrupt)
        await reload.value
        await model.reload()

        XCTAssertEqual(model.scenario, .stale)
        XCTAssertEqual(model.statusTitle, "Cached Feed")
        XCTAssertEqual(model.snapshot?.isStale, true)
        XCTAssertFalse(model.isLoading)
        let count = await loader.requestCount
        XCTAssertEqual(count, 1)
    }

    func testSampleScenariosLeaveStoredBytesUntouched() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("companion-sample-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let snapshot = FeedCompanionDemoSnapshot.tvSeed(writtenAt: self.date)
        try FeedWidgetSnapshotStore.write(snapshot, containerURLOverride: root)
        let file = try XCTUnwrap(FeedWidgetSnapshotStore.snapshotFileURL(containerURLOverride: root))
        let bytes = try Data(contentsOf: file)
        let frozenDate = self.date
        let model = self.makeModel {
            FeedWidgetSnapshotStore.loadState(now: frozenDate, containerURLOverride: root)
        }
        await model.reload()
        for scenario in FeedCompanionScenario.allCases {
            model.showSample(scenario)
            await model.reload()
            XCTAssertEqual(try Data(contentsOf: file), bytes)
        }
        await model.useStoredSnapshot()
        XCTAssertEqual(model.state, .ok(snapshot))
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testSwitchingToStorageDoesNotRelabelSampleAsStoredWhileLoading() async {
        let loader = SnapshotLoader()
        let model = self.makeModel { await loader.load() }
        model.showSample(.fresh)
        let reload = Task { await model.useStoredSnapshot() }
        await loader.waitForRequests(1)
        XCTAssertNil(model.scenario)
        XCTAssertNil(model.snapshot)
        XCTAssertEqual(model.statusTitle, "Loading Feed")
        await loader.finish(0, state: .absent)
        await reload.value
        XCTAssertEqual(model.statusTitle, "No snapshot yet")
    }

    func testNewestStoredReadWinsWhenRequestsFinishOutOfOrder() async {
        let loader = SnapshotLoader()
        let model = self.makeModel { await loader.load() }
        let first = Task { await model.reload() }
        await loader.waitForRequests(1)
        let second = Task { await model.reload() }
        await loader.waitForRequests(2)
        let snapshot = FeedCompanionDemoSnapshot.watchSeed(writtenAt: self.date)
        await loader.finish(1, state: .ok(snapshot))
        await second.value
        await loader.finish(0, state: .corrupt)
        await first.value

        XCTAssertEqual(model.state, .ok(snapshot))
        XCTAssertFalse(model.isLoading)
    }

    func testCanceledReadDoesNotPublishResult() async {
        let loader = SnapshotLoader()
        let model = self.makeModel { await loader.load() }
        let reload = Task { await model.reload() }
        await loader.waitForRequests(1)
        reload.cancel()
        await loader.finish(0, state: .corrupt)
        await reload.value

        XCTAssertEqual(model.state, .absent)
        XCTAssertFalse(model.isLoading)
    }

    func testUseStoredFeedExitsSampleModeAndLoadsActualState() async {
        let snapshot = FeedCompanionDemoSnapshot.watchSeed(writtenAt: self.date)
        let model = self.makeModel { .expired(snapshot) }
        model.showSample(.fresh)
        await model.useStoredSnapshot()

        XCTAssertNil(model.scenario)
        XCTAssertEqual(model.sourceTitle, "Stored on this device")
        XCTAssertEqual(model.state, .expired(snapshot))
        XCTAssertEqual(model.snapshot?.titles, snapshot.titles)
    }

    func testFreshnessExpiresWithoutLosingHeadlinesOrResettingTimestamp() {
        let clock = TestClock(date: self.date)
        let model = FeedCompanionModel(
            makeSeed: { FeedCompanionDemoSnapshot.watchSeed(writtenAt: $0) },
            scenario: .fresh,
            now: clock.currentDate
        )
        let snapshot = model.snapshot
        clock.date = self.date.addingTimeInterval(900)
        model.refreshFreshness()
        XCTAssertEqual(model.statusTitle, "Fresh Feed")
        clock.date = self.date.addingTimeInterval(901)
        model.refreshFreshness()
        XCTAssertEqual(model.statusTitle, "Expired Feed")
        XCTAssertEqual(model.snapshot, snapshot)
    }

    func testReloadDoesNotMakeExpiredSampleFreshAgain() async {
        let model = self.makeModel()
        model.showSample(.expired)
        let timestamp = model.snapshot?.writtenAt
        await model.reload()
        XCTAssertEqual(model.statusTitle, "Expired Feed")
        XCTAssertEqual(model.snapshot?.writtenAt, timestamp)
    }

    func testEmptyAndUnavailableStatesOfferDistinctHonestPresentation() {
        let model = self.makeModel()
        model.showSample(.empty)
        XCTAssertEqual(model.statusTitle, "No headlines")
        XCTAssertEqual(model.snapshot?.postCount, 0)
        XCTAssertEqual(model.snapshot?.titles, [])
        model.showSample(.unavailable)
        XCTAssertEqual(model.statusTitle, "Storage unavailable")
        XCTAssertNil(model.snapshot)
        model.showSample(.fresh)
        XCTAssertEqual(model.sourceTitle, "Sample Feed")
        XCTAssertEqual(model.snapshot?.titles.isEmpty, false)
    }

    func testLaunchScenarioRequiresKnownValueAndCompleteArgument() {
        XCTAssertEqual(
            FeedCompanionScenario.launchSelection(arguments: ["app", "-CompanionDemoScenario", "stale"]),
            .stale
        )
        XCTAssertNil(FeedCompanionScenario.launchSelection(arguments: ["app", "-CompanionDemoScenario"]))
        XCTAssertNil(FeedCompanionScenario.launchSelection(arguments: ["app", "-CompanionDemoScenario", "unknown"]))
        XCTAssertNil(FeedCompanionScenario.launchSelection(arguments: ["app"]))
    }

    private func makeModel(
        loadState: @escaping @Sendable () async -> FeedWidgetSnapshotState = { .absent }
    ) -> FeedCompanionModel {
        let frozenDate = self.date
        return FeedCompanionModel(
            makeSeed: { FeedCompanionDemoSnapshot.watchSeed(writtenAt: $0) },
            now: { frozenDate },
            loadState: loadState
        )
    }
}

@MainActor
private final class TestClock {
    var date: Date

    func currentDate() -> Date {
        self.date
    }

    init(date: Date) {
        self.date = date
    }
}

private actor SnapshotLoader {
    private(set) var requestCount = 0
    private var pending: [Int: CheckedContinuation<FeedWidgetSnapshotState, Never>] = [:]
    private var waiter: (count: Int, continuation: CheckedContinuation<Void, Never>)?

    func load() async -> FeedWidgetSnapshotState {
        let index = self.requestCount
        self.requestCount += 1
        return await withCheckedContinuation { continuation in
            self.pending[index] = continuation
            if let waiter = self.waiter, self.requestCount >= waiter.count {
                self.waiter = nil
                waiter.continuation.resume()
            }
        }
    }

    func waitForRequests(_ count: Int) async {
        guard self.requestCount < count else { return }
        await withCheckedContinuation { self.waiter = (count, $0) }
    }

    func finish(_ index: Int, state: FeedWidgetSnapshotState) {
        self.pending.removeValue(forKey: index)?.resume(returning: state)
    }
}
