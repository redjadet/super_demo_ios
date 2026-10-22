//
//  CompositeProductionReadinessRepository.swift
//  superDemoApp
//

import Foundation

/// Merges local sample readiness with a live Remote API probe.
///
/// Sample and remote loads are independent, so they run in a throwing
/// `TaskGroup`. Parent cancel cancels both children; remote cancel still
/// rethrows (no soft-fail warning row).
struct CompositeProductionReadinessRepository: ProductionReadinessRepository {
    private let sample: any ProductionReadinessRepository
    private let remoteHealth: any RemoteAPIHealthLoading
    private let remoteEndpoint: URL
    private let diagnostics: ReleaseDiagnosticsReporting
    private let now: @Sendable () -> Date

    init(
        sample: some ProductionReadinessRepository,
        remoteHealth: some RemoteAPIHealthLoading,
        remoteEndpoint: URL,
        diagnostics: ReleaseDiagnosticsReporting = ReleaseDiagnostics.shared,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.sample = sample
        self.remoteHealth = remoteHealth
        self.remoteEndpoint = remoteEndpoint
        self.diagnostics = diagnostics
        self.now = now
    }

    func loadSnapshot() async throws -> ProductionReadinessSnapshot {
        try await withThrowingTaskGroup(of: LoadPart.self) { group in
            group.addTask {
                try .sample(await self.sample.loadSnapshot())
            }
            group.addTask {
                try .remote(await self.loadRemoteHealthEntry())
            }

            var sampleSnapshot: ProductionReadinessSnapshot?
            var remoteEntry: APIHealthCheck?

            for try await part in group {
                switch part {
                case let .sample(snapshot):
                    sampleSnapshot = snapshot
                case let .remote(entry):
                    remoteEntry = entry
                }
            }

            guard let sampleSnapshot, let remoteEntry else {
                // TaskGroup completed without both parts — treat as cancelled
                // rather than inventing a partial Dashboard snapshot.
                throw CancellationError()
            }

            return ProductionReadinessSnapshot(
                modules: sampleSnapshot.modules,
                apiHealth: [remoteEntry] + sampleSnapshot.apiHealth,
                checklist: sampleSnapshot.checklist,
                risks: sampleSnapshot.risks
            )
        }
    }

    private func loadRemoteHealthEntry() async throws -> APIHealthCheck {
        let check = ReleaseDiagnosticCheck(
            name: "remote-api-health",
            metadata: ["endpoint": self.remoteEndpoint.path()]
        )
        do {
            let entry = try await self.remoteHealth.loadHealthCheck()
            self.diagnostics.releaseCheckPassed(check)
            return entry
        } catch is CancellationError {
            // Cancel is not a Remote API warning — keep OI cancel honesty.
            throw CancellationError()
        } catch APIError.cancelled {
            throw CancellationError()
        } catch {
            self.diagnostics.releaseCheckFailed(check, reason: String(describing: error))
            return APIHealthCheck(
                id: "remote-api",
                name: String(localized: "Remote API"),
                endpoint: self.remoteEndpoint.path(),
                status: .warning,
                latencyMilliseconds: 0,
                lastChecked: self.now(),
                isLiveProbe: true
            )
        }
    }
}

private enum LoadPart: Sendable {
    case sample(ProductionReadinessSnapshot)
    case remote(APIHealthCheck)
}
