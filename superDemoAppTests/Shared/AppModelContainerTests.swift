//
//  AppModelContainerTests.swift
//  superDemoAppTests
//

import Foundation
import SwiftData
import Testing
@testable import superDemoApp

@Suite("App model container")
struct AppModelContainerTests {
    @Test
    @MainActor
    func makeInMemoryContainerSucceedsWithoutDiagnosticsFailure() {
        let diagnostics = RecordingReleaseDiagnostics()

        let container = AppModelContainer.make(
            isStoredInMemoryOnly: true,
            diagnostics: diagnostics
        )

        #expect(container.configurations.count == 1)
        #expect(diagnostics.failedChecks().isEmpty)
        #expect(diagnostics.deviceFailures().isEmpty)
    }

    @Test
    func removePersistentStoreFilesDeletesStoreAndSidecars() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppModelContainerWipe-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appendingPathComponent("default.store")
        let shmURL = URL(fileURLWithPath: storeURL.path + "-shm")
        let walURL = URL(fileURLWithPath: storeURL.path + "-wal")
        try Data("store".utf8).write(to: storeURL)
        try Data("shm".utf8).write(to: shmURL)
        try Data("wal".utf8).write(to: walURL)

        AppModelContainer.removePersistentStoreFiles(at: storeURL)

        #expect(FileManager.default.fileExists(atPath: storeURL.path) == false)
        #expect(FileManager.default.fileExists(atPath: shmURL.path) == false)
        #expect(FileManager.default.fileExists(atPath: walURL.path) == false)
    }

    @Test
    @MainActor
    func makeOnDiskRecreatesStoreAfterIncompatibleFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppModelContainerRecreate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appendingPathComponent("default.store")
        try Data("not-a-valid-swiftdata-store".utf8).write(to: storeURL)

        let diagnostics = RecordingReleaseDiagnostics()
        let container = AppModelContainer.make(
            isStoredInMemoryOnly: false,
            storeURL: storeURL,
            diagnostics: diagnostics
        )

        #expect(container.configurations.count == 1)
        #expect(container.configurations.contains { !$0.isStoredInMemoryOnly })

        let failed = diagnostics.failedChecks()
        #expect(failed.count == 1)
        #expect(failed.first?.name == "model-container")
        #expect(failed.first?.metadata["fallback"] == "recreated-store")
        #expect(diagnostics.deviceFailures().isEmpty)
    }
}

private final class RecordingReleaseDiagnostics: ReleaseDiagnosticsReporting, @unchecked Sendable {
    private let lock = NSLock()
    private var failed: [ReleaseDiagnosticCheck] = []
    private var devices: [DeviceOnlyFailure] = []

    func releaseCheckPassed(_: ReleaseDiagnosticCheck) { /* no-op */ }

    func releaseCheckFailed(_ check: ReleaseDiagnosticCheck, reason _: String) {
        self.lock.lock()
        self.failed.append(check)
        self.lock.unlock()
    }

    func deviceOnlyFailure(_ failure: DeviceOnlyFailure) {
        self.lock.lock()
        self.devices.append(failure)
        self.lock.unlock()
    }

    func failedChecks() -> [ReleaseDiagnosticCheck] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.failed
    }

    func deviceFailures() -> [DeviceOnlyFailure] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.devices
    }
}
