//
//  TaskList.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

struct TaskList: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let createdAt: Date
    let updatedAt: Date
    var title: String
    let userID: Int
    var position: Int
    var items: [TaskItem]

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
        case title
        case userID = "user_id"
        case position
        case items
    }

}

extension TaskList {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        title = try c.decode(String.self, forKey: .title)
        userID = try c.decode(Int.self, forKey: .userID)
        position = try c.decodeIfPresent(Int.self, forKey: .position) ?? 0
        items = try c.decodeIfPresent([TaskItem].self, forKey: .items) ?? []
    }
}
