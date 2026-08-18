//
//  TaskAPIClient.swift
//  TodoList
//

import Foundation

protocol TaskAPIClient {
    func fetchLists(search: String, page: Int, limit: Int, status: String?, mine: Bool) async throws -> TaskListResponse
    func createList(title: String) async throws -> TaskList
    func updateList(id: Int, title: String) async throws -> TaskList
    func deleteList(id: Int) async throws
    func addItem(listID: Int, text: String) async throws -> TaskItem
    func updateItem(listID: Int, itemID: Int, text: String, completed: Bool) async throws -> TaskItem
    func deleteItem(listID: Int, itemID: Int) async throws
    func reorderLists(ids: [Int]) async throws
    func reorderItems(listID: Int, ids: [Int]) async throws
    func changeStatus(listID: Int, status: VehicleStatus) async throws
    func fetchQuotes(listID: Int) async throws -> [QuoteItem]
    func addQuote(listID: Int, text: String) async throws -> QuoteItem
    func fetchFlags(listID: Int) async throws -> [PendingFlag]
    func addFlag(listID: Int, flagType: String, note: String) async throws -> PendingFlag
    func resolveFlag(listID: Int, flagID: Int) async throws
}
