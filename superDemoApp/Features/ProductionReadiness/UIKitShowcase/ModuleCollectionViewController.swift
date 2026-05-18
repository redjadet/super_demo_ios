//
//  ModuleCollectionViewController.swift
//  superDemoApp
//

#if os(iOS)
import SwiftUI
import UIKit

final class ModuleCollectionViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {
    typealias ModuleCellRegistration = UICollectionView.CellRegistration<
        UICollectionViewListCell, String
    >
    typealias SectionID = String

    let showcaseTransitionCoordinator = ShowcaseNavigationTransitionCoordinator()
    private var dataSource: UICollectionViewDiffableDataSource<SectionID, String>?
    private var modules: [FeatureModule]
    private var prefetchTasks: [String: Task<Void, Never>] = [:]

    init(modules: [FeatureModule]) {
        self.modules = modules
        super.init(collectionViewLayout: Self.makeLayout())
        self.title = "UIKit Modules"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    deinit {
        self.cancelAllPrefetchTasks()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isMovingFromParent || self.isBeingDismissed {
            self.teardown()
        }
    }

    /// Called on the main thread when the SwiftUI host removes this hierarchy.
    func teardown() {
        self.collectionView.prefetchDataSource = nil
        self.cancelAllPrefetchTasks()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.backgroundColor = .systemGroupedBackground
        self.collectionView.prefetchDataSource = self
        self.collectionView.accessibilityIdentifier = "uikitShowcaseCollection"
        self.configureDataSource()
        self.apply(modules: self.modules)
    }

    func apply(modules: [FeatureModule]) {
        self.modules = modules
        var snapshot = NSDiffableDataSourceSnapshot<SectionID, String>()
        snapshot.appendSections(["main"])
        snapshot.appendItems(modules.map(\.id))
        self.dataSource?.apply(snapshot, animatingDifferences: true)
    }

    override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let id = self.dataSource?.itemIdentifier(for: indexPath),
              let module = self.module(id: id)
        else { return }
        let detail = UIHostingController(rootView: ModuleUIKitDetailView(module: module))
        detail.title = module.name
        self.navigationController?.pushViewController(detail, animated: true)
    }

    func collectionView(_: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let id = self.dataSource?.itemIdentifier(for: indexPath),
                  self.prefetchTasks[id] == nil
            else {
                continue
            }
            self.prefetchTasks[id] = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 80_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.prefetchTasks[id] = nil
                }
            }
        }
    }

    func collectionView(_: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let id = self.dataSource?.itemIdentifier(for: indexPath) else { continue }
            self.prefetchTasks[id]?.cancel()
            self.prefetchTasks[id] = nil
        }
    }

    private func cancelAllPrefetchTasks() {
        for task in self.prefetchTasks.values {
            task.cancel()
        }
        self.prefetchTasks.removeAll()
    }

    private func configureDataSource() {
        let registration = ModuleCellRegistration { [weak self] cell, _, id in
            guard let module = self?.module(id: id) else { return }
            var content = UIListContentConfiguration.subtitleCell()
            content.text = module.name
            content.secondaryText = module.summary
            content.image = UIImage(systemName: module.status.symbolName)
            content.imageProperties.tintColor = module.status.tintColor
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
        }

        self.dataSource = UICollectionViewDiffableDataSource<SectionID, String>(
            collectionView: self.collectionView
        ) { collectionView, indexPath, id -> UICollectionViewCell? in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: id)
        }
    }

    private func module(id: String) -> FeatureModule? {
        self.modules.first { $0.id == id }
    }

    private static func makeLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .none
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
}

private struct ModuleUIKitDetailView: View {
    let module: FeatureModule

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(self.module.name, systemImage: self.module.status.symbolName)
                .font(.title2)
                .fontWeight(.semibold)
            Text(self.module.summary)
                .foregroundStyle(.secondary)
            Text(
                "UIKit controls mature flows well; SwiftUI keeps this detail readable through UIHostingController."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

fileprivate extension ReadinessStatus {
    var symbolName: String {
        switch self {
        case .healthy:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .blocked:
            "xmark.octagon.fill"
        }
    }

    var tintColor: UIColor {
        switch self {
        case .healthy:
            .systemGreen
        case .warning:
            .systemOrange
        case .blocked:
            .systemRed
        }
    }
}
#endif
