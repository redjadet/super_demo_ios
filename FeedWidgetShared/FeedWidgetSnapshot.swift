//
//  FeedWidgetSnapshot.swift
//  FeedWidgetShared
//
//  Versioned App Group DTO for Home Screen Feed widget.
//  Widget process is read-only; app owns writes.
//

import Foundation

/// App Group ID shared by the main app and Feed widget extension.
nonisolated enum FeedWidgetAppGroup {
    static let identifier = "group.com.ilkersevim.superDemoApp"
    static let widgetKind = "com.ilkersevim.superDemoApp.FeedWidget"
    static let fileName = "feed-widget-snapshot.json"
}

/// Versioned snapshot written atomically into the App Group container.
nonisolated struct FeedWidgetSnapshot: Codable, Equatable, Sendable {
    static let currentVersion = 1

    /// Wire format key remains `"v"` for the platform-channel-shaped contract.
    var schemaVersion: Int
    var writtenAt: Date
    var cacheTTLSeconds: TimeInterval?
    var isStale: Bool
    /// Full Feed cache size for host-bridge `postCount` (titles stay capped for UI).
    var postCount: Int
    var titles: [FeedWidgetSnapshotTitle]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "v"
        case writtenAt
        case cacheTTLSeconds
        case isStale
        case postCount
        case titles
    }

    nonisolated struct FeedWidgetSnapshotTitle: Codable, Equatable, Sendable {
        var id: Int
        var title: String
    }

    init(
        writtenAt: Date,
        cacheTTLSeconds: TimeInterval?,
        isStale: Bool,
        titles: [FeedWidgetSnapshotTitle],
        postCount: Int? = nil,
        schemaVersion: Int = Self.currentVersion
    ) {
        self.schemaVersion = schemaVersion
        self.writtenAt = writtenAt
        self.cacheTTLSeconds = cacheTTLSeconds
        self.isStale = isStale
        self.titles = titles
        self.postCount = postCount ?? titles.count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        self.writtenAt = try container.decode(Date.self, forKey: .writtenAt)
        self.cacheTTLSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .cacheTTLSeconds)
        self.isStale = try container.decode(Bool.self, forKey: .isStale)
        self.titles = try container.decode([FeedWidgetSnapshotTitle].self, forKey: .titles)
        // Pre-postCount snapshots: fall back to titles.count (widget-capped).
        self.postCount = try container.decodeIfPresent(Int.self, forKey: .postCount) ?? self.titles.count
    }
}

/// Honest widget render states (no invented “empty product” theater).
nonisolated enum FeedWidgetSnapshotState: Equatable, Sendable {
    case unavailable
    case absent
    case corrupt
    case expired(FeedWidgetSnapshot)
    case ok(FeedWidgetSnapshot)
}
