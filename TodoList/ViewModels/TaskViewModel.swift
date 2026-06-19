//
//  TaskViewModel.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class TaskViewModel {
    private(set) var taskLists: [TaskList] = []
    var isLoading = false
    var errorMessage: String?

    private let apiClient: TaskAPIClient

    init(apiClient: TaskAPIClient) {
        self.apiClient = apiClient
    }

    func loadLists() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.fetchLists(search: "", page: 1, limit: 100)
            taskLists = response.lists
        } catch {
            errorMessage = message(for: error)
        }

        isLoading = false
    }

    func addList(title: String) async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "O título é obrigatório"
            return
        }

        errorMessage = nil

        do {
            let list = try await apiClient.createList(title: title)
            taskLists.append(list)
        } catch {
            errorMessage = message(for: error)
        }
    }

    func deleteList(_ list: TaskList) async {
        errorMessage = nil

        do {
            try await apiClient.deleteList(id: list.id)
            taskLists.removeAll { $0.id == list.id }
        } catch {
            errorMessage = message(for: error)
        }
    }

    func addItem(text: String, to list: TaskList) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "O texto do item é obrigatório"
            return
        }

        errorMessage = nil

        do {
            let item = try await apiClient.addItem(listID: list.id, text: text)
            if let index = taskLists.firstIndex(where: { $0.id == list.id }) {
                taskLists[index].items.append(item)
            }
        } catch {
            errorMessage = message(for: error)
        }
    }

    func toggleCompleted(_ item: TaskItem, in list: TaskList) async {
        await updateItem(item, in: list, text: item.text, completed: !item.completed)
    }

    func updateItem(_ item: TaskItem, in list: TaskList, text: String, completed: Bool) async {
        errorMessage = nil

        do {
            let updated = try await apiClient.updateItem(listID: list.id, itemID: item.id, text: text, completed: completed)
            if let listIndex = taskLists.firstIndex(where: { $0.id == list.id }),
               let itemIndex = taskLists[listIndex].items.firstIndex(where: { $0.id == updated.id }) {
                taskLists[listIndex].items[itemIndex] = updated
            }
        } catch {
            errorMessage = message(for: error)
        }
    }

    func deleteItem(_ item: TaskItem, from list: TaskList) async {
        errorMessage = nil

        do {
            try await apiClient.deleteItem(listID: list.id, itemID: item.id)
            if let listIndex = taskLists.firstIndex(where: { $0.id == list.id }) {
                taskLists[listIndex].items.removeAll { $0.id == item.id }
            }
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        (error as? APIError)?.userMessage ?? error.localizedDescription
    }
}
