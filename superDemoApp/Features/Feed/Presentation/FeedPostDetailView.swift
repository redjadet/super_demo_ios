//
//  FeedPostDetailView.swift
//  superDemoApp
//

import SwiftUI

struct FeedPostDetailView: View {
    let post: FeedPost

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(self.post.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(self.post.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Post")
        .iosInlineNavigationBarTitle()
        .accessibilityIdentifier("feedPostDetail-\(self.post.id)")
    }
}
