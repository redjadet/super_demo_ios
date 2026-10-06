//
//  ImmediateSuccessBookmarkRemoteClient.swift
//  superDemoApp
//

import Foundation

/// Deterministic remote for UITesting / offline demos (no live HTTP).
struct ImmediateSuccessBookmarkRemoteClient: BookmarkRemoteClient {
    func setBookmark(postID: Int, idempotencyKey _: String) async throws -> Int? {
        postID + 10_000
    }

    func clearBookmark(postID _: Int, remoteBookmarkID _: Int?, idempotencyKey _: String) async throws {
        // no-op success
    }
}
