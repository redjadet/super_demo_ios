//
//  ToggleBookmarkUseCase.swift
//  superDemoApp
//

import Foundation

struct ToggleBookmarkUseCase {
    private let repository: BookmarkRepository

    init(repository: BookmarkRepository) {
        self.repository = repository
    }

    func callAsFunction(postID: Int) throws -> PostBookmark {
        let current = try self.repository.bookmark(forPostID: postID)
        return try self.repository.setBookmarked(!current.isBookmarked, postID: postID)
    }
}

struct RetryBookmarkSyncUseCase {
    private let repository: BookmarkRepository

    init(repository: BookmarkRepository) {
        self.repository = repository
    }

    func callAsFunction(postID: Int? = nil) throws {
        try self.repository.retryFailedMutations(forPostID: postID)
    }
}
