//
//  ProductionReadinessModels.swift
//  superDemoApp
//

import Foundation

nonisolated enum ReadinessStatus: String, CaseIterable {
    case healthy
    case warning
    case blocked

    var score: Int {
        switch self {
        case .healthy:
            100
        case .warning:
            65
        case .blocked:
            25
        }
    }
}

nonisolated struct FeatureModule: Identifiable, Equatable {
    let id: String
    let name: String
    let layerBoundary: String
    let owner: String
    let status: ReadinessStatus
    let summary: String
}

nonisolated struct APIHealthCheck: Identifiable, Equatable {
    let id: String
    let name: String
    let endpoint: String
    let status: ReadinessStatus
    let latencyMilliseconds: Int
    let lastChecked: Date
    /// Live network probe (composite Dashboard). Sample Auth/Release/Push rows
    /// stay `false` so the hero score does not mix simulated API into a live %.
    let isLiveProbe: Bool

    init(
        id: String,
        name: String,
        endpoint: String,
        status: ReadinessStatus,
        latencyMilliseconds: Int,
        lastChecked: Date,
        isLiveProbe: Bool = false
    ) {
        self.id = id
        self.name = name
        self.endpoint = endpoint
        self.status = status
        self.latencyMilliseconds = latencyMilliseconds
        self.lastChecked = lastChecked
        self.isLiveProbe = isLiveProbe
    }
}

nonisolated struct ReleaseChecklistItem: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let isComplete: Bool
    let owner: String
}

nonisolated struct ProductionRisk: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let mitigation: String
    let status: ReadinessStatus
    let legacyCode: String
}

nonisolated struct ProductionReadinessSnapshot: Equatable {
    let modules: [FeatureModule]
    let apiHealth: [APIHealthCheck]
    let checklist: [ReleaseChecklistItem]
    let risks: [ProductionRisk]
}
