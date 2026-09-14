//
//  AppModelContainerTests.swift
//  superDemoAppTests
//

import Foundation
import SwiftData
import Testing
@testable import superDemoApp

@Suite("App model container")
struct AppModelContainerTests {
    @Test
    @MainActor
    func makeInMemoryContainerSucceedsWithoutDiagnosticsFailure() {
        let diagnostics = RecordingReleaseDiagnostics()

        let container = AppModelContainer.make(
            isStoredInMemoryOnly: true,
            diagnostics: diagnostics
        )

        #expect(container.configurations.count == 1)
        #expect(diagnostics.failedChecks().isEmpty)
        #expect(diagnostics.deviceFailures().isEmpty)
    }
}

private final class RecordingReleaseDiagnostics: ReleaseDiagnosticsReporting, @unchecked Sendable {
    private let lock = NSLock()
    private var failed: [ReleaseDiagnosticCheck] = []
    private var devices: [DeviceOnlyFailure] = []

    func releaseCheckPassed(_: ReleaseDiagnosticCheck) {}

    func releaseCheckFailed(_ check: ReleaseDiagnosticCheck, reason _: String) {
        self.lock.lock()
        self.failed.append(check)
        self.lock.unlock()
    }

    func deviceOnlyFailure(_ failure: DeviceOnlyFailure) {
        self.lock.lock()
        self.devices.append(failure)
        self.lock.unlock()
    }

    func failedChecks() -> [ReleaseDiagnosticCheck] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.failed
    }

    func deviceFailures() -> [DeviceOnlyFailure] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.devices
    }
}
