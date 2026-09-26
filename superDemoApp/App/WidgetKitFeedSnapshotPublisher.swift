//
//  WidgetKitFeedSnapshotPublisher.swift
//  superDemoApp
//
//  Composition-owned: write App Group snapshot + reload WidgetKit timelines.
//

import Foundation
import os
import WidgetKit

struct WidgetKitFeedSnapshotPublisher: FeedWidgetSnapshotPublishing {
    private static let logger = Logger(
        subsystem: "com.ilkersevim.superDemoApp",
        category: "FeedWidgetSnapshot"
    )

    func publish(_ snapshot: FeedWidgetSnapshot) {
        do {
            try FeedWidgetSnapshotStore.write(snapshot)
        } catch FeedWidgetSnapshotStoreError.containerUnavailable {
            // Unsigned Simulator / missing App Group — widget shows unavailable.
            return
        } catch {
            Self.logger.error("Feed widget snapshot write failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        WidgetCenter.shared.reloadTimelines(ofKind: FeedWidgetAppGroup.widgetKind)
    }

    func clearPublishedSnapshot() {
        do {
            try FeedWidgetSnapshotStore.remove()
        } catch FeedWidgetSnapshotStoreError.containerUnavailable {
            return
        } catch {
            Self.logger.error("Feed widget snapshot clear failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        WidgetCenter.shared.reloadTimelines(ofKind: FeedWidgetAppGroup.widgetKind)
    }
}
