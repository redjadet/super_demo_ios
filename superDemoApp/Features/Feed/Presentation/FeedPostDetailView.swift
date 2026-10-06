//
//  FeedPostDetailView.swift
//  superDemoApp
//

import SwiftUI

struct FeedPostDetailView: View {
    let post: FeedPost
    private let model: FeedFeatureModel?

    init(post: FeedPost, model: FeedFeatureModel? = nil) {
        self.post = post
        self.model = model
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(self.post.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(self.post.body)
                    .foregroundStyle(.secondary)

                if let model {
                    FeedBookmarkButton(
                        bookmark: model.bookmark(for: self.post.id),
                        action: { model.toggleBookmark(for: self.post.id) },
                        onRetry: { model.retryFailedBookmarks(postID: self.post.id) }
                    )
                    .padding(.top, 8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Post")
        .iosInlineNavigationBarTitle()
        .accessibilityIdentifier("feedPostDetail-\(self.post.id)")
    }
}
