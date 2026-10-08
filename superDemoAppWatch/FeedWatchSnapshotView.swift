// Native, glanceable Feed companion. Stored snapshots are read-only.

import SwiftUI

struct FeedWatchSnapshotView: View {
    @Environment(\.scenePhase)
    private var scenePhase
    @State private var model: FeedCompanionModel

    init(scenario: FeedCompanionScenario? = FeedCompanionScenario.launchSelection()) {
        self._model = State(initialValue: FeedCompanionModel(
            makeSeed: { FeedCompanionDemoSnapshot.watchSeed(writtenAt: $0) },
            scenario: scenario
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(self.model.sourceTitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Label(self.model.statusTitle, systemImage: self.model.statusSymbol)
                            .font(.headline)
                            .accessibilityIdentifier("watchFeedSnapshotStatus")
                        if self.model.isLoading, self.model.snapshot == nil {
                            ProgressView("Loading Feed")
                        } else if self.model.snapshot == nil || self.model.snapshot?.titles.isEmpty == true {
                            Text(self.model.statusDetail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    if self.model.snapshot == nil || self.model.snapshot?.titles.isEmpty == true {
                        Button("Try sample Feed", systemImage: "play.circle") {
                            self.model.showSample()
                        }
                        .accessibilityIdentifier("watchFeedSnapshotSeed")
                    }
                }

                if let snapshot = self.model.snapshot {
                    Section {
                        ForEach(snapshot.titles.prefix(5), id: \.id) { row in
                            NavigationLink {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(row.title)
                                            .font(.headline)
                                            .accessibilityIdentifier("watchFeedHeadlineTitle")
                                        Text(self.model.statusDetail)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(self.model.sourceTitle)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                }
                                .navigationTitle("Headline")
                            } label: {
                                Text(row.title)
                                    .font(.body)
                                    .lineLimit(3)
                            }
                            .accessibilityHint("Opens the full headline")
                            .accessibilityIdentifier("watchFeedHeadline_\(row.id)")
                        }
                    } header: {
                        Text("Headlines")
                    } footer: {
                        Text("Updated \(snapshot.writtenAt.formatted(date: .omitted, time: .shortened))")
                    }
                }

                Section {
                    NavigationLink {
                        FeedWatchScenariosView(model: self.model)
                    } label: {
                        Label("Demo states", systemImage: "slider.horizontal.3")
                    }
                    .accessibilityIdentifier("watchFeedDemoStates")
                    Button("Reload", systemImage: "arrow.clockwise") {
                        Task { await self.model.reload() }
                    }
                    .disabled(self.model.isLoading)
                    .accessibilityIdentifier("watchFeedSnapshotReload")
                    if self.model.scenario != nil {
                        Button("Use stored Feed", systemImage: "internaldrive") {
                            Task { await self.model.useStoredSnapshot() }
                        }
                        .accessibilityIdentifier("watchFeedUseStored")
                    }
                } footer: {
                    Text("Independent demo. Samples stay on this watch.")
                }
            }
            .navigationTitle("Feed")
        }
        .task(id: self.scenePhase) {
            guard self.scenePhase == .active else { return }
            await self.model.observeSnapshots()
        }
    }
}

private struct FeedWatchScenariosView: View {
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
                    if self.model.scenario == scenario {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                    }
                }
            }
            .accessibilityValue(self.model.scenario == scenario ? "Selected" : "")
            .accessibilityIdentifier("watchFeedScenario_\(scenario.rawValue)")
        }
        .navigationTitle("Demo states")
    }
}

#Preview("Fresh sample") { FeedWatchSnapshotView(scenario: .fresh) }
#Preview("Expired sample") { FeedWatchSnapshotView(scenario: .expired) }
#Preview("Empty sample") { FeedWatchSnapshotView(scenario: .empty) }
#Preview("No snapshot") { FeedWatchSnapshotView(scenario: .absent) }
