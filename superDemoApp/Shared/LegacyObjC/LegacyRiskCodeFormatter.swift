//
//  LegacyRiskCodeFormatter.swift
//  superDemoApp
//

import Foundation

struct LegacyRiskCodeFormatter {
    private let sanitizer: LegacyRiskSanitizer

    init(sanitizer: LegacyRiskSanitizer = LegacyRiskSanitizer()) {
        self.sanitizer = sanitizer
    }

    func code(title: String, owner: String?) -> String {
        self.sanitizer.normalizedRiskCode(fromTitle: title, owner: owner)
    }
}
