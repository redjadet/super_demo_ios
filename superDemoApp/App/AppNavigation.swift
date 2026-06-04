//
//  AppNavigation.swift
//  superDemoApp
//

import Foundation

enum AppTab: Hashable {
    case dashboard
    case items
    case feed
}

enum AppRoute: Hashable {
    case productionRisks
}

enum AppDeepLink: Equatable {
    case productionRisks

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "superdemo",
              components.host?.lowercased() == "dashboard",
              components.path == "/risks",
              components.user == nil,
              components.password == nil,
              components.port == nil
        else {
            return nil
        }

        self = .productionRisks
    }
}

struct AppNavigationState {
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
        case .productionRisks:
            self.selection = .dashboard
            self.dashboardPath = [.productionRisks]
        }
    }
}
