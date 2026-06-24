//
//  TaskViewModelTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class MockTaskAPIClient: TaskAPIClient {
    var fetchListsResult: Result<TaskListResponse, Error> = .success(TaskListResponse(lists: [], page: 1, limit: 100, total: 0, totalPages: 0))
    var createListResult: Result<TaskList, Error> = .success(.stub())
    var deleteListError: Error?
    var addItemResult: Result<TaskItem, Error> = .success(.stub())
    var updateItemResult: Result<TaskItem, Error> = .success(.stub())
    var deleteItemError: Error?

    private(set) var createListCallCount = 0
    private(set) var lastDeletedListID: Int?
    private(set) var lastUpdateItemInput: (listID: Int, itemID: Int, text: String, completed: Bool)?
    private(set) var lastDeleteItemInput: (listID: Int, itemID: Int)?
    private(set) var fetchListsCallCount = 0
    private(set) var lastFetchListsSearch: String?
    private(set) var reorderListsIDs: [Int]?
    private(set) var reorderItemsInput: (listID: Int, ids: [Int])?

    func reorderLists(ids: [Int]) async throws {
        reorderListsIDs = ids
    }

    func reorderItems(listID: Int, ids: [Int]) async throws {
        reorderItemsInput = (listID, ids)
    }

    func fetchLists(search: String, page: Int, limit: Int) async throws -> TaskListResponse {
        fetchListsCallCount += 1
        lastFetchListsSearch = search
        return try fetchListsResult.get()
    }

    func createList(title: String) async throws -> TaskList {
        createListCallCount += 1
        return try createListResult.get()
    }

    func updateList(id: Int, title: String) async throws -> TaskList {
        .stub(id: id, title: title)
    }

    func deleteList(id: Int) async throws {
        lastDeletedListID = id
        if let deleteListError { throw deleteListError }
    }

    func addItem(listID: Int, text: String) async throws -> TaskItem {
        try addItemResult.get()
    }

    func updateItem(listID: Int, itemID: Int, text: String, completed: Bool) async throws -> TaskItem {
        lastUpdateItemInput = (listID, itemID, text, completed)
        return try updateItemResult.get()
    }

    func deleteItem(listID: Int, itemID: Int) async throws {
        lastDeleteItemInput = (listID, itemID)
        if let deleteItemError { throw deleteItemError }
    }
}

@MainActor
final class TaskViewModelTests: XCTestCase {

    func testLoadListsPopulatesTaskListsOnSuccess() async {
        let mock = MockTaskAPIClient()
        mock.fetchListsResult = .success(TaskListResponse(lists: [.stub(id: 1), .stub(id: 2)], page: 1, limit: 100, total: 2, totalPages: 1))
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)

        await viewModel.loadLists()

        XCTAssertEqual(viewModel.taskLists.count, 2)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadListsSetsErrorMessageOnFailure() async {
        let mock = MockTaskAPIClient()
        mock.fetchListsResult = .failure(APIError.notAuthenticated)
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)

        await viewModel.loadLists()

        XCTAssertTrue(viewModel.taskLists.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Sessão expirada, faça login novamente")
    }

    func testAddListAppendsReturnedListToTaskLists() async {
        let mock = MockTaskAPIClient()
        mock.createListResult = .success(.stub(id: 9, title: "Nova lista"))
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)

        await viewModel.addList(title: "Nova lista")

        XCTAssertEqual(viewModel.taskLists.first?.title, "Nova lista")
        XCTAssertEqual(mock.createListCallCount, 1)
    }

    func testAddListWithBlankTitleDoesNotCallAPI() async {
        let mock = MockTaskAPIClient()
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)

        await viewModel.addList(title: "   ")

        XCTAssertEqual(mock.createListCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "O título é obrigatório")
    }

    func testDeleteListRemovesItFromTaskLists() async {
        let mock = MockTaskAPIClient()
        let list = TaskList.stub(id: 1)
        mock.fetchListsResult = .success(TaskListResponse(lists: [list], page: 1, limit: 100, total: 1, totalPages: 1))
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)
        await viewModel.loadLists()

        await viewModel.deleteList(list)

        XCTAssertTrue(viewModel.taskLists.isEmpty)
        XCTAssertEqual(mock.lastDeletedListID, 1)
    }

    func testAddItemAppendsItemToCorrectList() async {
        let mock = MockTaskAPIClient()
        let list = TaskList.stub(id: 1)
        mock.fetchListsResult = .success(TaskListResponse(lists: [list], page: 1, limit: 100, total: 1, totalPages: 1))
        mock.addItemResult = .success(.stub(id: 5, text: "Leite", taskListID: 1))
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)
        await viewModel.loadLists()

        await viewModel.addItem(text: "Leite", to: list)

        XCTAssertEqual(viewModel.taskLists.first?.items.count, 1)
        XCTAssertEqual(viewModel.taskLists.first?.items.first?.text, "Leite")
    }

    func testToggleCompletedSendsInvertedValueAndUpdatesLocalItem() async {
        let mock = MockTaskAPIClient()
        let item = TaskItem.stub(id: 5, completed: false, taskListID: 1)
        let list = TaskList.stub(id: 1, items: [item])
        mock.fetchListsResult = .success(TaskListResponse(lists: [list], page: 1, limit: 100, total: 1, totalPages: 1))
        mock.updateItemResult = .success(.stub(id: 5, completed: true, taskListID: 1))
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)
        await viewModel.loadLists()

        await viewModel.toggleCompleted(item, in: list)

        XCTAssertEqual(mock.lastUpdateItemInput?.completed, true)
        XCTAssertEqual(viewModel.taskLists.first?.items.first?.completed, true)
    }

    func testDeleteItemRemovesItFromCorrectList() async {
        let mock = MockTaskAPIClient()
        let item = TaskItem.stub(id: 5, taskListID: 1)
        let list = TaskList.stub(id: 1, items: [item])
        mock.fetchListsResult = .success(TaskListResponse(lists: [list], page: 1, limit: 100, total: 1, totalPages: 1))
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)
        await viewModel.loadLists()

        await viewModel.deleteItem(item, from: list)

        XCTAssertTrue(viewModel.taskLists.first?.items.isEmpty ?? false)
        XCTAssertEqual(mock.lastDeleteItemInput?.listID, 1)
        XCTAssertEqual(mock.lastDeleteItemInput?.itemID, 5)
    }

    func testDeleteItemFailureKeepsItemAndSetsErrorMessage() async {
        let mock = MockTaskAPIClient()
        let item = TaskItem.stub(id: 5, taskListID: 1)
        let list = TaskList.stub(id: 1, items: [item])
        mock.fetchListsResult = .success(TaskListResponse(lists: [list], page: 1, limit: 100, total: 1, totalPages: 1))
        mock.deleteItemError = APIError.server(message: "item não encontrado")
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)
        await viewModel.loadLists()

        await viewModel.deleteItem(item, from: list)

        XCTAssertEqual(viewModel.taskLists.first?.items.count, 1)
        XCTAssertEqual(viewModel.errorMessage, "item não encontrado")
    }
    
    func testRenameListUpdatesTitleInTaskLists() async {
        let mock = MockTaskAPIClient()
        let list = TaskList.stub(id: 1, title: "Antigo título")
        mock.fetchListsResult = .success(TaskListResponse(lists: [list], page: 1, limit: 100, total: 1, totalPages: 1))
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)
        await viewModel.loadLists()

        await viewModel.renameList(list, title: "Novo título")

        XCTAssertEqual(viewModel.taskLists.first?.title, "Novo título")
    }
}
