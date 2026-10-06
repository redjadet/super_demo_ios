//
//  OutboxCoalescer.swift
//  superDemoApp
//

import Foundation

/// Pure coalescing rules for bookmark outbox ops (FIFO-safe per entity).
///
/// - Repeated toggles collapse to the final desired bookmark state.
/// - Set then clear (from an unbookmarked baseline) cancels out.
/// - In-flight rows are never deleted; a newer desired state is queued after.
nonisolated enum OutboxCoalescer {
    struct Plan: Equatable, Sendable {
        /// Pending / failed entry IDs to remove before inserting `enqueue`.
        var removeIDs: [UUID]
        /// When non-nil, enqueue this operation after removals.
        var enqueue: EnqueueSpec?
    }

    struct EnqueueSpec: Equatable, Sendable {
        let kind: OutboxOperationKind
        let payload: BookmarkOutboxPayload
        let idempotencyKey: String
    }

    /// Builds a coalesce plan for a bookmark mutation.
    ///
    /// - Parameters:
    ///   - postID: Feed post id.
    ///   - existing: Non-completed entries for the entity (any status).
    ///   - syncedOrInFlightBaseline: Local bookmark before this toggle, or the
    ///     desired state of an in-flight op when one exists (caller may pass
    ///     either; this method recomputes baseline from in-flight when present).
    ///   - desiredBookmarked: Desired end state after the user action.
    ///   - makeIdempotencyKey: Factory for a fresh key when enqueueing.
    static func plan(
        postID: Int,
        existing: [OutboxEntrySnapshot],
        syncedOrInFlightBaseline: Bool,
        desiredBookmarked: Bool,
        makeIdempotencyKey: () -> String = { UUID().uuidString }
    ) -> Plan {
        let inFlight = existing.filter { entry in entry.status == .inFlight }
        let replaceable = existing.filter { entry in
            entry.status == .pending || entry.status == .failed
        }

        let baseline: Bool
        if let inFlightOp = inFlight.max(by: { lhs, rhs in lhs.createdAt < rhs.createdAt }),
           let payload = inFlightOp.bookmarkPayload
        {
            baseline = payload.desiredBookmarked
        } else {
            baseline = syncedOrInFlightBaseline
        }

        if desiredBookmarked == baseline {
            return Plan(removeIDs: replaceable.map(\.id), enqueue: nil)
        }

        return Plan(
            removeIDs: replaceable.map(\.id),
            enqueue: EnqueueSpec(
                kind: .bookmark(desiredBookmarked: desiredBookmarked),
                payload: BookmarkOutboxPayload(
                    postID: postID,
                    desiredBookmarked: desiredBookmarked
                ),
                idempotencyKey: makeIdempotencyKey()
            )
        )
    }
}
