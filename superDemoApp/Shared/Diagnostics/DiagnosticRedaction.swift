//
//  DiagnosticRedaction.swift
//  superDemoApp
//

import Foundation

/// Backstop redaction for diagnostic metadata and reasons.
/// Prefer omitting secrets at call sites; approved fields live in docs/incident-playbook.md.
nonisolated enum DiagnosticRedaction {
    private static let sensitiveKeys: Set<String> = [
        "authorization",
        "token",
        "access_token",
        "refresh_token",
        "password",
        "secret",
        "api_key",
        "apikey",
        "bearer",
    ]

    static func sanitizeMetadata(_ metadata: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in metadata {
            if self.isSensitiveKey(key) {
                result[key] = "<redacted>"
            } else {
                result[key] = self.sanitizeText(value)
            }
        }
        return result
    }

    static func sanitizeText(_ text: String) -> String {
        var output = text
        // Bearer tokens
        if let regex = try? NSRegularExpression(
            pattern: #"(?i)bearer\s+[A-Za-z0-9._\-]+"#
        ) {
            let range = NSRange(output.startIndex ..< output.endIndex, in: output)
            output = regex.stringByReplacingMatches(
                in: output,
                range: range,
                withTemplate: "Bearer <redacted>"
            )
        }
        return output
    }

    private static func isSensitiveKey(_ key: String) -> Bool {
        let normalized = key.lowercased().replacingOccurrences(of: "-", with: "_")
        if self.sensitiveKeys.contains(normalized) {
            return true
        }
        return self.sensitiveKeys.contains { normalized.contains($0) }
    }
}
