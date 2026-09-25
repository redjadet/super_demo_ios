//
//  HostBridgeMessage.swift
//  superDemoApp
//
//  Platform-channel–shaped host bridge messages (no Flutter SDK).
//

import Foundation

/// Wire contract version for host ↔ native messages.
enum HostBridgeContract {
    static let version = 1
    static let feedCacheStatusMethod = "feed.cacheStatus"
}

/// Typed error codes returned on the wire (no Presentation types).
enum HostBridgeErrorCode: String, Codable, Sendable, Equatable, Error {
    case malformedJSON
    case unsupportedMethod
    case versionMismatch
    case cancelled
    case unavailable
}

struct HostBridgeRequest: Equatable, Sendable {
    var schemaVersion: Int
    var method: String
    var id: String
}

struct FeedCacheStatusResult: Codable, Equatable, Sendable {
    var postCount: Int
    var isStale: Bool
    var cacheAgeSeconds: Int?
    /// `"snapshot"` | `"repository"` | `"unavailable"`
    var source: String
}

enum HostBridgeResponse: Equatable, Sendable {
    case ok(id: String, schemaVersion: Int, result: FeedCacheStatusResult)
    case error(id: String?, schemaVersion: Int, code: HostBridgeErrorCode, message: String)
}
