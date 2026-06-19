//
//  TaskListModels.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

struct CreateListInput: Codable {
    let title: String
}

struct UpdateListInput: Codable {
    let title: String
}

struct CreateItemInput: Codable {
    let text: String
}

struct UpdateItemInput: Codable {
    let text: String
    let completed: Bool
}

struct TaskListResponse: Codable {
    let lists: [TaskList]
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case lists, page, limit, total
        case totalPages = "total_pages"
    }
}
