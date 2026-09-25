//
//  FeedWidgetSnapshot.swift
//  FeedWidgetShared
//
//  Versioned App Group DTO for Home Screen Feed widget.
//  Widget process is read-only; app owns writes.
//

import Foundation

/// App Group ID shared by the main app and Feed widget extension.
enum FeedWidgetAppGroup {
    static let identifier = "group.com.ilkersevim.superDemoApp"
    static let widgetKind = "com.ilkersevim.superDemoApp.FeedWidget"
    static let fileName = "feed-widget-snapshot.json"
}

/// Versioned snapshot written atomically into the App Group container.
struct FeedWidgetSnapshot: Codable, Equatable, Sendable {
    static let currentVersion = 1

    /// Wire format key remains `"v"` for the platform-channel-shaped contract.
    var schemaVersion: Int
    var writtenAt: Date
    var cacheTTLSeconds: TimeInterval?
    var isStale: Bool
    var titles: [FeedWidgetSnapshotTitle]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "v"
        case writtenAt
        case cacheTTLSeconds
        case isStale
        case titles
    }

    struct FeedWidgetSnapshotTitle: Codable, Equatable, Sendable {
        var id: Int
        var title: String
    }

    init(
        writtenAt: Date,
        cacheTTLSeconds: TimeInterval?,
        isStale: Bool,
        titles: [FeedWidgetSnapshotTitle],
        schemaVersion: Int = Self.currentVersion
    ) {
        self.schemaVersion = schemaVersion
        self.writtenAt = writtenAt
        self.cacheTTLSeconds = cacheTTLSeconds
        self.isStale = isStale
        self.titles = titles
    }
}

/// Honest widget render states (no invented “empty product” theater).
enum FeedWidgetSnapshotState: Equatable, Sendable {
    case unavailable
    case absent
    case corrupt
    case expired(FeedWidgetSnapshot)
    case ok(FeedWidgetSnapshot)
}
