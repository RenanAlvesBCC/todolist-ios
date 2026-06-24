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
    var position: Int
    let taskListID: Int

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
        case text
        case completed
        case position
        case taskListID = "task_list_id"
    }

}

extension TaskItem {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        text = try c.decode(String.self, forKey: .text)
        completed = try c.decode(Bool.self, forKey: .completed)
        position = try c.decodeIfPresent(Int.self, forKey: .position) ?? 0
        taskListID = try c.decode(Int.self, forKey: .taskListID)
    }
}
