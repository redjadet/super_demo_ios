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
                name: String(localized: "Architecture"),
                layerBoundary: String(localized: "Presentation -> Domain <- Data"),
                owner: String(localized: "Mobile Platform"),
                status: .healthy,
                summary: String(
                    localized: "Feature ownership and layer boundaries are documented for release triage."
                )
            ),
            FeatureModule(
                id: "networking",
                name: String(localized: "Networking"),
                layerBoundary: String(localized: "Shared client + feature repositories"),
                owner: String(localized: "API Integration"),
                status: .healthy,
                summary: String(
                    localized: "Auth, release, and push endpoints monitored with retry policy and redacted logs."
                )
            ),
            FeatureModule(
                id: "ui-kit",
                name: String(localized: "UIKit Interop"),
                layerBoundary: String(localized: "UIKit container hosts SwiftUI detail"),
                owner: String(localized: "Native iOS"),
                status: .healthy,
                summary: String(
                    localized: "Native list and transitions validated on device for mixed UI stacks."
                )
            ),
            FeatureModule(
                id: "release",
                name: String(localized: "Release Safety"),
                layerBoundary: String(localized: "Docs + test fixtures + checklist"),
                owner: String(localized: "Release"),
                status: .warning,
                summary: String(
                    localized: "Device-only risks are tracked before TestFlight, not after review."
                )
            ),
        ]
    }

    private func makeAPIHealth() -> [APIHealthCheck] {
        [
            APIHealthCheck(
                id: "auth",
                name: String(localized: "Auth Refresh"),
                endpoint: "/v1/session/refresh",
                status: .healthy,
                latencyMilliseconds: 118,
                lastChecked: self.now()
            ),
            APIHealthCheck(
                id: "release",
                name: String(localized: "Release Checklist"),
                endpoint: "/v1/mobile/release-readiness",
                status: .healthy,
                latencyMilliseconds: 162,
                lastChecked: self.now()
            ),
            APIHealthCheck(
                id: "push",
                name: String(localized: "Push Token Sync"),
                endpoint: "/v1/devices/push-token",
                status: .warning,
                latencyMilliseconds: 420,
                lastChecked: self.now()
            ),
        ]
    }

    // Sample copy uses long English source keys for String Catalog extraction.
    // swiftlint:disable line_length
    private func makeChecklist() -> [ReleaseChecklistItem] {
        [
            ReleaseChecklistItem(
                id: "tests",
                title: String(localized: "Fast unit and UI smoke tests pass"),
                detail: String(
                    localized: "Retry, domain scoring, UIKit entry, and dashboard launch have deterministic coverage."
                ),
                isComplete: true,
                owner: String(localized: "iOS")
            ),
            ReleaseChecklistItem(
                id: "observability",
                title: String(localized: "OSLog release diagnostics are ready"),
                detail: String(
                    localized: "Sensitive headers redacted; OSLogCrashMonitor records non-fatals until a vendor SDK is wired."
                ),
                isComplete: true,
                owner: String(localized: "Platform")
            ),
            ReleaseChecklistItem(
                id: "device-proof",
                title: String(localized: "Real-device capabilities checked"),
                detail: String(
                    localized: "Push, deep links, keychain, memory pressure, and permissions need device/TestFlight passes."
                ),
                isComplete: false,
                owner: String(localized: "QA")
            ),
            ReleaseChecklistItem(
                id: "review",
                title: String(localized: "App Store review notes prepared"),
                detail: String(
                    localized: "Permission purpose, background modes, and account/demo data are documented."
                ),
                isComplete: false,
                owner: String(localized: "Release")
            ),
        ]
    }

    private func makeRisks() -> [ProductionRisk] {
        self.riskDefinitions().map { definition in
            ProductionRisk(
                id: definition.id,
                title: String(localized: String.LocalizationValue(definition.englishTitle)),
                detail: definition.detail,
                mitigation: definition.mitigation,
                status: definition.status,
                legacyCode: self.riskCodeFormatter.code(title: definition.englishTitle, owner: "ios")
            )
        }
    }

    private func riskDefinitions() -> [SampleRiskDefinition] {
        [
            SampleRiskDefinition(
                id: "push-notifications",
                englishTitle: "Push Notifications",
                detail: String(
                    localized: "APNs token, entitlements, notification settings, and environment mismatch often fail only on devices."
                ),
                mitigation: String(
                    localized: "Use mock states locally, then verify sandbox APNs on TestFlight with logs and crash monitoring."
                ),
                status: .warning
            ),
            SampleRiskDefinition(
                id: "deep-links",
                englishTitle: "Deep Links",
                detail: String(
                    localized: "Associated Domains and universal link routing can differ by build type."
                ),
                mitigation: String(
                    localized: "HTTPS paths mirror custom-scheme routes; host AASA at /.well-known and verify on device."
                ),
                status: .healthy
            ),
            SampleRiskDefinition(
                id: "keychain",
                englishTitle: "Keychain",
                detail: String(
                    localized: "Access groups, biometric state, protected data, and reinstall behavior differ by device."
                ),
                mitigation: String(
                    localized: "Use AccessTokenStore + flag-gated KeychainDemoTokenRefresher; verify locked/unlocked devices."
                ),
                status: .healthy
            ),
            SampleRiskDefinition(
                id: "memory-pressure",
                englishTitle: "Memory Pressure",
                detail: String(
                    localized: "Large feeds, image-heavy collection views, and older devices reveal hidden crashes."
                ),
                mitigation: String(
                    localized: "Use reusable cells, prefetching, cancellation, and memory pressure scenarios before release."
                ),
                status: .warning
            ),
        ]
    }
    // swiftlint:enable line_length
}

private struct SampleRiskDefinition {
    let id: String
    let englishTitle: String
    let detail: String
    let mitigation: String
    let status: ReadinessStatus
}
