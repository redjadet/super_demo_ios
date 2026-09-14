//
//  ProductionReadinessTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Production readiness")
struct ProductionReadinessTests {
    @Test
    func scoreReflectsModulesRisksAndChecklist() {
        let snapshot = ProductionReadinessSnapshot(
            modules: [
                FeatureModule(id: "a", name: "A", layerBoundary: "Domain", owner: "iOS", status: .healthy, summary: ""),
            ],
            apiHealth: [
                APIHealthCheck(
                    id: "api",
                    name: "API",
                    endpoint: "/",
                    status: .warning,
                    latencyMilliseconds: 100,
                    lastChecked: Date()
                ),
            ],
            checklist: [
                ReleaseChecklistItem(id: "done", title: "Done", detail: "", isComplete: true, owner: "iOS"),
                ReleaseChecklistItem(id: "todo", title: "Todo", detail: "", isComplete: false, owner: "QA"),
            ],
            risks: [
                ProductionRisk(
                    id: "risk",
                    title: "Risk",
                    detail: "",
                    mitigation: "",
                    status: .blocked,
                    legacyCode: "RISK"
                ),
            ],
            designTokens: [],
            aiFeedbackNotes: []
        )

        let score = ScoreProductionReadinessUseCase()(snapshot: snapshot)

        #expect(score == 66)
    }

    @Test
    func sampleSnapshotClaimsOSLogCrashMonitorIsWired() async throws {
        let snapshot = try await SampleProductionReadinessRepository().loadSnapshot()
        let observability = try #require(snapshot.checklist.first { $0.id == "observability" })
        let uiKit = try #require(snapshot.modules.first { $0.id == "ui-kit" })

        #expect(observability.title == "OSLog release diagnostics are ready")
        #expect(observability.detail.contains("OSLogCrashMonitor"))
        #expect(observability.isComplete == true)
        #expect(uiKit.status == .healthy)
    }

    @Test
    @MainActor
    func cancellationDoesNotReplaceFeatureStateWithFailure() async {
        let model = ProductionReadinessFeatureModel(
            loadSnapshot: LoadProductionReadinessSnapshotUseCase(repository: CancellingReadinessRepository())
        )

        await model.refreshAndWait()

        #expect(model.state == .loading)
    }

    @Test
    @MainActor
    func cancelRefreshRestoresPriorContent() async {
        let repository = ReadinessModelRepositorySpy()
        let model = ProductionReadinessFeatureModel(
            loadSnapshot: LoadProductionReadinessSnapshotUseCase(repository: repository)
        )
        await model.refreshAndWait()

        repository.delayNanoseconds = 500_000_000
        model.refresh()
        try? await Task.sleep(nanoseconds: 50_000_000)
        model.cancelRefresh()

        if case let .content(_, score) = model.state {
            #expect(score == 66)
        } else {
            Issue.record("Expected restored content after cancel")
        }
    }

    @Test
    @MainActor
    func cancelledRetryRestoresFailedState() async {
        let repository = ReadinessModelRepositorySpy()
        repository.shouldThrow = true
        let model = ProductionReadinessFeatureModel(
            loadSnapshot: LoadProductionReadinessSnapshotUseCase(repository: repository)
        )
        await model.refreshAndWait()

        guard case .failed = model.state else {
            Issue.record("Expected failed state before retry")
            return
        }

        repository.delayNanoseconds = 500_000_000
        let retry = Task {
            await model.refreshAndWait()
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        retry.cancel()
        _ = await retry.result

        if case .failed = model.state {
            return
        }
        Issue.record("Expected failed state after cancelling retry, not a stuck spinner")
    }

    @Test
    @MainActor
    func refreshKeepsExistingContentVisible() async {
        let repository = ReadinessModelRepositorySpy()
        let model = ProductionReadinessFeatureModel(
            loadSnapshot: LoadProductionReadinessSnapshotUseCase(repository: repository)
        )
        await model.refreshAndWait()

        repository.delayNanoseconds = 500_000_000
        model.refresh()
        try? await Task.sleep(nanoseconds: 50_000_000)

        if case let .content(_, score) = model.state {
            #expect(score == 66)
        } else {
            Issue.record("Expected existing content to remain visible during refresh")
        }

        model.cancelRefresh()
    }

    @Test
    func apiErrorMapsToDomainDisplayMessage() {
        let display = ProductionReadinessDisplayError(APIError.httpStatus(500))

        #expect(display.message == "API health check failed. Review server status before release.")
    }
}

@MainActor
private final class ReadinessModelRepositorySpy: ProductionReadinessRepository {
    var delayNanoseconds: UInt64 = 0
    var shouldThrow = false

    func loadSnapshot() async throws -> ProductionReadinessSnapshot {
        if self.delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: self.delayNanoseconds)
        } else {
            await Task.yield()
        }
        if self.shouldThrow {
            throw APIError.httpStatus(503)
        }
        return ProductionReadinessSnapshot(
            modules: [
                FeatureModule(id: "a", name: "A", layerBoundary: "Domain", owner: "iOS", status: .healthy, summary: ""),
            ],
            apiHealth: [
                APIHealthCheck(
                    id: "api",
                    name: "API",
                    endpoint: "/",
                    status: .warning,
                    latencyMilliseconds: 100,
                    lastChecked: Date()
                ),
            ],
            checklist: [
                ReleaseChecklistItem(id: "done", title: "Done", detail: "", isComplete: true, owner: "iOS"),
                ReleaseChecklistItem(id: "todo", title: "Todo", detail: "", isComplete: false, owner: "QA"),
            ],
            risks: [
                ProductionRisk(
                    id: "risk",
                    title: "Risk",
                    detail: "",
                    mitigation: "",
                    status: .blocked,
                    legacyCode: "RISK"
                ),
            ],
            designTokens: [],
            aiFeedbackNotes: []
        )
    }
}

private struct CancellingReadinessRepository: ProductionReadinessRepository {
    func loadSnapshot() async throws -> ProductionReadinessSnapshot {
        await Task.yield()
        throw CancellationError()
    }
}
