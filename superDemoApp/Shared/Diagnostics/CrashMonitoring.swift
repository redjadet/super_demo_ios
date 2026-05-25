//
//  CrashMonitoring.swift
//  superDemoApp
//

import Foundation

protocol CrashMonitoring: Sendable {
    func recordNonFatal(_ failure: CrashMonitorFailure)
}

struct CrashMonitorFailure: Error, Equatable {
    let source: String
    let reason: String
    let metadata: [String: String]
}

struct NoopCrashMonitor: CrashMonitoring {
    func recordNonFatal(_: CrashMonitorFailure) {}
}
