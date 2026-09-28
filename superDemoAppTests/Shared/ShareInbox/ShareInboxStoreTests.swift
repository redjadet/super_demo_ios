//
//  ShareInboxStoreTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Share inbox store")
struct ShareInboxStoreTests {
    @Test
    func appendAndLoadRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("share-inbox-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let entry = ShareInboxEntry(
            text: "Hello",
            urlString: "https://example.com"
        )
        try ShareInboxStore.append(entry, containerURLOverride: directory)

        let state = ShareInboxStore.loadState(containerURLOverride: directory)
        guard case let .ok(payload) = state else {
            Issue.record("Expected ok payload, got \(state)")
            return
        }
        #expect(payload.schemaVersion == ShareInboxPayload.currentVersion)
        #expect(payload.entries.count == 1)
        #expect(payload.entries[0].text == "Hello")
        #expect(payload.entries[0].urlString == "https://example.com")
    }

    @Test
    func absentWhenFileMissing() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("share-inbox-absent-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let state = ShareInboxStore.loadState(containerURLOverride: directory)
        #expect(state == .absent)
    }

    @Test
    func corruptWhenJSONInvalid() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("share-inbox-corrupt-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent(ShareInboxAppGroup.fileName)
        try Data("not-json".utf8).write(to: fileURL)

        let state = ShareInboxStore.loadState(containerURLOverride: directory)
        #expect(state == .corrupt)
    }

    @Test
    func clearRemovesFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("share-inbox-clear-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try ShareInboxStore.append(
            ShareInboxEntry(text: "x"),
            containerURLOverride: directory
        )
        try ShareInboxStore.clear(containerURLOverride: directory)
        #expect(ShareInboxStore.loadState(containerURLOverride: directory) == .absent)
    }

    @Test
    func capsAtMaxEntries() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("share-inbox-cap-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        for index in 0 ..< 25 {
            try ShareInboxStore.append(
                ShareInboxEntry(text: "n\(index)"),
                containerURLOverride: directory,
                maxEntries: 20
            )
        }
        guard case let .ok(payload) = ShareInboxStore.loadState(containerURLOverride: directory) else {
            Issue.record("Expected ok")
            return
        }
        #expect(payload.entries.count == 20)
        #expect(payload.entries[0].text == "n24")
    }

    @Test
    func appendOnCorruptQuarantinesBytesInsteadOfWipingQuietly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("share-inbox-quarantine-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent(ShareInboxAppGroup.fileName)
        let corrupt = Data("not-json-keep-me".utf8)
        try corrupt.write(to: fileURL)

        try ShareInboxStore.append(
            ShareInboxEntry(text: "recovered"),
            containerURLOverride: directory
        )

        let quarantineURL = directory.appendingPathComponent(ShareInboxStore.quarantineFileName)
        #expect(FileManager.default.fileExists(atPath: quarantineURL.path))
        #expect(try Data(contentsOf: quarantineURL) == corrupt)

        guard case let .ok(payload) = ShareInboxStore.loadState(containerURLOverride: directory) else {
            Issue.record("Expected fresh ok inbox after quarantine")
            return
        }
        #expect(payload.entries.count == 1)
        #expect(payload.entries[0].text == "recovered")
    }
}
