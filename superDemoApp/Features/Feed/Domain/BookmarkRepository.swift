//
//  BookmarkRepository.swift
//  superDemoApp
//

import Foundation

protocol BookmarkRepository {
    func observeChanges(_ onChange: @escaping @MainActor () -> Void)
    func bookmark(forPostID postID: Int) throws -> PostBookmark
    func allBookmarks() throws -> [PostBookmark]
    func setBookmarked(_ isBookmarked: Bool, postID: Int) throws -> PostBookmark
    func retryFailedMutations(forPostID postID: Int?) throws
    func failedMutationCount() throws -> Int
}
