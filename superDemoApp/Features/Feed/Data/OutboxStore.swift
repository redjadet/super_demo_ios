//
//  OutboxStore.swift
//  superDemoApp
//

import Foundation
import SwiftData

@MainActor
protocol OutboxStoring: AnyObject {
    func performTransaction(_ changes: () throws -> Void) throws
    func claimPending(id: UUID, now: Date) throws -> OutboxEntrySnapshot?
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
    private var isInTransaction = false

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

    /// Bookmark and queue changes share one context and one durable commit.
    /// On failure, rollback also removes unsaved optimistic values.
    func performTransaction(_ changes: () throws -> Void) throws {
        if self.isInTransaction {
            try changes()
            return
        }
        self.isInTransaction = true
        defer { self.isInTransaction = false }
        do {
            try changes()
            try self.saveContext(self.context)
        } catch {
            self.context.rollback()
            throw error
        }
    }

    func readyPending(now: Date) throws -> [OutboxEntrySnapshot] {
        var seenEntities = Set<String>()
        return try self.snapshots(forEntityKey: nil).filter { entry in
            // A failed, in-flight, or backing-off head blocks its successors.
            guard seenEntities.insert(entry.entityKey).inserted else { return false }
            return entry.status == .pending && entry.nextAttemptAt <= now
        }
    }

    /// Atomically revalidate a snapshot before sending: a user may have
    /// coalesced it away while the actor was suspended on a previous request.
    func claimPending(id: UUID, now: Date) throws -> OutboxEntrySnapshot? {
        guard let snapshot = try self.readyPending(now: now).first(where: { $0.id == id }) else {
            return nil
        }
        try self.markInFlight(id: id)
        return snapshot
    }

    func insert(
        kind: OutboxOperationKind,
        payload: BookmarkOutboxPayload,
        idempotencyKey: String,
        createdAt: Date
    ) throws -> OutboxEntrySnapshot {
        // Preserve enqueue order even when the clock repeats or moves backward.
        let previousDate = try self.snapshots(forEntityKey: payload.entityKey).last?.createdAt
        let orderedDate = previousDate.map { previousDate in
            max(createdAt, previousDate.addingTimeInterval(0.000_001))
        } ?? createdAt
        let data = try JSONEncoder().encode(payload)
        let entry = OutboxEntry(
            idempotencyKey: idempotencyKey,
            operationType: kind.rawValue,
            entityKey: payload.entityKey,
            payload: data,
            createdAt: orderedDate,
            nextAttemptAt: createdAt,
            status: .pending
        )
        self.context.insert(entry)
        try self.persistChanges()
        return entry.toSnapshot()
    }

    func remove(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }
        let descriptor = FetchDescriptor<OutboxEntry>()
        let entries = try self.context.fetch(descriptor).filter { ids.contains($0.id) }
        for entry in entries {
            self.context.delete(entry)
        }
        try self.persistChanges()
    }

    func markInFlight(id: UUID) throws {
        guard let entry = try self.entry(id: id) else { return }
        entry.status = .inFlight
        entry.lastError = nil
        try self.persistChanges()
    }

    func markPendingAfterCancellation(id: UUID) throws {
        guard let entry = try self.entry(id: id) else { return }
        entry.status = .pending
        try self.persistChanges()
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
        try self.persistChanges()
    }

    func markFailed(id: UUID, attemptCount: Int, lastError: String) throws {
        guard let entry = try self.entry(id: id) else { return }
        entry.status = .failed
        entry.attemptCount = attemptCount
        entry.lastError = lastError
        try self.persistChanges()
    }

    func markCompletedAndRemove(id: UUID) throws {
        guard let entry = try self.entry(id: id) else { return }
        self.context.delete(entry)
        try self.persistChanges()
    }

    func recoverInFlightAsPending() throws {
        let descriptor = FetchDescriptor<OutboxEntry>()
        let entries = try self.context.fetch(descriptor).filter { $0.status == .inFlight }
        for entry in entries {
            entry.status = .pending
        }
        if !entries.isEmpty {
            try self.persistChanges()
        }
    }

    func failedCount() throws -> Int {
        let descriptor = FetchDescriptor<OutboxEntry>()
        return try self.context.fetch(descriptor).filter { $0.status == .failed }.count
    }

    private func persistChanges() throws {
        guard !self.isInTransaction else { return }
        do {
            try self.saveContext(self.context)
        } catch {
            self.context.rollback()
            throw error
        }
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

    func claimPending(id: UUID, now: Date) async throws -> OutboxEntrySnapshot? {
        try await MainActor.run { try self.store.claimPending(id: id, now: now) }
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
