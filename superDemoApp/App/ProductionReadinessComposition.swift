//
//  ProductionReadinessComposition.swift
//  superDemoApp
//

import SwiftUI

enum ProductionReadinessComposition {
    private static var remoteHealthEndpoint: URL {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
            preconditionFailure("Invalid remote health URL")
        }
        return url
    }

    @MainActor
    static func makeFeatureModel() -> ProductionReadinessFeatureModel {
        let repository = self.makeRepository()
        return ProductionReadinessFeatureModel(
            loadSnapshot: LoadProductionReadinessSnapshotUseCase(repository: repository)
        )
    }

    @MainActor
    private static func makeRepository() -> ProductionReadinessRepository {
        let sample = SampleProductionReadinessRepository()
        if AppLaunchConfiguration.isUITesting {
            return sample
        }
        let client = URLSessionAPIClient(session: AppURLSession.makeDefault())
        let remoteHealth = RemoteAPIHealthRepository(
            client: client,
            endpoint: self.remoteHealthEndpoint
        )
        return CompositeProductionReadinessRepository(
            sample: sample,
            remoteHealth: remoteHealth,
            remoteEndpoint: self.remoteHealthEndpoint
        )
    }
}

struct ProductionReadinessRootView: View {
    @State private var model = ProductionReadinessComposition.makeFeatureModel()

    var body: some View {
        ProductionReadinessView(model: self.model)
    }
}
