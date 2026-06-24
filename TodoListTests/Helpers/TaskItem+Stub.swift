
//
//  Untitled.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

@testable import TodoList
import Foundation

extension TaskItem {
    static func stub(
        id: Int = 1,
        text: String = "Item de teste",
        completed: Bool = false,
        position: Int = 0,
        taskListID: Int = 1
    ) -> TaskItem {
        TaskItem(
            id: id,
            createdAt: Date(timeIntervalSince1970: 1_750_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_750_000_000),
            text: text,
            completed: completed,
            position: position,
            taskListID: taskListID
        )
    }
}
