//
//  CrashMonitoring.swift
//  superDemoApp
//

import Foundation
import os

nonisolated protocol CrashMonitoring: Sendable {
    func recordNonFatal(_ failure: CrashMonitorFailure)
}

nonisolated struct CrashMonitorFailure: Error, Equatable {
    let source: String
    let reason: String
    let metadata: [String: String]
}

nonisolated struct NoopCrashMonitor: CrashMonitoring {
    func recordNonFatal(_: CrashMonitorFailure) { /* no-op */ }
}

/// Lightweight OSLog-backed non-fatal recorder. Swap for a vendor SDK adapter in production.
nonisolated struct OSLogCrashMonitor: CrashMonitoring {
    private let logger: Logger

    init(subsystem: String = "com.ilkersevim.superDemoApp") {
        self.logger = Logger(subsystem: subsystem, category: "crash-monitor")
    }

    func recordNonFatal(_ failure: CrashMonitorFailure) {
        let safeReason = DiagnosticRedaction.sanitizeText(failure.reason)
        let metadata = Self.format(DiagnosticRedaction.sanitizeMetadata(failure.metadata))
        self.logger.error(
            "nonfatal source=\(failure.source, privacy: .public) reason=\(safeReason, privacy: .public) metadata=\(metadata, privacy: .public)"
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
