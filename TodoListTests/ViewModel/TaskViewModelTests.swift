//
//  TaskViewModelTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class MockTaskAPIClient: TaskAPIClient {
    var fetchTasksResult: Result<TaskListResponse, Error> = .success(TaskListResponse(tasks: [], page: 1, limit: 100, total: 0, totalPages: 0))
    var createTaskResult: Result<TodoTask, Error> = .success(.stub())
    var updateTaskResult: Result<TodoTask, Error> = .success(.stub())
    var deleteTaskError: Error?

    private(set) var createTaskCallCount = 0
    private(set) var lastUpdateInput: (id: Int, title: String, description: String, completed: Bool)?
    private(set) var lastDeletedID: Int?

    func fetchTasks(completed: Bool?, search: String, page: Int, limit: Int) async throws -> TaskListResponse {
        try fetchTasksResult.get()
    }

    func createTask(title: String, description: String) async throws -> TodoTask {
        createTaskCallCount += 1
        return try createTaskResult.get()
    }

    func updateTask(id: Int, title: String, description: String, completed: Bool) async throws -> TodoTask {
        lastUpdateInput = (id, title, description, completed)
        return try updateTaskResult.get()
    }

    func deleteTask(id: Int) async throws {
        lastDeletedID = id
        if let deleteTaskError {
            throw deleteTaskError
        }
    }
}

@MainActor
final class TaskViewModelTests: XCTestCase {

    func testLoadTasksPopulatesTasksOnSuccess() async {
        let mock = MockTaskAPIClient()
        mock.fetchTasksResult = .success(TaskListResponse(tasks: [.stub(id: 1), .stub(id: 2)], page: 1, limit: 100, total: 2, totalPages: 1))
        let viewModel = TaskViewModel(apiClient: mock)

        await viewModel.loadTasks()

        XCTAssertEqual(viewModel.tasks.count, 2)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadTasksSetsErrorMessageOnFailure() async {
        let mock = MockTaskAPIClient()
        mock.fetchTasksResult = .failure(APIError.notAuthenticated)
        let viewModel = TaskViewModel(apiClient: mock)

        await viewModel.loadTasks()

        XCTAssertTrue(viewModel.tasks.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Sessão expirada, faça login novamente")
    }

    func testAddTaskAppendsReturnedTaskToList() async {
        let mock = MockTaskAPIClient()
        mock.createTaskResult = .success(.stub(id: 9, title: "Nova lista"))
        let viewModel = TaskViewModel(apiClient: mock)

        await viewModel.addTask(title: "Nova lista", description: "")

        XCTAssertEqual(viewModel.tasks.first?.title, "Nova lista")
        XCTAssertEqual(mock.createTaskCallCount, 1)
    }

    func testAddTaskWithBlankTitleDoesNotCallAPI() async {
        let mock = MockTaskAPIClient()
        let viewModel = TaskViewModel(apiClient: mock)

        await viewModel.addTask(title: "   ", description: "")

        XCTAssertEqual(mock.createTaskCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "O título é obrigatório")
    }

    func testToggleCompletedSendsInvertedValueAndUpdatesLocalTask() async {
        let mock = MockTaskAPIClient()
        let original = TodoTask.stub(id: 1, completed: false)
        mock.fetchTasksResult = .success(TaskListResponse(tasks: [original], page: 1, limit: 100, total: 1, totalPages: 1))
        mock.updateTaskResult = .success(.stub(id: 1, completed: true))
        let viewModel = TaskViewModel(apiClient: mock)
        await viewModel.loadTasks()

        await viewModel.toggleCompleted(original)

        XCTAssertEqual(mock.lastUpdateInput?.completed, true)
        XCTAssertEqual(viewModel.tasks.first?.completed, true)
    }

    func testDeleteRemovesTaskFromList() async {
        let mock = MockTaskAPIClient()
        let task = TodoTask.stub(id: 1)
        mock.fetchTasksResult = .success(TaskListResponse(tasks: [task], page: 1, limit: 100, total: 1, totalPages: 1))
        let viewModel = TaskViewModel(apiClient: mock)
        await viewModel.loadTasks()

        await viewModel.delete(task)

        XCTAssertTrue(viewModel.tasks.isEmpty)
        XCTAssertEqual(mock.lastDeletedID, 1)
    }

    func testDeleteFailureKeepsTaskAndSetsErrorMessage() async {
        let mock = MockTaskAPIClient()
        let task = TodoTask.stub(id: 1)
        mock.fetchTasksResult = .success(TaskListResponse(tasks: [task], page: 1, limit: 100, total: 1, totalPages: 1))
        mock.deleteTaskError = APIError.server(message: "tarefa não encontrada")
        let viewModel = TaskViewModel(apiClient: mock)
        await viewModel.loadTasks()

        await viewModel.delete(task)

        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.errorMessage, "tarefa não encontrada")
    }
}
