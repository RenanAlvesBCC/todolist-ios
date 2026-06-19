//
//  TaskAPIClient.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

protocol TaskAPIClient {
    func fetchLists(search: String, page: Int, limit: Int) async throws -> TaskListResponse
    func createList(title: String) async throws -> TaskList
    func updateList(id: Int, title: String) async throws -> TaskList
    func deleteList(id: Int) async throws
    func addItem(listID: Int, text: String) async throws -> TaskItem
    func updateItem(listID: Int, itemID: Int, text: String, completed: Bool) async throws -> TaskItem
    func deleteItem(listID: Int, itemID: Int) async throws
}
