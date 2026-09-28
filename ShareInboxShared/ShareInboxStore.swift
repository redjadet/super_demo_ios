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

    /// Quarantine sibling written when inbox JSON is unreadable / unsupported.
    nonisolated static let quarantineFileName = "\(ShareInboxAppGroup.fileName).corrupt"

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

    static func quarantineFileURL(
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) -> URL? {
        self.containerURL(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        )?
            .appendingPathComponent(self.quarantineFileName, isDirectory: false)
    }

    /// Append one entry (coordinated load → append → atomic write). Caps at 20 newest.
    /// Corrupt / unsupported payloads are quarantined; append starts a fresh inbox
    /// without silently destroying the unreadable bytes.
    static func append(
        _ entry: ShareInboxEntry,
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil,
        maxEntries: Int = 20
    ) throws {
        try self.coordinate(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        ) {
            var payload: ShareInboxPayload
            switch self.loadStateUnlocked(
                fileManager: fileManager,
                suiteName: suiteName,
                containerURLOverride: containerURLOverride
            ) {
            case let .ok(existing):
                payload = existing
            case .absent, .unavailable:
                payload = ShareInboxPayload(entries: [])
            case .corrupt:
                try self.quarantineCorruptInbox(
                    fileManager: fileManager,
                    suiteName: suiteName,
                    containerURLOverride: containerURLOverride
                )
                payload = ShareInboxPayload(entries: [])
            }
            payload.entries.insert(entry, at: 0)
            if payload.entries.count > maxEntries {
                payload.entries = Array(payload.entries.prefix(maxEntries))
            }
            try self.writeUnlocked(
                payload,
                fileManager: fileManager,
                suiteName: suiteName,
                containerURLOverride: containerURLOverride
            )
        }
    }

    /// Atomically write full payload (temp file + replace), under file coordination.
    static func write(
        _ payload: ShareInboxPayload,
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) throws {
        try self.coordinate(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        ) {
            try self.writeUnlocked(
                payload,
                fileManager: fileManager,
                suiteName: suiteName,
                containerURLOverride: containerURLOverride
            )
        }
    }

    static func loadState(
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) -> ShareInboxLoadState {
        var result: ShareInboxLoadState = .unavailable
        do {
            try self.coordinate(
                fileManager: fileManager,
                suiteName: suiteName,
                containerURLOverride: containerURLOverride
            ) {
                result = self.loadStateUnlocked(
                    fileManager: fileManager,
                    suiteName: suiteName,
                    containerURLOverride: containerURLOverride
                )
            }
        } catch {
            return .unavailable
        }
        return result
    }

    /// Clear inbox after reviewer “import” or demo reset (coordinated vs append).
    static func clear(
        fileManager: FileManager = .default,
        suiteName: String = ShareInboxAppGroup.identifier,
        containerURLOverride: URL? = nil
    ) throws {
        try self.coordinate(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        ) {
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

    // MARK: - Coordination

    private static func coordinate(
        fileManager: FileManager,
        suiteName: String,
        containerURLOverride: URL?,
        body: () throws -> Void
    ) throws {
        guard let fileURL = inboxFileURL(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        ) else {
            throw ShareInboxStoreError.containerUnavailable
        }
        var coordinationError: NSError?
        var bodyError: Error?
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(writingItemAt: fileURL, options: [], error: &coordinationError) { _ in
            do {
                try body()
            } catch {
                bodyError = error
            }
        }
        if let coordinationError {
            throw coordinationError
        }
        if let bodyError {
            throw bodyError
        }
    }

    private static func loadStateUnlocked(
        fileManager: FileManager,
        suiteName: String,
        containerURLOverride: URL?
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

    private static func writeUnlocked(
        _ payload: ShareInboxPayload,
        fileManager: FileManager,
        suiteName: String,
        containerURLOverride: URL?
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

    /// Moves unreadable inbox bytes aside so append can start fresh without wiping evidence.
    private static func quarantineCorruptInbox(
        fileManager: FileManager,
        suiteName: String,
        containerURLOverride: URL?
    ) throws {
        guard let source = inboxFileURL(
            fileManager: fileManager,
            suiteName: suiteName,
            containerURLOverride: containerURLOverride
        ),
            let destination = quarantineFileURL(
                fileManager: fileManager,
                suiteName: suiteName,
                containerURLOverride: containerURLOverride
            )
        else {
            throw ShareInboxStoreError.containerUnavailable
        }
        guard fileManager.fileExists(atPath: source.path) else { return }
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: source, to: destination)
    }
}

nonisolated enum ShareInboxStoreError: Error, Equatable, Sendable {
    case containerUnavailable
}
