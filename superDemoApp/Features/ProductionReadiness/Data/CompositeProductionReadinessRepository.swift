//
//  CompositeProductionReadinessRepository.swift
//  superDemoApp
//

import Foundation

struct CompositeProductionReadinessRepository: ProductionReadinessRepository {
    private let sample: SampleProductionReadinessRepository
    private let remoteHealth: RemoteAPIHealthRepository
    private let remoteEndpoint: URL
    private let diagnostics: ReleaseDiagnosticsReporting
    private let now: @Sendable () -> Date

    init(
        sample: SampleProductionReadinessRepository,
        remoteHealth: RemoteAPIHealthRepository,
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
        let snapshot = try await self.sample.loadSnapshot()
        let remoteEntry = await self.loadRemoteHealthEntry()
        return ProductionReadinessSnapshot(
            modules: snapshot.modules,
            apiHealth: [remoteEntry] + snapshot.apiHealth,
            checklist: snapshot.checklist,
            risks: snapshot.risks,
            designTokens: snapshot.designTokens,
            aiFeedbackNotes: snapshot.aiFeedbackNotes
        )
    }

    private func loadRemoteHealthEntry() async -> APIHealthCheck {
        let check = ReleaseDiagnosticCheck(
            name: "remote-api-health",
            metadata: ["endpoint": self.remoteEndpoint.path()]
        )
        do {
            let entry = try await self.remoteHealth.loadHealthCheck()
            self.diagnostics.releaseCheckPassed(check)
            return entry
        } catch {
            self.diagnostics.releaseCheckFailed(check, reason: String(describing: error))
            return APIHealthCheck(
                id: "remote-api",
                name: "Remote API",
                endpoint: self.remoteEndpoint.path(),
                status: .warning,
                latencyMilliseconds: 0,
                lastChecked: self.now()
            )
        }
    }
}
