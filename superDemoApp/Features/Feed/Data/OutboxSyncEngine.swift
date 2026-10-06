//
//  OutboxSyncEngine.swift
//  superDemoApp
//

import Foundation

/// Flushes the persistent outbox with crash-safe status transitions.
///
/// Triggers: connectivity regain, app foreground (`requestFlush`), and manual
/// retry. FIFO per `entityKey`; coalescing happens at enqueue time.
actor OutboxSyncEngine: OutboxSyncing {
    private let outbox: OutboxStoreBox
    private let remote: BookmarkRemoteClient
    private let bookmarkMutator: BookmarkLocalMutatorBox
    private let backoff: OutboxBackoffPolicy
    private let clock: OutboxClock
    private let connectivity: ConnectivityMonitoring

    private var isFlushing = false
    private var pendingFlush = false
    private var started = false

    init(
        outbox: OutboxStoreBox,
        remote: BookmarkRemoteClient,
        bookmarkMutator: BookmarkLocalMutatorBox,
        backoff: OutboxBackoffPolicy = OutboxBackoffPolicy(),
        clock: OutboxClock = SystemOutboxClock(),
        connectivity: ConnectivityMonitoring
    ) {
        self.outbox = outbox
        self.remote = remote
        self.bookmarkMutator = bookmarkMutator
        self.backoff = backoff
        self.clock = clock
        self.connectivity = connectivity
    }

    func start() async {
        guard !self.started else { return }
        self.started = true
        try? await self.outbox.recoverInFlightAsPending()
        self.connectivity.start { [weak self] connected in
            guard let self, connected else { return }
            Task { await self.requestFlush() }
        }
        await self.requestFlush()
    }

    func stop() {
        self.connectivity.stop()
        self.started = false
    }

    func requestFlush() async {
        if self.isFlushing {
            self.pendingFlush = true
            return
        }
        self.isFlushing = true
        defer {
            self.isFlushing = false
            if self.pendingFlush {
                self.pendingFlush = false
                Task { await self.requestFlush() }
            }
        }

        guard self.connectivity.isConnected else { return }

        do {
            try await self.flushReadyEntries()
        } catch is CancellationError {
            // Cooperative cancel — leave entries pending without attempt bumps.
        } catch {
            // Unexpected store errors; next trigger retries.
        }
    }

    private func flushReadyEntries() async throws {
        let now = self.clock.now()
        let ready = try await self.outbox.readyPending(now: now)

        var blockedEntities = Set<String>()

        for entry in ready {
            try Task.checkCancellation()
            if blockedEntities.contains(entry.entityKey) {
                continue
            }
            blockedEntities.insert(entry.entityKey)
            await self.process(entry: entry)
        }
    }

    private func process(entry: OutboxEntrySnapshot) async {
        do {
            try await self.outbox.markInFlight(id: entry.id)
        } catch {
            return
        }

        do {
            try await self.send(entry: entry)
            try await self.outbox.markCompletedAndRemove(id: entry.id)
        } catch is CancellationError {
            try? await self.outbox.markPendingAfterCancellation(id: entry.id)
        } catch let error as BookmarkRemoteError {
            await self.handleRemoteError(error, entry: entry)
        } catch {
            await self.handleRetryableFailure(
                entry: entry,
                message: String(describing: error)
            )
        }
    }

    private func send(entry: OutboxEntrySnapshot) async throws {
        guard let payload = entry.bookmarkPayload else {
            throw BookmarkRemoteError.decodingFailed
        }
        switch entry.operationKind {
        case .bookmarkSet:
            let remoteID = try await self.remote.setBookmark(
                postID: payload.postID,
                idempotencyKey: entry.idempotencyKey
            )
            try await self.bookmarkMutator.markSynced(
                postID: payload.postID,
                isBookmarked: true,
                remoteBookmarkID: remoteID
            )
        case .bookmarkClear:
            let remoteID = await self.bookmarkMutator.remoteBookmarkID(for: payload.postID)
            try await self.remote.clearBookmark(
                postID: payload.postID,
                remoteBookmarkID: remoteID,
                idempotencyKey: entry.idempotencyKey
            )
            try await self.bookmarkMutator.markSynced(
                postID: payload.postID,
                isBookmarked: false,
                remoteBookmarkID: nil
            )
        }
    }

    private func handleRemoteError(_ error: BookmarkRemoteError, entry: OutboxEntrySnapshot) async {
        switch error {
        case .conflict:
            let postID = entry.bookmarkPayload?.postID ?? 0
            let serverBookmarked = !entry.operationKind.desiredBookmarked
            try? await self.bookmarkMutator.applyServerWin(
                postID: postID,
                isBookmarked: serverBookmarked,
                message: "Conflict (HTTP 409/412) — server wins"
            )
            try? await self.outbox.markFailed(
                id: entry.id,
                attemptCount: entry.attemptCount,
                lastError: "Conflict (HTTP 409/412) — server wins"
            )
        case let .httpStatus(code) where (400 ..< 500).contains(code) && code != 408 && code != 429:
            try? await self.outbox.markFailed(
                id: entry.id,
                attemptCount: entry.attemptCount + 1,
                lastError: "HTTP \(code)"
            )
            if let postID = entry.bookmarkPayload?.postID {
                try? await self.bookmarkMutator.markFailed(postID: postID, message: "HTTP \(code)")
            }
        case .httpStatus, .transport, .decodingFailed:
            await self.handleRetryableFailure(entry: entry, message: String(describing: error))
        }
    }

    private func handleRetryableFailure(entry: OutboxEntrySnapshot, message: String) async {
        let nextAttempts = entry.attemptCount + 1
        if self.backoff.hasExhaustedAttempts(nextAttempts) {
            try? await self.outbox.markFailed(
                id: entry.id,
                attemptCount: nextAttempts,
                lastError: message
            )
            if let postID = entry.bookmarkPayload?.postID {
                try? await self.bookmarkMutator.markFailed(postID: postID, message: message)
            }
            return
        }
        let delay = self.backoff.delay(afterAttemptCount: nextAttempts)
        let nextAt = self.clock.now().addingTimeInterval(delay)
        try? await self.outbox.markPendingForRetry(
            id: entry.id,
            attemptCount: nextAttempts,
            nextAttemptAt: nextAt,
            lastError: message
        )
        if let postID = entry.bookmarkPayload?.postID {
            try? await self.bookmarkMutator.markPending(postID: postID, message: message)
        }
    }
}

@MainActor
protocol BookmarkLocalMutating: AnyObject {
    func remoteBookmarkID(for postID: Int) -> Int?
    func markSynced(postID: Int, isBookmarked: Bool, remoteBookmarkID: Int?) throws
    func markFailed(postID: Int, message: String) throws
    func markPending(postID: Int, message: String?) throws
    func applyServerWin(postID: Int, isBookmarked: Bool, message: String) throws
}

final class BookmarkLocalMutatorBox: @unchecked Sendable {
    @MainActor private let mutator: BookmarkLocalMutating

    @MainActor
    init(_ mutator: BookmarkLocalMutating) {
        self.mutator = mutator
    }

    func remoteBookmarkID(for postID: Int) async -> Int? {
        await MainActor.run { self.mutator.remoteBookmarkID(for: postID) }
    }

    func markSynced(postID: Int, isBookmarked: Bool, remoteBookmarkID: Int?) async throws {
        try await MainActor.run {
            try self.mutator.markSynced(
                postID: postID,
                isBookmarked: isBookmarked,
                remoteBookmarkID: remoteBookmarkID
            )
        }
    }

    func markFailed(postID: Int, message: String) async throws {
        try await MainActor.run {
            try self.mutator.markFailed(postID: postID, message: message)
        }
    }

    func markPending(postID: Int, message: String?) async throws {
        try await MainActor.run {
            try self.mutator.markPending(postID: postID, message: message)
        }
    }

    func applyServerWin(postID: Int, isBookmarked: Bool, message: String) async throws {
        try await MainActor.run {
            try self.mutator.applyServerWin(
                postID: postID,
                isBookmarked: isBookmarked,
                message: message
            )
        }
    }
}
