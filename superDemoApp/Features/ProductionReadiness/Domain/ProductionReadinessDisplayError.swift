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
                self.message = "Validation was cancelled."
            case .unauthorizedAfterRefresh:
                self.message = "Session refresh failed. Sign in again before release validation."
            case .transport:
                self.message = "Network unavailable. Use cached sample states or retry on a stable connection."
            case .httpStatus:
                self.message = "API health check failed. Review server status before release."
            case .invalidResponse, .decodingFailed:
                self.message = "API response shape changed. Update mapping and tests before release."
            }
        } else {
            self.message = error.localizedDescription
        }
    }

    init(message: String) {
        self.message = message
    }
}
