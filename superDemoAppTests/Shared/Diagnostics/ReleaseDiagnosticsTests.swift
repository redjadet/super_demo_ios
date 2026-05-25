//
//  ReleaseDiagnosticsTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@MainActor
@Suite("Release diagnostics")
struct ReleaseDiagnosticsTests {
    @Test
    func forwardsFailuresToCrashMonitorAdapter() {
        let crashMonitor = RecordingCrashMonitor()
        let diagnostics = ReleaseDiagnostics(crashMonitor: crashMonitor)

        diagnostics.releaseCheckFailed(
            ReleaseDiagnosticCheck(name: "signing", metadata: ["lane": "beta"]),
            reason: "missing profile"
        )
        diagnostics.deviceOnlyFailure(
            DeviceOnlyFailure(area: "push", reason: "token registration failed")
        )

        let failures = crashMonitor.failures()
        #expect(failures == [
            CrashMonitorFailure(
                source: "release-checks",
                reason: "signing: missing profile",
                metadata: ["lane": "beta"]
            ),
            CrashMonitorFailure(
                source: "device-only-failures",
                reason: "push: token registration failed",
                metadata: [:]
            ),
        ])
    }
}

private final class RecordingCrashMonitor: CrashMonitoring, @unchecked Sendable {
    private let lock = NSLock()
    private var recordedFailures: [CrashMonitorFailure] = []

    func recordNonFatal(_ failure: CrashMonitorFailure) {
        self.lock.lock()
        self.recordedFailures.append(failure)
        self.lock.unlock()
    }

    func failures() -> [CrashMonitorFailure] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.recordedFailures
    }
}
