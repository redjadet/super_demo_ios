//
//  AppModelContainer.swift
//  superDemoApp
//

import Foundation
import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = make(
        isStoredInMemoryOnly: AppLaunchConfiguration.isUITesting
    )

    /// Builds the app SwiftData container.
    ///
    /// Recovery order when the preferred store cannot load (corrupt file / schema mismatch):
    /// 1. Delete on-disk store + SQLite sidecars and recreate on disk
    /// 2. Fall back to an in-memory store
    static func make(
        isStoredInMemoryOnly: Bool,
        storeURL: URL? = nil,
        diagnostics: ReleaseDiagnosticsReporting = ReleaseDiagnostics.shared,
        fileManager: FileManager = .default
    ) -> ModelContainer {
        let schema = Schema([
            Item.self,
            CachedFeedPost.self,
        ])

        let preferred = self.configuration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            storeURL: storeURL
        )

        do {
            return try ModelContainer(for: schema, configurations: [preferred])
        } catch {
            let preferredError = error

            if !isStoredInMemoryOnly {
                self.removePersistentStoreFiles(at: preferred.url, fileManager: fileManager)
                do {
                    let recreated = try ModelContainer(for: schema, configurations: [preferred])
                    diagnostics.releaseCheckFailed(
                        ReleaseDiagnosticCheck(
                            name: "model-container",
                            metadata: [
                                "preferredInMemory": "false",
                                "fallback": "recreated-store",
                            ]
                        ),
                        reason: String(describing: preferredError)
                    )
                    return recreated
                } catch {
                    diagnostics.releaseCheckFailed(
                        ReleaseDiagnosticCheck(
                            name: "model-container",
                            metadata: [
                                "preferredInMemory": "false",
                                "fallback": "in-memory",
                                "recreateFailed": "true",
                            ]
                        ),
                        reason: String(describing: preferredError)
                    )

                    return self.makeInMemoryContainer(
                        schema: schema,
                        diagnostics: diagnostics,
                        priorError: error
                    )
                }
            }

            diagnostics.releaseCheckFailed(
                ReleaseDiagnosticCheck(
                    name: "model-container",
                    metadata: [
                        "preferredInMemory": "true",
                        "fallback": "in-memory",
                    ]
                ),
                reason: String(describing: preferredError)
            )

            return self.makeInMemoryContainer(
                schema: schema,
                diagnostics: diagnostics,
                priorError: preferredError
            )
        }
    }

    /// Removes a SwiftData / SQLite store URL and its `-shm` / `-wal` sidecars.
    static func removePersistentStoreFiles(
        at url: URL,
        fileManager: FileManager = .default
    ) {
        let path = url.path
        for suffix in ["", "-shm", "-wal"] {
            let candidate = URL(fileURLWithPath: path + suffix)
            guard fileManager.fileExists(atPath: candidate.path) else { continue }
            try? fileManager.removeItem(at: candidate)
        }
    }

    private static func configuration(
        schema: Schema,
        isStoredInMemoryOnly: Bool,
        storeURL: URL?
    ) -> ModelConfiguration {
        if isStoredInMemoryOnly {
            return ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        }
        if let storeURL {
            return ModelConfiguration(schema: schema, url: storeURL)
        }
        return ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    }

    private static func makeInMemoryContainer(
        schema: Schema,
        diagnostics: ReleaseDiagnosticsReporting,
        priorError: Error
    ) -> ModelContainer {
        let fallback = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [fallback])
        } catch {
            diagnostics.deviceOnlyFailure(
                DeviceOnlyFailure(
                    area: "model-container",
                    reason: "In-memory fallback also failed: \(error); prior: \(priorError)"
                )
            )
            fatalError("Could not create ModelContainer even in memory: \(error)")
        }
    }
}
