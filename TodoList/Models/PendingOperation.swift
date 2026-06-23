//
//  PendingOperation.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import SwiftData
import Foundation

enum PendingOperationType: String, Codable {
    case createList
    case updateList
    case deleteList
    case createItem
    case updateItem
    case deleteItem
    case reorderLists
    case reorderItems
}

// Payloads — um por tipo de operação
struct CreateListPayload: Codable { let title: String; let tempID: Int }
struct UpdateListPayload: Codable { let id: Int; let title: String }
struct DeleteListPayload: Codable { let id: Int }
struct CreateItemPayload: Codable { let listID: Int; let text: String; let tempID: Int }
struct UpdateItemPayload: Codable { let listID: Int; let itemID: Int; let text: String; let completed: Bool }
struct DeleteItemPayload: Codable { let listID: Int; let itemID: Int }
struct ReorderListsPayload: Codable { let ids: [Int] }
struct ReorderItemsPayload: Codable { let listID: Int; let ids: [Int] }

@Model
final class PendingOperation {
    var operationType: String
    var payloadJSON: String
    var createdAt: Date
    var retryCount: Int

    init(type: PendingOperationType, payload: some Encodable) {
        self.operationType = type.rawValue
        self.payloadJSON = (try? String(data: JSONEncoder().encode(payload), encoding: .utf8)) ?? "{}"
        self.createdAt = Date()
        self.retryCount = 0
    }

    func decoded<T: Decodable>(as type: T.Type) -> T? {
        guard let data = payloadJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
