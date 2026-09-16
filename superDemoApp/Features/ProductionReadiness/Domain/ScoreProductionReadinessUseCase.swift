//
//  ScoreProductionReadinessUseCase.swift
//  superDemoApp
//

nonisolated struct ScoreProductionReadinessUseCase {
    func callAsFunction(snapshot: ProductionReadinessSnapshot) -> Int {
        let statusScores = snapshot.modules.map(\.status.score)
            + snapshot.apiHealth.map(\.status.score)
            + snapshot.risks.map(\.status.score)
        let checklistScores = snapshot.checklist.map { $0.isComplete ? 100 : 40 }
        let scores = statusScores + checklistScores
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / scores.count
    }
}
