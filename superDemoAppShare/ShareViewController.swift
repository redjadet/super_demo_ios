//
//  ShareViewController.swift
//  superDemoAppShare
//
//  Share extension: URL/text → App Group inbox (not SwiftData).
//  JP-P2-A — portfolio demo; Mac lane skips embed (`platformFilter = ios`).
//

import UIKit
import UniformTypeIdentifiers

/// Share sheet principal: writes one inbox entry then completes the request.
@objc(ShareViewController)
final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.configureChrome()
        Task { @MainActor in
            await self.persistSharedContent()
        }
    }

    private func configureChrome() {
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statusLabel.numberOfLines = 0
        self.statusLabel.textAlignment = .center
        self.statusLabel.text = String(localized: "Saving shared content to App Group inbox…")
        self.statusLabel.accessibilityIdentifier = "shareExtensionStatus"

        self.saveButton.translatesAutoresizingMaskIntoConstraints = false
        self.saveButton.setTitle(String(localized: "Done"), for: .normal)
        self.saveButton.addTarget(self, action: #selector(self.finish), for: .touchUpInside)
        self.saveButton.accessibilityIdentifier = "shareExtensionDone"

        self.view.addSubview(self.statusLabel)
        self.view.addSubview(self.saveButton)
        NSLayoutConstraint.activate([
            self.statusLabel.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            self.statusLabel.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            self.statusLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -24),
            self.saveButton.topAnchor.constraint(equalTo: self.statusLabel.bottomAnchor, constant: 16),
            self.saveButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
        ])
    }

    @objc
    private func finish() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    @MainActor
    private func persistSharedContent() async {
        let extracted = await Self.extractSharePayload(from: self.extensionContext)
        let entry = ShareInboxEntry(
            text: extracted.text,
            urlString: extracted.urlString
        )
        do {
            try ShareInboxStore.append(entry)
            self.statusLabel.text = String(
                localized: "Saved to Share inbox (App Group). Open the app → Engineering demos → Share inbox to review. SwiftData Items store is not written from the extension."
            )
        } catch ShareInboxStoreError.containerUnavailable {
            self.statusLabel.text = String(
                localized: "App Group unavailable (unsigned Simulator / missing entitlement). Share was not persisted — honesty path, not a silent success."
            )
        } catch {
            self.statusLabel.text =
                "Could not write Share inbox: \(error.localizedDescription)"
        }
    }

    private struct ExtractedShare {
        var text: String?
        var urlString: String?
    }

    private static func extractSharePayload(
        from context: NSExtensionContext?
    ) async -> ExtractedShare {
        guard let items = context?.inputItems as? [NSExtensionItem] else {
            return ExtractedShare()
        }
        var text: String?
        var urlString: String?
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await loadURL(from: provider) {
                        urlString = url.absoluteString
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let string = try? await loadString(from: provider) {
                        text = string
                    }
                }
            }
        }
        return ExtractedShare(text: text, urlString: urlString)
    }

    private static func loadURL(from provider: NSItemProvider) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil)
                {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "ShareInbox",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "URL load failed"]
                        )
                    )
                }
            }
        }
    }

    private static func loadString(from provider: NSItemProvider) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let string = item as? String {
                    continuation.resume(returning: string)
                } else if let data = item as? Data,
                          let string = String(data: data, encoding: .utf8)
                {
                    continuation.resume(returning: string)
                } else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "ShareInbox",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Text load failed"]
                        )
                    )
                }
            }
        }
    }
}
