//
//  TaskViewModel+ReorderTests.swift
//  TodoList
//
//  Created by Renan Alves on 21/06/26.
//

import XCTest
@testable import TodoList

@MainActor
final class TaskViewModelReorderTests: XCTestCase {

    func testMoveListsReordersLocalArray() async {
        let mock = MockTaskAPIClient()
        let lists = [TaskList.stub(id: 1, title: "A"), TaskList.stub(id: 2, title: "B"), TaskList.stub(id: 3, title: "C")]
        mock.fetchListsResult = .success(TaskListResponse(lists: lists, page: 1, limit: 100, total: 3, totalPages: 1))
        let viewModel = TaskViewModel(apiClient: mock)
        await viewModel.loadLists()

        viewModel.moveLists(fromID: 1, toID: 3)

        XCTAssertEqual(viewModel.taskLists.map(\.id), [2, 3, 1])
    }

    func testPersistListOrderSendsCurrentOrderToAPI() async {
        let mock = MockTaskAPIClient()
        let lists = [TaskList.stub(id: 2), TaskList.stub(id: 1)]
        mock.fetchListsResult = .success(TaskListResponse(lists: lists, page: 1, limit: 100, total: 2, totalPages: 1))
        let viewModel = TaskViewModel(apiClient: mock)
        await viewModel.loadLists()

        await viewModel.persistListOrder()

        XCTAssertEqual(mock.reorderListsIDs, [2, 1])
    }

    func testMoveItemsReordersWithinCorrectList() async {
        let mock = MockTaskAPIClient()
        let items = [TaskItem.stub(id: 10, taskListID: 1), TaskItem.stub(id: 11, taskListID: 1)]
        let list = TaskList.stub(id: 1, items: items)
        mock.fetchListsResult = .success(TaskListResponse(lists: [list], page: 1, limit: 100, total: 1, totalPages: 1))
        let viewModel = TaskViewModel(apiClient: mock)
        await viewModel.loadLists()

        viewModel.moveItems(in: list, fromID: 10, toID: 11)

        XCTAssertEqual(viewModel.taskLists.first?.items.map(\.id), [11, 10])
    }

    func testPersistItemOrderSendsCurrentItemOrderToAPI() async {
        let mock = MockTaskAPIClient()
        let items = [TaskItem.stub(id: 11, taskListID: 1), TaskItem.stub(id: 10, taskListID: 1)]
        let list = TaskList.stub(id: 1, items: items)
        mock.fetchListsResult = .success(TaskListResponse(lists: [list], page: 1, limit: 100, total: 1, totalPages: 1))
        let viewModel = TaskViewModel(apiClient: mock)
        await viewModel.loadLists()

        await viewModel.persistItemOrder(for: list)

        XCTAssertEqual(mock.reorderItemsInput?.listID, 1)
        XCTAssertEqual(mock.reorderItemsInput?.ids, [11, 10])
    }
}
