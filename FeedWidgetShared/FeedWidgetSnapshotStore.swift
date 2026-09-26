//
//  FeedWidgetSnapshotStore.swift
//  FeedWidgetShared
//
//  Atomic App Group read/write for Feed widget snapshots.
//  Foundation-only — no SwiftUI / Domain / Presentation imports.
//

import Foundation

nonisolated enum FeedWidgetSnapshotStore {
    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Container URL for the App Group, or `nil` when unavailable (Simulator /
    /// unsigned / missing entitlement).
    ///
    /// Pass `containerURLOverride` in unit tests to exercise write/load without
    /// a real App Group container.
    static func containerURL(
        fileManager: FileManager = .default,
        suiteName: String = FeedWidgetAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) -> URL? {
        if let containerURLOverride {
            return containerURLOverride
        }
        return fileManager.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    static func snapshotFileURL(
        fileManager: FileManager = .default,
        suiteName: String = FeedWidgetAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) -> URL? {
        self.containerURL(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        )?
            .appendingPathComponent(FeedWidgetAppGroup.fileName, isDirectory: false)
    }

    /// Atomically write snapshot (temp file + replace).
    static func write(
        _ snapshot: FeedWidgetSnapshot,
        fileManager: FileManager = .default,
        suiteName: String = FeedWidgetAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) throws {
        guard let directory = containerURL(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        ) else {
            throw FeedWidgetSnapshotStoreError.containerUnavailable
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(FeedWidgetAppGroup.fileName, isDirectory: false)
        let data = try jsonEncoder.encode(snapshot)
        let temporary = directory.appendingPathComponent(
            ".\(FeedWidgetAppGroup.fileName).tmp-\(UUID().uuidString)",
            isDirectory: false
        )
        try data.write(to: temporary, options: .atomic)
        if fileManager.fileExists(atPath: destination.path) {
            _ = try fileManager.replaceItemAt(destination, withItemAt: temporary)
        } else {
            try fileManager.moveItem(at: temporary, to: destination)
        }
    }

    /// Read + classify snapshot for widget / host-bridge honesty.
    static func loadState(
        now: Date = Date(),
        fileManager: FileManager = .default,
        suiteName: String = FeedWidgetAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) -> FeedWidgetSnapshotState {
        guard let fileURL = snapshotFileURL(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        ) else {
            return .unavailable
        }
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .absent
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try jsonDecoder.decode(FeedWidgetSnapshot.self, from: data)
            guard snapshot.schemaVersion == FeedWidgetSnapshot.currentVersion else {
                return .corrupt
            }
            if let ttl = snapshot.cacheTTLSeconds {
                let age = now.timeIntervalSince(snapshot.writtenAt)
                if age > ttl {
                    return .expired(snapshot)
                }
            }
            return .ok(snapshot)
        } catch {
            return .corrupt
        }
    }
}

nonisolated enum FeedWidgetSnapshotStoreError: Error, Equatable, Sendable {
    case containerUnavailable
}

/// App-owned publish hook. Default is no-op so unit tests stay App Group–free.
protocol FeedWidgetSnapshotPublishing: Sendable {
    func publish(_ snapshot: FeedWidgetSnapshot)
}

nonisolated struct NoOpFeedWidgetSnapshotPublisher: FeedWidgetSnapshotPublishing {
    func publish(_ snapshot: FeedWidgetSnapshot) {
        // Intentionally empty — tests and in-memory demos must not touch App Group.
        _ = snapshot
    }
}
