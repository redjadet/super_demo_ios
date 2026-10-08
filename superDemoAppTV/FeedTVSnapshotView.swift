// Focus-driven Feed companion. Stored snapshots are read-only.

import SwiftUI
import UIKit

struct FeedTVSnapshotView: View {
    @Environment(\.scenePhase)
    private var scenePhase
    @State private var model: FeedCompanionModel

    init(scenario: FeedCompanionScenario? = FeedCompanionScenario.launchSelection()) {
        self._model = State(initialValue: FeedCompanionModel(
            makeSeed: { FeedCompanionDemoSnapshot.tvSeed(writtenAt: $0) },
            scenario: scenario
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 32) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Feed")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text(self.model.sourceTitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .top, spacing: 48) {
                    self.summary
                        .frame(maxWidth: .infinity, alignment: .leading)
                    self.controls
                }
                self.headlines
                Text("Independent Apple TV demo · Sample Feed stays on this device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 40)
        }
        .task(id: self.scenePhase) {
            guard self.scenePhase == .active else { return }
            await self.model.observeSnapshots()
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(self.model.statusTitle, systemImage: self.model.statusSymbol)
                .font(.title2.bold())
                .accessibilityIdentifier("tvFeedSnapshotStatus")
            Text(self.model.statusDetail)
                .font(.body)
                .foregroundStyle(.secondary)
            if let snapshot = self.model.snapshot {
                Text("Updated \(snapshot.writtenAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if self.model.isLoading, self.model.snapshot == nil {
                ProgressView("Loading Feed")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            NavigationLink {
                FeedTVScenariosView(model: self.model)
            } label: {
                Label("Demo states", systemImage: "slider.horizontal.3")
            }
            .accessibilityIdentifier("tvFeedDemoStates")
            HStack(spacing: 24) {
                Button("Reload", systemImage: "arrow.clockwise") {
                    Task { await self.model.reload() }
                }
                .disabled(self.model.isLoading)
                .accessibilityIdentifier("tvFeedSnapshotReload")
                if self.model.scenario != nil {
                    Button("Use stored Feed") {
                        Task { await self.model.useStoredSnapshot() }
                    }
                    .accessibilityIdentifier("tvFeedUseStored")
                }
            }
        }
    }

    @ViewBuilder private var headlines: some View {
        if let snapshot = self.model.snapshot, !snapshot.titles.isEmpty {
            List {
                Section("Headlines") {
                    ForEach(snapshot.titles.prefix(8), id: \.id) { row in
                        NavigationLink {
                            FeedTVHeadlineView(title: row.title, model: self.model)
                        } label: {
                            Text(row.title)
                                .font(.title3)
                                .lineLimit(2)
                        }
                        .accessibilityHint("Opens the full headline")
                        .accessibilityIdentifier("tvFeedHeadline_\(row.id)")
                    }
                }
            }
            .accessibilityIdentifier("tvFeedHeadlines")
        } else {
            VStack(spacing: 24) {
                Label(self.model.statusTitle, systemImage: self.model.statusSymbol)
                    .font(.title)
                Button("Try sample Feed", systemImage: "play.circle") {
                    self.model.showSample()
                }
                .accessibilityIdentifier("tvFeedSnapshotSeed")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct FeedTVScenariosView: View {
    @Environment(\.dismiss)
    private var dismiss
    let model: FeedCompanionModel

    var body: some View {
        List(FeedCompanionScenario.allCases) { scenario in
            Button {
                self.model.showSample(scenario)
                self.dismiss()
            } label: {
                HStack {
                    Text(scenario.title)
                    Spacer()
                    if self.model.scenario == scenario {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                    }
                }
            }
            .accessibilityValue(self.model.scenario == scenario ? "Selected" : "")
            .accessibilityIdentifier("tvFeedScenario_\(scenario.rawValue)")
        }
        .navigationTitle("Demo states")
    }
}

private struct FeedTVHeadlineView: View {
    @FocusState private var headlineFocused: Bool
    @State private var scrollStep = 0
    let title: String
    let model: FeedCompanionModel

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            FeedTVHeadlineText(title: self.title, scrollStep: self.scrollStep)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .focusable()
                .focused(self.$headlineFocused)
                .focusEffectDisabled()
                .onMoveCommand { direction in
                    switch direction {
                    case .up: self.scrollStep -= 1
                    case .down: self.scrollStep += 1
                    default: break
                    }
                }
                .accessibilityHint("Use the remote's up and down controls to scroll")
            Label(self.model.statusTitle, systemImage: self.model.statusSymbol)
                .font(.title2)
            Text(self.model.statusDetail)
                .foregroundStyle(.secondary)
            Text(self.model.sourceTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(64)
        .navigationTitle("Headline")
        .defaultFocus(self.$headlineFocused, true)
    }
}

/// SwiftUI owns remote focus; UIKit renders and scrolls the full text region.
private struct FeedTVHeadlineText: UIViewRepresentable {
    let title: String
    let scrollStep: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context _: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.font = .preferredFont(forTextStyle: .title1)
        view.textColor = .label
        view.adjustsFontForContentSizeCategory = true
        view.isSelectable = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.accessibilityIdentifier = "tvFeedHeadlineTitle"
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        if view.text != self.title {
            view.text = self.title
        }
        let delta = self.scrollStep - context.coordinator.scrollStep
        guard delta != 0 else { return }
        context.coordinator.scrollStep = self.scrollStep
        let page = max(120, view.bounds.height * 0.7)
        let limit = max(0, view.contentSize.height - view.bounds.height)
        let offset = min(limit, max(0, view.contentOffset.y + CGFloat(delta) * page))
        view.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
    }

    final class Coordinator {
        var scrollStep = 0
    }
}

#Preview("Fresh sample") { FeedTVSnapshotView(scenario: .fresh) }
#Preview("Fresh sample dark") { FeedTVSnapshotView(scenario: .fresh).preferredColorScheme(.dark) }
#Preview("Expired sample") { FeedTVSnapshotView(scenario: .expired) }
#Preview("Empty sample") { FeedTVSnapshotView(scenario: .empty) }
