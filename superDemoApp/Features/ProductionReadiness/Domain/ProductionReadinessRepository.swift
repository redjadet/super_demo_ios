//
//  ProductionReadinessRepository.swift
//  superDemoApp
//

protocol ProductionReadinessRepository: Sendable {
    func loadSnapshot() async throws -> ProductionReadinessSnapshot
}
