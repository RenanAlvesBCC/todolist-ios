//
//  CachedTaskList.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import SwiftData
import Foundation

@Model
final class CachedTaskList {
    @Attribute(.unique) var serverID: Int
    var title: String
    var userID: Int
    var position: Int
    var syncedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CachedTaskItem.list)
    var items: [CachedTaskItem] = []

    init(serverID: Int, title: String, userID: Int, position: Int) {
        self.serverID = serverID
        self.title = title
        self.userID = userID
        self.position = position
        self.syncedAt = Date()
    }

    func toTaskList() -> TaskList {
        TaskList(
            id: serverID,
            createdAt: syncedAt,
            updatedAt: syncedAt,
            title: title,
            userID: userID,
            position: position,
            items: items
                .sorted { $0.position < $1.position }
                .map { $0.toTaskItem() }
        )
    }
}
