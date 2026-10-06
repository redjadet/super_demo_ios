//
//  FeatureLoadingPlaceholder.swift
//  superDemoApp
//

import SwiftUI

/// List-shaped skeleton for the first-load gap (real-time feedback without a spinner-only void).
/// Respects Reduce Motion by dropping the redacted shimmer-like placeholder rows.
struct FeatureLoadingPlaceholder: View {
    private let accessibilityIdentifier: String
    private let accessibilityLabel: String
    private let rowCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        accessibilityIdentifier: String,
        accessibilityLabel: String,
        rowCount: Int = 5
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityLabel = accessibilityLabel
        self.rowCount = rowCount
    }

    var body: some View {
        Group {
            if self.reduceMotion {
                ProgressView()
                    .controlSize(.large)
            } else {
                List {
                    ForEach(0 ..< self.rowCount, id: \.self) { index in
                        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                            Text("Loading title \(index)")
                                .font(.headline)
                            Text("Loading detail \(index)")
                                .font(.subheadline)
                        }
                        .redacted(reason: .placeholder)
                        .accessibilityHidden(true)
                    }
                }
                .disabled(true)
                .featureSidebarColumnWidth()
            }
        }
        .featureScreenFrame()
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(self.accessibilityIdentifier)
        .accessibilityLabel(self.accessibilityLabel)
        .accessibilityAddTraits(.updatesFrequently)
    }
}
