//
//  AppModelContainer.swift
//  superDemoApp
//

import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = make(
        isStoredInMemoryOnly: AppLaunchConfiguration.isUITesting
    )

    /// Builds the app SwiftData container. Falls back to an in-memory store when
    /// the preferred configuration cannot be created (corrupt store / schema mismatch).
    static func make(
        isStoredInMemoryOnly: Bool,
        diagnostics: ReleaseDiagnosticsReporting = ReleaseDiagnostics.shared
    ) -> ModelContainer {
        let schema = Schema([
            Item.self,
            CachedFeedPost.self,
        ])

        let preferred = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        do {
            return try ModelContainer(for: schema, configurations: [preferred])
        } catch {
            diagnostics.releaseCheckFailed(
                ReleaseDiagnosticCheck(
                    name: "model-container",
                    metadata: [
                        "preferredInMemory": String(isStoredInMemoryOnly),
                        "fallback": "in-memory",
                    ]
                ),
                reason: String(describing: error)
            )

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
                        reason: "In-memory fallback also failed: \(error)"
                    )
                )
                // Last resort: empty schema-less memory container is not viable
                // with required models; rethrow as fatal after diagnostics.
                fatalError("Could not create ModelContainer even in memory: \(error)")
            }
        }
    }
}
