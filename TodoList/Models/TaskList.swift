//
//  TaskList.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

struct TaskList: Codable, Identifiable, Equatable {
    let id: Int
    let createdAt: Date
    let updatedAt: Date
    var title: String
    let userID: Int
    var items: [TaskItem]

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
        case title
        case userID = "user_id"
        case items
    }
}
