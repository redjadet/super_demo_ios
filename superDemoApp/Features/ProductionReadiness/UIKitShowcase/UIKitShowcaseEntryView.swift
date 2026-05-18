//
//  UIKitShowcaseEntryView.swift
//  superDemoApp
//

import SwiftUI

struct UIKitShowcaseEntryView: View {
    let modules: [FeatureModule]

    var body: some View {
        #if os(iOS)
        UIKitShowcaseContainerView(modules: self.modules)
            .navigationTitle("UIKit Showcase")
            .navigationBarTitleDisplayMode(.inline)
        #else
        let message = "UICollectionView and custom transitions are iOS-only. Mac keeps SwiftUI shell."
        ContentUnavailableView {
            Label("UIKit Showcase", systemImage: "rectangle.grid.2x2")
        } description: {
            Text(
                message
            )
        }
        #endif
    }
}

#if os(iOS)
private struct UIKitShowcaseContainerView: UIViewControllerRepresentable {
    let modules: [FeatureModule]

    func makeUIViewController(context _: Context) -> UINavigationController {
        let controller = ModuleCollectionViewController(modules: self.modules)
        let navigation = UINavigationController(rootViewController: controller)
        navigation.delegate = controller.showcaseTransitionCoordinator
        navigation.view.accessibilityIdentifier = "uikitShowcaseCollection"
        return navigation
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context _: Context) {
        guard
            let controller = uiViewController.viewControllers.first as? ModuleCollectionViewController
        else { return }
        controller.apply(modules: self.modules)
    }

    static func dismantleUIViewController(
        _ uiViewController: UINavigationController, coordinator _: ()
    ) {
        uiViewController.delegate = nil
        if let controller = uiViewController.viewControllers.first as? ModuleCollectionViewController {
            controller.teardown()
        }
    }
}
#endif
