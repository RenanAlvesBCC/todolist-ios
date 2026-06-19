//
//  TaskModels.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

struct TaskListResponse: Codable {
    let tasks: [TodoTask]
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case tasks, page, limit, total
        case totalPages = "total_pages"
    }
}

struct CreateTaskInput: Codable {
    let title: String
    let description: String
}

struct UpdateTaskInput: Codable {
    let title: String
    let description: String
    let completed: Bool
}
