//
//  AppNavigation.swift
//  superDemoApp
//

import Foundation
import Observation

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
    /// Opens Feed and selects a post by JSONPlaceholder-style id when present.
    case feedPost(id: Int)

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

    private static func link(from segments: [String]) -> Self? {
        switch segments {
        case ["dashboard", "risks"]:
            return .productionRisks
        case ["dashboard"]:
            return .dashboard
        case ["items"]:
            return .items
        case ["feed"]:
            return .feed
        case let parts where parts.count == 2 && parts[0] == "feed":
            guard let id = Int(parts[1]), id > 0 else { return nil }
            return .feedPost(id: id)
        default:
            return nil
        }
    }

    /// Custom-scheme URL used by App Intents handoff and UI tests.
    var customSchemeURL: URL {
        switch self {
        case .dashboard:
            Self.dashboardURL
        case .productionRisks:
            Self.productionRisksURL
        case .items:
            Self.itemsURL
        case .feed:
            Self.feedURL
        case let .feedPost(id):
            Self.customURL(host: "feed", path: "/\(id)")
        }
    }

    private static let dashboardURL = customURL(host: "dashboard")
    private static let productionRisksURL = customURL(host: "dashboard", path: "/risks")
    private static let itemsURL = customURL(host: "items")
    private static let feedURL = customURL(host: "feed")

    private static func customURL(host: String, path: String = "") -> URL {
        var components = URLComponents()
        components.scheme = "superdemo"
        components.host = host
        if !path.isEmpty {
            components.path = path.hasPrefix("/") ? path : "/" + path
        }
        guard let url = components.url else {
            preconditionFailure("Invalid deep link components for host \(host)")
        }
        return url
    }
}

nonisolated struct AppNavigationState {
    var selection: AppTab = .dashboard
    var dashboardPath: [AppRoute] = []
    var invalidDeepLinkMessage: String?
    /// Bumped by App Intents / typed callers to request a Feed refresh.
    /// Deep links do not touch it; `FeedRefreshCoordinator` refreshes a live model.
    var feedRefreshRequestID: UInt = 0
    /// Pending Feed post id from App Intent / deep link (`superdemo://feed/<id>`).
    /// `FeedView` selects the matching row when content is loaded, then clears.
    var feedOpenPostID: Int?
    /// Bumped whenever `feedOpenPostID` is set so remounts re-apply selection.
    var feedOpenPostRequestID: UInt = 0

    mutating func handle(url: URL) {
        guard let deepLink = AppDeepLink(url: url) else {
            self.selection = .dashboard
            self.dashboardPath = []
            self.invalidDeepLinkMessage = String(
                localized: "This link is not supported. The Dashboard is open instead."
            )
            return
        }
        self.apply(deepLink)
    }

    mutating func apply(_ deepLink: AppDeepLink) {
        self.invalidDeepLinkMessage = nil

        switch deepLink {
        case .dashboard:
            self.selection = .dashboard
            self.dashboardPath = []
            self.feedOpenPostID = nil
        case .productionRisks:
            self.selection = .dashboard
            self.dashboardPath = [.productionRisks]
            self.feedOpenPostID = nil
        case .items:
            self.selection = .items
            self.dashboardPath = []
            self.feedOpenPostID = nil
        case .feed:
            self.selection = .feed
            self.dashboardPath = []
            self.feedOpenPostID = nil
        case let .feedPost(id):
            self.requestOpenFeedPost(id: id)
        }
    }

    /// Requests a Feed refresh via typed navigation state (not string routes).
    mutating func requestFeedRefresh(openFeedTab: Bool = true) {
        self.invalidDeepLinkMessage = nil
        if openFeedTab {
            self.selection = .feed
            self.dashboardPath = []
        }
        self.feedRefreshRequestID &+= 1
    }

    /// Opens Feed and queues selection of a post by id (honest demo; missing id = no-op).
    mutating func requestOpenFeedPost(id: Int) {
        self.invalidDeepLinkMessage = nil
        self.selection = .feed
        self.dashboardPath = []
        self.feedOpenPostID = id
        self.feedOpenPostRequestID &+= 1
    }

    mutating func clearPendingFeedPostOpen() {
        self.feedOpenPostID = nil
    }
}

@MainActor
@Observable
final class AppNavigationStore {
    static let shared = AppNavigationStore()
    nonisolated(unsafe) static var testingOverride: AppNavigationStore?

    static var current: AppNavigationStore {
        testingOverride ?? shared
    }

    var state = AppNavigationState()

    func handle(url: URL) {
        self.state.handle(url: url)
    }

    func apply(_ deepLink: AppDeepLink) {
        self.state.apply(deepLink)
    }

    func requestFeedRefresh(openFeedTab: Bool = true) {
        self.state.requestFeedRefresh(openFeedTab: openFeedTab)
    }

    func requestOpenFeedPost(id: Int) {
        self.state.requestOpenFeedPost(id: id)
    }

    func clearPendingFeedPostOpen() {
        self.state.clearPendingFeedPostOpen()
    }

    func resetForTesting() {
        self.state = AppNavigationState()
    }
}
