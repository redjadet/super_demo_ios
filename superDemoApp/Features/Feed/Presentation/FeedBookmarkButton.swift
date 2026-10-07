//
//  FeedBookmarkButton.swift
//  superDemoApp
//

import SwiftUI

struct FeedBookmarkButton: View {
    let bookmark: PostBookmark
    let action: () -> Void
    var onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            Button(action: self.action) {
                Label {
                    Text(self.bookmark.isBookmarked ? "Bookmarked" : "Bookmark")
                } icon: {
                    Image(systemName: self.bookmark.isBookmarked ? "star.fill" : "star")
                }
            }
            .accessibilityIdentifier("feedBookmark-\(self.bookmark.postID)")
            .accessibilityValue(self.accessibilityValue)

            if self.bookmark.syncStatus == .pending {
                ProgressView()
                    .controlSize(.mini)
                    .accessibilityIdentifier("feedBookmarkPending-\(self.bookmark.postID)")
            } else if self.bookmark.syncStatus == .failed {
                Button {
                    self.onRetry?()
                } label: {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.red)
                }
                .accessibilityIdentifier("feedBookmarkFailed-\(self.bookmark.postID)")
                .accessibilityLabel("Bookmark sync failed. Retry.")
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
    }

    private var accessibilityValue: String {
        switch self.bookmark.syncStatus {
        case .synced:
            self.bookmark.isBookmarked ? "bookmarked" : "not bookmarked"
        case .pending:
            "pending sync"
        case .failed:
            "sync failed"
        }
    }
}
