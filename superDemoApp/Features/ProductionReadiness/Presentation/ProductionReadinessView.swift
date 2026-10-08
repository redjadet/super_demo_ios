//
//  ProductionReadinessView.swift
//  superDemoApp
//

import SwiftUI

/// App-owned Engineering demo destinations that need composition-root wiring.
/// Keeps Presentation free of `*Composition` calls (layers / DI boundary).
struct ProductionReadinessEngineeringDemos {
    let makeIdempotentPost: @MainActor () -> AnyView
    let makeStaleFeed: @MainActor () -> AnyView

    @MainActor static var preview: Self {
        Self(
            makeIdempotentPost: {
                AnyView(
                    IdempotentPostDemoView(
                        model: IdempotentPostDemoModel(
                            submit: SubmitIdempotentPostDemoUseCase(
                                transport: SimulatedIdempotentPostTransport()
                            )
                        )
                    )
                )
            },
            makeStaleFeed: {
                AnyView(
                    Text("Stale Feed preview")
                        .accessibilityIdentifier("staleFeedDemoScreen")
                )
            }
        )
    }
}

struct ProductionReadinessView: View {
    @Bindable private var model: ProductionReadinessFeatureModel
    @Binding private var path: [AppRoute]
    private let engineeringDemos: ProductionReadinessEngineeringDemos

    @State private var refreshFeedbackTick = 0

    init(
        model: ProductionReadinessFeatureModel,
        path: Binding<[AppRoute]>,
        engineeringDemos: ProductionReadinessEngineeringDemos
    ) {
        self.model = model
        self._path = path
        self.engineeringDemos = engineeringDemos
    }

    var body: some View {
        NavigationStack(path: self.$path) {
            self.content
                .navigationTitle("Production Readiness")
                .iosLargeNavigationBarTitle()
                .toolbar {
                    ToolbarItem {
                        Button {
                            self.refreshFeedbackTick &+= 1
                            self.model.refresh()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .chromeGlassButtonStyle()
                        .accessibilityIdentifier("refreshProductionReadiness")
                        .accessibilityHint("Reloads dashboard modules, API health, and checklist")
                        .disabled(self.model.isInitialLoading)
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    self.destination(for: route)
                }
        }
        .sensoryFeedback(.selection, trigger: self.refreshFeedbackTick)
        #if os(macOS)
        .focusedSceneValue(\.macRefresh, self.model.isInitialLoading ? nil : { self.model.refresh() })
        #endif
        .task {
            await self.model.refreshAndWait()
        }
        .onDisappear {
            self.model.cancelRefresh()
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .productionRisks:
            if case let .content(snapshot, _) = self.model.state {
                ProductionRisksView(risks: snapshot.risks)
            } else {
                FeatureLoadingPlaceholder(
                    accessibilityIdentifier: "productionRisksLoading",
                    accessibilityLabel: "Loading production risks",
                    rowCount: 3
                )
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch self.model.state {
        case .loading:
            FeatureLoadingPlaceholder(
                accessibilityIdentifier: "productionReadinessLoading",
                accessibilityLabel: "Loading production readiness"
            )
        case let .failed(error):
            ContentUnavailableView {
                Label("Could Not Load Dashboard", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button("Retry") {
                    self.refreshFeedbackTick &+= 1
                    self.model.refresh()
                }
                .chromeGlassButtonStyle()
                .accessibilityIdentifier("productionReadinessRetry")
            }
            .featureScreenFrame()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("productionReadinessFailed")
            .accessibilityLabel("Could not load dashboard")
        case let .content(snapshot, score):
            ProductionReadinessContent(
                snapshot: snapshot,
                score: score,
                engineeringDemos: self.engineeringDemos
            )
        }
    }
}

private struct ProductionReadinessContent: View {
    let snapshot: ProductionReadinessSnapshot
    let score: Int
    let engineeringDemos: ProductionReadinessEngineeringDemos

    var body: some View {
        List {
            #if os(macOS)
            Section {
                Label("Native macOS · SwiftUI + SwiftData", systemImage: "desktopcomputer")
                    .font(.headline)
                if AppLaunchConfiguration.usesSeededSampleState {
                    Text("Sample dashboard. Status, score, and API timings are demo data.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("macSampleDashboardNotice")
                }
            }
            #endif
            Section {
                ReadinessHero(
                    score: self.score,
                    includesLiveAPIProbe: self.snapshot.apiHealth.contains(where: \.isLiveProbe)
                )
                .listRowInsets(
                    EdgeInsets(
                        top: DesignSpacing.md,
                        leading: DesignSpacing.md,
                        bottom: DesignSpacing.md,
                        trailing: DesignSpacing.md
                    )
                )
            }

            Section("Feature Modules") {
                ForEach(self.snapshot.modules) { module in
                    ModuleRow(module: module)
                }
            }

            Section("API Health") {
                ForEach(self.snapshot.apiHealth) { health in
                    APIHealthRow(
                        health: health,
                        scoreExcludesSampleAPI: self.snapshot.apiHealth.contains(where: \.isLiveProbe)
                    )
                }
            }

            Section("Release Checklist") {
                ForEach(self.snapshot.checklist) { item in
                    ChecklistRow(item: item)
                }
            }

            Section("Engineering demos") {
                NavigationLink {
                    ProductionRisksView(risks: self.snapshot.risks)
                } label: {
                    Label("Device-only and App Store risks", systemImage: "exclamationmark.shield")
                }
                .accessibilityIdentifier("productionRisksLink")

                #if canImport(UIKit)
                NavigationLink {
                    UIKitShowcaseEntryView(modules: self.snapshot.modules)
                } label: {
                    Label("Collection view, prefetching, hosting, custom transition", systemImage: "rectangle.grid.2x2")
                }
                .accessibilityIdentifier("uikitShowcaseLink")
                #endif

                NavigationLink {
                    DiagnosticsDemoView()
                } label: {
                    Label("OSLog diagnostics and crash-monitor swap point", systemImage: "waveform.path.ecg")
                }
                .accessibilityIdentifier("diagnosticsDemoLink")

                NavigationLink {
                    self.engineeringDemos.makeIdempotentPost()
                } label: {
                    Label("Idempotent POST (simulated duplicate-safe)", systemImage: "arrow.triangle.2.circlepath")
                }
                .accessibilityIdentifier("idempotentPostDemoLink")

                NavigationLink {
                    self.engineeringDemos.makeStaleFeed()
                } label: {
                    Label("Stale Feed cache fallback", systemImage: "externaldrive.badge.exclamationmark")
                }
                .accessibilityIdentifier("staleFeedDemoLink")

                #if os(iOS)
                NavigationLink {
                    FeedWidgetSnapshotDemoView()
                } label: {
                    Label("Feed widget App Group snapshot", systemImage: "rectangle.on.rectangle")
                }
                .accessibilityIdentifier("feedWidgetSnapshotDemoLink")

                NavigationLink {
                    HostBridgePingDemoView()
                } label: {
                    Label("Host bridge ping (feed.cacheStatus)", systemImage: "cable.connector")
                }
                .accessibilityIdentifier("hostBridgePingDemoLink")

                NavigationLink {
                    FlutterModuleDemoView()
                } label: {
                    Label("Flutter add-to-app module", systemImage: "cube.transparent")
                }
                .accessibilityIdentifier("flutterAddToAppDemoLink")
                #endif

                NavigationLink {
                    LocalNotificationDemoView()
                } label: {
                    Label("Local stale-Feed reminder (not APNs)", systemImage: "bell.badge")
                }
                .accessibilityIdentifier("localNotificationDemoLink")

                NavigationLink {
                    StoreKitProductQueryDemoView()
                } label: {
                    Label("StoreKit 2 product query (demo)", systemImage: "bag")
                }
                .accessibilityIdentifier("storeKitProductQueryDemoLink")

                NavigationLink {
                    SignInWithAppleDemoView()
                } label: {
                    Label("Sign in with Apple (demo)", systemImage: "apple.logo")
                }
                .accessibilityIdentifier("signInWithAppleDemoLink")

                #if os(iOS)
                NavigationLink {
                    ShareInboxDemoView()
                } label: {
                    Label("Share inbox (App Group, not SwiftData)", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("shareInboxDemoLink")
                #endif

                NavigationLink {
                    OnDeviceVisionDemoView()
                } label: {
                    Label("On-device Vision OCR (demo)", systemImage: "text.viewfinder")
                }
                .accessibilityIdentifier("onDeviceVisionDemoLink")

                NavigationLink {
                    WatchCompanionDemoView()
                } label: {
                    Label("watchOS Feed companion (demo)", systemImage: "applewatch")
                }
                .accessibilityIdentifier("watchCompanionDemoLink")

                NavigationLink {
                    TVCompanionDemoView()
                } label: {
                    Label("tvOS Feed companion (demo)", systemImage: "appletv")
                }
                .accessibilityIdentifier("tvCompanionDemoLink")
            }
        }
        .accessibilityIdentifier("productionReadinessDashboard")
    }
}

private struct ReadinessHero: View {
    let score: Int
    let includesLiveAPIProbe: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.sm + DesignSpacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("Release health")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                ReadinessScoreBadge(score: self.score, includesLiveAPIProbe: self.includesLiveAPIProbe)
                    .equatable()
            }
            Text(self.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        if self.includesLiveAPIProbe {
            // Keep under SwiftLint line_length (120 warning / --strict).
            String(
                localized: "Includes modules, live Remote API, checklist, and risks. Sample API rows are listed only."
            )
        } else {
            String(localized: "Module status, API checks, release checklist, and tracked risks in one view.")
        }
    }
}

private struct ReadinessScoreBadge: View, Equatable {
    let score: Int
    let includesLiveAPIProbe: Bool

    var body: some View {
        Text("\(self.score)%")
            .font(.headline)
            .padding(.horizontal, DesignSpacing.sm + DesignSpacing.xs)
            .padding(.vertical, DesignSpacing.sm)
            .background(self.score >= 80 ? Color.accentColor.opacity(0.16) : Color.orange.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: DesignSpacing.cornerMD))
            .accessibilityLabel(self.scoreAccessibilityText)
            .accessibilityAddTraits(.isStaticText)
    }

    private var scoreAccessibilityText: String {
        if self.includesLiveAPIProbe {
            String(
                localized: "Readiness score \(self.score) percent; live Remote API only, sample API excluded"
            )
        } else {
            String(localized: "Readiness score \(self.score) percent")
        }
    }
}

private struct ModuleRow: View {
    let module: FeatureModule

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xs + 2) {
            HStack {
                Text(self.module.name)
                    .font(.headline)
                Spacer()
                StatusPill(status: self.module.status)
            }
            Text(self.module.layerBoundary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(self.module.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.moduleAccessibilityLabel)
    }

    private var moduleAccessibilityLabel: String {
        let status = self.module.status.accessibilityLabel
        return "\(self.module.name), \(status). \(self.module.layerBoundary). \(self.module.summary)"
    }
}

private struct APIHealthRow: View {
    let health: APIHealthCheck
    let scoreExcludesSampleAPI: Bool

    var body: some View {
        HStack(alignment: .top, spacing: DesignSpacing.sm + DesignSpacing.xs) {
            StatusPill(status: self.health.status)
            VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                Text(self.health.name)
                    .font(.headline)
                if self.health.isLiveProbe {
                    Text("Live network probe (included in Release health score)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if self.scoreExcludesSampleAPI {
                    Text("Sample check (not in live Release health score)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("\(self.health.endpoint) - \(self.health.latencyMilliseconds) ms")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var parts = [
            self.health.name,
            self.health.status.accessibilityLabel,
            "\(self.health.endpoint), \(self.health.latencyMilliseconds) milliseconds",
        ]
        if self.health.isLiveProbe {
            parts.append("Live network probe included in Release health score")
        } else if self.scoreExcludesSampleAPI {
            parts.append("Sample check not in live Release health score")
        }
        return parts.joined(separator: ". ")
    }
}

private struct ChecklistRow: View {
    let item: ReleaseChecklistItem

    var body: some View {
        HStack(alignment: .top, spacing: DesignSpacing.sm + DesignSpacing.xs) {
            Image(systemName: self.item.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(self.item.isComplete ? Color.accentColor : .secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                Text(self.item.title)
                    .font(.headline)
                Text(self.item.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(self.item.title), \(self.item.isComplete ? "Complete" : "Incomplete"). \(self.item.detail)"
        )
        .accessibilityAddTraits(self.item.isComplete ? .isSelected : AccessibilityTraits())
    }
}

private extension ReadinessStatus {
    var accessibilityLabel: String {
        switch self {
        case .healthy:
            String(localized: "Healthy")
        case .warning:
            String(localized: "Watch")
        case .blocked:
            String(localized: "Blocked")
        }
    }
}

private struct StatusPill: View {
    let status: ReadinessStatus

    var body: some View {
        // Safe conditional modifiers: value changes color/opacity only, preserving view identity and lifecycle.
        Text(self.label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, DesignSpacing.sm)
            .padding(.vertical, DesignSpacing.xs)
            .foregroundStyle(self.foregroundStyle)
            .background(self.backgroundStyle)
            .clipShape(Capsule())
            .opacity(self.status == .blocked ? 0.9 : 1)
            .accessibilityHidden(true)
    }

    private var label: LocalizedStringKey {
        switch self.status {
        case .healthy:
            "Healthy"
        case .warning:
            "Watch"
        case .blocked:
            "Blocked"
        }
    }

    private var foregroundStyle: Color {
        switch self.status {
        case .healthy:
            .accentColor
        case .warning:
            .orange
        case .blocked:
            .red
        }
    }

    private var backgroundStyle: Color {
        self.foregroundStyle.opacity(0.14)
    }
}

#Preview("Production Readiness — iPhone", traits: UniversalPreviewLayouts.iPhonePortrait) {
    ProductionReadinessPreviewFactory.view()
}

#Preview("Production Readiness — iPhone (Dark)", traits: UniversalPreviewLayouts.iPhonePortrait) {
    ProductionReadinessPreviewFactory.view()
        .previewDarkAppearance()
}

#Preview("Production Readiness — iPad", traits: UniversalPreviewLayouts.iPadRegular) {
    ProductionReadinessPreviewFactory.view()
}

#Preview("Production Readiness — Mac", traits: UniversalPreviewLayouts.macWindow) {
    ProductionReadinessPreviewFactory.view()
}

#Preview("Production Readiness — Mac (Dark)", traits: UniversalPreviewLayouts.macWindow) {
    ProductionReadinessPreviewFactory.view()
        .previewDarkAppearance()
}

@MainActor
private enum ProductionReadinessPreviewFactory {
    static func view() -> some View {
        let repository = SampleProductionReadinessRepository()
        let model = ProductionReadinessFeatureModel(
            loadSnapshot: LoadProductionReadinessSnapshotUseCase(repository: repository),
            scoreSnapshot: ScoreProductionReadinessUseCase()
        )
        return ProductionReadinessPreviewRoot(model: model)
    }
}

private struct ProductionReadinessPreviewRoot: View {
    let model: ProductionReadinessFeatureModel
    @State private var path: [AppRoute] = []

    var body: some View {
        ProductionReadinessView(
            model: self.model,
            path: self.$path,
            engineeringDemos: .preview
        )
        .task { await self.model.refreshAndWait() }
    }
}
