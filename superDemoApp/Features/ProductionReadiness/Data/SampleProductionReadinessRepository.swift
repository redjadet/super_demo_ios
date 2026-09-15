//
//  SampleProductionReadinessRepository.swift
//  superDemoApp
//

import Foundation

struct SampleProductionReadinessRepository: ProductionReadinessRepository {
    private let riskCodeFormatter: LegacyRiskCodeFormatter
    private let now: @Sendable () -> Date

    init(
        riskCodeFormatter: LegacyRiskCodeFormatter = LegacyRiskCodeFormatter(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.riskCodeFormatter = riskCodeFormatter
        self.now = now
    }

    func loadSnapshot() async throws -> ProductionReadinessSnapshot {
        await Task.yield()
        let risks = self.makeRisks()
        return ProductionReadinessSnapshot(
            modules: self.makeModules(),
            apiHealth: self.makeAPIHealth(),
            checklist: self.makeChecklist(),
            risks: risks
        )
    }

    private func makeModules() -> [FeatureModule] {
        [
            FeatureModule(
                id: "architecture",
                name: "Architecture",
                layerBoundary: "Presentation -> Domain <- Data",
                owner: "Mobile Platform",
                status: .healthy,
                summary: "Feature ownership and layer boundaries are documented for release triage."
            ),
            FeatureModule(
                id: "networking",
                name: "Networking",
                layerBoundary: "Shared client + feature repositories",
                owner: "API Integration",
                status: .healthy,
                summary: "Auth, release, and push endpoints monitored with retry policy and redacted logs."
            ),
            FeatureModule(
                id: "ui-kit",
                name: "UIKit Interop",
                layerBoundary: "UIKit container hosts SwiftUI detail",
                owner: "Native iOS",
                status: .healthy,
                summary: "Native list and transitions validated on device for mixed UI stacks."
            ),
            FeatureModule(
                id: "release",
                name: "Release Safety",
                layerBoundary: "Docs + test fixtures + checklist",
                owner: "Release",
                status: .warning,
                summary: "Device-only risks are tracked before TestFlight, not after review."
            ),
        ]
    }

    private func makeAPIHealth() -> [APIHealthCheck] {
        [
            APIHealthCheck(
                id: "auth",
                name: "Auth Refresh",
                endpoint: "/v1/session/refresh",
                status: .healthy,
                latencyMilliseconds: 118,
                lastChecked: self.now()
            ),
            APIHealthCheck(
                id: "release",
                name: "Release Checklist",
                endpoint: "/v1/mobile/release-readiness",
                status: .healthy,
                latencyMilliseconds: 162,
                lastChecked: self.now()
            ),
            APIHealthCheck(
                id: "push",
                name: "Push Token Sync",
                endpoint: "/v1/devices/push-token",
                status: .warning,
                latencyMilliseconds: 420,
                lastChecked: self.now()
            ),
        ]
    }

    private func makeChecklist() -> [ReleaseChecklistItem] {
        [
            ReleaseChecklistItem(
                id: "tests",
                title: "Fast unit and UI smoke tests pass",
                detail: "Retry, domain scoring, UIKit entry, and dashboard launch have deterministic coverage.",
                isComplete: true,
                owner: "iOS"
            ),
            ReleaseChecklistItem(
                id: "observability",
                title: "OSLog release diagnostics are ready",
                detail: "Sensitive headers redacted; OSLogCrashMonitor records non-fatals until a vendor SDK is wired.",
                isComplete: true,
                owner: "Platform"
            ),
            ReleaseChecklistItem(
                id: "device-proof",
                title: "Real-device capabilities checked",
                detail: "Push, deep links, keychain, memory pressure, and permissions need device/TestFlight passes.",
                isComplete: false,
                owner: "QA"
            ),
            ReleaseChecklistItem(
                id: "review",
                title: "App Store review notes prepared",
                detail: "Permission purpose, background modes, and account/demo data are documented.",
                isComplete: false,
                owner: "Release"
            ),
        ]
    }

    private func makeRisks() -> [ProductionRisk] {
        let deepLinkDetail = "Associated Domains and universal link routing can differ by build type."
        let keychainDetail = "Access groups, biometric state, protected data, and reinstall behavior differ by device."
        let memoryDetail = "Large feeds, image-heavy collection views, and older devices reveal hidden crashes."
        let definitions = [
            (
                "push-notifications",
                "Push Notifications",
                "APNs token, entitlements, notification settings, and environment mismatch often fail only on devices.",
                "Use mock states locally, then verify sandbox APNs on TestFlight with logs and crash monitoring.",
                ReadinessStatus.warning
            ),
            (
                "deep-links",
                "Deep Links",
                deepLinkDetail,
                "HTTPS paths mirror custom-scheme routes; host AASA at /.well-known and verify on device.",
                ReadinessStatus.healthy
            ),
            (
                "keychain",
                "Keychain",
                keychainDetail,
                "Use AccessTokenStore + flag-gated KeychainDemoTokenRefresher; verify locked/unlocked devices.",
                ReadinessStatus.healthy
            ),
            (
                "memory-pressure",
                "Memory Pressure",
                memoryDetail,
                "Use reusable cells, prefetching, cancellation, and memory pressure scenarios before release.",
                ReadinessStatus.warning
            ),
        ]

        return definitions.map { id, title, detail, mitigation, status in
            ProductionRisk(
                id: id,
                title: title,
                detail: detail,
                mitigation: mitigation,
                status: status,
                legacyCode: self.riskCodeFormatter.code(title: title, owner: "ios")
            )
        }
    }
}
