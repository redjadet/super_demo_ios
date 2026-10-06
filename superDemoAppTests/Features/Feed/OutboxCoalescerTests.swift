//
//  OutboxCoalescerTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Outbox coalescer")
struct OutboxCoalescerTests {
    @Test
    func setThenClearCancelsOutFromUnbookmarkedBaseline() throws {
        let set = try Self.pending(kind: .bookmarkSet, postID: 1, key: "a")
        let plan = OutboxCoalescer.plan(
            postID: 1,
            existing: [set],
            syncedOrInFlightBaseline: false,
            desiredBookmarked: false
        ) { "b" }
        #expect(plan.removeIDs == [set.id])
        #expect(plan.enqueue == nil)
    }

    @Test
    func repeatedTogglesCollapseToFinalSet() throws {
        let clear = try Self.pending(kind: .bookmarkClear, postID: 2, key: "c1")
        let plan = OutboxCoalescer.plan(
            postID: 2,
            existing: [clear],
            syncedOrInFlightBaseline: true,
            desiredBookmarked: true
        ) { "final" }
        #expect(plan.removeIDs == [clear.id])
        #expect(plan.enqueue?.kind == .bookmarkSet)
        #expect(plan.enqueue?.idempotencyKey == "final")
    }

    @Test
    func inFlightIsPreservedWhenQueuingOpposite() throws {
        let inFlight = try Self.entry(kind: .bookmarkSet, postID: 3, key: "inf", status: .inFlight)
        let plan = OutboxCoalescer.plan(
            postID: 3,
            existing: [inFlight],
            syncedOrInFlightBaseline: false,
            desiredBookmarked: false
        ) { "after" }
        #expect(plan.removeIDs.isEmpty)
        #expect(plan.enqueue?.kind == .bookmarkClear)
    }

    private static func pending(
        kind: OutboxOperationKind,
        postID: Int,
        key: String
    ) throws -> OutboxEntrySnapshot {
        try self.entry(kind: kind, postID: postID, key: key, status: .pending)
    }

    private static func entry(
        kind: OutboxOperationKind,
        postID: Int,
        key: String,
        status: OutboxEntryStatus
    ) throws -> OutboxEntrySnapshot {
        let payload = BookmarkOutboxPayload(postID: postID, desiredBookmarked: kind.desiredBookmarked)
        let data = try JSONEncoder().encode(payload)
        return OutboxEntrySnapshot(
            id: UUID(),
            idempotencyKey: key,
            operationKind: kind,
            entityKey: payload.entityKey,
            payload: data,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            attemptCount: 0,
            nextAttemptAt: Date(timeIntervalSince1970: 1_700_000_000),
            status: status,
            lastError: nil
        )
    }
}
