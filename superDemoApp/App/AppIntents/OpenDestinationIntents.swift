//
//  OpenDestinationIntents.swift
//  superDemoApp
//

import AppIntents

struct OpenFeedIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Feed"
    static var description = IntentDescription("Opens the Feed tab.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await Task.yield()
        AppIntentNavigationRouter.open(.feed)
        return .result()
    }
}

struct OpenItemsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Items"
    static var description = IntentDescription("Opens the Items tab.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await Task.yield()
        AppIntentNavigationRouter.open(.items)
        return .result()
    }
}

struct OpenProductionRisksIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Production Risks"
    static var description = IntentDescription("Opens Production Risks on the Dashboard.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await Task.yield()
        AppIntentNavigationRouter.open(.productionRisks)
        return .result()
    }
}

struct SuperDemoAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenFeedIntent(),
            phrases: [
                "Open Feed in \(.applicationName)",
                "Show Feed in \(.applicationName)",
            ],
            shortTitle: "Open Feed",
            systemImageName: "text.bubble"
        )
        AppShortcut(
            intent: OpenItemsIntent(),
            phrases: [
                "Open Items in \(.applicationName)",
                "Show Items in \(.applicationName)",
            ],
            shortTitle: "Open Items",
            systemImageName: "list.bullet"
        )
        AppShortcut(
            intent: OpenProductionRisksIntent(),
            phrases: [
                "Open Production Risks in \(.applicationName)",
                "Show Production Risks in \(.applicationName)",
            ],
            shortTitle: "Open Risks",
            systemImageName: "exclamationmark.triangle"
        )
    }
}
