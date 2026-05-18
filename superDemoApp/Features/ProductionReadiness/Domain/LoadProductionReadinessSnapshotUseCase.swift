//
//  LoadProductionReadinessSnapshotUseCase.swift
//  superDemoApp
//

struct LoadProductionReadinessSnapshotUseCase {
    private let repository: ProductionReadinessRepository

    init(repository: ProductionReadinessRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> ProductionReadinessSnapshot {
        try await self.repository.loadSnapshot()
    }
}
