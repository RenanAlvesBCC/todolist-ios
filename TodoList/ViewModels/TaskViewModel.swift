//
//  TaskViewModel.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class TaskViewModel {
    private(set) var taskLists: [TaskList] = []
    var isLoading = false
    var errorMessage: String?
    private(set) var hasPendingSync = false

    private let apiClient: TaskAPIClient
    private let cacheService: CacheServiceProtocol
    private let syncService: SyncServiceProtocol
    private let tempIDGenerator = TempIDGenerator()
    private var currentUserID: Int = 0

    init(
        apiClient: TaskAPIClient,
        cacheService: CacheServiceProtocol,
        syncService: SyncServiceProtocol
    ) {
        self.apiClient = apiClient
        self.cacheService = cacheService
        self.syncService = syncService
    }

    // MARK: - Sync

    func syncPendingOperations() async {
        guard syncService.hasPendingOperations else { return }
        await syncService.processPendingOperations()
        hasPendingSync = syncService.hasPendingOperations
        // Após sync, recarrega do servidor pra garantir consistência
        await loadLists()
    }

    // MARK: - Listas

    func loadLists() async {
        // 1. Mostra cache imediatamente
        let cached = cacheService.loadLists(userID: currentUserID)
        if !cached.isEmpty {
            taskLists = cached
        } else {
            isLoading = true
        }

        // 2. Busca do servidor em background
        do {
            let response = try await apiClient.fetchLists(search: searchText, page: 1, limit: 100)
            taskLists = response.lists
            currentUserID = response.lists.first?.userID ?? currentUserID
            cacheService.saveLists(response.lists)
        } catch {
            // Mantém o cache — não mostra erro se já tem dados
            if taskLists.isEmpty {
                errorMessage = message(for: error)
            }
        }

        isLoading = false
        hasPendingSync = syncService.hasPendingOperations
    }

    func addList(title: String) async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = L10n.Error.titleRequired
            return
        }

        errorMessage = nil
        let tempID = tempIDGenerator.next()
        let tempList = TaskList(
            id: tempID, createdAt: Date(), updatedAt: Date(),
            title: title, userID: currentUserID,
            position: taskLists.count, items: []
        )

        // Atualiza UI e cache imediatamente
        taskLists.append(tempList)
        cacheService.upsertList(tempList)

        do {
            let created = try await apiClient.createList(title: title)
            // Substitui o item temporário pelo real
            if let index = taskLists.firstIndex(where: { $0.id == tempID }) {
                taskLists[index] = created
            }
            cacheService.replaceTempID(tempID, with: created)
        } catch {
            // Enfileira pra sync posterior
            syncService.enqueue(PendingOperation(
                type: .createList,
                payload: CreateListPayload(title: title, tempID: tempID)
            ))
            hasPendingSync = true
        }
    }

    func deleteList(_ list: TaskList) async {
        errorMessage = nil
        taskLists.removeAll { $0.id == list.id }
        cacheService.deleteList(serverID: list.id)

        // Só envia pro servidor se não é um item pendente de criação
        guard list.id > 0 else { return }

        do {
            try await apiClient.deleteList(id: list.id)
        } catch {
            syncService.enqueue(PendingOperation(
                type: .deleteList,
                payload: DeleteListPayload(id: list.id)
            ))
            hasPendingSync = true
        }
    }

    func renameList(_ list: TaskList, title: String) async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = L10n.Error.titleRequired
            return
        }

        errorMessage = nil
        if let index = taskLists.firstIndex(where: { $0.id == list.id }) {
            taskLists[index].title = title
        }
        var updated = list
        updated.title = title
        cacheService.upsertList(updated)

        guard list.id > 0 else { return }

        do {
            let result = try await apiClient.updateList(id: list.id, title: title)
            if let index = taskLists.firstIndex(where: { $0.id == list.id }) {
                taskLists[index] = result
            }
            cacheService.upsertList(result)
        } catch {
            syncService.enqueue(PendingOperation(
                type: .updateList,
                payload: UpdateListPayload(id: list.id, title: title)
            ))
            hasPendingSync = true
        }
    }

    // MARK: - Itens

    func addItem(text: String, to list: TaskList) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = L10n.Error.itemTextRequired
            return
        }

        errorMessage = nil
        let tempID = tempIDGenerator.next()
        let tempItem = TaskItem(
            id: tempID, createdAt: Date(), updatedAt: Date(),
            text: text, completed: false,
            position: list.items.count, taskListID: list.id
        )

        if let index = taskLists.firstIndex(where: { $0.id == list.id }) {
            taskLists[index].items.append(tempItem)
        }
        cacheService.upsertItem(tempItem)

        guard list.id > 0 else {
            syncService.enqueue(PendingOperation(
                type: .createItem,
                payload: CreateItemPayload(listID: list.id, text: text, tempID: tempID)
            ))
            hasPendingSync = true
            return
        }

        do {
            let created = try await apiClient.addItem(listID: list.id, text: text)
            if let listIndex = taskLists.firstIndex(where: { $0.id == list.id }),
               let itemIndex = taskLists[listIndex].items.firstIndex(where: { $0.id == tempID }) {
                taskLists[listIndex].items[itemIndex] = created
            }
            cacheService.replaceTempItemID(tempID, with: created)
        } catch {
            syncService.enqueue(PendingOperation(
                type: .createItem,
                payload: CreateItemPayload(listID: list.id, text: text, tempID: tempID)
            ))
            hasPendingSync = true
        }
    }

    func toggleCompleted(_ item: TaskItem, in list: TaskList) async {
        await updateItem(item, in: list, text: item.text, completed: !item.completed)
    }

    func updateItem(_ item: TaskItem, in list: TaskList, text: String, completed: Bool) async {
        errorMessage = nil

        if let listIndex = taskLists.firstIndex(where: { $0.id == list.id }),
           let itemIndex = taskLists[listIndex].items.firstIndex(where: { $0.id == item.id }) {
            taskLists[listIndex].items[itemIndex].text = text
            taskLists[listIndex].items[itemIndex].completed = completed
        }
        var updatedItem = item
        updatedItem.text = text
        updatedItem.completed = completed
        cacheService.upsertItem(updatedItem)

        guard item.id > 0 else { return }

        do {
            let updated = try await apiClient.updateItem(
                listID: list.id, itemID: item.id, text: text, completed: completed
            )
            if let listIndex = taskLists.firstIndex(where: { $0.id == list.id }),
               let itemIndex = taskLists[listIndex].items.firstIndex(where: { $0.id == item.id }) {
                taskLists[listIndex].items[itemIndex] = updated
            }
            cacheService.upsertItem(updated)
        } catch {
            syncService.enqueue(PendingOperation(
                type: .updateItem,
                payload: UpdateItemPayload(listID: list.id, itemID: item.id, text: text, completed: completed)
            ))
            hasPendingSync = true
        }
    }

    func deleteItem(_ item: TaskItem, from list: TaskList) async {
        errorMessage = nil
        if let listIndex = taskLists.firstIndex(where: { $0.id == list.id }) {
            taskLists[listIndex].items.removeAll { $0.id == item.id }
        }
        cacheService.deleteItem(serverID: item.id)

        guard item.id > 0 else { return }

        do {
            try await apiClient.deleteItem(listID: list.id, itemID: item.id)
        } catch {
            syncService.enqueue(PendingOperation(
                type: .deleteItem,
                payload: DeleteItemPayload(listID: list.id, itemID: item.id)
            ))
            hasPendingSync = true
        }
    }

    // MARK: - Reordenação

    func moveLists(fromID: Int, toID: Int) {
        guard let fromIndex = taskLists.firstIndex(where: { $0.id == fromID }),
              let toIndex = taskLists.firstIndex(where: { $0.id == toID }),
              fromIndex != toIndex else { return }
        taskLists.move(
            fromOffsets: IndexSet(integer: fromIndex),
            toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
        )
    }

    func persistListOrder() async {
        do {
            try await apiClient.reorderLists(ids: taskLists.map(\.id))
        } catch {
            syncService.enqueue(PendingOperation(
                type: .reorderLists,
                payload: ReorderListsPayload(ids: taskLists.map(\.id))
            ))
            hasPendingSync = true
        }
    }

    func moveItems(in list: TaskList, fromID: Int, toID: Int) {
        guard let listIndex = taskLists.firstIndex(where: { $0.id == list.id }),
              let fromIndex = taskLists[listIndex].items.firstIndex(where: { $0.id == fromID }),
              let toIndex = taskLists[listIndex].items.firstIndex(where: { $0.id == toID }),
              fromIndex != toIndex else { return }
        taskLists[listIndex].items.move(
            fromOffsets: IndexSet(integer: fromIndex),
            toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
        )
    }

    func persistItemOrder(for list: TaskList) async {
        guard let current = taskLists.first(where: { $0.id == list.id }) else { return }
        do {
            try await apiClient.reorderItems(listID: list.id, ids: current.items.map(\.id))
        } catch {
            syncService.enqueue(PendingOperation(
                type: .reorderItems,
                payload: ReorderItemsPayload(listID: list.id, ids: current.items.map(\.id))
            ))
            hasPendingSync = true
        }
    }

    // MARK: - Busca

    var searchText = "" {
        didSet {
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                await loadLists()
            }
        }
    }

    private var searchTask: Task<Void, Never>?

    // MARK: - Helpers

    private func message(for error: Error) -> String {
        (error as? APIError)?.userMessage ?? error.localizedDescription
    }
}
