//
//  CachedTaskItem.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import SwiftData
import Foundation

@Model
final class CachedTaskItem {
    @Attribute(.unique) var serverID: Int
    var text: String
    var completed: Bool
    var position: Int
    var taskListServerID: Int
    var syncedAt: Date
    var list: CachedTaskList?

    init(serverID: Int, text: String, completed: Bool, position: Int, taskListServerID: Int) {
        self.serverID = serverID
        self.text = text
        self.completed = completed
        self.position = position
        self.taskListServerID = taskListServerID
        self.syncedAt = Date()
    }

    func toTaskItem() -> TaskItem {
        TaskItem(
            id: serverID,
            createdAt: syncedAt,
            updatedAt: syncedAt,
            text: text,
            completed: completed,
            position: position,
            taskListID: taskListServerID
        )
    }
}
