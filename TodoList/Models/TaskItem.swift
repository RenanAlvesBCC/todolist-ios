//
//  TaskItem.swift
//  TodoList
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
        case id, ID
        case createdAt, CreatedAt
        case updatedAt, UpdatedAt
        case text
        case completed
        case position
        case taskListID = "task_list_id"
    }

    init(
        id: Int,
        createdAt: Date,
        updatedAt: Date,
        text: String,
        completed: Bool,
        position: Int,
        taskListID: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.text = text
        self.completed = completed
        self.position = position
        self.taskListID = taskListID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try c.decodeIfPresent(Int.self, forKey: .id) {
            id = value
        } else {
            id = try c.decode(Int.self, forKey: .ID)
        }
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
            ?? c.decodeIfPresent(Date.self, forKey: .CreatedAt)
            ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
            ?? c.decodeIfPresent(Date.self, forKey: .UpdatedAt)
            ?? Date()
        text = try c.decode(String.self, forKey: .text)
        completed = try c.decode(Bool.self, forKey: .completed)
        position = try c.decodeIfPresent(Int.self, forKey: .position) ?? 0
        taskListID = try c.decode(Int.self, forKey: .taskListID)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(text, forKey: .text)
        try c.encode(completed, forKey: .completed)
        try c.encode(position, forKey: .position)
        try c.encode(taskListID, forKey: .taskListID)
    }
}
