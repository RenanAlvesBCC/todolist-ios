//
//  TodoTask+Stub.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

@testable import TodoList
import Foundation

extension TodoTask {
    static func stub(
        id: Int = 1,
        title: String = "Tarefa de teste",
        description: String = "",
        completed: Bool = false,
        userID: Int = 1
    ) -> TodoTask {
        let json = """
        {
            "ID": \(id),
            "CreatedAt": "2026-06-18T10:00:00Z",
            "UpdatedAt": "2026-06-18T10:00:00Z",
            "title": "\(title)",
            "description": "\(description)",
            "completed": \(completed),
            "user_id": \(userID)
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(TodoTask.self, from: json)
    }
}
