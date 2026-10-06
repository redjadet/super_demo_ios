//
//  SwiftDataBookmarkRepository.swift
//  superDemoApp
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataBookmarkRepository: BookmarkRepository, BookmarkLocalMutating {
    private let context: ModelContext
    private let outbox: OutboxStoring
    private let clock: OutboxClock
    private let makeIdempotencyKey: () -> String
    private let saveContext: (ModelContext) throws -> Void
    private let onEnqueued: (@Sendable () -> Void)?

    init(
        context: ModelContext,
        outbox: OutboxStoring,
        clock: OutboxClock = SystemOutboxClock(),
        saveContext: @escaping (ModelContext) throws -> Void = { try $0.save() },
        makeIdempotencyKey: @escaping () -> String = { UUID().uuidString },
        onEnqueued: (@Sendable () -> Void)? = nil
    ) {
        self.context = context
        self.outbox = outbox
        self.clock = clock
        self.makeIdempotencyKey = makeIdempotencyKey
        self.saveContext = saveContext
        self.onEnqueued = onEnqueued
    }

    func bookmark(forPostID postID: Int) throws -> PostBookmark {
        if let record = try self.record(postID: postID) {
            return record.toEntity()
        }
        return PostBookmark(postID: postID, isBookmarked: false, syncStatus: .synced)
    }

    func allBookmarks() throws -> [PostBookmark] {
        let descriptor = FetchDescriptor<BookmarkedPost>(
            sortBy: [SortDescriptor(\.postID, order: .forward)]
        )
        return try self.context.fetch(descriptor).map { $0.toEntity() }
    }

    func setBookmarked(_ isBookmarked: Bool, postID: Int) throws -> PostBookmark {
        let existingRecord = try self.record(postID: postID)
        let syncedBaseline = existingRecord?.lastSyncedIsBookmarked ?? false

        let record = existingRecord ?? BookmarkedPost(
            postID: postID,
            isBookmarked: isBookmarked,
            lastSyncedIsBookmarked: false,
            syncStatus: .pending,
            updatedAt: self.clock.now()
        )
        if existingRecord == nil {
            self.context.insert(record)
        }
        record.isBookmarked = isBookmarked
        record.syncStatus = .pending
        record.lastError = nil
        record.updatedAt = self.clock.now()
        try self.saveContext(self.context)

        let entityKey = BookmarkOutboxPayload.entityKey(postID: postID)
        let existing = try self.outbox.snapshots(forEntityKey: entityKey)
        let plan = OutboxCoalescer.plan(
            postID: postID,
            existing: existing,
            syncedOrInFlightBaseline: syncedBaseline,
            desiredBookmarked: isBookmarked,
            makeIdempotencyKey: self.makeIdempotencyKey
        )
        try self.outbox.remove(ids: plan.removeIDs)
        if let enqueue = plan.enqueue {
            _ = try self.outbox.insert(
                kind: enqueue.kind,
                payload: enqueue.payload,
                idempotencyKey: enqueue.idempotencyKey,
                createdAt: self.clock.now()
            )
            record.syncStatus = .pending
        } else if existing.contains(where: { $0.status == .inFlight }) {
            record.syncStatus = .pending
        } else {
            record.syncStatus = .synced
            record.lastError = nil
            record.isBookmarked = syncedBaseline
            record.lastSyncedIsBookmarked = syncedBaseline
        }
        try self.saveContext(self.context)
        self.onEnqueued?()
        return record.toEntity()
    }

    func retryFailedMutations(forPostID postID: Int?) throws {
        let entityKey = postID.map { BookmarkOutboxPayload.entityKey(postID: $0) }
        let snapshots = try self.outbox.snapshots(forEntityKey: entityKey)
        let failed = snapshots.filter { $0.status == .failed }
        let now = self.clock.now()
        for entry in failed {
            try self.outbox.markPendingForRetry(
                id: entry.id,
                attemptCount: entry.attemptCount,
                nextAttemptAt: now,
                lastError: entry.lastError
            )
            if let payload = entry.bookmarkPayload,
               let record = try self.record(postID: payload.postID)
            {
                record.syncStatus = .pending
                record.lastError = nil
            }
        }
        try self.saveContext(self.context)
        self.onEnqueued?()
    }

    func failedMutationCount() throws -> Int {
        try self.outbox.failedCount()
    }

    // MARK: - BookmarkLocalMutating

    func remoteBookmarkID(for postID: Int) -> Int? {
        try? self.record(postID: postID)?.remoteBookmarkID
    }

    func markSynced(postID: Int, isBookmarked: Bool, remoteBookmarkID: Int?) throws {
        let existing = try self.record(postID: postID)
        let record = existing ?? BookmarkedPost(
            postID: postID,
            isBookmarked: isBookmarked,
            lastSyncedIsBookmarked: isBookmarked,
            syncStatus: .synced
        )
        if existing == nil {
            self.context.insert(record)
        }
        record.isBookmarked = isBookmarked
        record.lastSyncedIsBookmarked = isBookmarked
        record.syncStatus = .synced
        record.lastError = nil
        record.remoteBookmarkID = isBookmarked ? remoteBookmarkID : nil
        record.updatedAt = self.clock.now()
        try self.saveContext(self.context)
    }

    func markFailed(postID: Int, message: String) throws {
        guard let record = try self.record(postID: postID) else { return }
        record.syncStatus = .failed
        record.lastError = message
        record.updatedAt = self.clock.now()
        try self.saveContext(self.context)
    }

    func markPending(postID: Int, message: String?) throws {
        guard let record = try self.record(postID: postID) else { return }
        record.syncStatus = .pending
        record.lastError = message
        record.updatedAt = self.clock.now()
        try self.saveContext(self.context)
    }

    func applyServerWin(postID: Int, isBookmarked: Bool, message: String) throws {
        let existing = try self.record(postID: postID)
        let record = existing ?? BookmarkedPost(
            postID: postID,
            isBookmarked: isBookmarked,
            lastSyncedIsBookmarked: isBookmarked,
            syncStatus: .failed
        )
        if existing == nil {
            self.context.insert(record)
        }
        record.isBookmarked = isBookmarked
        record.lastSyncedIsBookmarked = isBookmarked
        record.syncStatus = .failed
        record.lastError = message
        record.updatedAt = self.clock.now()
        try self.saveContext(self.context)
    }

    private func record(postID: Int) throws -> BookmarkedPost? {
        let descriptor = FetchDescriptor<BookmarkedPost>()
        return try self.context.fetch(descriptor).first { $0.postID == postID }
    }
}
