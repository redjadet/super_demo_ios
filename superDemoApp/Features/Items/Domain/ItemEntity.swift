//
//  ItemEntity.swift
//  superDemoApp
//

import Foundation

struct ItemEntity: Equatable, Hashable, Identifiable {
    let id: UUID
    var title: String
    var note: String
    let timestamp: Date
}
