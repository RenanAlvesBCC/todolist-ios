//
//  SyncService.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import SwiftData
import Foundation

@MainActor
final class SyncService: SyncServiceProtocol {
    private let apiClient: TaskAPIClient
    private let cacheService: CacheServiceProtocol
    private let modelContext: ModelContext

    init(apiClient: TaskAPIClient, cacheService: CacheServiceProtocol, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.cacheService = cacheService
        self.modelContext = modelContext
    }

    var hasPendingOperations: Bool {
        let descriptor = FetchDescriptor<PendingOperation>()
        return ((try? modelContext.fetch(descriptor))?.count ?? 0) > 0
    }

    func enqueue(_ operation: PendingOperation) {
        modelContext.insert(operation)
        try? modelContext.save()
    }

    func processPendingOperations() async {
        let descriptor = FetchDescriptor<PendingOperation>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        guard let operations = try? modelContext.fetch(descriptor),
              !operations.isEmpty else { return }

        for operation in operations {
            let success = await process(operation)
            if success {
                modelContext.delete(operation)
            } else {
                operation.retryCount += 1
                // Remove da fila após 5 tentativas — evita retry infinito de operações inválidas
                if operation.retryCount >= 5 {
                    modelContext.delete(operation)
                }
            }
        }
        try? modelContext.save()
    }

    private func process(_ operation: PendingOperation) async -> Bool {
        guard let type = PendingOperationType(rawValue: operation.operationType) else { return true }

        do {
            switch type {
            case .createList:
                guard let payload = operation.decoded(as: CreateListPayload.self) else { return true }
                let created = try await apiClient.createList(title: payload.title)
                cacheService.replaceTempID(payload.tempID, with: created)

            case .updateList:
                guard let payload = operation.decoded(as: UpdateListPayload.self) else { return true }
                let updated = try await apiClient.updateList(id: payload.id, title: payload.title)
                cacheService.upsertList(updated)

            case .deleteList:
                guard let payload = operation.decoded(as: DeleteListPayload.self) else { return true }
                try await apiClient.deleteList(id: payload.id)

            case .createItem:
                guard let payload = operation.decoded(as: CreateItemPayload.self) else { return true }
                let created = try await apiClient.addItem(listID: payload.listID, text: payload.text)
                cacheService.replaceTempItemID(payload.tempID, with: created)

            case .updateItem:
                guard let payload = operation.decoded(as: UpdateItemPayload.self) else { return true }
                let updated = try await apiClient.updateItem(
                    listID: payload.listID, itemID: payload.itemID,
                    text: payload.text, completed: payload.completed
                )
                cacheService.upsertItem(updated)

            case .deleteItem:
                guard let payload = operation.decoded(as: DeleteItemPayload.self) else { return true }
                try await apiClient.deleteItem(listID: payload.listID, itemID: payload.itemID)

            case .reorderLists:
                guard let payload = operation.decoded(as: ReorderListsPayload.self) else { return true }
                try await apiClient.reorderLists(ids: payload.ids)

            case .reorderItems:
                guard let payload = operation.decoded(as: ReorderItemsPayload.self) else { return true }
                try await apiClient.reorderItems(listID: payload.listID, ids: payload.ids)
            }
            return true
        } catch {
            return false
        }
    }
}
