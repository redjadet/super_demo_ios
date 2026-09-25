//
//  WidgetKitFeedSnapshotPublisher.swift
//  superDemoApp
//
//  Composition-owned: write App Group snapshot + reload WidgetKit timelines.
//

import Foundation
import WidgetKit

struct WidgetKitFeedSnapshotPublisher: FeedWidgetSnapshotPublishing {
    func publish(_ snapshot: FeedWidgetSnapshot) {
        do {
            try FeedWidgetSnapshotStore.write(snapshot)
        } catch {
            // Unsigned Simulator / missing App Group — stay silent; widget shows unavailable/absent.
            return
        }
        WidgetCenter.shared.reloadTimelines(ofKind: FeedWidgetAppGroup.widgetKind)
    }
}
