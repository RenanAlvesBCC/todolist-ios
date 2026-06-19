//
//  Task.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

struct Task: Codable, Identifiable, Equatable {
    let id: Int
    let createdAt: Date
    let updatedAt: Date
    let title: String
    let description: String
    let completed: Bool
    let userID: Int

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
        case title
        case description
        case completed
        case userID = "user_id"
    }
}
