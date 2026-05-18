//
//  AppURLSession.swift
//  superDemoApp
//

import Foundation

enum AppURLSession {
    /// One process-wide session; avoids leaking `URLSession` instances from repeated `makeDefault()` calls.
    private static let sharedSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()

    /// Shared defaults for app-issued HTTP (matches `APIRequest` request timeout).
    static func makeDefault() -> URLSession {
        self.sharedSession
    }
}
