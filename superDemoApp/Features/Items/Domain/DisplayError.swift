//
//  DisplayError.swift
//  superDemoApp
//

import Foundation

struct DisplayError: Equatable {
    let message: String

    init(_ error: Error) {
        self.message = error.localizedDescription
    }

    init(message: String) {
        self.message = message
    }
}
