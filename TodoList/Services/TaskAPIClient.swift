//
//  TaskAPIClient.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

protocol TaskAPIClient {
    func fetchTasks(completed: Bool?, search: String, page: Int, limit: Int) async throws -> TaskListResponse
    func createTask(title: String, description: String) async throws -> TodoTask
    func updateTask(id: Int, title: String, description: String, completed: Bool) async throws -> TodoTask
    func deleteTask(id: Int) async throws
}

extension APIClient: TaskAPIClient {}
