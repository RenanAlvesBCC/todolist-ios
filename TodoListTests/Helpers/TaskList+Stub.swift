//
//  TaskList+Stub.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

@testable import TodoList
import Foundation

extension TaskList {
    static func stub(
        id: Int = 1,
        title: String = "Lista de teste",
        userID: Int = 1,
        items: [TaskItem] = []
    ) -> TaskList {
        TaskList(
            id: id,
            createdAt: Date(timeIntervalSince1970: 1_750_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_750_000_000),
            title: title,
            userID: userID,
            items: items
        )
    }
}
