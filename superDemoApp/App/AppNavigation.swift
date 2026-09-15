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

    /// Hosts allowed for HTTPS universal links (Associated Domains).
    static let associatedHosts: Set<String> = [
        "superdemo.app",
        "www.superdemo.app",
    ]

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.user == nil,
              components.password == nil,
              components.port == nil,
              let scheme = components.scheme?.lowercased()
        else {
            return nil
        }

        let segments: [String]
        switch scheme {
        case "superdemo":
            guard let host = components.host?.lowercased() else { return nil }
            segments = Self.pathSegments(host: host, path: components.path)
        case "https":
            guard let host = components.host?.lowercased(),
                  Self.associatedHosts.contains(host)
            else {
                return nil
            }
            segments = Self.pathSegments(host: nil, path: components.path)
        default:
            return nil
        }

        guard let link = Self.link(from: segments) else {
            return nil
        }
        self = link
    }

    private static func pathSegments(host: String?, path: String) -> [String] {
        var segments: [String] = []
        if let host, !host.isEmpty {
            segments.append(host)
        }
        let pathParts = path
            .lowercased()
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
        segments.append(contentsOf: pathParts)
        return segments
    }

    private static func link(from segments: [String]) -> AppDeepLink? {
        switch segments {
        case ["dashboard", "risks"]:
            return .productionRisks
        case ["dashboard"]:
            return .dashboard
        case ["items"]:
            return .items
        case ["feed"]:
            return .feed
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
