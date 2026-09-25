//
//  StoreKitProductQueryDemoView.swift
//  superDemoApp
//
//  Engineering demo: StoreKit 2 product query (JP-P1-D). Query-only — no charge path.
//

import SwiftUI

/// Engineering demo: list StoreKit Configuration products or an honest unavailable state.
struct StoreKitProductQueryDemoView: View {
    @State private var model: StoreKitProductQueryDemoModel

    /// - Parameter querier: Injected for tests/previews. `nil` builds the system
    ///   querier in this MainActor init body (avoids default-arg isolation under
    ///   `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`).
    init(querier: (any StoreKitProductQuerying)? = nil) {
        let resolved = querier ?? SystemStoreKitProductQuerier()
        self._model = State(initialValue: StoreKitProductQueryDemoModel(querier: resolved))
    }

    var body: some View {
        List {
            Section("Honesty") {
                Text(
                    """
                    StoreKit 2 product query demo only. Uses the checked-in \
                    Config/Products.storekit via the shared scheme’s StoreKit \
                    Configuration. No purchase button, no real charge path, \
                    no App Store Connect catalog claim.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Query") {
                Button("Load demo products") {
                    Task { await self.model.loadProducts() }
                }
                .disabled(self.model.isBusy)
                .accessibilityIdentifier("storeKitLoadProducts")
            }

            switch self.model.state {
            case .idle:
                Section("Status") {
                    Text("Tap Load to query Product.products for the demo IDs.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("storeKitStatusIdle")
                }
            case .loading:
                Section("Status") {
                    ProgressView("Loading products…")
                        .accessibilityIdentifier("storeKitStatusLoading")
                }
            case let .loaded(products):
                Section("Products (\(products.count))") {
                    ForEach(products) { product in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.displayName)
                                .font(.headline)
                            Text(product.id)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(product.description)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text(product.displayPrice)
                                .font(.subheadline)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("storeKitProductRow_\(product.id)")
                    }
                }
            case .empty:
                Section("Unavailable") {
                    ContentUnavailableView(
                        "No products returned",
                        systemImage: "bag.badge.questionmark",
                        description: Text(
                            """
                            StoreKit returned an empty list. Confirm \
                            Config/Products.storekit is selected on the Run \
                            scheme (StoreKit Configuration), or that you are \
                            not expecting App Store Connect products.
                            """
                        )
                    )
                    .accessibilityIdentifier("storeKitStatusEmpty")
                }
            case let .unavailable(message):
                Section("Unavailable") {
                    ContentUnavailableView(
                        "StoreKit unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                    .accessibilityIdentifier("storeKitStatusUnavailable")
                }
            }
        }
        .navigationTitle("StoreKit 2 query")
        .iosLargeNavigationBarTitle()
        .accessibilityIdentifier("storeKitProductQueryDemoScreen")
    }
}

@MainActor
@Observable
final class StoreKitProductQueryDemoModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([StoreKitDemoProduct])
        case empty
        case unavailable(String)
    }

    private let querier: any StoreKitProductQuerying

    private(set) var state: State = .idle
    private(set) var isBusy = false

    init(querier: any StoreKitProductQuerying) {
        self.querier = querier
    }

    func loadProducts() async {
        self.isBusy = true
        self.state = .loading
        defer { self.isBusy = false }
        do {
            let products = try await self.querier.products(for: StoreKitDemoProductIDs.allKnown)
            if products.isEmpty {
                self.state = .empty
            } else {
                self.state = .loaded(products)
            }
        } catch is CancellationError {
            self.state = .idle
        } catch let StoreKitProductQueryFailure.unavailable(reason) {
            self.state = .unavailable(reason)
        } catch {
            self.state = .unavailable(error.localizedDescription)
        }
    }
}

#Preview("StoreKit product query — loaded") {
    NavigationStack {
        StoreKitProductQueryDemoView(querier: PreviewStoreKitProductQuerier(mode: .products))
    }
}

#Preview("StoreKit product query — empty") {
    NavigationStack {
        StoreKitProductQueryDemoView(querier: PreviewStoreKitProductQuerier(mode: .empty))
    }
}

#Preview("StoreKit product query — unavailable") {
    NavigationStack {
        StoreKitProductQueryDemoView(querier: PreviewStoreKitProductQuerier(mode: .unavailable))
    }
}

@MainActor
private final class PreviewStoreKitProductQuerier: StoreKitProductQuerying {
    enum Mode {
        case products
        case empty
        case unavailable
    }

    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func products(for _: [String]) async throws -> [StoreKitDemoProduct] {
        await Task.yield()
        switch self.mode {
        case .products:
            return [
                StoreKitDemoProduct(
                    id: StoreKitDemoProductIDs.tipJar,
                    displayName: "Portfolio Tip Jar (Demo)",
                    description: "Engineering demo non-consumable.",
                    displayPrice: "$0.99"
                ),
            ]
        case .empty:
            return []
        case .unavailable:
            throw StoreKitProductQueryFailure.unavailable(
                reason: "Preview: StoreKit testing config missing."
            )
        }
    }
}
