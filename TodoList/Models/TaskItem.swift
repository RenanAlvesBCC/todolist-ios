//
//  TaskItem.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

struct TaskItem: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let createdAt: Date
    let updatedAt: Date
    var text: String
    var completed: Bool
    let taskListID: Int

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
        case text
        case completed
        case taskListID = "task_list_id"
    }
}
