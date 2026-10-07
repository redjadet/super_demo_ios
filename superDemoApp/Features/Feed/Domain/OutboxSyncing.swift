//
//  OutboxSyncing.swift
//  superDemoApp
//

import Foundation

/// Domain-facing outbox flush control (implemented by `OutboxSyncEngine`).
protocol OutboxSyncing: Sendable {
    func start() async
    func requestFlush() async
}
