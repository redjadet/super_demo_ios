//
//  BookmarkSyncStatus.swift
//  superDemoApp
//

import Foundation

/// Local sync indicator for an optimistic Feed bookmark mutation.
nonisolated enum BookmarkSyncStatus: String, Equatable, Sendable {
    case synced
    case pending
    case failed
}
