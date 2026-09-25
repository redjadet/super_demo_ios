//
//  ReleaseDiagnostics.swift
//  superDemoApp
//

import Foundation
import os

nonisolated protocol ReleaseDiagnosticsReporting: Sendable {
    func releaseCheckPassed(_ check: ReleaseDiagnosticCheck)
    func releaseCheckFailed(_ check: ReleaseDiagnosticCheck, reason: String)
    func deviceOnlyFailure(_ failure: DeviceOnlyFailure)
}

nonisolated struct ReleaseDiagnosticCheck: Equatable {
    let name: String
    let metadata: [String: String]

    init(name: String, metadata: [String: String] = [:]) {
        self.name = name
        self.metadata = metadata
    }
}

nonisolated struct DeviceOnlyFailure: Equatable {
    let area: String
    let reason: String
    let metadata: [String: String]

    init(area: String, reason: String, metadata: [String: String] = [:]) {
        self.area = area
        self.reason = reason
        self.metadata = metadata
    }
}

nonisolated struct ReleaseDiagnostics: ReleaseDiagnosticsReporting {
    static let shared = Self()

    private let releaseChecksLogger: Logger
    private let deviceOnlyFailuresLogger: Logger
    private let crashMonitor: CrashMonitoring

    init(
        subsystem: String = "com.ilkersevim.superDemoApp",
        crashMonitor: CrashMonitoring = OSLogCrashMonitor()
    ) {
        self.releaseChecksLogger = Logger(subsystem: subsystem, category: "release-checks")
        self.deviceOnlyFailuresLogger = Logger(subsystem: subsystem, category: "device-only-failures")
        self.crashMonitor = crashMonitor
    }

    func releaseCheckPassed(_ check: ReleaseDiagnosticCheck) {
        let metadata = DiagnosticRedaction.sanitizeMetadata(check.metadata)
        self.releaseChecksLogger.info(
            "release check passed name=\(check.name, privacy: .public) metadata=\(Self.format(metadata), privacy: .public)"
        )
    }

    func releaseCheckFailed(_ check: ReleaseDiagnosticCheck, reason: String) {
        let safeReason = DiagnosticRedaction.sanitizeText(reason)
        let metadata = DiagnosticRedaction.sanitizeMetadata(check.metadata)
        self.releaseChecksLogger.error(
            "release check failed name=\(check.name, privacy: .public) reason=\(safeReason, privacy: .public) metadata=\(Self.format(metadata), privacy: .public)"
        )
        self.crashMonitor.recordNonFatal(
            CrashMonitorFailure(
                source: "release-checks",
                reason: "\(check.name): \(safeReason)",
                metadata: metadata
            )
        )
    }

    func deviceOnlyFailure(_ failure: DeviceOnlyFailure) {
        let safeReason = DiagnosticRedaction.sanitizeText(failure.reason)
        let metadata = DiagnosticRedaction.sanitizeMetadata(failure.metadata)
        self.deviceOnlyFailuresLogger.error(
            "device-only failure area=\(failure.area, privacy: .public) reason=\(safeReason, privacy: .public) metadata=\(Self.format(metadata), privacy: .public)"
        )
        self.crashMonitor.recordNonFatal(
            CrashMonitorFailure(
                source: "device-only-failures",
                reason: "\(failure.area): \(safeReason)",
                metadata: metadata
            )
        )
    }

    private static func format(_ metadata: [String: String]) -> String {
        guard metadata.isEmpty == false else { return "none" }
        return metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ",")
    }
}
