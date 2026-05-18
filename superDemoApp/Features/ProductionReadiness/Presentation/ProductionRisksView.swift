//
//  ProductionRisksView.swift
//  superDemoApp
//

import SwiftUI

struct ProductionRisksView: View {
    let risks: [ProductionRisk]

    var body: some View {
        List(self.risks) { risk in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(risk.title)
                        .font(.headline)
                    Spacer()
                    Text(risk.legacyCode)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(risk.detail)
                    .foregroundStyle(.secondary)
                Text("Mitigation: \(risk.mitigation)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
        .navigationTitle("Production Risks")
        .accessibilityIdentifier("productionRisksScreen")
    }
}
