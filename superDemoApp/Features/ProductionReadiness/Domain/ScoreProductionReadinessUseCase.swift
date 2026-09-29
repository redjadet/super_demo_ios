//
//  ScoreProductionReadinessUseCase.swift
//  superDemoApp
//

nonisolated struct ScoreProductionReadinessUseCase {
    func callAsFunction(snapshot: ProductionReadinessSnapshot) -> Int {
        // When a live Remote API probe is present, exclude sample API rows from
        // the hero % so simulated Auth/Release/Push cannot inflate or dilute it.
        let liveAPI = snapshot.apiHealth.filter(\.isLiveProbe)
        let apiForScore = liveAPI.isEmpty ? snapshot.apiHealth : liveAPI
        let statusScores = snapshot.modules.map(\.status.score)
            + apiForScore.map(\.status.score)
            + snapshot.risks.map(\.status.score)
        let checklistScores = snapshot.checklist.map { $0.isComplete ? 100 : 40 }
        let scores = statusScores + checklistScores
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / scores.count
    }
}
