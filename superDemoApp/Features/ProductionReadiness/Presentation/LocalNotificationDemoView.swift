//
//  LocalNotificationDemoView.swift
//  superDemoApp
//

import SwiftUI
import UserNotifications

/// Engineering demo: schedule a local “stale Feed” reminder (JP-P1-C).
/// Honesty: not APNs / TestFlight push.
struct LocalNotificationDemoView: View {
    @State private var model: LocalNotificationDemoModel

    init(scheduler: any LocalNotificationScheduling = SystemLocalNotificationScheduler()) {
        self._model = State(initialValue: LocalNotificationDemoModel(scheduler: scheduler))
    }

    var body: some View {
        List {
            Section("Honesty") {
                Text(
                    """
                    Schedules a local notification on this device/Simulator only. \
                    No APNs certificate, no push entitlement, no production delivery claim.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Permission") {
                LabeledContent("Status", value: self.model.statusLabel)
                if self.model.isDenied {
                    Text("Notifications are denied. Enable them in Settings to run this demo.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("localNotificationDeniedHint")
                }
                Button("Request permission") {
                    Task { await self.model.requestPermission() }
                }
                .disabled(self.model.isBusy)
                .accessibilityIdentifier("localNotificationRequestPermission")
            }

            Section("Stale Feed reminder") {
                Button("Schedule in 5 seconds") {
                    Task { await self.model.scheduleReminder(delaySeconds: 5) }
                }
                .disabled(self.model.isBusy || self.model.isDenied)
                .accessibilityIdentifier("localNotificationSchedule")

                Button("Cancel pending reminder", role: .destructive) {
                    Task { await self.model.cancelReminder() }
                }
                .disabled(self.model.isBusy)
                .accessibilityIdentifier("localNotificationCancel")
            }

            if let message = self.model.statusMessage {
                Section("Last result") {
                    Text(message)
                        .font(.footnote)
                        .accessibilityIdentifier("localNotificationStatusMessage")
                }
            }
        }
        .navigationTitle("Local notifications")
        .iosLargeNavigationBarTitle()
        .accessibilityIdentifier("localNotificationDemoScreen")
        .task {
            await self.model.refreshStatus()
        }
    }
}

@MainActor
@Observable
final class LocalNotificationDemoModel {
    private let scheduler: any LocalNotificationScheduling

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var statusMessage: String?
    private(set) var isBusy = false

    init(scheduler: any LocalNotificationScheduling) {
        self.scheduler = scheduler
    }

    var isDenied: Bool {
        self.authorizationStatus == .denied
    }

    var statusLabel: String {
        switch self.authorizationStatus {
        case .authorized: "Authorized"
        case .denied: "Denied"
        case .notDetermined: "Not determined"
        case .provisional: "Provisional"
        case .ephemeral: "Ephemeral"
        @unknown default: "Unknown"
        }
    }

    func refreshStatus() async {
        self.authorizationStatus = await self.scheduler.authorizationStatus()
    }

    func requestPermission() async {
        self.isBusy = true
        defer { self.isBusy = false }
        do {
            let granted = try await self.scheduler.requestAuthorization()
            await self.refreshStatus()
            self.statusMessage = granted
                ? String(localized: "Permission granted.")
                : String(localized: "Permission not granted.")
        } catch {
            self.statusMessage = String(localized: "Permission request failed.")
        }
    }

    func scheduleReminder(delaySeconds: TimeInterval) async {
        self.isBusy = true
        defer { self.isBusy = false }
        await self.refreshStatus()
        guard !self.isDenied else {
            self.statusMessage = String(localized: "Cannot schedule while permission is denied.")
            return
        }
        do {
            try await self.scheduler.scheduleStaleFeedReminder(delaySeconds: delaySeconds)
            self.statusMessage = String(localized: "Scheduled local reminder.")
        } catch {
            self.statusMessage = String(localized: "Schedule failed.")
        }
    }

    func cancelReminder() async {
        self.isBusy = true
        defer { self.isBusy = false }
        await self.scheduler.cancelStaleFeedReminder()
        self.statusMessage = String(localized: "Cancelled pending/delivered reminder.")
    }
}

#Preview("Local notification demo") {
    NavigationStack {
        LocalNotificationDemoView(scheduler: PreviewLocalNotificationScheduler())
    }
}

@MainActor
private final class PreviewLocalNotificationScheduler: LocalNotificationScheduling {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await Task.yield()
        return .authorized
    }

    func requestAuthorization() async throws -> Bool {
        await Task.yield()
        return true
    }

    func scheduleStaleFeedReminder(delaySeconds _: TimeInterval) async throws {
        await Task.yield()
    }

    func cancelStaleFeedReminder() async {
        await Task.yield()
    }
}
