//
//  ProductionReadinessView.swift
//  superDemoApp
//

import SwiftUI

struct ProductionReadinessView: View {
    @Bindable private var model: ProductionReadinessFeatureModel
    @Binding private var path: [AppRoute]

    init(model: ProductionReadinessFeatureModel, path: Binding<[AppRoute]>) {
        self.model = model
        self._path = path
    }

    var body: some View {
        NavigationStack(path: self.$path) {
            self.content
                .navigationTitle("Production Readiness")
                .iosLargeNavigationBarTitle()
                .toolbar {
                    ToolbarItem {
                        Button {
                            self.model.refresh()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .chromeGlassButtonStyle()
                        .accessibilityIdentifier("refreshProductionReadiness")
                        .disabled(self.model.isInitialLoading)
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    self.destination(for: route)
                }
        }
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
                ProgressView()
                    .featureScreenFrame()
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch self.model.state {
        case .loading:
            ProgressView()
                .featureScreenFrame()
        case let .failed(error):
            ContentUnavailableView {
                Label("Could Not Load Dashboard", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button("Retry") {
                    self.model.refresh()
                }
                .chromeGlassButtonStyle()
            }
            .featureScreenFrame()
        case let .content(snapshot, score):
            ProductionReadinessContent(snapshot: snapshot, score: score)
        }
    }
}

private struct ProductionReadinessContent: View {
    let snapshot: ProductionReadinessSnapshot
    let score: Int

    var body: some View {
        List {
            Section {
                ReadinessHero(score: self.score)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }

            Section("Feature Modules") {
                ForEach(self.snapshot.modules) { module in
                    ModuleRow(module: module)
                }
            }

            Section("API Health") {
                ForEach(self.snapshot.apiHealth) { health in
                    APIHealthRow(health: health)
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

                NavigationLink {
                    UIKitShowcaseEntryView(modules: self.snapshot.modules)
                } label: {
                    Label("Collection view, prefetching, hosting, custom transition", systemImage: "rectangle.grid.2x2")
                }
                .accessibilityIdentifier("uikitShowcaseLink")

                NavigationLink {
                    DiagnosticsDemoView()
                } label: {
                    Label("OSLog diagnostics and crash-monitor swap point", systemImage: "waveform.path.ecg")
                }
                .accessibilityIdentifier("diagnosticsDemoLink")

                NavigationLink {
                    IdempotentPostDemoView(
                        model: ProductionReadinessComposition.makeIdempotentPostDemoModel()
                    )
                } label: {
                    Label("Idempotent POST (simulated duplicate-safe)", systemImage: "arrow.triangle.2.circlepath")
                }
                .accessibilityIdentifier("idempotentPostDemoLink")

                NavigationLink {
                    StaleFeedDemoView(session: FeedComposition.makeStaleDemoSession())
                } label: {
                    Label("Stale Feed cache fallback", systemImage: "externaldrive.badge.exclamationmark")
                }
                .accessibilityIdentifier("staleFeedDemoLink")

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

                NavigationLink {
                    OnDeviceVisionDemoView()
                } label: {
                    Label("On-device Vision OCR (demo)", systemImage: "text.viewfinder")
                }
                .accessibilityIdentifier("onDeviceVisionDemoLink")
            }
        }
        .accessibilityIdentifier("productionReadinessDashboard")
    }
}

private struct ReadinessHero: View {
    let score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Release health")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                ReadinessScoreBadge(score: self.score)
                    .equatable()
            }
            Text("Module status, API checks, release checklist, and tracked risks in one view.")
                .foregroundStyle(.secondary)
        }
    }
}

private struct ReadinessScoreBadge: View, Equatable {
    let score: Int

    var body: some View {
        Text("\(self.score)%")
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(self.score >= 80 ? Color.accentColor.opacity(0.16) : Color.orange.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(String(localized: "Readiness score \(self.score) percent"))
    }
}

private struct ModuleRow: View {
    let module: FeatureModule

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
    }
}

private struct APIHealthRow: View {
    let health: APIHealthCheck

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StatusPill(status: self.health.status)
            VStack(alignment: .leading, spacing: 4) {
                Text(self.health.name)
                    .font(.headline)
                if self.health.isLiveNetworkProbe {
                    Text("Live network probe (prepended to sample checks)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("\(self.health.endpoint) - \(self.health.latencyMilliseconds) ms")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private extension APIHealthCheck {
    var isLiveNetworkProbe: Bool {
        self.id == "remote-api"
    }
}

private struct ChecklistRow: View {
    let item: ReleaseChecklistItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: self.item.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(self.item.isComplete ? Color.accentColor : .secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(self.item.title)
                    .font(.headline)
                Text(self.item.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct StatusPill: View {
    let status: ReadinessStatus

    var body: some View {
        // Safe conditional modifiers: value changes color/opacity only, preserving view identity and lifecycle.
        Text(self.label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(self.foregroundStyle)
            .background(self.backgroundStyle)
            .clipShape(Capsule())
            .opacity(self.status == .blocked ? 0.9 : 1)
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
        ProductionReadinessView(model: self.model, path: self.$path)
            .task { await self.model.refreshAndWait() }
    }
}
