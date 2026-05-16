//
//  FeedDisplayError.swift
//  superDemoApp
//

import Foundation

struct FeedDisplayError: Equatable {
    let message: String

    init(_ error: Error) {
        if let feedError = error as? FeedError {
            self.message = feedError.localizedDescription
        } else if let urlError = error as? URLError {
            self.message = urlError.localizedDescription
        } else {
            self.message = error.localizedDescription
        }
    }

    init(message: String) {
        self.message = message
    }
}
