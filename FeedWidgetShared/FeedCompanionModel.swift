// Shared presentation state for the independent watchOS and tvOS Feed demos.
// Sample scenarios stay in memory; stored snapshots are always read-only.

#if os(watchOS) || os(tvOS)
import Foundation
import Observation

nonisolated enum FeedCompanionScenario: String, CaseIterable, Identifiable {
    case fresh, stale, expired, empty, absent, corrupt, unavailable

    var id: String {
        self.rawValue
    }

    var title: String {
        switch self {
        case .fresh: "Fresh Feed"
        case .stale: "Cached Feed"
        case .expired: "Expired Feed"
        case .empty: "Empty Feed"
        case .absent: "No snapshot"
        case .corrupt: "Unreadable snapshot"
        case .unavailable: "Storage unavailable"
        }
    }

    static func launchSelection(arguments: [String] = ProcessInfo.processInfo.arguments) -> Self? {
        guard let index = arguments.firstIndex(of: "-CompanionDemoScenario"),
              arguments.indices.contains(index + 1)
        else { return nil }
        return Self(rawValue: arguments[index + 1])
    }

    func state(seed: FeedWidgetSnapshot, now: Date) -> FeedWidgetSnapshotState {
        var snapshot = seed
        switch self {
        case .fresh:
            return .ok(snapshot)
        case .stale:
            snapshot.isStale = true
            return .ok(snapshot)
        case .expired:
            snapshot.writtenAt = now.addingTimeInterval(-16 * 60)
            return .expired(snapshot)
        case .empty:
            snapshot.titles = []
            snapshot.postCount = 0
            return .ok(snapshot)
        case .absent: return .absent
        case .corrupt: return .corrupt
        case .unavailable: return .unavailable
        }
    }
}

private enum FeedCompanionSnapshotReader {
    @concurrent
    nonisolated static func loadState() async -> FeedWidgetSnapshotState {
        FeedWidgetSnapshotStore.loadState()
    }
}

@MainActor
@Observable
final class FeedCompanionModel {
    private(set) var state: FeedWidgetSnapshotState = .absent
    private(set) var scenario: FeedCompanionScenario?
    private(set) var isLoading = false

    private let makeSeed: (Date) -> FeedWidgetSnapshot
    private let now: () -> Date
    private let loadState: @Sendable () async -> FeedWidgetSnapshotState
    private var revision = 0

    init(
        makeSeed: @escaping (Date) -> FeedWidgetSnapshot,
        scenario: FeedCompanionScenario? = nil,
        now: @escaping () -> Date = Date.init,
        loadState: @escaping @Sendable () async -> FeedWidgetSnapshotState = {
            await FeedCompanionSnapshotReader.loadState()
        }
    ) {
        self.makeSeed = makeSeed
        self.now = now
        self.loadState = loadState
        if let scenario {
            self.showSample(scenario)
        }
    }

    var snapshot: FeedWidgetSnapshot? {
        switch self.state {
        case let .ok(snapshot), let .expired(snapshot): snapshot
        case .absent, .corrupt, .unavailable: nil
        }
    }

    var sourceTitle: String {
        self.scenario == nil ? "Stored on this device" : "Sample Feed"
    }

    var statusTitle: String {
        if self.isLoading, self.snapshot == nil {
            return "Loading Feed"
        }
        switch self.state {
        case .unavailable: return "Storage unavailable"
        case .absent: return "No snapshot yet"
        case .corrupt: return "Unreadable snapshot"
        case .expired: return "Expired Feed"
        case let .ok(snapshot):
            if snapshot.titles.isEmpty {
                return "No headlines"
            }
            return snapshot.isStale ? "Cached Feed" : "Fresh Feed"
        }
    }

    var statusSymbol: String {
        switch self.state {
        case .unavailable, .corrupt: return "exclamationmark.triangle"
        case .absent: return "tray"
        case .expired: return "clock.badge.exclamationmark"
        case let .ok(snapshot):
            if snapshot.titles.isEmpty {
                return "tray"
            }
            return snapshot.isStale ? "clock.arrow.circlepath" : "checkmark.circle"
        }
    }

    var statusDetail: String {
        if self.isLoading, self.snapshot == nil {
            return "Checking the snapshot saved on this device."
        }
        switch self.state {
        case .unavailable: return "Local storage cannot be opened. Try sample Feed to explore offline."
        case .absent: return "No Feed has been saved here. Try sample Feed to explore offline."
        case .corrupt: return "The saved Feed could not be read. Reload or try sample Feed."
        case .expired: return "These saved headlines are past their freshness limit."
        case let .ok(snapshot):
            if snapshot.titles.isEmpty {
                return "This snapshot contains no headlines."
            }
            return snapshot.isStale
                ? "Saved headlines from an earlier refresh."
                : "Headlines within the freshness limit."
        }
    }

    func showSample(_ scenario: FeedCompanionScenario = .fresh) {
        self.revision += 1
        self.isLoading = false
        self.scenario = scenario
        let date = self.now()
        self.state = scenario.state(seed: self.makeSeed(date), now: date)
    }

    func useStoredSnapshot() async {
        self.state = .absent
        self.scenario = nil
        await self.reload()
    }

    func reload() async {
        if self.scenario != nil {
            self.refreshFreshness()
            return
        }
        self.revision += 1
        let request = self.revision
        self.isLoading = true
        let loaded = await self.loadState()
        guard request == self.revision else { return }
        self.isLoading = false
        guard !Task.isCancelled else { return }
        self.state = loaded
        self.refreshFreshness()
    }

    func refreshFreshness() {
        guard case let .ok(snapshot) = self.state,
              let ttl = snapshot.cacheTTLSeconds,
              self.now().timeIntervalSince(snapshot.writtenAt) > ttl
        else { return }
        self.state = .expired(snapshot)
    }

    /// Called by a scene-phase task. Disappearing or backgrounding cancels polling.
    func observeSnapshots() async {
        await self.reload()
        while !Task.isCancelled {
            do { try await Task.sleep(for: .seconds(15)) } catch { return }
            await self.reload()
        }
    }
}
#endif
