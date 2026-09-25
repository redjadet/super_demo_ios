//
//  LocalNotificationScheduling.swift
//  superDemoApp
//

import Foundation
import UserNotifications

/// Authorization + schedule surface for the local-notification Engineering demo (JP-P1-C).
/// Not production APNs — in-app / Simulator local delivery only.
@MainActor
protocol LocalNotificationScheduling: AnyObject {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func scheduleStaleFeedReminder(delaySeconds: TimeInterval) async throws
    func cancelStaleFeedReminder() async
}

enum LocalNotificationDemoIDs {
    static let staleFeedReminder = "com.ilkersevim.superDemoApp.local.stale-feed-reminder"
}

@MainActor
final class SystemLocalNotificationScheduler: LocalNotificationScheduling {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await self.center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await self.center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleStaleFeedReminder(delaySeconds: TimeInterval) async throws {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Feed cache may be stale")
        let body = String(
            localized: "Open Feed to refresh. Local demo only — not production push."
        )
        content.body = DiagnosticRedaction.sanitizeText(body)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, delaySeconds),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: LocalNotificationDemoIDs.staleFeedReminder,
            content: content,
            trigger: trigger
        )
        try await self.center.add(request)
    }

    func cancelStaleFeedReminder() async {
        await Task.yield()
        self.center.removePendingNotificationRequests(
            withIdentifiers: [LocalNotificationDemoIDs.staleFeedReminder]
        )
        self.center.removeDeliveredNotifications(
            withIdentifiers: [LocalNotificationDemoIDs.staleFeedReminder]
        )
    }
}
