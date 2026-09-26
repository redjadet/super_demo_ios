//
//  ShareInboxPayload.swift
//  ShareInboxShared
//
//  Versioned App Group DTO for Share → Items inbox.
//  Extension writes; main app reads. Does **not** open SwiftData.
//

import Foundation

/// Reuses the same App Group as the Feed widget (single group ID).
nonisolated enum ShareInboxAppGroup {
    static let identifier = "group.com.ilkersevim.superDemoApp"
    static let fileName = "share-inbox.json"
}

/// One share handoff (URL and/or plain text).
nonisolated struct ShareInboxEntry: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var text: String?
    var urlString: String?
    var receivedAt: Date

    init(
        id: UUID = UUID(),
        text: String? = nil,
        urlString: String? = nil,
        receivedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.urlString = urlString
        self.receivedAt = receivedAt
    }

    /// Display line for Engineering demo / reviewer talk track.
    var displaySummary: String {
        if let urlString = self.urlString, !urlString.isEmpty {
            if let text = self.text, !text.isEmpty {
                return "\(text) — \(urlString)"
            }
            return urlString
        }
        return self.text ?? "(empty)"
    }
}

/// Versioned inbox written atomically into the App Group container.
nonisolated struct ShareInboxPayload: Codable, Equatable, Sendable {
    static let currentVersion = 1

    /// Wire format key remains `"v"` (same honesty pattern as Feed widget snapshot).
    var schemaVersion: Int
    var entries: [ShareInboxEntry]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "v"
        case entries
    }

    init(entries: [ShareInboxEntry], schemaVersion: Int = Self.currentVersion) {
        self.schemaVersion = schemaVersion
        self.entries = entries
    }
}

/// Honest load states for the main-app Engineering demo.
nonisolated enum ShareInboxLoadState: Equatable, Sendable {
    case unavailable
    case absent
    case corrupt
    case ok(ShareInboxPayload)
}
