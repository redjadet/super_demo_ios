//
//  OutboxEntry.swift
//  superDemoApp
//

import Foundation
import SwiftData

@Model
final class OutboxEntry {
    @Attribute(.unique)
    var id: UUID
    var idempotencyKey: String
    var operationType: String
    var entityKey: String
    var payload: Data
    var createdAt: Date
    var attemptCount: Int
    var nextAttemptAt: Date
    var statusRaw: String
    var lastError: String?

    init(
        idempotencyKey: String,
        operationType: String,
        entityKey: String,
        payload: Data,
        createdAt: Date,
        nextAttemptAt: Date,
        id: UUID = UUID(),
        attemptCount: Int = 0,
        status: OutboxEntryStatus = .pending,
        lastError: String? = nil
    ) {
        self.id = id
        self.idempotencyKey = idempotencyKey
        self.operationType = operationType
        self.entityKey = entityKey
        self.payload = payload
        self.createdAt = createdAt
        self.attemptCount = attemptCount
        self.nextAttemptAt = nextAttemptAt
        self.statusRaw = status.rawValue
        self.lastError = lastError
    }

    var status: OutboxEntryStatus {
        get { OutboxEntryStatus(rawValue: self.statusRaw) ?? .pending }
        set { self.statusRaw = newValue.rawValue }
    }

    var operationKind: OutboxOperationKind? {
        OutboxOperationKind(rawValue: self.operationType)
    }

    func toSnapshot() -> OutboxEntrySnapshot {
        OutboxEntrySnapshot(
            id: self.id,
            idempotencyKey: self.idempotencyKey,
            operationKind: self.operationKind ?? .bookmarkSet,
            entityKey: self.entityKey,
            payload: self.payload,
            createdAt: self.createdAt,
            attemptCount: self.attemptCount,
            nextAttemptAt: self.nextAttemptAt,
            status: self.status,
            lastError: self.lastError
        )
    }
}
