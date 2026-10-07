//
//  ProductionRisksView.swift
//  superDemoApp
//

import SwiftUI

struct ProductionRisksView: View {
    let risks: [ProductionRisk]

    var body: some View {
        Group {
            if self.risks.isEmpty {
                ContentUnavailableView {
                    Label("No Tracked Risks", systemImage: "checkmark.shield")
                } description: {
                    Text("Device-only and App Store risks appear here when the dashboard lists them.")
                }
                .featureScreenFrame()
                .accessibilityIdentifier("productionRisksEmpty")
                .accessibilityLabel("No tracked risks")
            } else {
                List(self.risks) { risk in
                    VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(risk.title)
                                .font(.headline)
                            Spacer(minLength: DesignSpacing.sm)
                            Text(risk.legacyCode)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                        Text(risk.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Mitigation: \(risk.mitigation)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, DesignSpacing.xs)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(risk.title), code \(risk.legacyCode). \(risk.detail). Mitigation: \(risk.mitigation)"
                    )
                    .accessibilityIdentifier("productionRiskRow-\(risk.id)")
                }
            }
        }
        .navigationTitle("Production Risks")
        .accessibilityIdentifier("productionRisksScreen")
    }
}
