//
//  OutboxStore.swift
//  superDemoApp
//

import Foundation
import SwiftData

@MainActor
protocol OutboxStoring: AnyObject {
    func snapshots(forEntityKey entityKey: String?) throws -> [OutboxEntrySnapshot]
    func readyPending(now: Date) throws -> [OutboxEntrySnapshot]
    func insert(
        kind: OutboxOperationKind,
        payload: BookmarkOutboxPayload,
        idempotencyKey: String,
        createdAt: Date
    ) throws -> OutboxEntrySnapshot
    func remove(ids: [UUID]) throws
    func markInFlight(id: UUID) throws
    func markPendingAfterCancellation(id: UUID) throws
    func markPendingForRetry(
        id: UUID,
        attemptCount: Int,
        nextAttemptAt: Date,
        lastError: String?
    ) throws
    func markFailed(id: UUID, attemptCount: Int, lastError: String) throws
    func markCompletedAndRemove(id: UUID) throws
    func recoverInFlightAsPending() throws
    func failedCount() throws -> Int
}

@MainActor
final class SwiftDataOutboxStore: OutboxStoring {
    private let context: ModelContext
    private let saveContext: (ModelContext) throws -> Void

    init(
        context: ModelContext,
        saveContext: @escaping (ModelContext) throws -> Void = { try $0.save() }
    ) {
        self.context = context
        self.saveContext = saveContext
    }

    func snapshots(forEntityKey entityKey: String?) throws -> [OutboxEntrySnapshot] {
        var descriptor = FetchDescriptor<OutboxEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        if let entityKey {
            descriptor.predicate = #Predicate { $0.entityKey == entityKey }
        }
        return try self.context.fetch(descriptor)
            .filter { $0.status != .completed }
            .map { $0.toSnapshot() }
    }

    func readyPending(now: Date) throws -> [OutboxEntrySnapshot] {
        let descriptor = FetchDescriptor<OutboxEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try self.context.fetch(descriptor)
            .filter { entry in
                entry.status == .pending && entry.nextAttemptAt <= now
            }
            .map { $0.toSnapshot() }
    }

    func insert(
        kind: OutboxOperationKind,
        payload: BookmarkOutboxPayload,
        idempotencyKey: String,
        createdAt: Date
    ) throws -> OutboxEntrySnapshot {
        let data = try JSONEncoder().encode(payload)
        let entry = OutboxEntry(
            idempotencyKey: idempotencyKey,
            operationType: kind.rawValue,
            entityKey: payload.entityKey,
            payload: data,
            createdAt: createdAt,
            nextAttemptAt: createdAt,
            status: .pending
        )
        self.context.insert(entry)
        try self.saveContext(self.context)
        return entry.toSnapshot()
    }

    func remove(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }
        let descriptor = FetchDescriptor<OutboxEntry>()
        let entries = try self.context.fetch(descriptor).filter { ids.contains($0.id) }
        for entry in entries {
            self.context.delete(entry)
        }
        try self.saveContext(self.context)
    }

    func markInFlight(id: UUID) throws {
        guard let entry = try self.entry(id: id) else { return }
        entry.status = .inFlight
        entry.lastError = nil
        try self.saveContext(self.context)
    }

    func markPendingAfterCancellation(id: UUID) throws {
        guard let entry = try self.entry(id: id) else { return }
        entry.status = .pending
        try self.saveContext(self.context)
    }

    func markPendingForRetry(
        id: UUID,
        attemptCount: Int,
        nextAttemptAt: Date,
        lastError: String?
    ) throws {
        guard let entry = try self.entry(id: id) else { return }
        entry.status = .pending
        entry.attemptCount = attemptCount
        entry.nextAttemptAt = nextAttemptAt
        entry.lastError = lastError
        try self.saveContext(self.context)
    }

    func markFailed(id: UUID, attemptCount: Int, lastError: String) throws {
        guard let entry = try self.entry(id: id) else { return }
        entry.status = .failed
        entry.attemptCount = attemptCount
        entry.lastError = lastError
        try self.saveContext(self.context)
    }

    func markCompletedAndRemove(id: UUID) throws {
        guard let entry = try self.entry(id: id) else { return }
        self.context.delete(entry)
        try self.saveContext(self.context)
    }

    func recoverInFlightAsPending() throws {
        let descriptor = FetchDescriptor<OutboxEntry>()
        let entries = try self.context.fetch(descriptor).filter { $0.status == .inFlight }
        for entry in entries {
            entry.status = .pending
        }
        if !entries.isEmpty {
            try self.saveContext(self.context)
        }
    }

    func failedCount() throws -> Int {
        let descriptor = FetchDescriptor<OutboxEntry>()
        return try self.context.fetch(descriptor).filter { $0.status == .failed }.count
    }

    private func entry(id: UUID) throws -> OutboxEntry? {
        let descriptor = FetchDescriptor<OutboxEntry>()
        return try self.context.fetch(descriptor).first { $0.id == id }
    }
}

/// Sendable MainActor hop for `OutboxSyncEngine`.
final class OutboxStoreBox: @unchecked Sendable {
    @MainActor private let store: OutboxStoring

    @MainActor
    init(_ store: OutboxStoring) {
        self.store = store
    }

    func snapshots(forEntityKey entityKey: String?) async throws -> [OutboxEntrySnapshot] {
        try await MainActor.run { try self.store.snapshots(forEntityKey: entityKey) }
    }

    func readyPending(now: Date) async throws -> [OutboxEntrySnapshot] {
        try await MainActor.run { try self.store.readyPending(now: now) }
    }

    func markInFlight(id: UUID) async throws {
        try await MainActor.run { try self.store.markInFlight(id: id) }
    }

    func markPendingAfterCancellation(id: UUID) async throws {
        try await MainActor.run { try self.store.markPendingAfterCancellation(id: id) }
    }

    func markPendingForRetry(
        id: UUID,
        attemptCount: Int,
        nextAttemptAt: Date,
        lastError: String?
    ) async throws {
        try await MainActor.run {
            try self.store.markPendingForRetry(
                id: id,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError
            )
        }
    }

    func markFailed(id: UUID, attemptCount: Int, lastError: String) async throws {
        try await MainActor.run {
            try self.store.markFailed(id: id, attemptCount: attemptCount, lastError: lastError)
        }
    }

    func markCompletedAndRemove(id: UUID) async throws {
        try await MainActor.run { try self.store.markCompletedAndRemove(id: id) }
    }

    func recoverInFlightAsPending() async throws {
        try await MainActor.run { try self.store.recoverInFlightAsPending() }
    }
}
