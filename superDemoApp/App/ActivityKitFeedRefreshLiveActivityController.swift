//
//  ActivityKitFeedRefreshLiveActivityController.swift
//  superDemoApp
//
//  Composition-owned ActivityKit bridge for Feed refresh Live Activity.
//  Gate A: activity spans refresh + short post-complete hold, then ends.
//

import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

/// Gate A post-complete hold so a reviewer can see the Island/banner before end.
private enum FeedRefreshLiveActivityTiming {
    /// ≤ few seconds (plan gate A). Not a fake long-running workload.
    static let postCompleteHoldNanoseconds: UInt64 = 2_500_000_000
}

#if canImport(ActivityKit) && os(iOS)

@MainActor
final class ActivityKitFeedRefreshLiveActivityController: FeedRefreshLiveActivityControlling {
    private var activity: Activity<FeedRefreshActivityAttributes>?
    private var endAfterHoldTask: Task<Void, Never>?

    func refreshDidStart() {
        self.cancelHoldTask()
        self.endCurrentActivity(state: .cancelled(), dismissal: .immediate)

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = FeedRefreshActivityAttributes(startedAt: Date())
        let state = FeedRefreshActivityAttributes.ContentState.refreshing()
        do {
            self.activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Simulator / unsigned / policy denial — stay silent; Feed UI still works.
            self.activity = nil
        }
    }

    func refreshDidSucceed(postCount: Int, isStale: Bool) {
        let state = FeedRefreshActivityAttributes.ContentState.completed(
            postCount: postCount,
            isStale: isStale
        )
        self.updateCurrentActivity(state: state)
        self.scheduleEndAfterHold(finalState: state)
    }

    func refreshDidFail() {
        let state = FeedRefreshActivityAttributes.ContentState.failed()
        self.updateCurrentActivity(state: state)
        self.scheduleEndAfterHold(finalState: state)
    }

    func refreshDidCancel() {
        self.cancelHoldTask()
        self.endCurrentActivity(state: .cancelled(), dismissal: .immediate)
    }

    private func updateCurrentActivity(state: FeedRefreshActivityAttributes.ContentState) {
        guard let activity else { return }
        let content = ActivityContent(state: state, staleDate: nil)
        Task {
            await activity.update(content)
        }
    }

    private func scheduleEndAfterHold(finalState: FeedRefreshActivityAttributes.ContentState) {
        self.cancelHoldTask()
        let hold = FeedRefreshLiveActivityTiming.postCompleteHoldNanoseconds
        self.endAfterHoldTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: hold)
            guard !Task.isCancelled else { return }
            self?.endCurrentActivity(state: finalState, dismissal: .default)
        }
    }

    private func endCurrentActivity(
        state: FeedRefreshActivityAttributes.ContentState,
        dismissal: ActivityUIDismissalPolicy
    ) {
        guard let activity else { return }
        self.activity = nil
        let content = ActivityContent(state: state, staleDate: nil)
        Task {
            await activity.end(content, dismissalPolicy: dismissal)
        }
    }

    private func cancelHoldTask() {
        self.endAfterHoldTask?.cancel()
        self.endAfterHoldTask = nil
    }
}

#else

@MainActor
final class ActivityKitFeedRefreshLiveActivityController: FeedRefreshLiveActivityControlling {
    func refreshDidStart() {
        // Intentionally empty — ActivityKit unavailable (Mac / Catalyst / etc.).
    }

    func refreshDidSucceed(postCount _: Int, isStale _: Bool) {
        // Intentionally empty — ActivityKit unavailable (Mac / Catalyst / etc.).
    }

    func refreshDidFail() {
        // Intentionally empty — ActivityKit unavailable (Mac / Catalyst / etc.).
    }

    func refreshDidCancel() {
        // Intentionally empty — ActivityKit unavailable (Mac / Catalyst / etc.).
    }
}

#endif
