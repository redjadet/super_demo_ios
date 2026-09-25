//
//  LocalNotificationDemoTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
import UserNotifications
@testable import superDemoApp

@MainActor
private final class LocalNotificationSchedulerSpy: LocalNotificationScheduling {
    var status: UNAuthorizationStatus = .notDetermined
    var grantPermission = true
    var scheduleCount = 0
    var cancelCount = 0
    var lastDelay: TimeInterval?
    var scheduleError: Error?

    func authorizationStatus() async -> UNAuthorizationStatus {
        await Task.yield()
        return self.status
    }

    func requestAuthorization() async throws -> Bool {
        await Task.yield()
        if self.grantPermission {
            self.status = .authorized
        } else {
            self.status = .denied
        }
        return self.grantPermission
    }

    func scheduleStaleFeedReminder(delaySeconds: TimeInterval) async throws {
        await Task.yield()
        if let scheduleError {
            throw scheduleError
        }
        self.scheduleCount += 1
        self.lastDelay = delaySeconds
    }

    func cancelStaleFeedReminder() async {
        await Task.yield()
        self.cancelCount += 1
    }
}

@Suite("Local notification demo")
struct LocalNotificationDemoTests {
    @Test
    @MainActor
    func requestPermissionUpdatesStatusWhenGranted() async {
        let spy = LocalNotificationSchedulerSpy()
        spy.grantPermission = true
        let model = LocalNotificationDemoModel(scheduler: spy)

        await model.requestPermission()

        #expect(model.authorizationStatus == .authorized)
        #expect(model.isDenied == false)
        #expect(model.statusMessage == "Permission granted.")
    }

    @Test
    @MainActor
    func requestPermissionRecordsDenialHonestly() async {
        let spy = LocalNotificationSchedulerSpy()
        spy.grantPermission = false
        let model = LocalNotificationDemoModel(scheduler: spy)

        await model.requestPermission()

        #expect(model.authorizationStatus == .denied)
        #expect(model.isDenied)
        #expect(model.statusMessage == "Permission not granted.")
    }

    @Test
    @MainActor
    func scheduleIsBlockedWhenDenied() async {
        let spy = LocalNotificationSchedulerSpy()
        spy.status = .denied
        let model = LocalNotificationDemoModel(scheduler: spy)

        await model.scheduleReminder(delaySeconds: 5)

        #expect(spy.scheduleCount == 0)
        #expect(model.statusMessage == "Cannot schedule while permission is denied.")
    }

    @Test
    @MainActor
    func scheduleAndCancelInvokeScheduler() async {
        let spy = LocalNotificationSchedulerSpy()
        spy.status = .authorized
        let model = LocalNotificationDemoModel(scheduler: spy)

        await model.scheduleReminder(delaySeconds: 5)
        #expect(spy.scheduleCount == 1)
        #expect(spy.lastDelay == 5)
        #expect(model.statusMessage == "Scheduled local reminder.")

        await model.cancelReminder()
        #expect(spy.cancelCount == 1)
        #expect(model.statusMessage == "Cancelled pending/delivered reminder.")
    }
}
