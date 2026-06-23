//
//  CacheService.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import SwiftData
import Foundation

@MainActor
final class CacheService: CacheServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveLists(_ lists: [TaskList]) {
        lists.forEach { upsertList($0) }
        // Remove listas do cache que não vieram mais do servidor
        let serverIDs = Set(lists.map(\.id))
        let descriptor = FetchDescriptor<CachedTaskList>()
        let cached = (try? modelContext.fetch(descriptor)) ?? []
        cached.filter { !serverIDs.contains($0.serverID) }.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }

    func loadLists(userID: Int) -> [TaskList] {
        var descriptor = FetchDescriptor<CachedTaskList>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.position)]
        )
        let cached = (try? modelContext.fetch(descriptor)) ?? []
        return cached.map { $0.toTaskList() }
    }

    func upsertList(_ list: TaskList) {
        if let existing = findList(serverID: list.id) {
            existing.title = list.title
            existing.position = list.position
            existing.syncedAt = Date()
            // Atualiza os itens
            list.items.forEach { item in
                if let existingItem = findItem(serverID: item.id) {
                    existingItem.text = item.text
                    existingItem.completed = item.completed
                    existingItem.position = item.position
                } else {
                    let cached = CachedTaskItem(
                        serverID: item.id, text: item.text, completed: item.completed,
                        position: item.position, taskListServerID: list.id
                    )
                    existing.items.append(cached)
                    modelContext.insert(cached)
                }
            }
        } else {
            let cached = CachedTaskList(
                serverID: list.id, title: list.title,
                userID: list.userID, position: list.position
            )
            modelContext.insert(cached)
            list.items.forEach { item in
                let cachedItem = CachedTaskItem(
                    serverID: item.id, text: item.text, completed: item.completed,
                    position: item.position, taskListServerID: list.id
                )
                cached.items.append(cachedItem)
                modelContext.insert(cachedItem)
            }
        }
        try? modelContext.save()
    }

    func deleteList(serverID: Int) {
        if let list = findList(serverID: serverID) {
            modelContext.delete(list)
            try? modelContext.save()
        }
    }

    func upsertItem(_ item: TaskItem) {
        if let existing = findItem(serverID: item.id) {
            existing.text = item.text
            existing.completed = item.completed
            existing.position = item.position
        } else if let list = findList(serverID: item.taskListID) {
            let cached = CachedTaskItem(
                serverID: item.id, text: item.text, completed: item.completed,
                position: item.position, taskListServerID: item.taskListID
            )
            list.items.append(cached)
            modelContext.insert(cached)
        }
        try? modelContext.save()
    }

    func deleteItem(serverID: Int) {
        if let item = findItem(serverID: serverID) {
            modelContext.delete(item)
            try? modelContext.save()
        }
    }

    func replaceTempID(_ tempID: Int, with realList: TaskList) {
        if let temp = findList(serverID: tempID) {
            temp.serverID = realList.id
            temp.syncedAt = Date()
        }
        try? modelContext.save()
    }

    func replaceTempItemID(_ tempID: Int, with realItem: TaskItem) {
        if let temp = findItem(serverID: tempID) {
            temp.serverID = realItem.id
            temp.syncedAt = Date()
        }
        try? modelContext.save()
    }

    // MARK: - Helpers privados
    private func findList(serverID: Int) -> CachedTaskList? {
        let descriptor = FetchDescriptor<CachedTaskList>(
            predicate: #Predicate { $0.serverID == serverID }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func findItem(serverID: Int) -> CachedTaskItem? {
        let descriptor = FetchDescriptor<CachedTaskItem>(
            predicate: #Predicate { $0.serverID == serverID }
        )
        return try? modelContext.fetch(descriptor).first
    }
}
