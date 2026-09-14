//
//  AppNavigation.swift
//  superDemoApp
//

import Foundation

nonisolated enum AppTab: Hashable {
    case dashboard
    case items
    case feed
}

nonisolated enum AppRoute: Hashable {
    case productionRisks
}

nonisolated enum AppDeepLink: Equatable {
    case dashboard
    case productionRisks
    case items
    case feed

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "superdemo",
              components.user == nil,
              components.password == nil,
              components.port == nil,
              let host = components.host?.lowercased()
        else {
            return nil
        }

        let path = components.path.lowercased()
        switch (host, path) {
        case ("dashboard", "/risks"):
            self = .productionRisks
        case ("dashboard", ""), ("dashboard", "/"):
            self = .dashboard
        case ("items", ""), ("items", "/"):
            self = .items
        case ("feed", ""), ("feed", "/"):
            self = .feed
        default:
            return nil
        }
    }
}

nonisolated struct AppNavigationState {
    var selection: AppTab = .dashboard
    var dashboardPath: [AppRoute] = []
    var invalidDeepLinkMessage: String?

    mutating func handle(url: URL) {
        guard let deepLink = AppDeepLink(url: url) else {
            self.selection = .dashboard
            self.dashboardPath = []
            self.invalidDeepLinkMessage = "This link is not supported. The Dashboard is open instead."
            return
        }

        self.invalidDeepLinkMessage = nil

        switch deepLink {
        case .dashboard:
            self.selection = .dashboard
            self.dashboardPath = []
        case .productionRisks:
            self.selection = .dashboard
            self.dashboardPath = [.productionRisks]
        case .items:
            self.selection = .items
            self.dashboardPath = []
        case .feed:
            self.selection = .feed
            self.dashboardPath = []
        }
    }
}
