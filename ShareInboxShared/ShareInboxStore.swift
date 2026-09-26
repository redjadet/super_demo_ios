//
//  ShareInboxStore.swift
//  ShareInboxShared
//
//  Atomic App Group read/write for Share → Items inbox.
//  Foundation-only — no SwiftUI / Domain / Presentation / SwiftData imports.
//

import Foundation

nonisolated enum ShareInboxStore {
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

    static func containerURL(
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) -> URL? {
        if let containerURLOverride {
            return containerURLOverride
        }
        return fileManager.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    static func inboxFileURL(
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) -> URL? {
        self.containerURL(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        )?
            .appendingPathComponent(ShareInboxAppGroup.fileName, isDirectory: false)
    }

    /// Append one entry (load → append → atomic write). Caps at 20 newest.
    static func append(
        _ entry: ShareInboxEntry,
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil,
        maxEntries: Int = 20
    ) throws {
        var payload: ShareInboxPayload
        switch self.loadState(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        ) {
        case let .ok(existing):
            payload = existing
        case .absent, .unavailable, .corrupt:
            payload = ShareInboxPayload(entries: [])
        }
        payload.entries.insert(entry, at: 0)
        if payload.entries.count > maxEntries {
            payload.entries = Array(payload.entries.prefix(maxEntries))
        }
        try self.write(
            payload,
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        )
    }

    /// Atomically write full payload (temp file + replace).
    static func write(
        _ payload: ShareInboxPayload,
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) throws {
        guard let directory = containerURL(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        ) else {
            throw ShareInboxStoreError.containerUnavailable
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(
            ShareInboxAppGroup.fileName,
            isDirectory: false
        )
        let data = try jsonEncoder.encode(payload)
        let temporary = directory.appendingPathComponent(
            ".\(ShareInboxAppGroup.fileName).tmp-\(UUID().uuidString)",
            isDirectory: false
        )
        defer {
            if fileManager.fileExists(atPath: temporary.path) {
                try? fileManager.removeItem(at: temporary)
            }
        }
        try data.write(to: temporary, options: .atomic)
        if fileManager.fileExists(atPath: destination.path) {
            _ = try fileManager.replaceItemAt(destination, withItemAt: temporary)
        } else {
            try fileManager.moveItem(at: temporary, to: destination)
        }
    }

    static func loadState(
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) -> ShareInboxLoadState {
        guard let fileURL = inboxFileURL(
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
            let payload = try jsonDecoder.decode(ShareInboxPayload.self, from: data)
            guard payload.schemaVersion == ShareInboxPayload.currentVersion else {
                return .corrupt
            }
            return .ok(payload)
        } catch {
            return .corrupt
        }
    }

    /// Clear inbox after reviewer “import” or demo reset.
    static func clear(
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) throws {
        guard let fileURL = inboxFileURL(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        ) else {
            throw ShareInboxStoreError.containerUnavailable
        }
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
}

nonisolated enum ShareInboxStoreError: Error, Equatable, Sendable {
    case containerUnavailable
}
