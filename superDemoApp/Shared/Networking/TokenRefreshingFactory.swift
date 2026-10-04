//
//  TokenRefreshingFactory.swift
//  superDemoApp
//
//  App-only wiring for launch-flag Keychain demo auth. SDK types come from
//  IlkerSevimNetworking (see IlkerSevimNetworkingExport.swift).
//

import Foundation

enum TokenRefreshingFactory {
    /// Default production path is empty; opt into Keychain demo via launch flag.
    static func makeDefault(
        usesKeychainDemo: Bool = AppLaunchConfiguration.usesKeychainTokenDemo
    ) -> any TokenRefreshing {
        if usesKeychainDemo {
            return KeychainDemoTokenRefresher(
                store: KeychainAccessTokenStore(service: "com.superdemoapp.token")
            )
        }
        return EmptyTokenRefresher()
    }
}
