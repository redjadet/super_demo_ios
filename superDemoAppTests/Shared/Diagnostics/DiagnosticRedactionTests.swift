//
//  DiagnosticRedactionTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Diagnostic redaction")
struct DiagnosticRedactionTests {
    @Test
    func redactsSensitiveMetadataKeysAndBearerText() {
        let sanitized = DiagnosticRedaction.sanitizeMetadata([
            "lane": "beta",
            "authorization": "Bearer super-secret-token",
            "note": "Authorization Bearer abc.def.ghi leaked",
        ])

        #expect(sanitized["lane"] == "beta")
        #expect(sanitized["authorization"] == "<redacted>")
        #expect(sanitized["note"]?.contains("Bearer <redacted>") == true)
        #expect(sanitized["note"]?.contains("abc.def.ghi") != true)
    }
}

@MainActor
@Suite("Release diagnostics redaction")
struct ReleaseDiagnosticsRedactionTests {
    @Test
    func stripsSensitiveSamplesBeforeCrashMonitor() {
        let crashMonitor = RecordingCrashMonitor()
        let diagnostics = ReleaseDiagnostics(crashMonitor: crashMonitor)

        diagnostics.releaseCheckFailed(
            ReleaseDiagnosticCheck(
                name: "auth-probe",
                metadata: [
                    "token": "raw-access-token-value",
                    "lane": "beta",
                ]
            ),
            reason: "refresh failed with Bearer leak-me-now"
        )

        let failures = crashMonitor.failures()
        #expect(failures.count == 1)
        let failure = failures[0]
        #expect(failure.metadata["token"] == "<redacted>")
        #expect(failure.metadata["lane"] == "beta")
        #expect(failure.reason.contains("Bearer <redacted>"))
        #expect(failure.reason.contains("leak-me-now") != true)
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
