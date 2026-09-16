//
//  ProductionReadinessDisplayError.swift
//  superDemoApp
//

import Foundation

struct ProductionReadinessDisplayError: Equatable {
    let message: String

    init(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .cancelled:
                self.message = String(localized: "Validation was cancelled.")
            case .unauthorizedAfterRefresh:
                self.message = String(
                    localized: "Session refresh failed. Sign in again before release validation."
                )
            case .transport:
                self.message = String(
                    localized: "Network unavailable. Use cached sample states or retry on a stable connection."
                )
            case .httpStatus:
                self.message = String(
                    localized: "API health check failed. Review server status before release."
                )
            case .invalidResponse, .decodingFailed:
                self.message = String(
                    localized: "API response shape changed. Update mapping and tests before release."
                )
            }
        } else {
            self.message = error.localizedDescription
        }
    }

    init(message: String) {
        self.message = message
    }
}
