//
//  ErrorDiagnostics.swift
//  superDemoApp
//

import Foundation

enum ErrorDiagnostics {
    static func reason(for error: Error) -> String {
        guard let localized = error as? LocalizedError else {
            return String(describing: type(of: error))
        }
        guard let description = localized.errorDescription, !description.isEmpty else {
            return String(describing: type(of: error))
        }
        return description
    }
}
