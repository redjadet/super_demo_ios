//
//  StoreKitProductQuerying.swift
//  superDemoApp
//
//  StoreKit 2 product query surface for the JP-P1-D Engineering demo.
//  Query-only — no purchase / charge path.
//

import Foundation
import StoreKit

/// Product IDs mirrored in `Config/Products.storekit` (scheme StoreKit Configuration).
nonisolated enum StoreKitDemoProductIDs {
    static let tipJar = "com.ilkersevim.superDemoApp.demo.tip"
    static let allKnown: [String] = [tipJar]
}

/// Display DTO — no StoreKit types leak into the demo view model surface.
struct StoreKitDemoProduct: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let description: String
    let displayPrice: String
}

enum StoreKitProductQueryFailure: Error, Equatable, Sendable {
    case unavailable(reason: String)
}

@MainActor
protocol StoreKitProductQuerying: AnyObject {
    func products(for ids: [String]) async throws -> [StoreKitDemoProduct]
}

@MainActor
final class SystemStoreKitProductQuerier: StoreKitProductQuerying {
    func products(for ids: [String]) async throws -> [StoreKitDemoProduct] {
        do {
            let storeProducts = try await Product.products(for: Set(ids))
            return storeProducts
                .sorted { $0.id < $1.id }
                .map { product in
                    StoreKitDemoProduct(
                        id: product.id,
                        displayName: product.displayName,
                        description: product.description,
                        displayPrice: product.displayPrice
                    )
                }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw StoreKitProductQueryFailure.unavailable(
                reason: error.localizedDescription
            )
        }
    }
}
