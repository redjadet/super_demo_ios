//
//  CompositeProductionReadinessRepository.swift
//  superDemoApp
//

import Foundation

struct CompositeProductionReadinessRepository: ProductionReadinessRepository {
    private let sample: SampleProductionReadinessRepository
    private let remoteHealth: RemoteAPIHealthRepository
    private let remoteEndpoint: URL
    private let now: @Sendable () -> Date

    init(
        sample: SampleProductionReadinessRepository,
        remoteHealth: RemoteAPIHealthRepository,
        remoteEndpoint: URL,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.sample = sample
        self.remoteHealth = remoteHealth
        self.remoteEndpoint = remoteEndpoint
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
        do {
            return try await self.remoteHealth.loadHealthCheck()
        } catch {
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
