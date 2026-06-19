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
    private(set) var tasks: [TodoTask] = []
    var isLoading = false
    var errorMessage: String?

    private let apiClient: TaskAPIClient

    init(apiClient: TaskAPIClient) {
        self.apiClient = apiClient
    }

    func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.fetchTasks(completed: nil, search: "", page: 1, limit: 100)
            tasks = response.tasks
        } catch {
            errorMessage = message(for: error)
        }

        isLoading = false
    }

    func addTask(title: String, description: String) async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "O título é obrigatório"
            return
        }

        errorMessage = nil

        do {
            let task = try await apiClient.createTask(title: title, description: description)
            tasks.append(task)
        } catch {
            errorMessage = message(for: error)
        }
    }

    func toggleCompleted(_ task: TodoTask) async {
        await update(task: task, title: task.title, description: task.description, completed: !task.completed)
    }

    func update(task: TodoTask, title: String, description: String, completed: Bool) async {
        errorMessage = nil

        do {
            let updated = try await apiClient.updateTask(id: task.id, title: title, description: description, completed: completed)
            if let index = tasks.firstIndex(where: { $0.id == updated.id }) {
                tasks[index] = updated
            }
        } catch {
            errorMessage = message(for: error)
        }
    }

    func delete(_ task: TodoTask) async {
        errorMessage = nil

        do {
            try await apiClient.deleteTask(id: task.id)
            tasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        (error as? APIError)?.userMessage ?? error.localizedDescription
    }
}
